#!/bin/bash

# Define an array of source and destination file pairs
FILES=(
  "/path/to/source/file1:/path/to/destination/file1"
  "/path/to/source/file2:/path/to/destination/file2"
  # Add more file pairs as needed
)

# Iterate through the file pairs and sync each one
for PAIR in "${FILES[@]}"; do
  SOURCE_FILE="${PAIR%%:*}"
  DEST_FILE="${PAIR##*:}"

  # Sync from SOURCE to DEST if the source is newer
  if [ "$SOURCE_FILE" -nt "$DEST_FILE" ]; then
    rsync -avu "$SOURCE_FILE" "$DEST_FILE"
  fi

  # Sync from DEST to SOURCE if the destination is newer
  if [ "$DEST_FILE" -nt "$SOURCE_FILE" ]; then
    rsync -avu "$DEST_FILE" "$SOURCE_FILE"
  fi
done

echo "Two-way sync complete."
