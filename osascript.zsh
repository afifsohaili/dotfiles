function notify() {
  osascript -e "display notification \"$1\" with title \"Notification\""
}
