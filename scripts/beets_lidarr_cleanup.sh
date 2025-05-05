#!/usr/bin/env bash

# Load configuration from .env file
source /scripts/config.env

# Runtime flags
DRY_RUN=false
REFRESH_CACHE=false
RESUME_ONLY=false

# Parse CLI flags
for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
    --refresh-cache) REFRESH_CACHE=true ;;
    --resume-only) RESUME_ONLY=true ;;
  esac
done

# Log files
LOGFILE="/scripts/beets_lidarr_cleanup.log"
MATCHED_LOG="/scripts/beets_matched.log"
FAILED_LOG="/scripts/beets_failed.log"
TODO_FILE="/scripts/beets_todo.log"
DONE_FILE="/scripts/beets_done.log"

# Prepare logs
> "$LOGFILE"
> "$MATCHED_LOG"
> "$FAILED_LOG"

# Get known Lidarr album paths
CACHE_FILE="/scripts/lidarr_album_paths.cache"
if [ -f "$CACHE_FILE" ] && [ "$REFRESH_CACHE" = false ]; then
  echo "Using cached Lidarr album paths..." | tee -a "$LOGFILE"
  known_paths=$(cat "$CACHE_FILE")
else
  echo "Fetching album paths from Lidarr..." | tee -a "$LOGFILE"
  known_paths=$(curl -s -H "X-Api-Key: $API_KEY" "$LIDARR_HOST/api/v1/album" | jq -r '.[].path')
  echo "$known_paths" > "$CACHE_FILE"
fi

# Convert to grep-friendly list
tempfile=$(mktemp)
echo "$known_paths" > "$tempfile"

# If not resuming, generate the TODO list fresh
if [ "$RESUME_ONLY" = false ]; then
  echo "Scanning music directory for unmapped folders..." | tee -a "$LOGFILE"
  > "$TODO_FILE"
  find "$ROOT_DIR" -mindepth 2 -type f \( -iname "*.mp3" -o -iname "*.flac" \) -printf '%h\n' | sort -u | while read -r folder; do
    if grep -Fxq "$folder" "$tempfile"; then
      continue
    fi
    echo "$folder" >> "$TODO_FILE"
  done
  rm "$tempfile"
fi

# Calculate remaining folders to process
> /scripts/beets_remaining.log
comm -23 <(sort "$TODO_FILE") <(sort -u -o "$DONE_FILE" "$DONE_FILE"; sort -u -o "$FAILED_LOG" "$FAILED_LOG"; cat "$DONE_FILE" "$FAILED_LOG" | sort -u) > /scripts/beets_remaining.log
remaining=$(wc -l < /scripts/beets_remaining.log)
echo "Remaining folders to process: $remaining" | tee -a "$LOGFILE"

matched=0
failed=0
mkdir -p /scripts/resume

while read -r folder; do
  if grep -Fxq "$folder" "$DONE_FILE" || grep -Fxq "$folder" "$FAILED_LOG"; then
    echo "Skipping previously processed folder: $folder" | tee -a "$LOGFILE"
    continue
  fi

  echo "Unmapped folder found: $folder" | tee -a "$LOGFILE"

  if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN: Would process (unmapped): $folder" | tee -a "$LOGFILE"
    continue
  fi

  # Run Beets tagger
  if beet -c "$BEETS_CONFIG" import -qC "$folder" >> "$LOGFILE" 2>&1; then
    echo "$folder" >> "$MATCHED_LOG"
    echo "$folder" >> "$DONE_FILE"
    echo "✅ Matched: $folder" | tee -a "$LOGFILE"
    matched=$((matched + 1))
    touch "$folder/.beets_done"
  else
    echo "$folder" >> "$FAILED_LOG"
    echo "❌ Failed to match: $folder" | tee -a "$LOGFILE"
    failed=$((failed + 1))
  fi

done < /scripts/beets_remaining.log

if [ "$DRY_RUN" = false ]; then
  echo "Triggering Lidarr rescan..." | tee -a "$LOGFILE"
  curl -s -H "X-Api-Key: $API_KEY" \
    -X POST "$LIDARR_HOST/api/v1/command" \
    -H "Content-Type: application/json" \
    -d '{"name": "RescanFolder", "path": "/music"}' \
    >> "$LOGFILE"
  echo "===== Beets-Lidarr Unmapped Cleanup Complete =====" | tee -a "$LOGFILE"
else
  echo "===== DRY RUN COMPLETE — No changes made =====" | tee -a "$LOGFILE"
fi

# Summary
echo "" | tee -a "$LOGFILE"
echo "===== Beets Cleanup Summary =====" | tee -a "$LOGFILE"
echo "Remaining processed: $remaining" | tee -a "$LOGFILE"
echo "Successfully tagged: $matched" | tee -a "$LOGFILE"
echo "Failed to match: $failed" | tee -a "$LOGFILE"
echo "Logs:" | tee -a "$LOGFILE"
echo "  Matched: $MATCHED_LOG" | tee -a "$LOGFILE"
echo "  Failed:  $FAILED_LOG" | tee -a "$LOGFILE"
echo "  Resume list: $DONE_FILE" | tee -a "$LOGFILE"
