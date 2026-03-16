#!/usr/bin/env bash

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <youtube_url_or_id>"
  exit 1
fi

INPUT="$1"

# Extract video ID
if echo "$INPUT" | grep -Eq '(v=|/)[A-Za-z0-9_-]{11}'; then
  VIDEO_ID=$(echo "$INPUT" | sed -E 's/.*(v=|\/)([A-Za-z0-9_-]{11}).*/\2/')
else
  VIDEO_ID="$INPUT"
fi

URL="https://www.youtube.com/watch?v=$VIDEO_ID"

HTML=$(curl -s \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'User-Agent: Mozilla/5.0' \
  "$URL"
)

# Extract ytInitialPlayerResponse JSON (single line)
PLAYER_JSON=$(echo "$HTML" \
  | tr '\n' ' ' \
  | sed -n 's/.*ytInitialPlayerResponse = \(.*\);\s*var.*/\1/p')

if [ -z "$PLAYER_JSON" ]; then
  echo "Failed to extract player data"
  exit 1
fi

# grep -oP with PCRE: (\\.|[^"])* correctly skips escaped quotes
TITLE=$(echo "$PLAYER_JSON" \
  | grep -oP '"videoDetails":\{[^}]*"title":"\K(\\.|[^"])*')

DESC=$(echo "$PLAYER_JSON" \
  | grep -oP '"shortDescription":"\K(\\.|[^"])*')

# Unescape JSON string sequences
unescape() {
  printf '%b' "$1" | sed 's/\\"/"/g; s/\\u0026/\&/g; s/\\\//\//g'
}

TITLE=$(unescape "$TITLE")
DESC=$(unescape "$DESC")

echo "Title:"
echo "$TITLE"
echo
echo "Description:"
echo "$DESC"
