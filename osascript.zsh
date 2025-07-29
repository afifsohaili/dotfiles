function notify() {
  osascript -e "display notification \"$1\" with title \"Notification\""
}

function alert() {
  osascript -e "display dialog \"$1\" with title \"Alert\" buttons {\"Ok\"} default button \"Ok\""
}
