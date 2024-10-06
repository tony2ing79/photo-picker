#!/bin/bash

# Source directory containing photos (customize this)
SOURCE_DIR="./photos"

# Destination directory where photos will be sorted (customize this)
DEST_DIR="./sorted_photos"

# Log file
LOG_FILE=./log/$(date +"%Y.%m.%d.%H%M%S").log
echo Log folder: $LOG_FILE
echo Start to process...
exec > "$LOG_FILE" 2>&1

# Check if the date parameter is passed
if [ -z "$1" ]; then
  echo "Usage: $0 <reference_date>"
  echo "Example: $0 2024-01-01"
  exit 1
fi

# Read the reference date from the first parameter
REFERENCE_DATE=$1

# Convert the reference date to Unix timestamp
REFERENCE_TIMESTAMP=$(date -ju -f "%F %T" "$REFERENCE_DATE"00:00:00 "+%s")

# Counter of files
total_processed_files=0
skipped_files=0

# Loop over all files in the source directory
for file in "$SOURCE_DIR"/*; do
    # Update counter
    total_processed_files=$((total_processed_files + 1))

    # Check if it's a file (not a directory)
    if [ -f "$file" ]; then
        # Extract the year and month from the file's metadata
        PHOTO_FULL_DATE=$(exiftool -d "%Y-%m-%d %H:%M:%S" -DateTimeOriginal "$file" 2>/dev/null | awk -F': ' '{print $2}')
        # If no DateTimeOriginal metadata exists, skip the file
        if [ -z "$PHOTO_FULL_DATE" ]; then
            echo "No date found for $file, skipping..."
            skipped_files=$((skipped_files + 1))
            continue
        fi

        PHOTO_TIMESTAMP=$(date -ju -f "%F %T" "$PHOTO_FULL_DATE" "+%s")
        if [ "$PHOTO_TIMESTAMP" -lt "$REFERENCE_TIMESTAMP" ]; then
            echo "$file was taken before $REFERENCE_DATE, so skip it"
            skipped_files=$((skipped_files + 1))
            continue
        fi

        # Extract the year and month from the file's metadata
        DATE=$(exiftool -d "%Y.%m.%d" -DateTimeOriginal "$file" 2>/dev/null | awk -F': ' '{print $2}')
        
        # Create the destination folder based on the date (Year/Month)
        DEST_FOLDER="$DEST_DIR/$DATE"
        mkdir -p "$DEST_FOLDER"

        # Move the file to the appropriate folder
        cp "$file" "$DEST_FOLDER/"

        echo "Moved $file to $DEST_FOLDER/"
    fi
done

echo ""
echo "Photos sorted by date!"
echo "Total processed files: "$total_processed_files
echo "Total skipped files: "$skipped_files