import QtQuick
import Quickshell
import Quickshell.Io
import "SpacesLogic.js" as Logic

// Omarchy Spaces policy service.
//
// Owns three things:
//   1. which space is active, read from and written to a state file that the
//      CLI shares, so a hotkey switch and a bar click cannot disagree
//   2. the notification policy in effect right now, recomputed when the
//      config changes, the space changes, or the clock crosses a minute
//   3. enforcement, by filtering popups the built-in notification service has
//      already accepted
//
// Enforcement works by post filtering rather than by replacing
// omarchy.notifications. The built-in service stays the D-Bus owner, history
// keeps recording everything, and a blocked notification is still there in
// history when you switch back to the space that owns it. Replacing the
// daemon would mean reimplementing history, images, actions, and the popup
// lifecycle, and it would break the moment Omarchy changed any of them.
Item {
  id: service

  // Injected by omarchy-shell.
  property var shell: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")) + "/omarchy-spaces"
  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")) + "/omarchy-spaces"
  readonly property string configPath: configDir + "/spaces.json"
  readonly property string activePath: stateDir + "/active"

  property var config: ({ spaces: [] })
  property bool configLoaded: false
  property string configError: ""

  property string activeSpaceId: ""
  property int nowMinutes: Logic.minutesNow()

  readonly property var spaces: (config && Array.isArray(config.spaces)) ? config.spaces : []
  readonly property var activeSpace: Logic.findSpace(config, activeSpaceId)
  readonly property var policy: Logic.resolvePolicy(config, activeSpaceId, nowMinutes)

  // True when the active policy blocks at least one space that exists. Drives
  // the dot on the bar icon, so filtering is visible rather than mysterious.
  readonly property bool filtering: {
    var all = Logic.spaceIds(config)
    if (!all.length) return false
    for (var i = 0; i < all.length; i++) {
      if (policy.allowFrom.indexOf(all[i]) === -1) return true
    }
    return !policy.allowUnassigned
  }

  readonly property bool fullyMuted: Logic.isFullyMuted(policy)

  // Workspace range of the active space, read by the Spaces workspace widget
  // so the bar can show slot numbers instead of real Hyprland ids.
  readonly property bool workspaceIsolation: !(config && config.workspaceIsolation === false)
  readonly property int wsOffset: Logic.wsOffset(config, activeSpaceId)
  readonly property int wsCount: Logic.wsCount(config, activeSpaceId)

  function slotForReal(realId) { return Logic.slotForReal(config, realId) }

  readonly property var notificationService: shell ? shell.serviceFor("omarchy.notifications") : null

  signal spaceChanged(string spaceId)

  function displayName(spaceId) {
    var s = Logic.findSpace(config, spaceId)
    return s ? (s.name || s.id) : spaceId
  }

  function iconFor(spaceId) {
    var s = Logic.findSpace(config, spaceId)
    return (s && s.icon) ? s.icon : "●"
  }

  function colorFor(spaceId) {
    var s = Logic.findSpace(config, spaceId)
    return (s && s.color) ? s.color : ""
  }

  // Switching goes through the CLI rather than writing the state file here.
  // The CLI also runs user hooks and sends the toast, and having exactly one
  // implementation of "switch" means a hotkey and a bar click do the same
  // thing, including the parts this service does not know about.
  function switchTo(spaceId) {
    if (!spaceId || spaceId === activeSpaceId) return
    switchProcess.command = ["omarchy-spaces", "switch", String(spaceId)]
    switchProcess.running = true
  }

  // Open the config in the user's editor. Falls back through EDITOR and then
  // to xdg-open, so this does something sensible whether or not a terminal
  // editor is configured.
  function openConfigInEditor() {
    editorProcess.command = ["bash", "-lc",
      "cfg=" + JSON.stringify(configPath) + "; " +
      "mkdir -p \"$(dirname \"$cfg\")\"; " +
      "[ -f \"$cfg\" ] || omarchy-spaces init >/dev/null 2>&1; " +
      "if [ -n \"${EDITOR:-}\" ]; then exec uwsm-app -- $TERMINAL -e $EDITOR \"$cfg\"; " +
      "else exec xdg-open \"$cfg\"; fi"]
    editorProcess.running = true
  }

  function cycle(step) {
    var ids = Logic.spaceIds(config)
    if (!ids.length) return
    var idx = ids.indexOf(activeSpaceId)
    if (idx === -1) idx = 0
    switchTo(ids[(idx + step + ids.length) % ids.length])
  }

  // --- notification filtering ------------------------------------------------

  // Urgency 2 is Critical in the freedesktop spec. The built-in service uses
  // NotificationUrgency.Critical for the same value.
  readonly property int criticalUrgency: 2

  function decide(row) {
    return Logic.shouldShow(config, activeSpaceId, row, nowMinutes,
                            { criticalUrgency: criticalUrgency })
  }

  // Guards against re-entering the sweep. removePopup mutates popupModel,
  // which re-fires the model signals this service listens to. Without the
  // guard the sweep recurses into a half-mutated model and the notification
  // card renders a row whose fields are all undefined.
  property bool sweeping: false

  function sweepPopups() {
    if (sweeping) return
    Qt.callLater(runSweep)
  }

  // Walk the popup model backwards and drop anything the current policy blocks.
  // Backwards because removePopup shifts every index above the one removed.
  //
  // Deferred through Qt.callLater so the model is never mutated from inside
  // its own change signal.
  function runSweep() {
    if (sweeping) return
    if (!configLoaded) return
    var ns = notificationService
    if (!ns || !ns.popupModel) return
    sweeping = true
    try {
      for (var i = ns.popupModel.count - 1; i >= 0; i--) {
        if (i >= ns.popupModel.count) continue
        var row = ns.popupModel.get(i)
        if (!row || row.app === undefined) continue
        var verdict = decide({ app: row.app, urgency: row.urgency })
        if (!verdict.show) ns.removePopup(i, "dismiss")
      }
    } finally {
      sweeping = false
    }
  }

  // The built-in global DND flag is the honest representation of "allow
  // nothing", and reusing it keeps the stock DND bar icon truthful. Anything
  // narrower than a full mute is ours to enforce, because the built-in flag
  // has no notion of which app a notification came from.
  function syncGlobalDnd() {
    var ns = notificationService
    if (!ns || typeof ns.setDoNotDisturb !== "function") return
    if (fullyMuted && !ns.doNotDisturb) ns.setDoNotDisturb(true)
    else if (!fullyMuted && ns.doNotDisturb && dndOwnedByUs) ns.setDoNotDisturb(false)
  }

  // Only release DND if we were the ones who set it. A user who hits the DND
  // toggle themselves should not have it undone by a schedule boundary.
  property bool dndOwnedByUs: false
  onFullyMutedChanged: {
    var ns = notificationService
    if (fullyMuted) dndOwnedByUs = !!(ns && !ns.doNotDisturb)
    syncGlobalDnd()
    if (!fullyMuted) dndOwnedByUs = false
  }

  onPolicyChanged: sweepPopups()
  onActiveSpaceIdChanged: {
    sweepPopups()
    syncGlobalDnd()
    spaceChanged(activeSpaceId)
  }

  // Only rowsInserted. Listening to countChanged as well would fire on this
  // service's own removals and turn every filtered notification into a second
  // sweep pass.
  Connections {
    target: service.notificationService && service.notificationService.popupModel
      ? service.notificationService.popupModel : null
    ignoreUnknownSignals: true
    function onRowsInserted() { service.sweepPopups() }
  }

  // --- clock -----------------------------------------------------------------

  // Every 20 seconds rather than every minute. A schedule boundary should take
  // effect within a few seconds of the wall clock, and this is cheap enough
  // that aligning to the exact minute is not worth the bookkeeping.
  Timer {
    interval: 20000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      var m = Logic.minutesNow()
      if (m !== service.nowMinutes) service.nowMinutes = m
    }
  }

  // --- files -----------------------------------------------------------------

  // Both files are rewritten by atomic rename (the CLI writes a .tmp and calls
  // os.replace, and most editors do the same). A rename swaps the inode, so a
  // FileView pointed at the file keeps watching the old one and never fires.
  // Watching the parent directory and re-reading through a Process is the same
  // workaround Omarchy's own Bar.qml uses for its toggles flag.

  Component.onCompleted: {
    ensureDirs.running = true
  }

  Process {
    id: ensureDirs
    command: ["bash", "-c", "mkdir -p " + JSON.stringify(service.configDir) + " " + JSON.stringify(service.stateDir)]
    onExited: function () {
      configProbe.running = true
      activeProbe.running = true
    }
  }

  Process {
    id: configProbe
    command: ["bash", "-c", "cat " + JSON.stringify(service.configPath) + " 2>/dev/null"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "").trim()
        if (raw === "") {
          service.configError = "no config at " + service.configPath
          service.configLoaded = false
          return
        }
        try {
          var parsed = JSON.parse(raw)
          service.config = parsed
          service.configError = ""
          service.configLoaded = true
          if (!Logic.findSpace(parsed, service.activeSpaceId)) {
            var ids = Logic.spaceIds(parsed)
            service.activeSpaceId = (parsed.activeSpace && Logic.findSpace(parsed, parsed.activeSpace))
              ? String(parsed.activeSpace)
              : (ids.length ? ids[0] : "")
          }
          service.sweepPopups()
        } catch (e) {
          service.configError = String(e)
          console.warn("omarchy-spaces: config parse failed: " + e)
        }
      }
    }
  }

  Process {
    id: activeProbe
    command: ["bash", "-c", "cat " + JSON.stringify(service.activePath) + " 2>/dev/null"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var id = String(text || "").trim()
        if (id !== "" && id !== service.activeSpaceId) service.activeSpaceId = id
      }
    }
  }

  // Both the directory and the file, because the two ways of saving a file
  // produce different events and each watcher misses one of them.
  //
  //   atomic rename (the CLI, most editors)  -> directory event, no file event
  //                                             the watched inode is replaced
  //   in-place write (nano, cat >, sed -i)   -> file event, no directory event
  //                                             the directory did not change
  //
  // Watching only the directory was the original bug: editing spaces.json by
  // hand in an in-place editor changed nothing until the shell restarted.
  FileView {
    path: service.configDir
    watchChanges: true
    printErrors: false
    onFileChanged: configProbe.running = true
  }

  FileView {
    path: service.configPath
    watchChanges: true
    printErrors: false
    onFileChanged: configProbe.running = true
    onLoadFailed: { /* not written yet; the directory watcher covers creation */ }
  }

  FileView {
    path: service.stateDir
    watchChanges: true
    printErrors: false
    onFileChanged: activeProbe.running = true
  }

  FileView {
    path: service.activePath
    watchChanges: true
    printErrors: false
    onFileChanged: activeProbe.running = true
    onLoadFailed: { /* no state file until the first switch */ }
  }

  Process {
    id: editorProcess
  }

  Process {
    id: switchProcess
    onExited: function () {
      activeProbe.running = true
      configProbe.running = true
    }
  }
}
