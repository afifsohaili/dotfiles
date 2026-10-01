import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Caffeinate picker panel. Anchored above the bar icon, it offers preset
// durations, a typed duration (bare number = hours), an extend affordance
// while a run is active, and the display-dim toggle.
//
// The widget (Caffeinate.qml) is the source of truth for live state and is
// injected here as `status`; every action is delegated back to it so the
// CLI remains the only writer of the caffeinate state file.
Panel {
  id: root
  moduleName: "local.caffeinate"
  ipcTarget: "local.caffeinate"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  // The bar widget instance; live state + actions.
  property var status: null
  readonly property var barIdentity: hostWidget || root

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color dim: Qt.darker(foreground, 1.55)

  readonly property bool running: status ? status.active === true : false
  readonly property double remainingSecs: status ? status.remainingSeconds : 0
  readonly property bool dimActive: status ? status.dim === true : false
  readonly property double expiresAt: status ? status.expiresAt : 0

  // Presets are start durations while idle and extend amounts while running.
  readonly property var presets: Model.parsePresets(
    setting("presets", "30m,1h,2h,4h,8h,12h,24h"))
  readonly property var extendPresets: ["30m", "1h", "4h"]

  // Dim is a sticky panel preference for the next start; while a run is
  // active the toggle re-applies the run with the new value right away.
  property bool dimWanted: false

  property string inputText: ""

  readonly property int parsedSeconds: Model.parseDuration(inputText)
  readonly property bool hasInput: inputText.trim() !== ""
  readonly property bool parsedValid: Model.isValid(parsedSeconds)

  readonly property string untilText: expiresAt > 0
    ? Qt.formatDateTime(new Date(expiresAt * 1000), "HH:mm")
    : ""
  readonly property string remainingText: status ? status.remainingText : ""

  readonly property string previewText: {
    if (!hasInput) return ""
    if (parsedSeconds < 0) return "Could not read that"
    if (parsedSeconds < Model.MIN_SECONDS) return "Minimum is 1 minute"
    if (parsedSeconds > Model.MAX_SECONDS) return "Maximum is 7 days"
    return "= " + Model.formatLong(parsedSeconds)
  }
  readonly property bool previewBad: hasInput && !parsedValid

  onOpenedChanged: {
    if (!opened) return
    dimWanted = dimActive
    inputText = ""
    Qt.callLater(function() { if (inputField) inputField.forceActiveFocus() })
  }

  function submit() {
    if (!parsedValid || !status) return
    if (running) status.extendCaffeinate(inputText, dimWanted)
    else status.startCaffeinate(inputText, dimWanted)
    inputText = ""
    root.close()
  }

  function choosePreset(spec) {
    if (!status) return
    if (running) status.extendCaffeinate(spec, dimWanted)
    else status.startCaffeinate(spec, dimWanted)
    root.close()
  }

  function extendBy(spec) {
    if (!status) return
    status.extendCaffeinate(spec, dimWanted)
  }

  function stopRun() {
    if (!status) return
    status.stopCaffeinate()
    root.close()
  }

  function toggleDim() {
    dimWanted = !dimWanted
    // Apply to a live run by restarting it with the remaining time; the CLI
    // owns the brightness save/restore either way.
    if (running && status) status.startCaffeinate(Math.max(60, Math.round(remainingSecs)) + "s", dimWanted)
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      // Let the TextField own the keys (including Enter) while it is focused.
      blocked: inputField.activeFocus
      onCloseRequested: root.close()

      Column {
        id: column
        width: parent.width
        spacing: Style.space(12)

        PanelHero {
          width: parent.width
          title: "Caffeinate"
          meta: root.running
            ? "Running · until " + root.untilText
            : "Not running"
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconComponent: Component {
            Text {
              text: "󰅶"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        // ---- Running: remaining time as the headline.
        Text {
          width: parent.width
          visible: root.running
          text: root.remainingText
          textFormat: Text.PlainText
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.display
          horizontalAlignment: Text.AlignHCenter
        }

        // ---- Idle: one-click start durations.
        Flow {
          width: parent.width
          visible: !root.running
          spacing: Style.space(6)

          Repeater {
            model: root.presets

            Button {
              required property string modelData
              text: modelData
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.choosePreset(modelData)
            }
          }
        }

        // ---- Running: one-click extend amounts, plus stop.
        Flow {
          width: parent.width
          visible: root.running
          spacing: Style.space(6)

          Repeater {
            model: root.extendPresets

            Button {
              required property string modelData
              text: "+" + modelData
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.extendBy(modelData)
            }
          }

          Button {
            text: "Stop"
            bordered: true
            foreground: Color.urgent
            fontFamily: root.fontFamily
            onClicked: root.stopRun()
          }
        }

        // ---- Typed duration.
        Row {
          width: parent.width
          spacing: Style.space(8)

          TextField {
            id: inputField
            width: parent.width - startButton.width - parent.spacing
            placeholderText: "1 = 1h · 90m · 3d"
            foreground: root.foreground
            font.family: root.fontFamily
            text: root.inputText
            onTextChanged: if (text !== root.inputText) root.inputText = text
            onAccepted: root.submit()
            Keys.onEscapePressed: root.close()
          }

          Button {
            id: startButton
            text: root.running ? "Extend" : "Start"
            bordered: true
            enabled: root.parsedValid
            foreground: root.parsedValid ? root.foreground : root.dim
            fontFamily: root.fontFamily
            onClicked: root.submit()
          }
        }

        Text {
          width: parent.width
          visible: root.previewText !== ""
          text: root.previewText
          textFormat: Text.PlainText
          color: root.previewBad ? Color.urgent : root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        // ---- Dim toggle.
        Toggle {
          width: parent.width
          label: "Dim display to 10%"
          description: root.running && root.dimWanted !== root.dimActive
            ? "Re-applying…"
            : "Pre-dims the focused display while caffeinating."
          checked: root.dimWanted
          foreground: root.foreground
          fontFamily: root.fontFamily
          onClicked: root.toggleDim()
        }
      }
    }
  }
}
