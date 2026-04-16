function latest_desktop_screenshot() {
    # get from args, defaults to 1
    local num_screenshots=1

    local output_mode="echo"
    # shift all args
    # if arg is integer, set num_screenshots
    # if not, set output_mode to either cursor, clipboard, or open based on "o", "c", or "p" flags
    while [ $# -gt 0 ]; do
        case "$1" in
            -n)
                shift
                num_screenshots=$1
                ;;
            -o)
                output_mode="cursor"
                ;;
            -c)
                output_mode="clipboard"
                ;;
            -p)
                output_mode="open"
                ;;
            *)
                output_mode="echo"
                ;;
        esac
        shift
    done
    local IFS=$'\n'
    local -a latest_screenshots=($(ls -t ~/Desktop | grep 'Screenshot' | head -n "$num_screenshots"))

    case "$output_mode" in
        "cursor")
            for img in "${latest_screenshots[@]}"; do
                local full_path="$HOME/Desktop/$img"
                local escaped_path=$(echo $full_path | sed 's/ /\\\ /g')
                cursor "$escaped_path"
            done
            ;;
        "clipboard")
            for img in "${latest_screenshots[@]}"; do
                local full_path="$HOME/Desktop/$img"
                osascript -e "set the clipboard to (read (POSIX file \"$full_path\") as TIFF picture)"
                echo "Copied $img to clipboard"
            done
            echo "Copied $num_screenshots screenshot(s) to clipboard"
            ;;
        "open")
            for img in "${latest_screenshots[@]}"; do
                local full_path="$HOME/Desktop/$img"
                open "$full_path"
            done
            ;;
        "echo")
            for img in "${latest_screenshots[@]}"; do
                local full_path="$HOME/Desktop/$img"
                echo "$full_path"
            done
            ;;
        *)
            echo "Invalid output mode: $output_mode"
            return 1
            ;;
    esac
}
