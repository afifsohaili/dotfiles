import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Caffeinate bar widget: a coffee cup that carries the hours left while a
// stay-awake run lasts, and a picker panel (Panel.qml) for starting,
// extending, or stopping one. State comes from
// `omarchy-caffeinate status --json`; the state file flip on start/stop is
// what drives updates, with a slow timer as a safety net.
BarWidget {
  id: root
  moduleName: "local.caffeinate"

  readonly property string glyph: "󰅶"

  // ---------------------------------------------------------------- state
  property bool active: false
  property double expiresAt: 0
  property double startedAt: 0
  property real hours: 0
  property bool dim: false
  property double nowMs: Date.now()
  property bool refreshing: false

  readonly property double remainingSeconds: active
    ? Math.max(0, Math.round((expiresAt * 1000 - nowMs) / 1000))
    : 0
  readonly property string remainingLabel: Model.formatLabel(remainingSeconds)
  readonly property string remainingText: Model.formatLong(remainingSeconds)

  function refresh() {
    if (statusProc.running) return
    statusProc.running = true
  }

  function applyStatus(raw) {
    var data = {}
    try {
      data = JSON.parse(String(raw || "").trim() || "{}")
    } catch (error) {
      data = {}
    }
    root.active = data.active === true
    root.expiresAt = Number(data.expiresAt || 0)
    root.startedAt = Number(data.startedAt || 0)
    root.hours = Number(data.hours || 0)
    root.dim = data.dim === true
    root.nowMs = Date.now()
    if (root.active) tickTimer.restart()
  }

  // Actions run through the shared caffeinate CLI; state changes land in the
  // state file, which the watcher below picks up.
  function startCaffeinate(spec, dim) {
    if (!root.bar) return
    root.bar.run("omarchy-caffeinate start " + shellQuote(String(spec)) + (dim ? " --dim" : ""))
  }

  function extendCaffeinate(spec, dim) {
    if (!root.bar) return
    root.bar.run("omarchy-caffeinate extend " + shellQuote(String(spec)) + (dim ? " --dim" : ""))
  }

  function stopCaffeinate() {
    if (root.bar) root.bar.run("omarchy-caffeinate stop")
  }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  // Panel plumbing, the contract shell.summon/hide/toggle use for
  // bar-widget panels (see clock's BarWidget): open/close/opened + the
  // popout-switch close the coordinator hands off to.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("status" in target) target.status = root
  }

  // ----------------------------------------------------------------- bars

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Component.onCompleted: refresh()

  Timer {
    id: tickTimer
    interval: 15000
    repeat: true
    running: false
    onTriggered: {
      root.nowMs = Date.now()
      if (root.remainingSeconds <= 1) root.refresh()
    }
  }

  Timer {
    id: pollTimer
    interval: 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: refreshAfterAction
    interval: 400
    onTriggered: root.refresh()
  }

  Process {
    id: statusProc
    command: ["omarchy-caffeinate", "status", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyStatus(text)
    }
    onExited: function(exitCode) {
      root.refreshing = false
      if (exitCode !== 0) {
        root.active = false
        root.dim = false
        root.nowMs = Date.now()
        refreshAfterAction.restart()
      }
    }
  }

  // Directory watch: the state file is created/removed inside it on every
  // start/stop, so watching the directory catches both edges.
  FileView {
    id: stateDirWatch
    path: Quickshell.env("HOME") + "/.local/state/omarchy/caffeinate"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
  }

  IpcHandler {
    target: "local.caffeinate"

    function refresh(): void { root.broadcast("refresh") }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.active ? root.glyph + " " + root.remainingLabel : root.glyph
    hasVisualContent: text !== ""
    horizontalMargin: 6
    verticalPadding: 5
    fontSize: Style.font.caption
    active: root.active
    useActiveColor: false
    dimmed: !root.active
    keepSpace: false
    tooltipText: root.tooltip

    onPressed: function(button) {
      if (button === Qt.RightButton) {
        if (root.active) root.stopCaffeinate()
        else root.togglePanel()
        return
      }
      root.togglePanel()
    }
  }

  readonly property string tooltip: {
    if (!root.active) return "Caffeinate — click to stay awake"
    var text = "Caffeinate: " + root.remainingText + " left"
    if (root.dim) text += " · display 10%"
    return text
  }
}
