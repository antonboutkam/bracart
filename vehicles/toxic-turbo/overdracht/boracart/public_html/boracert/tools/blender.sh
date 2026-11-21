#!/usr/bin/env bash
set -euo pipefail
if [[ -n "${BORACERT_BLENDER:-}" ]]; then
    blender_binary="$BORACERT_BLENDER"
elif [[ -x /snap/blender/current/blender ]]; then
    blender_binary=/snap/blender/current/blender
else
    blender_binary="$(command -v blender)"
fi
export SDL_AUDIODRIVER="${SDL_AUDIODRIVER:-dummy}"
exec "$blender_binary" "$@"
