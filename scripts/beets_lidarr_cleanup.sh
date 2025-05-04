#!/usr/bin/env bash

# CONFIGURATION
API_KEY="YOURAPIKEYFROM LIDARR"
LIDARR_HOST="http://LIDARIP:6061"
ROOT_DIR="/music" #change this to match your root dir
BEETS_CONFIG="/scripts/beets-config.yaml"
LOGFILE="/scripts/beets_lidarr_cleanup.log"
MATCHED_LOG="/scripts/beets_matched.log"
FAILED_LOG="/scripts/beets_failed.log"
CACHE_FILE="/scripts/lidarr_album_paths.cache"
DRY_RUN=false  # Set to true to simulate
REFRESH_CACHE=false  # Set to true to re-fetch album paths from Lidarr

# Check for --refresh-cache flag
for arg in "$@"; do
  if [ "$arg" == "--refresh-cache" ]; then
    REFRESH_CACHE=true
    echo "Flag detected: --refresh-cache. Cache will be refreshed." | tee -a "$LOGFILE"
  fi
done

# Prepare log files
> "$LOGFILE"
> "$MATCHED_LOG"
> "$FAILED_LOG"

# Fetch album paths from Lidarr or load from cache
if [ -f "$CACHE_FILE" ] && [ "$REFRESH_CACHE" = false ]; then
  echo "Using cached Lidarr album paths..." | tee -a "$LOGFILE"
  known_paths=$(cat "$CACHE_FILE")
else
  echo "Fetching album paths from Lidarr..." | tee -a "$LOGFILE"
  known_paths=$(curl -s -H "X-Api-Key: $API_KEY" "$LIDARR_HOST/api/v1/album" | jq -r '.[].path')
  echo "$known_paths" > "$CACHE_FILE"
fi

# Convert to grep-friendly pattern list
tempfile=$(mktemp)
echo "$known_paths" > "$tempfile"

# Counters
total=0
matched=0
failed=0

# Find candidate folders with music files
find "$ROOT_DIR" -mindepth 2 -type f \( -iname "*.mp3" -o -iname "*.flac" \) -printf '%h
' | sort -u | while read -r folder; do
  total=$((total + 1))

  # Skip if it's already a known Lidarr album folder
  if grep -Fxq "$folder" "$tempfile"; then
    echo "Skipping known Lidarr folder: $folder" | tee -a "$LOGFILE"
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
    echo "✅ Matched: $folder" | tee -a "$LOGFILE"
    matched=$((matched + 1))
    touch "$folder/.beets_done"
  else
    echo "$folder" >> "$FAILED_LOG"
    echo "❌ Failed to match: $folder" | tee -a "$LOGFILE"
    failed=$((failed + 1))
  fi

done

rm "$tempfile"

if [ "$DRY_RUN" = false ]; then
  # Trigger Lidarr rescan of /music
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
echo "Total folders scanned: $total" | tee -a "$LOGFILE"
echo "Successfully tagged: $matched" | tee -a "$LOGFILE"
echo "Failed to match: $failed" | tee -a "$LOGFILE"
echo "Logs:" | tee -a "$LOGFILE"
echo "  Matched: $MATCHED_LOG" | tee -a "$LOGFILE"
echo "  Failed:  $FAILED_LOG" | tee -a "$LOGFILE"
