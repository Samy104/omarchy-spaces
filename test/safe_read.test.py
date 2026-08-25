# The shell plugin is long lived, so a read of a replaceable path must be
# bounded, must not block, and must not be redirected by a symlink. These are
# the exact cases the marketplace security review named.
import os, stat, sys, tempfile, types

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
cli = types.ModuleType("cli")
src = open(os.path.join(root, "bin", "omarchy-spaces")).read()
src = src.replace('if __name__ == "__main__":\n    sys.exit(main(sys.argv[1:]))', "")
exec(src, cli.__dict__)

passed = failed = 0


def check(name, got, want):
    global passed, failed
    if got == want:
        passed += 1
        print("  ok   %s" % name)
    else:
        failed += 1
        print("  FAIL %s: got %r, want %r" % (name, got, want))


tmp = tempfile.mkdtemp()

print("\nthe happy path still works")
good = os.path.join(tmp, "good.json")
open(good, "w").write('{"a":1}')
text, reason = cli.safe_read(good, 1 << 20)
check("a regular file you own is read", (text, reason), ('{"a":1}', None))

print("\nsymlink replacement")
secret = os.path.join(tmp, "secret")
open(secret, "w").write("SHOULD NOT BE READ")
link = os.path.join(tmp, "link.json")
os.symlink(secret, link)
text, reason = cli.safe_read(link, 1 << 20)
check("a symlink is refused, not followed", text, None)
check("and says why", reason, "is a symlink")

print("\nFIFO, the case that would stall the shell forever")
fifo = os.path.join(tmp, "fifo.json")
os.mkfifo(fifo)
# With no writer, a blocking open would hang here and never return.
text, reason = cli.safe_read(fifo, 1 << 20)
check("a FIFO is refused rather than waited on", text, None)
check("and says why", reason, "is not a regular file")

print("\ndirectory in place of the file")
d = os.path.join(tmp, "dir.json")
os.mkdir(d)
text, reason = cli.safe_read(d, 1 << 20)
check("a directory is refused", text, None)

print("\noversized file")
big = os.path.join(tmp, "big.json")
with open(big, "wb") as fh:
    fh.write(b"x" * 5000)
text, reason = cli.safe_read(big, 4096)
check("over the limit is refused", text, None)
check("and says the limit", reason, "is larger than 4096 bytes")
text, reason = cli.safe_read(big, 1 << 20)
check("under a larger limit it reads", len(text or ""), 5000)

print("\nexactly at the limit is allowed")
edge = os.path.join(tmp, "edge.json")
open(edge, "wb").write(b"y" * 4096)
text, reason = cli.safe_read(edge, 4096)
check("a file exactly at the limit reads", len(text or ""), 4096)

print("\nmissing file")
text, reason = cli.safe_read(os.path.join(tmp, "nope"), 4096)
check("absent is reported, not raised", (text, reason), (None, "does not exist"))

print("\ndevice node")
text, reason = cli.safe_read("/dev/zero", 4096)
check("/dev/zero is refused rather than read forever", text, None)
check("and says why", reason, "is not a regular file")

print("\n%d passed, %d failed\n" % (passed, failed))
sys.exit(0 if failed == 0 else 1)
