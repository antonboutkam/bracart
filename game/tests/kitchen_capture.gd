extends SceneTree
## Native views of the actual kitchen track. Validation never produces images.
const Main = preload("res://scripts/main.gd")
var output: String
var validate_only := false
var failures := 0
var scenarios := 0

func _initialize() -> void:
 call_deferred("run")

func shot(filename: String) -> void:
 scenarios += 1
 if validate_only:
  await process_frame
  var camera := root.get_camera_3d()
  if camera == null or not camera.global_transform.is_finite(): failures += 1
  print("KITCHEN SETUP ", filename, " (no image)")
  return
 for frame in 10: await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 if picture.is_empty() or picture.save_png(output.path_join(filename + ".png")) != OK:
  failures += 1
 print("KITCHEN CAPTURE ", filename)

func run() -> void:
 validate_only = "--validate-only" in OS.get_cmdline_user_args()
 output = OS.get_environment("BORACER_CAPTURE_DIR")
 if not validate_only and (output.is_empty() or DisplayServer.get_name() == "headless"):
  push_error("Set BORACER_CAPTURE_DIR and use native Godot rendering")
  quit(2)
  return
 root.size = Vector2i(1280,720)
 var game := Main.new()
 root.add_child(game)
 game.set_physics_process(false)
 game.set_process(false)
 game.audio.muted = true
 game.audio.music.stop()
 game.audio.music.stream = null
 game.start_race(5)
 game.race.countdown = 0
 game.race.player.progress = game.track.length * 0.10
 game.race.player.speed = 18
 game.race.player.update_visual(game.track,0)
 game._camera(0,true)
 game.ui.update_hud(0)
 await shot("keukentafel-racecamera")
 game.ui.visible = false
 game.camera.fov = 65
 game.camera.position = Vector3(0,220,150)
 game.camera.look_at(Vector3.ZERO)
 await shot("keukentafel-overzicht")
 var props = game.track.get_node_or_null("KitchenProps")
 var objects: Array = props.get_meta("objects",[]) if props != null else []
 if objects.size() < 10: failures += 1
 for item in objects:
  var height: float = float(item.height)
  var center: Vector3 = item.center + Vector3.UP * height * 0.45
  var radius: float = maxf(Vector2(float(item.radius),height*0.5).length(),3.0)
  game.camera.fov = 52
  game.camera.position = center + Vector3(1.0,0.95,1.6).normalized() * maxf(radius*3.2,12.0)
  game.camera.look_at(center)
  await shot("keukentafel-" + str(item.id).validate_filename())
 game.queue_free()
 await process_frame
 if validate_only:
  print("KITCHEN SETUP VALIDATION; no images; scenarios=",scenarios,"; failures=",failures)
 else:
  print("KITCHEN CAPTURE COMPLETE scenarios=",scenarios,"; failures=",failures)
 quit(0 if failures == 0 else 1)
