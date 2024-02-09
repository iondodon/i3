#!/usr/bin/env bash
set -euo pipefail

LOGFILE=""
ROFI_ARGS=()
KB_ACCEPT_APPEND=""
MODE=""
while getopts "m:l:" OPTION; do 
    case "$OPTION" in
        m)
            MODE="$OPTARG"
            case "$MODE" in
                alttab)
                    ROFI_ARGS+=( -show window -selected-row 1) # -selected-row is only available in https://github.com/davatorium/rofi/pull/909
                    KB_ACCEPT_APPEND=",!Alt+Alt_L"
                    ;;
                altspace)
                    ROFI_ARGS+=( -show window )
                    ;;
                superspace)
                    ROFI_ARGS+=( -show drun )
                    ;;
                *)
                    echo "unknown mode $MODE";
                    exit 1 # todo use libnotify to display error
                    ;;
            esac
            ;;
        l)
            LOGFILE="$OPTARG"
            ;;
        *)
            echo "unknown option '$OPTION'"
            exit 1
            ;;
    esac
done

if [ "$MODE" == "" ]; then
    echo "must specify a mode"
    exit 1
fi

if [ "$LOGFILE" != "" ]; then
    echo "redirecting output to file"
    exec >> "$LOGFILE"
    exec 2>&1
fi

# Capture the cursor's original position
eval $(xdotool getmouselocation --shell)

# Launch rofi
export ROFI_DUMP_WINDOW_POSITION="$(mktemp)"
rofi \
    -kb-cancel "Alt+Escape,Escape" \
    -kb-accept-entry '!Alt-Tab,!Alt+Down,!Alt+ISO_Left_Tab,!Alt+Up,Return'$KB_ACCEPT_APPEND \
    -kb-row-down 'Alt-Tab,Alt+Down,Down' \
    -kb-row-up 'Alt+ISO_Left_Tab,Alt+Up,Up' \
    "${ROFI_ARGS[@]}" \
    -show window -run-command "i3-msg exec '{cmd}'" -show-icons&
rofipid="$!"

# The strategy to move the cursor into the rofi window immediately after it appears
(
    sleep 0.1 # Small delay to ensure rofi window is up
    # Wait for the ROFI window to appear by monitoring its PID
    while : ; do
        if xdotool search --pid "$rofipid" > /dev/null 2>&1; then
            break # Rofi window found
        fi
        sleep 0.1
    done

    # Now move the mouse to the center of the rofi window
    WIN_ID=$(xdotool search --pid "$rofipid" | head -n 1)
    eval $(xdotool getwindowgeometry --shell "$WIN_ID")
    let "X+=WIDTH/2"
    let "Y+=HEIGHT/2"
    xdotool mousemove $X $Y
) &

# Wait for rofi to close
wait "$rofipid"

# Move the cursor back to its original position
xdotool mousemove $X $Y

# Clean up
rm -f "$ROFI_DUMP_WINDOW_POSITION"
