# DEFAULT_KEYBINDS exists in the CLI and again in the config app. They must
# agree, otherwise the app offers a binding the CLI never writes, or writes one
# the app cannot show.
import ast, os, sys

here = os.path.dirname(os.path.abspath(__file__))
root = os.path.dirname(here)


def literal(path, name):
    tree = ast.parse(open(os.path.join(root, path)).read())
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign):
            for t in node.targets:
                if isinstance(t, ast.Name) and t.id == name:
                    return ast.literal_eval(node.value)
    return None


def fields(path):
    tree = ast.parse(open(os.path.join(root, path)).read())
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign):
            for t in node.targets:
                if isinstance(t, ast.Name) and t.id == "KEYBIND_FIELDS":
                    return [row[0] for row in ast.literal_eval(node.value)]
    return []


cli = literal("bin/omarchy-spaces", "DEFAULT_KEYBINDS")
app = literal("bin/omarchy-spaces-config", "DEFAULT_KEYBINDS")
labels = literal("bin/omarchy-spaces", "KEYBIND_LABELS")
shown = fields("bin/omarchy-spaces-config")

failed = 0
if cli != app:
    print("  FAIL DEFAULT_KEYBINDS differ")
    for k in sorted(set(cli) | set(app)):
        if cli.get(k) != app.get(k):
            print("       %-18s cli=%r app=%r" % (k, cli.get(k), app.get(k)))
    failed += 1
else:
    print("  ok   DEFAULT_KEYBINDS match, %d bindings" % len(cli))

missing_ui = sorted(set(cli) - set(shown))
if missing_ui:
    print("  FAIL not editable in the app: %s" % ", ".join(missing_ui))
    failed += 1
else:
    print("  ok   every binding is editable in the app")

missing_label = sorted(set(cli) - set(labels))
if missing_label:
    print("  FAIL no label in `keybinds show`: %s" % ", ".join(missing_label))
    failed += 1
else:
    print("  ok   every binding has a label in `keybinds show`")

sys.exit(0 if failed == 0 else 1)
