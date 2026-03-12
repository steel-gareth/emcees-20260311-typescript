#!/usr/bin/env bash
# Inserts or replaces an 8-char alphanumeric + datetimestamp in the middle
# of the first line starting with '#', then git add/commit/push.

set -euo pipefail

FILE="README.md"

if [[ ! -f "$FILE" ]]; then
  echo "Error: file '$FILE' not found." >&2
  exit 1
fi

# ── 1. Build the new tag ──────────────────────────────────────────────────────
RANDOM_PART=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 8)
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
NEW_TAG="${RANDOM_PART}-${TIMESTAMP}"

# Pattern that matches a previously inserted tag (8 alnum chars + '-' + 14 digits)
TAG_PATTERN='[A-Za-z0-9]\{8\}-[0-9]\{14\}'

# ── 2. Find & transform the first '#' heading ─────────────────────────────────
FIRST_HEADING_LINE=$(grep -n '^#' "$FILE" | head -1)

if [[ -z "$FIRST_HEADING_LINE" ]]; then
  echo "Error: no line beginning with '#' found in '$FILE'." >&2
  exit 1
fi

LINE_NUM=$(echo "$FIRST_HEADING_LINE" | cut -d: -f1)
LINE_TEXT=$(sed -n "${LINE_NUM}p" "$FILE")

# Strip an existing tag (anywhere in the line) to get the clean heading
CLEAN_LINE=$(echo "$LINE_TEXT" | sed "s/ ${TAG_PATTERN}//g; s/${TAG_PATTERN} //g; s/${TAG_PATTERN}//g")

# Split clean heading into two halves at the midpoint of the text content
# (content = everything after the leading '#' characters and space)
HASHES=$(echo "$CLEAN_LINE" | sed 's/^\(#*\).*/\1/')
CONTENT=$(echo "$CLEAN_LINE" | sed 's/^#* *//')

CONTENT_LEN=${#CONTENT}
MID=$(( CONTENT_LEN / 2 ))

LEFT="${CONTENT:0:$MID}"
RIGHT="${CONTENT:$MID}"

NEW_LINE="${HASHES} ${LEFT}${NEW_TAG} ${RIGHT}"
# Tidy up any double-spaces that may appear when content was empty on one side
NEW_LINE=$(echo "$NEW_LINE" | sed 's/  */ /g; s/ $//')

# ── 3. Write the updated line back into the file ──────────────────────────────
# Escape special sed characters in both old and new line
escape_sed() { printf '%s\n' "$1" | sed 's/[\/&]/\\&/g'; }

ESCAPED_OLD=$(escape_sed "$LINE_TEXT")
ESCAPED_NEW=$(escape_sed "$NEW_LINE")

sed -i "${LINE_NUM}s/${ESCAPED_OLD}/${ESCAPED_NEW}/" "$FILE"

echo "Updated line ${LINE_NUM}:"
echo "  Before : $LINE_TEXT"
echo "  After  : $NEW_LINE"
echo "  Tag    : $NEW_TAG"

# ── 4. Git add, commit (message includes the exact tag), and push ─────────────
git add "$FILE"
git commit -m "conflict: introduce tag ${NEW_TAG} in heading of ${FILE}"
git push origin main

echo "Done. Committed and pushed with tag: ${NEW_TAG}"