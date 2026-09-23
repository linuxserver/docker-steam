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
ulimit -c 0
export XCURSOR_THEME=breeze_cursors
export XCURSOR_SIZE=24
export XKB_DEFAULT_LAYOUT=us
export XKB_DEFAULT_RULES=evdev
export WAYLAND_DISPLAY=wayland-1

if [ "${PELORUS,,}" == "true" ]; then
  export QT_ACCESSIBILITY=1
  export QT_LINUX_ACCESSIBILITY_ALWAYS_ON=1
  export GTK_MODULES=gail:atk-bridge
  export MOZ_ENABLE_WAYLAND=0
  if [ "${SELKIES_DESKTOP,,}" == "true" ]; then
    dbus-run-session bash -c '
      /usr/libexec/at-spi2-registryd &
      ATSPI_PID=$!
      pelorus &
      PELORUS_PID=$!
      labwc &
      LABWC_PID=$!
      sleep 1
      export WAYLAND_DISPLAY=wayland-0
      export DISPLAY=:0
      selkies-desktop
      kill $ATSPI_PID
      kill $LABWC_PID
      kill $PELORUS_PID
    ' > /dev/null 2>&1
  else
    dbus-run-session bash -c '
      /usr/libexec/at-spi2-registryd &
      ATSPI_PID=$!
      pelorus &
      PELORUS_PID=$!
      labwc
      kill $ATSPI_PID
      kill $PELORUS_PID
    ' > /dev/null 2>&1
  fi
else
  if [ "${SELKIES_DESKTOP,,}" == "true" ]; then
    labwc > /dev/null 2>&1 &
    LABWC_PID=$!
    sleep 1
    export WAYLAND_DISPLAY=wayland-0
    export DISPLAY=:0
    selkies-desktop
    kill $LABWC_PID
  else
    labwc > /dev/null 2>&1
  fi
fi
