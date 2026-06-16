#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Saving alerts data to the log file"
echo "$*" >> "$SCRIPT_DIR/log.out"

echo "Invoking alert handler"
python3 "$SCRIPT_DIR/handle_alert.py" "$@"