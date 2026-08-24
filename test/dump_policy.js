// Dump every policy decision the JS implementation makes, for parity checking.
var fs = require("fs"), path = require("path")
var L = require("../SpacesLogic.js")
var cfg = JSON.parse(fs.readFileSync(path.join(__dirname, "..", "config", "spaces.example.json"), "utf8"))
var apps = ["Signal", "Slack", "Ghost", "spotify", "SLACK.desktop", ""]
var out = []
L.spaceIds(cfg).forEach(function (sid) {
  for (var m = 0; m < 1440; m++) {
    var pol = L.resolvePolicy(cfg, sid, m)
    var row = [sid, m, pol.allowFrom.slice().sort(), pol.source, !!pol.allowUnassigned]
    apps.forEach(function (a) {
      var owner = L.spaceForApp(cfg, a)
      var allowed = owner === null ? !!pol.allowUnassigned : pol.allowFrom.indexOf(owner) !== -1
      row.push([a, owner, allowed])
    })
    out.push(row)
  }
})
console.log(JSON.stringify(out))
