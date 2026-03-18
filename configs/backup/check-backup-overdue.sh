#!/bin/bash

STATE_FILE="$HOME/.local/state/borg_rsync_last_run"
OVERDUE_DAYS=14

sleep 15

if [[ ! -f "$STATE_FILE" ]] || [[ -n "$(find "$STATE_FILE" -mtime +"$OVERDUE_DAYS" 2>/dev/null)" ]]; then
    notify-send "Backup Overdue!" "Plug in your backup drive to sync. It has been over $OVERDUE_DAYS days." --icon=dialog-warning --urgency=critical
fi