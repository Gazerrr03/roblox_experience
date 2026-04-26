#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

force_overwrite=false
if [[ "${1:-}" == "--force" ]]; then
  force_overwrite=true
fi

build_harness() {
  local project_path="$1"
  local output_path="$2"

  if [[ -f "$output_path" && "$force_overwrite" != true ]]; then
    echo "Skipping existing harness $output_path (pass --force to rebuild from source scaffold)"
    return
  fi

  rojo build "$project_path" -o "$output_path"

  if [[ "$output_path" == "places/maze/harness/maze.rbxlx" ]]; then
    python3 scripts/hydrate-maze-harness.py "$output_path"
  fi
}

build_harness places/run/default.project.json places/run/harness/run.rbxlx
build_harness places/maze/default.project.json places/maze/harness/maze.rbxlx
