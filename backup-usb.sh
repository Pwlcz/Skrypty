#!/bin/bash
# Script to backup Borg repository to any mounted drive with matching label using rsync.

REPOSITORY="${REPOSITORY:-$HOME/borg_backup}"
STATE_FILE="$HOME/.local/state/borg_rsync_last_run"
COOLDOWN_DAYS=7

if [[ -f "$STATE_FILE" ]] && [[ -n "$(find "$STATE_FILE" -mtime -"$COOLDOWN_DAYS" 2>/dev/null)" ]]; then
    echo "Last sync was less than $COOLDOWN_DAYS days ago. Skipping rsync."
    exit 0
fi

if [[ -n "$1" && "$1" == /media/$USER/Pwlcz_* ]]; then
    POSSIBLE_DRIVES=("$1")
else
    shopt -s nullglob
    POSSIBLE_DRIVES=(/media/$USER/Pwlcz_*/)
    shopt -u nullglob
fi

if [ ${#POSSIBLE_DRIVES[@]} -eq 0 ]; then
    echo "No external drives matching 'Pwlcz_*' are currently mounted."
    exit 0
fi

echo "Found ${#POSSIBLE_DRIVES[@]} drive(s). Starting parallel sync..."

for dest in "${POSSIBLE_DRIVES[@]}"; do
    if [ -d "$dest" ]; then
        echo " -> Starting background sync to: $dest"
        rsync -a --delete "$REPOSITORY/" "${dest}borg-repo-copy/" &
    fi
done

echo "Waiting for all transfers to complete..."
wait

mkdir -p "$(dirname "$STATE_FILE")"
echo $(date +%Y-%m-%dT%H:%M:%S) > "$STATE_FILE"

echo "All backup drives have been successfully synced!"