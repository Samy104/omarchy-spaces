// Dump every policy decision the JS implementation makes, for parity checking.
var fs = require("fs"), path = require("path")
var L = require("../SpacesLogic.js")
var cfg = JSON.parse(fs.readFileSync(path.join(__dirname, "..", "config", "spaces.example.json"), "utf8"))
cfg.defaults = {apps: [{name: "SharedPlayer", shared: true}],
                notifications: {allowUnassigned: false},
                workspaces: {count: 10},
                browser: {command: "brave"},
                apps: ["SharedApp"]}
delete cfg.spaces[1].browser.command
var apps = ["Signal", "Slack", "Ghost", "spotify", "SLACK.desktop", "SharedApp", "SharedPlayer", ""]
var out = []
L.spaceIds(cfg).forEach(function (sid) {
  for (var m = 0; m < 1440; m++) {
    var pol = L.resolvePolicy(cfg, sid, m)
    var resolved = L.resolveSpace(cfg, sid) || {}
    var row = [sid, m, pol.allowFrom.slice().sort(), pol.source, !!pol.allowUnassigned,
               L.wsOffset(cfg, sid), L.wsCount(cfg, sid),
               (resolved.browser || {}).command || ""]
    apps.forEach(function (a) {
      var owner = L.spaceForApp(cfg, a)
      var allowed = L.isSharedApp(cfg, a) ? true
        : (owner === null ? !!pol.allowUnassigned : pol.allowFrom.indexOf(owner) !== -1)
      row.push([a, owner, allowed])
    })
    out.push(row)
  }
})
console.log(JSON.stringify(out))
