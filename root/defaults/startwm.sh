#!/usr/bin/env bash

monitor_proton_dirs() {
    local LOCKFILE="/tmp/proton_monitor.lock"
    local SEARCH_DIR="$HOME/.steam/steam/steamapps/common"
    local SOURCE_FILE="/defaults/user_settings.py"
    if [ -f "$LOCKFILE" ]; then
        local PID=$(cat "$LOCKFILE")
        if kill -0 "$PID" > /dev/null 2>&1; then
            echo "Proton monitor is already running with PID $PID."
            return 0
        fi
    fi
    echo $$ > "$LOCKFILE"
    while true; do
        if [ -f "$SOURCE_FILE" ]; then
            shopt -s nullglob
            for dir in "$SEARCH_DIR"/*Proton*/; do
                if [ -d "$dir" ]; then
                    # Check if the destination file does NOT exist
                    if [ ! -f "$dir/user_settings.py" ]; then
                        echo "Copying settings to: $dir"
                        cp "$SOURCE_FILE" "$dir/"
                    fi
                fi
            done
            shopt -u nullglob
        fi
        sleep 1
    done
}

(monitor_proton_dirs) &

# Start DE
if [ "${SELKIES_DESKTOP,,}" == "true" ]; then
  exec dbus-launch --exit-with-session /usr/bin/openbox-session > /dev/null 2>&1 &
  OPENBOX_PID=$!
  sleep 1
  selkies-desktop
  kill $OPENBOX_PID
else
  exec dbus-launch --exit-with-session /usr/bin/openbox-session > /dev/null 2>&1
fi
