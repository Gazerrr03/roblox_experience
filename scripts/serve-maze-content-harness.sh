#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

port="${1:-34874}"
project="places/maze/content-harness.serve.project.json"

is_port_listening() {
  lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

pick_free_port() {
  local candidate="$1"
  while is_port_listening "$candidate"; do
    candidate=$((candidate + 1))
  done
  printf '%s' "$candidate"
}

if is_port_listening "$port"; then
  if curl -fsS "http://127.0.0.1:${port}/" >/dev/null 2>&1; then
    printf 'Rojo 已经在 127.0.0.1:%s 运行了，不需要重复启动。\n' "$port"
    printf '直接在 Studio Rojo 插件里连接 127.0.0.1:%s 就行。\n' "$port"
    exit 0
  fi

  free_port="$(pick_free_port "$port")"
  printf '端口 %s 已被占用，自动改用 %s。\n' "$port" "$free_port"
  port="$free_port"
fi

printf 'Starting Maze content harness hot-sync on port %s\n' "$port"
printf 'Open Studio with %s, connect the Rojo plugin to 127.0.0.1:%s, then just hit Play after code changes.\n' "places/maze/harness/maze.rbxlx" "$port"
exec rojo serve "$project" --port "$port"
