extends SceneTree
## Real dashboard screenshots; validation checks setup without rendering images.
const Main = preload("res://scripts/main.gd")
var output: String
var validate_only := false
var failures := 0
var scenarios := 0

func _initialize() -> void:
 call_deferred("run")

func shot(filename: String, game) -> void:
 scenarios += 1
 if validate_only:
  await process_frame
  var duo = game.ui.screen.get_node_or_null("HomeDuoPreview")
  if duo == null or duo.karts.size() != 2 or game.preview.visible:
   failures += 1
  print("DASHBOARD SETUP ",filename," (no image)")
  return
 for frame in 10: await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 if picture.is_empty() or picture.save_png(output.path_join(filename+".png")) != OK:
  failures += 1
 print("DASHBOARD CAPTURE ",filename)

func run() -> void:
 validate_only = "--validate-only" in OS.get_cmdline_user_args()
 output = OS.get_environment("BORACER_CAPTURE_DIR")
 if not validate_only and (output.is_empty() or DisplayServer.get_name() == "headless"):
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
 game.ui.show_home()
 game._process(0)
 await shot("dashboard-duo-front",game)
 var duo = game.ui.screen.get_node_or_null("HomeDuoPreview")
 if duo != null:
  duo.angle = PI/3
  duo._pose()
 else:
  failures += 1
 await shot("dashboard-duo-gedraaid",game)
 for dimensions in [Vector2i(1280,720),Vector2i(800,600),Vector2i(600,900)]:
  root.size = dimensions
  game.ui._resize_layout()
  await shot("dashboard-%dx%d" % [dimensions.x,dimensions.y],game)
 root.size = Vector2i(1280,800)
 game.ui._resize_layout()
 var focused := root.gui_get_focus_owner()
 if focused == null:
  failures += 1
 await shot("dashboard-tegelfocus",game)
 game.queue_free()
 await process_frame
 if validate_only:
  print("DASHBOARD SETUP VALIDATION; no images; scenarios=",scenarios,"; failures=",failures)
 else:
  print("DASHBOARD CAPTURE COMPLETE scenarios=",scenarios,"; failures=",failures)
 quit(0 if failures == 0 else 1)
