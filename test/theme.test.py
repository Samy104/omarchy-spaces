# The app maps Omarchy's colors.toml onto libadwaita's named colours. A wrong
# mapping is not a crash, it is an unreadable window, so the contrast rule and
# the required keys are checked here rather than by squinting at a screenshot.
import ast, os, sys

here = os.path.dirname(os.path.abspath(__file__))
root = os.path.dirname(here)

app = type(sys)("app")
src = open(os.path.join(root, "bin", "omarchy-spaces-config")).read()
# Import only the pure helpers; the rest needs a display.
start = src.index("def _luminance(")
end = src.index("class ThemeWatcher:")
exec("import json\n" + src[start:end], app.__dict__)

passed = failed = 0


def check(name, got, want):
    global passed, failed
    if got == want:
        passed += 1
        print("  ok   %s" % name)
    else:
        failed += 1
        print("  FAIL %s: got %r, want %r" % (name, got, want))


print("\nreadable text on accent colours")
check("white on a dark accent", app._on("#1a1a2e"), "#ffffff")
check("black on a bright accent", app._on("#f9cc6c"), "#000000")
check("black on white", app._on("#ffffff"), "#000000")
check("white on black", app._on("#000000"), "#ffffff")
check("garbage falls back to white", app._on("not-a-colour"), "#ffffff")

print("\nnamed colours libadwaita needs")
ristretto = {
    "mode": "dark", "accent": "#f38d70", "background": "#2c2525",
    "dark_background": "#211b1b", "darker_background": "#181414",
    "lighter_background": "#3d2f2a", "foreground": "#e6d9db",
    "muted": "#72696a", "red": "#fd6883", "green": "#adda78", "yellow": "#f9cc6c",
}
css = app.theme_css(ristretto)
required = ["window_bg_color", "window_fg_color", "view_bg_color",
            "headerbar_bg_color", "sidebar_bg_color", "card_bg_color",
            "dialog_bg_color", "popover_bg_color", "accent_bg_color",
            "accent_fg_color", "destructive_bg_color", "success_color",
            "warning_color", "error_color"]
missing = [k for k in required if ("@define-color %s " % k) not in css]
check("every required colour is defined", missing, [])
check("the palette's own values are used", "@define-color window_bg_color #2c2525;" in css, True)
check("accent drives the accent colour", "@define-color accent_bg_color #f38d70;" in css, True)

print("\nmissing keys do not produce broken css")
sparse = app.theme_css({"mode": "dark"})
check("a nearly empty palette still defines everything",
      [k for k in required if ("@define-color %s " % k) not in sparse], [])
check("no empty colour values", "@define-color window_bg_color ;" in sparse, False)

print("\n%d passed, %d failed\n" % (passed, failed))
sys.exit(0 if failed == 0 else 1)
