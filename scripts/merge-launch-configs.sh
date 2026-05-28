#!/bin/bash

# merge-launch-configs.sh
#
# Merges a Flutter app's .vscode/launch.json into the workspace root .vscode/launch.json.
# Configurations that already exist (matched by name) are skipped to avoid duplicates.
#
# Usage:
#   bash scripts/merge-launch-configs.sh <app-path>
#
# Example:
#   bash scripts/merge-launch-configs.sh apps/consumer_app

set -e

APP_PATH="$1"

if [ -z "$APP_PATH" ]; then
  echo "Usage: bash scripts/merge-launch-configs.sh <app-path>"
  echo "Example: bash scripts/merge-launch-configs.sh apps/consumer_app"
  exit 1
fi

SOURCE_LAUNCH="$APP_PATH/.vscode/launch.json"
WORKSPACE_LAUNCH=".vscode/launch.json"

if [ ! -f "$SOURCE_LAUNCH" ]; then
  echo "❌ Error: No .vscode/launch.json found at $SOURCE_LAUNCH"
  exit 1
fi

# Ensure workspace .vscode directory exists
mkdir -p .vscode

# Bootstrap workspace launch.json if it doesn't exist yet
if [ ! -f "$WORKSPACE_LAUNCH" ]; then
  printf '{\n  "version": "0.2.0",\n  "configurations": []\n}\n' > "$WORKSPACE_LAUNCH"
  echo "📁 Created $WORKSPACE_LAUNCH"
fi

# Count existing configurations before merge
BEFORE=$(jq '.configurations | length' "$WORKSPACE_LAUNCH")

# Merge: append new configs whose names don't already exist in workspace
jq -s \
  '.[0].configurations as $existing |
   .[1].configurations as $new |
   .[0] | .configurations = (
     $existing + (
       $new | map(
         select(.name as $n | ($existing | map(.name) | contains([$n])) | not)
       )
     )
   )' \
  "$WORKSPACE_LAUNCH" "$SOURCE_LAUNCH" > /tmp/_merged_launch.json

mv /tmp/_merged_launch.json "$WORKSPACE_LAUNCH"

# Report what was added
AFTER=$(jq '.configurations | length' "$WORKSPACE_LAUNCH")
ADDED=$((AFTER - BEFORE))

if [ "$ADDED" -gt 0 ]; then
  echo "✅ Added $ADDED configuration(s) from $SOURCE_LAUNCH → $WORKSPACE_LAUNCH:"
  jq -r '.configurations[-'"$ADDED"':] | .[].name | "   • \(.)"' "$WORKSPACE_LAUNCH"
else
  echo "ℹ️  No new configurations to add — all entries from $SOURCE_LAUNCH already exist in $WORKSPACE_LAUNCH."
fi
