.pragma library

// Duration grammar shared by the panel's input preview and validation. It
// mirrors `duration_seconds()` in omarchy-caffeinate so what the panel shows
// is what the CLI will parse. Bare numbers are hours; d is accepted but never
// shown (3d labels as 72h).

var MIN_SECONDS = 60
var MAX_SECONDS = 604800 // 7 days

function parseDuration(raw) {
  var s = String(raw === undefined || raw === null ? "" : raw)
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "")
  if (s === "") return -1

  var m
  // 3d, 1.5d -> days
  m = /^([0-9]+)(?:\.([0-9]+))?d$/.exec(s)
  if (m) return Math.round((parseInt(m[1], 10) + parseFloat("0." + (m[2] || "0"))) * 86400)

  // 1h30m
  m = /^([0-9]+)h([0-9]+)m$/.exec(s)
  if (m) return parseInt(m[1], 10) * 3600 + parseInt(m[2], 10) * 60

  // 90m
  m = /^([0-9]+)m$/.exec(s)
  if (m) return parseInt(m[1], 10) * 60

  // 3, 1.5, 2h -> hours (bare number is hours)
  m = /^([0-9]+)(?:\.([0-9]+))?h?$/.exec(s)
  if (m) return Math.round((parseInt(m[1], 10) + parseFloat("0." + (m[2] || "0"))) * 3600)

  return -1
}

function isValid(seconds) {
  return seconds >= MIN_SECONDS && seconds <= MAX_SECONDS
}

// Countdown label the bar shows: 36h, 1h, 30m. Ceil, never days.
function formatLabel(seconds) {
  var s = Math.max(0, Math.floor(seconds))
  if (s <= 0) return ""
  if (s >= 3600) return Math.ceil(s / 3600) + "h"
  return Math.ceil(s / 60) + "m"
}

// Finer human text for the panel: 35h 41m, 30m.
function formatLong(seconds) {
  var s = Math.max(0, Math.floor(seconds))
  if (s <= 0) return "0m"
  var hours = Math.floor(s / 3600)
  var minutes = Math.floor((s % 3600) / 60)
  if (hours > 0) return minutes > 0 ? hours + "h " + minutes + "m" : hours + "h"
  return minutes > 0 ? minutes + "m" : "<1m"
}

function parsePresets(raw) {
  var out = []
  var parts = String(raw === undefined || raw === null ? "" : raw).split(",")
  for (var i = 0; i < parts.length; i++) {
    var spec = parts[i].trim()
    if (spec === "") continue
    out.push(spec)
  }
  return out
}
