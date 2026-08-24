// Pure policy logic for Omarchy Spaces.
//
// This file has no QML or Quickshell imports on purpose. Everything here is
// plain JavaScript so the same code runs inside the shell and under node in
// the test suite. Anything that touches the filesystem, D-Bus, or the shell
// lives in Service.qml or bin/omarchy-spaces instead.

var DAY_MINUTES = 24 * 60

// "08:00" becomes 480. Returns null for anything that is not HH:MM.
function parseTime(value) {
  if (typeof value !== "string") return null
  var m = /^([01]?\d|2[0-3]):([0-5]\d)$/.exec(value.trim())
  if (!m) return null
  return parseInt(m[1], 10) * 60 + parseInt(m[2], 10)
}

function minutesNow(date) {
  var d = date || new Date()
  return d.getHours() * 60 + d.getMinutes()
}

// Windows may wrap past midnight, so 22:00 to 08:00 is a single window that
// covers the late evening and the early morning. The end bound is exclusive so
// two windows that share a boundary do not both match.
function windowContains(win, nowMinutes) {
  var from = parseTime(win && win.from)
  var to = parseTime(win && win.to)
  if (from === null || to === null) return false
  if (from === to) return true
  if (from < to) return nowMinutes >= from && nowMinutes < to
  return nowMinutes >= from || nowMinutes < to
}

function normalizeList(value) {
  if (!Array.isArray(value)) return []
  var out = []
  for (var i = 0; i < value.length; i++) {
    var s = String(value[i] || "").trim()
    if (s && out.indexOf(s) === -1) out.push(s)
  }
  return out
}

function findSpace(config, spaceId) {
  var spaces = (config && Array.isArray(config.spaces)) ? config.spaces : []
  for (var i = 0; i < spaces.length; i++) {
    if (spaces[i] && String(spaces[i].id) === String(spaceId)) return spaces[i]
  }
  return null
}

function spaceIds(config) {
  var spaces = (config && Array.isArray(config.spaces)) ? config.spaces : []
  var out = []
  for (var i = 0; i < spaces.length; i++) {
    if (spaces[i] && spaces[i].id) out.push(String(spaces[i].id))
  }
  return out
}


// Defaults inheritance.
//
// A top-level `defaults` object supplies values for every space. A space
// overrides what it sets and inherits the rest, so a shared schedule, browser,
// or workspace count is written once.
//
// Objects merge one key at a time, recursively. Arrays and scalars are
// replaced whole, because a half-inherited list is harder to reason about than
// an explicit one. Identity fields are never inherited.
var IDENTITY_KEYS = ["id", "name", "icon", "color"]

function isPlainObject(v) {
  return v !== null && typeof v === "object" && !Array.isArray(v)
}

function deepMerge(base, override) {
  if (!isPlainObject(base)) return override
  if (!isPlainObject(override)) return override === undefined ? base : override
  var out = {}
  var k
  for (k in base) out[k] = base[k]
  for (k in override) {
    out[k] = (isPlainObject(out[k]) && isPlainObject(override[k]))
      ? deepMerge(out[k], override[k])
      : override[k]
  }
  return out
}

function resolveSpace(config, spaceId) {
  var space = findSpace(config, spaceId)
  if (!space) return null
  var defaults = (config && isPlainObject(config.defaults)) ? config.defaults : null
  if (!defaults) return space
  var base = {}
  for (var k in defaults) {
    if (IDENTITY_KEYS.indexOf(k) === -1) base[k] = defaults[k]
  }
  return deepMerge(base, space)
}

// Which keys a space inherits rather than sets itself. The config app uses
// this to mark a field as inherited instead of pretending the user chose it.
function inheritedKeys(config, spaceId) {
  var space = findSpace(config, spaceId)
  var defaults = (config && isPlainObject(config.defaults)) ? config.defaults : null
  if (!space || !defaults) return []
  var out = []
  for (var k in defaults) {
    if (IDENTITY_KEYS.indexOf(k) !== -1) continue
    if (space[k] === undefined) out.push(k)
  }
  return out
}

// Which space owns an app, decided by the `apps` list on each space. Matching
// is case insensitive and ignores a trailing ".desktop", because the same app
// reaches us as "Signal", "signal", and "signal.desktop" depending on whether
// it came from a notification hint or a desktop entry.
function normalizeAppKey(name) {
  var s = String(name || "").trim().toLowerCase()
  if (s.slice(-8) === ".desktop") s = s.slice(0, -8)
  return s
}


// An `apps` entry is either a bare string or an object. The string form covers
// the common case where the notification name and the window class match.
//
//   "Signal"
//   { "name": "Steam", "class": "steam", "slot": 2 }
//
// `name` matches the app_name a notification carries. `class` matches the
// Hyprland window class, which is often but not always the same string.
// `slot` is which workspace of the owning space its windows open on.
function appEntry(raw) {
  if (typeof raw === "string") {
    var name = raw.trim()
    return name ? { name: name, cls: name, slot: 1, windowRule: true, shared: false } : null
  }
  if (raw && typeof raw === "object") {
    var n = String(raw.name || raw.class || "").trim()
    if (!n) return null
    var slot = parseInt(raw.slot, 10)
    return {
      name: n,
      cls: String(raw["class"] || n).trim(),
      slot: isFinite(slot) && slot > 0 ? slot : 1,
      windowRule: raw.windowRule !== false,
      // A shared app belongs to no single space. Its notifications always get
      // through and its windows are never forced anywhere, which is what a
      // music player or a password manager actually wants.
      shared: raw.shared === true
    }
  }
  return null
}

function appEntries(space) {
  var list = (space && Array.isArray(space.apps)) ? space.apps : []
  var out = []
  for (var i = 0; i < list.length; i++) {
    var e = appEntry(list[i])
    if (e) out.push(e)
  }
  return out
}


// Every app marked shared, from the defaults block and from every space.
//
// Read from `defaults.apps` directly rather than through resolveSpace, because
// arrays replace on inherit: a space with its own apps list would otherwise
// never see a shared entry declared in defaults, which is the one place people
// will put a music player.
function sharedAppEntries(config) {
  var out = []
  var lists = []
  if (config && isPlainObject(config.defaults)) lists.push(config.defaults)
  var spaces = (config && Array.isArray(config.spaces)) ? config.spaces : []
  for (var i = 0; i < spaces.length; i++) lists.push(spaces[i])
  for (var l = 0; l < lists.length; l++) {
    var entries = appEntries(lists[l])
    for (var j = 0; j < entries.length; j++) {
      if (entries[j].shared) out.push(entries[j])
    }
  }
  return out
}

function isSharedApp(config, appName) {
  var key = normalizeAppKey(appName)
  if (!key) return false
  var shared = sharedAppEntries(config)
  for (var i = 0; i < shared.length; i++) {
    if (normalizeAppKey(shared[i].name) === key) return true
  }
  return false
}

function spaceForApp(config, appName) {
  var key = normalizeAppKey(appName)
  if (!key) return null
  var ids = spaceIds(config)
  for (var i = 0; i < ids.length; i++) {
    var entries = appEntries(resolveSpace(config, ids[i]))
    for (var j = 0; j < entries.length; j++) {
      if (entries[j].shared) continue
      if (normalizeAppKey(entries[j].name) === key) return String(ids[i])
    }
  }
  return null
}

// The set of spaces whose notifications are allowed right now, given which
// space is active and what time it is.
//
// A space carries a baseline `notifications.allowFrom`. Schedule windows
// override that baseline for the hours they cover. The first matching window
// wins, so order matters and callers should keep windows non overlapping.
function resolvePolicy(config, activeSpaceId, nowMinutes) {
  var space = resolveSpace(config, activeSpaceId)
  if (!space) {
    return { allowFrom: spaceIds(config), source: "no-space", window: null, allowUnassigned: true }
  }

  var notif = space.notifications || {}
  var baseline = normalizeList(notif.allowFrom)
  var allowUnassigned = notif.allowUnassigned !== false

  var windows = Array.isArray(notif.schedule) ? notif.schedule : []
  for (var i = 0; i < windows.length; i++) {
    if (windowContains(windows[i], nowMinutes)) {
      var win = windows[i]
      return {
        allowFrom: normalizeList(win.allowFrom),
        source: "schedule",
        window: { from: win.from, to: win.to, label: win.label || "" },
        allowUnassigned: win.allowUnassigned !== undefined
          ? win.allowUnassigned !== false
          : allowUnassigned
      }
    }
  }

  return { allowFrom: baseline, source: "baseline", window: null, allowUnassigned: allowUnassigned }
}

// True when every space is muted, which is the case the built-in global DND
// flag models exactly. The service mirrors this into omarchy.notifications so
// the existing bar icon and history behaviour stay correct.
function isFullyMuted(policy) {
  return !!policy && policy.allowFrom.length === 0 && !policy.allowUnassigned
}

// The decision for one notification.
function shouldShow(config, activeSpaceId, notification, nowMinutes, options) {
  var opts = options || {}
  var policy = resolvePolicy(config, activeSpaceId, nowMinutes)
  var app = notification && notification.app

  // Critical notifications bypass filtering unless the user turns that off.
  // Losing a low battery or disk full warning because of a context filter is
  // worse than seeing one notification from the wrong space.
  var criticalBypass = (config && config.criticalBypass !== false)
  if (criticalBypass && opts.criticalUrgency !== undefined
      && notification && notification.urgency === opts.criticalUrgency) {
    return { show: true, reason: "critical-bypass", policy: policy, owner: null }
  }

  if (isSharedApp(config, app)) {
    return { show: true, reason: "shared-app", policy: policy, owner: null }
  }

  var owner = spaceForApp(config, app)
  if (owner === null) {
    return {
      show: !!policy.allowUnassigned,
      reason: policy.allowUnassigned ? "unassigned-allowed" : "unassigned-blocked",
      policy: policy,
      owner: null
    }
  }

  var allowed = policy.allowFrom.indexOf(owner) !== -1
  return {
    show: allowed,
    reason: allowed ? "space-allowed" : "space-blocked",
    policy: policy,
    owner: owner
  }
}

// Browser command for a space, as an argv array. Returns null when the space
// declares no browser, so callers can fall back to xdg-open.
function browserCommand(config, spaceId, url) {
  var space = resolveSpace(config, spaceId)
  var browser = space && space.browser
  if (!browser || !browser.command) return null

  var argv = [String(browser.command)]
  var args = normalizeList(browser.args)
  for (var i = 0; i < args.length; i++) argv.push(args[i])
  if (browser.profile) argv.push("--profile-directory=" + String(browser.profile))
  if (url) argv.push(String(url))
  return argv
}


// Hyprland workspace ranges. Mirrors ws_count and ws_offset in
// bin/omarchy-spaces; test/parity.sh checks both agree.
var DEFAULT_WS_COUNT = 10

function wsCount(config, spaceId) {
  var space = resolveSpace(config, spaceId)
  if (!space) return DEFAULT_WS_COUNT
  var ws = space.workspaces || {}
  var n = parseInt(ws.count, 10)
  return isFinite(n) && n > 0 ? n : DEFAULT_WS_COUNT
}

function wsOffset(config, spaceId) {
  var space = resolveSpace(config, spaceId)
  if (!space) return 0
  var ws = space.workspaces || {}
  if (ws.offset !== undefined && ws.offset !== null) {
    var o = parseInt(ws.offset, 10)
    return isFinite(o) ? o : 0
  }
  var idx = spaceIds(config).indexOf(String(spaceId))
  if (idx < 0) idx = 0
  return idx * wsCount(config, spaceId)
}

// Which space owns a real workspace id, and which slot it is.
function slotForReal(config, realId) {
  var ids = spaceIds(config)
  for (var i = 0; i < ids.length; i++) {
    var off = wsOffset(config, ids[i])
    var count = wsCount(config, ids[i])
    if (realId > off && realId <= off + count) {
      return { space: ids[i], slot: realId - off }
    }
  }
  return null
}

var api = {
  DAY_MINUTES: DAY_MINUTES,
  parseTime: parseTime,
  minutesNow: minutesNow,
  windowContains: windowContains,
  findSpace: findSpace,
  spaceIds: spaceIds,
  spaceForApp: spaceForApp,
  normalizeAppKey: normalizeAppKey,
  resolvePolicy: resolvePolicy,
  isFullyMuted: isFullyMuted,
  shouldShow: shouldShow,
  browserCommand: browserCommand,
  DEFAULT_WS_COUNT: DEFAULT_WS_COUNT,
  wsCount: wsCount,
  wsOffset: wsOffset,
  slotForReal: slotForReal,
  deepMerge: deepMerge,
  resolveSpace: resolveSpace,
  inheritedKeys: inheritedKeys,
  appEntry: appEntry,
  appEntries: appEntries,
  isSharedApp: isSharedApp,
  sharedAppEntries: sharedAppEntries
}

if (typeof module !== "undefined" && module.exports) module.exports = api
