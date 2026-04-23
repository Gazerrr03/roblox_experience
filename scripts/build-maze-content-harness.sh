#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

tmp_dir="$(mktemp -d /tmp/maze-content-harness.XXXXXX)"
scaffold_path="$tmp_dir/maze-content-harness.rbxlx"
output_path="places/maze/harness/maze.rbxlx"

rojo build places/maze/content-harness.project.json -o "$scaffold_path"
python3 scripts/sync-maze-content-harness.py \
  --authored "$output_path" \
  --scaffold "$scaffold_path" \
  --output "$output_path"

echo "Refreshed $output_path from places/maze/content-harness.project.json while preserving Workspace and Lighting."
