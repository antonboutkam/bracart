extends SceneTree
## Actual outdoor sky, aircraft and world-space trail; never a studio substitute.
const Main = preload("res://scripts/main.gd")
var output: String
var validate_only := false
var failures := 0
var scenarios := 0

func _initialize() -> void: call_deferred("run")

func shot(filename: String, game, aircraft) -> void:
 scenarios += 1
 if validate_only:
  await process_frame
  if not game.camera.is_position_in_frustum(aircraft.flight.global_position): failures += 1
  print("AIRCRAFT SETUP ",filename," (no image)")
  return
 for frame in 10: await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 if picture.is_empty() or picture.save_png(output.path_join(filename+".png")) != OK: failures += 1
 print("AIRCRAFT CAPTURE ",filename)

func run() -> void:
 validate_only = "--validate-only" in OS.get_cmdline_user_args()
 output = OS.get_environment("BORACER_CAPTURE_DIR")
 if not validate_only and (output.is_empty() or DisplayServer.get_name()=="headless"):
  push_error("Set BORACER_CAPTURE_DIR and use native Godot rendering")
  quit(2)
  return
 root.size = Vector2i(1280,800)
 var game := Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.muted = true
 game.audio.music.stop()
 game.audio.music.stream = null
 game.start_race(4)
 game.race.set_process(false)
 game.ui.visible = false
 var aircraft = game.track.get_node_or_null("Aircraft")
 if aircraft==null:
  push_error("Actual Uithoorn track has no aircraft")
  quit(1)
  return
 aircraft.set_process(false)
 aircraft.force_passage()
 var start: Vector3 = aircraft.flight.global_position
 for tick in 240: aircraft.advance(1.0/30)
 var position: Vector3 = aircraft.flight.global_position
 var forward := (position-start).normalized()
 var side := forward.cross(Vector3.UP).normalized()
 game.camera.fov = 58
 game.camera.position = position+side*600-Vector3.UP*140
 game.camera.look_at(position-forward*160)
 await shot("vliegtuig-dag-spoor-begin",game,aircraft)
 for tick in 180: aircraft.advance(1.0/30)
 await shot("vliegtuig-dag-spoor-later",game,aircraft)
 game.weather.force_event("night",true)
 aircraft.advance(1.0/60)
 var sky = game.track.get_node_or_null("DutchSky")
 if sky!=null: sky.sync_weather()
 await shot("vliegtuig-nacht",game,aircraft)
 game.queue_free()
 await process_frame
 print("AIRCRAFT ","SETUP VALIDATION; no images" if validate_only else "CAPTURE COMPLETE","; scenarios=",scenarios,"; failures=",failures)
 quit(0 if failures==0 and scenarios==3 else 1)
