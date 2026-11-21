#!/usr/bin/env bash
set -euo pipefail
boracer_game="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
boracer_engine="${GODOT_BIN:-godot}"
boracer_test_dir="$(mktemp -d /tmp/boracer-check.XXXXXX)"
trap 'rm -rf -- "$boracer_test_dir"' EXIT
export XDG_CACHE_HOME="$boracer_test_dir/cache"
export XDG_CONFIG_HOME="$boracer_test_dir/config"
export XDG_DATA_HOME="$boracer_test_dir/data"
"$boracer_engine" --headless --path "$boracer_game" --import --quiet
for boracer_test in render_resolution monster_breaker fractured_monster impact_replay profile_storage default_vehicle vehicle_audio vehicle_audio_qa world_geometry uithoorn_ground uithoorn_landmarks outdoor_life street_walkers street_walkers_main outdoor_life_qa kitchen_props kitchen_photo_qa kitchen_course kitchen_adventure_props kitchen_course_qa kitchen_adventure_qa nature_accents race_feedback quickwins_qa world_art architecture street_districts street_scene_qa tram_motion reward_weather kart_visuals garage_presentation garage_features garage_interaction_qa dutch_sky_horizons dutch_world_qa aircraft aircraft_qa birds birds_qa race_behavior rear_view rear_view_qa follow_camera camera_composition home_duo_preview home_dashboard_qa ui_layout ui_sfeer world_concepts ui_input_devices game10001_integration smoke input_flow integration_audit tracks_v2 tracks_v2_flight tracks_v2_ui tracks_v2_clearance victory_podium; do
  "$boracer_engine" --headless --audio-driver Dummy --path "$boracer_game" --script "tests/$boracer_test.gd"
done
