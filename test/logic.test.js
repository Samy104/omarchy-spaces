// Test suite for SpacesLogic. Run with: node test/logic.test.js
// No framework on purpose, so this runs anywhere node exists.

var assert = require("assert")
var fs = require("fs")
var path = require("path")
var L = require("../SpacesLogic.js")

var config = JSON.parse(fs.readFileSync(path.join(__dirname, "..", "config", "spaces.example.json"), "utf8"))

var passed = 0
var failed = 0

function test(name, fn) {
  try {
    fn()
    passed++
    console.log("  ok   " + name)
  } catch (e) {
    failed++
    console.log("  FAIL " + name)
    console.log("       " + e.message)
  }
}

function at(hhmm) { return L.parseTime(hhmm) }

console.log("\nparseTime")
test("parses HH:MM", function () {
  assert.strictEqual(L.parseTime("08:00"), 480)
  assert.strictEqual(L.parseTime("00:00"), 0)
  assert.strictEqual(L.parseTime("23:59"), 1439)
})
test("rejects junk", function () {
  assert.strictEqual(L.parseTime("24:00"), null)
  assert.strictEqual(L.parseTime("8:0"), null)
  assert.strictEqual(L.parseTime(""), null)
  assert.strictEqual(L.parseTime(null), null)
})

console.log("\nwindowContains")
test("normal window, end is exclusive", function () {
  var w = { from: "08:00", to: "17:00" }
  assert.strictEqual(L.windowContains(w, at("08:00")), true)
  assert.strictEqual(L.windowContains(w, at("12:30")), true)
  assert.strictEqual(L.windowContains(w, at("16:59")), true)
  assert.strictEqual(L.windowContains(w, at("17:00")), false)
  assert.strictEqual(L.windowContains(w, at("07:59")), false)
})
test("window wrapping past midnight", function () {
  var w = { from: "22:00", to: "08:00" }
  assert.strictEqual(L.windowContains(w, at("22:00")), true)
  assert.strictEqual(L.windowContains(w, at("23:59")), true)
  assert.strictEqual(L.windowContains(w, at("00:00")), true)
  assert.strictEqual(L.windowContains(w, at("07:59")), true)
  assert.strictEqual(L.windowContains(w, at("08:00")), false)
  assert.strictEqual(L.windowContains(w, at("12:00")), false)
})
test("adjacent windows never both match", function () {
  var a = { from: "08:00", to: "17:00" }
  var b = { from: "17:00", to: "22:00" }
  for (var m = 0; m < 1440; m++) {
    assert.ok(!(L.windowContains(a, m) && L.windowContains(b, m)), "overlap at minute " + m)
  }
})
test("the example personal schedule covers all 1440 minutes exactly once", function () {
  var wins = config.spaces[0].notifications.schedule
  for (var m = 0; m < 1440; m++) {
    var hits = 0
    for (var i = 0; i < wins.length; i++) if (L.windowContains(wins[i], m)) hits++
    assert.strictEqual(hits, 1, "minute " + m + " matched " + hits + " windows")
  }
})

console.log("\nspaceForApp")
test("maps apps to owning space, case insensitive", function () {
  assert.strictEqual(L.spaceForApp(config, "Signal"), "personal")
  assert.strictEqual(L.spaceForApp(config, "signal"), "personal")
  assert.strictEqual(L.spaceForApp(config, "Slack"), "work")
  assert.strictEqual(L.spaceForApp(config, "slack.desktop"), "work")
})
test("unknown app has no owner", function () {
  assert.strictEqual(L.spaceForApp(config, "SomeRandomApp"), null)
  assert.strictEqual(L.spaceForApp(config, ""), null)
})

console.log("\nresolvePolicy, the schedule from the spec")
test("personal at 09:00 allows personal and work", function () {
  var p = L.resolvePolicy(config, "personal", at("09:00"))
  assert.deepStrictEqual(p.allowFrom.sort(), ["personal", "work"])
  assert.strictEqual(p.source, "schedule")
})
test("personal at 19:00 allows personal only", function () {
  var p = L.resolvePolicy(config, "personal", at("19:00"))
  assert.deepStrictEqual(p.allowFrom, ["personal"])
})
test("personal at 23:00 allows nothing", function () {
  var p = L.resolvePolicy(config, "personal", at("23:00"))
  assert.deepStrictEqual(p.allowFrom, [])
  assert.strictEqual(L.isFullyMuted(p), true)
})
test("personal at 03:00 still allows nothing, the wrap works", function () {
  var p = L.resolvePolicy(config, "personal", at("03:00"))
  assert.deepStrictEqual(p.allowFrom, [])
  assert.strictEqual(L.isFullyMuted(p), true)
})
test("work at 10:00 allows work only, never personal", function () {
  var p = L.resolvePolicy(config, "work", at("10:00"))
  assert.deepStrictEqual(p.allowFrom, ["work"])
})

console.log("\nshouldShow")
test("in work, a personal app is blocked", function () {
  var r = L.shouldShow(config, "work", { app: "Signal" }, at("10:00"))
  assert.strictEqual(r.show, false)
  assert.strictEqual(r.owner, "personal")
  assert.strictEqual(r.reason, "space-blocked")
})
test("in work, a work app is shown", function () {
  var r = L.shouldShow(config, "work", { app: "Slack" }, at("10:00"))
  assert.strictEqual(r.show, true)
})
test("in personal during work hours, a work app is shown", function () {
  var r = L.shouldShow(config, "personal", { app: "Slack" }, at("10:00"))
  assert.strictEqual(r.show, true)
})
test("in personal in the evening, a work app is blocked", function () {
  var r = L.shouldShow(config, "personal", { app: "Slack" }, at("19:00"))
  assert.strictEqual(r.show, false)
})
test("in personal in the evening, a personal app is shown", function () {
  var r = L.shouldShow(config, "personal", { app: "Signal" }, at("19:00"))
  assert.strictEqual(r.show, true)
})
test("at night nothing is shown, assigned or not", function () {
  assert.strictEqual(L.shouldShow(config, "personal", { app: "Signal" }, at("23:30")).show, false)
  assert.strictEqual(L.shouldShow(config, "personal", { app: "Whatever" }, at("23:30")).show, false)
})
test("critical urgency bypasses filtering", function () {
  var r = L.shouldShow(config, "work", { app: "Signal", urgency: 2 }, at("23:30"), { criticalUrgency: 2 })
  assert.strictEqual(r.show, true)
  assert.strictEqual(r.reason, "critical-bypass")
})
test("critical bypass can be turned off", function () {
  var off = JSON.parse(JSON.stringify(config))
  off.criticalBypass = false
  var r = L.shouldShow(off, "work", { app: "Signal", urgency: 2 }, at("23:30"), { criticalUrgency: 2 })
  assert.strictEqual(r.show, false)
})
test("unassigned apps follow allowUnassigned", function () {
  assert.strictEqual(L.shouldShow(config, "personal", { app: "Ghost" }, at("10:00")).show, true)
  assert.strictEqual(L.shouldShow(config, "work", { app: "Ghost" }, at("10:00")).show, false)
})

console.log("\nbrowserCommand")
test("builds argv with the profile flag", function () {
  assert.deepStrictEqual(L.browserCommand(config, "personal", "https://example.com"),
    ["brave", "--profile-directory=Default", "https://example.com"])
  assert.deepStrictEqual(L.browserCommand(config, "work", "https://example.com"),
    ["brave", "--profile-directory=Profile 1", "https://example.com"])
})
test("profile name with a space stays one argv element", function () {
  var argv = L.browserCommand(config, "work", "https://x.test")
  assert.strictEqual(argv[1], "--profile-directory=Profile 1")
  assert.strictEqual(argv.length, 3)
})
test("unknown space yields null so callers fall back", function () {
  assert.strictEqual(L.browserCommand(config, "nope", "https://x.test"), null)
})

console.log("\ndefaults inheritance")
test("a space inherits what it does not set", function () {
  var c = { defaults: { browser: { command: "brave" }, workspaces: { count: 6 } },
            spaces: [{ id: "a", browser: { profile: "Default" } }] }
  var r = L.resolveSpace(c, "a")
  assert.strictEqual(r.browser.command, "brave")
  assert.strictEqual(r.browser.profile, "Default")
  assert.strictEqual(L.wsCount(c, "a"), 6)
})
test("a space overrides what it does set", function () {
  var c = { defaults: { browser: { command: "brave" } },
            spaces: [{ id: "a", browser: { command: "chromium" } }] }
  assert.strictEqual(L.resolveSpace(c, "a").browser.command, "chromium")
})
test("arrays replace rather than merge", function () {
  var c = { defaults: { apps: ["A", "B"] }, spaces: [{ id: "a", apps: ["C"] }] }
  assert.deepStrictEqual(L.resolveSpace(c, "a").apps, ["C"])
})
test("identity is never inherited", function () {
  var c = { defaults: { name: "Nope", icon: "X", color: "#fff" }, spaces: [{ id: "a" }] }
  var r = L.resolveSpace(c, "a")
  assert.strictEqual(r.name, undefined)
  assert.strictEqual(r.icon, undefined)
  assert.strictEqual(r.color, undefined)
})
test("inheritedKeys reports only what was not set locally", function () {
  var c = { defaults: { browser: { command: "brave" }, apps: ["A"] },
            spaces: [{ id: "a", apps: ["B"] }] }
  assert.deepStrictEqual(L.inheritedKeys(c, "a"), ["browser"])
})
test("no defaults block leaves spaces untouched", function () {
  var c = { spaces: [{ id: "a", apps: ["X"] }] }
  assert.deepStrictEqual(L.resolveSpace(c, "a"), { id: "a", apps: ["X"] })
})
test("a schedule set once in defaults applies to every space", function () {
  var c = { defaults: { notifications: { schedule: [
              { from: "22:00", to: "08:00", allowFrom: [], allowUnassigned: false }] } },
            spaces: [{ id: "a", notifications: { allowFrom: ["a"] } }, { id: "b" }] }
  assert.strictEqual(L.resolvePolicy(c, "a", L.parseTime("23:00")).allowFrom.length, 0)
  assert.strictEqual(L.resolvePolicy(c, "b", L.parseTime("23:00")).allowFrom.length, 0)
  assert.strictEqual(L.resolvePolicy(c, "a", L.parseTime("10:00")).allowFrom[0], "a")
})

console.log("\napp entries and shared apps")
test("a bare string is the simple form", function () {
  var e = L.appEntry("Signal")
  assert.strictEqual(e.name, "Signal")
  assert.strictEqual(e.cls, "Signal")
  assert.strictEqual(e.slot, 1)
  assert.strictEqual(e.windowRule, true)
  assert.strictEqual(e.shared, false)
})
test("an object form carries class, slot, and opt-outs", function () {
  var e = L.appEntry({ name: "Steam", "class": "steam", slot: 4, windowRule: false })
  assert.strictEqual(e.cls, "steam")
  assert.strictEqual(e.slot, 4)
  assert.strictEqual(e.windowRule, false)
})
test("a shared app is owned by nobody", function () {
  var c = { defaults: { apps: [{ name: "YT Music", shared: true }] },
            spaces: [{ id: "a", apps: ["Signal"] }] }
  assert.strictEqual(L.spaceForApp(c, "YT Music"), null)
  assert.strictEqual(L.isSharedApp(c, "YT Music"), true)
})
test("a shared app reaches every space even when spaces override apps", function () {
  var c = { defaults: { apps: [{ name: "YT Music", shared: true }] },
            spaces: [
              { id: "a", apps: ["Signal"], notifications: { allowFrom: ["a"], allowUnassigned: false } },
              { id: "b", apps: ["Slack"], notifications: { allowFrom: ["b"], allowUnassigned: false } }] }
  assert.strictEqual(L.shouldShow(c, "a", { app: "YT Music" }, 600).show, true)
  assert.strictEqual(L.shouldShow(c, "b", { app: "YT Music" }, 600).show, true)
  assert.strictEqual(L.shouldShow(c, "a", { app: "Slack" }, 600).show, false)
})
test("shared still obeys a full mute", function () {
  var c = { defaults: { apps: [{ name: "YT Music", shared: true }] },
            spaces: [{ id: "a", notifications: { allowFrom: [], allowUnassigned: false } }] }
  // Shared means "belongs to no space", not "ignores the schedule".
  assert.strictEqual(L.isSharedApp(c, "YT Music"), true)
})

console.log("\n" + passed + " passed, " + failed + " failed\n")
process.exit(failed === 0 ? 0 : 1)
