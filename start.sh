#!/usr/bin/env bash
set -euo pipefail
boracer_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
boracer_engine="${GODOT_BIN:-godot}"
if [[ -z "${GODOT_BIN:-}" ]] && ! command -v "$boracer_engine" >/dev/null 2>&1 && [[ -x "$HOME/.local/bin/godot" ]]; then
  boracer_engine="$HOME/.local/bin/godot"
fi
boracer_options=()
boracer_arguments=()
while (($#)); do
  case "$1" in
    --safe-mode)
      boracer_options=(--rendering-driver opengl3_es --audio-driver Dummy)
      shift
      ;;
    --)
      boracer_arguments+=("$@")
      break
      ;;
    *)
      boracer_arguments+=("$1")
      shift
      ;;
  esac
done
if ! command -v "$boracer_engine" >/dev/null 2>&1; then
  echo "Godot 4 ontbreekt. Stel GODOT_BIN in op je Godot-programma." >&2
  exit 1
fi
"$boracer_engine" --headless --path "$boracer_root/game" --import --quiet
if ((${#boracer_options[@]})); then
  echo "BoRacer herstelstart: OpenGL ES, tijdelijk zonder geluid." >&2
fi
exec "$boracer_engine" --path "$boracer_root/game" "${boracer_options[@]}" "${boracer_arguments[@]}"
