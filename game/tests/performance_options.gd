extends SceneTree
const Main = preload("res://scripts/main.gd")
const Profile = preload("res://scripts/profile.gd")
const Monsters = preload("res://scripts/monster/catalog.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func _initialize():
 call_deferred("run")
func run():
 var path = "user://performance-options.json"
 for suffix in ["", ".bak", ".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
 var profile = Profile.new(path)
 check(profile.settings.antialias and profile.settings.impact_replay and not profile.settings.show_fps, "Existing graphics defaults preserved")
 profile.settings.antialias = false
 profile.settings.impact_replay = false
 profile.settings.show_fps = true
 check(profile.save_profile(), "Save options")
 var saved = Profile.new(path)
 check(not saved.settings.antialias and not saved.settings.impact_replay and saved.settings.show_fps, "Options survive restart")
 var game = Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.music.stop()
 game.audio.muted = true
 await process_frame
 game.profile = saved
 game.apply_render_resolution()
 check(root.msaa_3d == Viewport.MSAA_DISABLED and root.scaling_3d_scale == 1, "MSAA can be disabled without reducing resolution")
 game.ui.update_fps(1)
 check(game.ui.fps_label.visible and game.ui.fps_label.text.begins_with("FPS:"), "FPS counter displayed")
 game.ui.show_settings()
 await process_frame
 var antialias = game.ui.screen.find_child("AntialiasSetting", true, false)
 var replay = game.ui.screen.find_child("ImpactReplaySetting", true, false)
 var fps = game.ui.screen.find_child("FpsSetting", true, false)
 check(not antialias.button_pressed and not replay.button_pressed and fps.button_pressed, "Settings match saved preferences")
 antialias.button_pressed = true
 check(root.msaa_3d == Viewport.MSAA_2X and Profile.new(path).settings.antialias, "MSAA toggle applies and persists")
 fps.button_pressed = false
 check(not game.ui.fps_label.visible and not Profile.new(path).settings.show_fps, "FPS toggle hides counter and persists")
 game.start_monster(Monsters.DEFAULT_ID, 1)
 var mode = game.monster_mode
 mode.set_process(false)
 mode.set_physics_process(false)
 mode.action()
 for i in 2400:
  mode.step(1.0 / 60)
  if mode.phase in ["between", "finished"]: break
 check(mode.impact_replay.frames.is_empty() and not mode.impact_replay.played, "Disabled replay does not record or play")
 check(mode.phase in ["between", "finished"] and mode.scores[0] > 0, "Monster hit and scoring still work")
 game.queue_free()
 await process_frame
 for suffix in ["", ".bak", ".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
 print("PERFORMANCE OPTIONS: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
