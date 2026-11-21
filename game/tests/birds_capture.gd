extends SceneTree
## Actual outdoor bird, two wing poses and the ordinary race camera.
const Main = preload("res://scripts/main.gd")
var output: String
var validate_only := false
var failures := 0
var scenarios := 0

func _initialize() -> void: call_deferred("run")

func shot(filename: String, game, bird) -> void:
 scenarios += 1
 if not game.camera.is_position_in_frustum(bird.flight.global_position): failures += 1
 if validate_only:
  await process_frame
  print("BIRDS SETUP ",filename," (no image)")
  return
 for frame in 10: await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 if picture.is_empty() or picture.save_png(output.path_join(filename+".png"))!=OK: failures += 1
 print("BIRDS CAPTURE ",filename)

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
 game.start_race(3)
 game.race.set_process(false)
 game.race.countdown = 0
 game.ui.visible = false
 var bird = game.track.get_node_or_null("Birds")
 if bird==null:
  push_error("Actual Haarlem track has no bird")
  quit(1)
  return
 bird.set_process(false)
 bird.force_passage()
 bird.advance(0.17)
 game.camera.fov = 55
 game.camera.position = bird.flight.global_position+bird.flight.global_basis.x*16+Vector3.UP*3+bird.flight.global_basis.z*14
 game.camera.look_at(bird.flight.global_position)
 await shot("vogeltje-vleugels-eerste-stand",game,bird)
 var first_angle: float = bird.left_wing.rotation.z
 bird.advance(0.22)
 if absf(bird.left_wing.rotation.z-first_angle)<0.1: failures += 1
 game.camera.look_at(bird.flight.global_position)
 await shot("vogeltje-vleugels-tweede-stand",game,bird)
 bird.force_passage()
 bird.advance(bird.duration*0.5)
 game.race.player.progress = 0
 game.race.player.update_visual(game.track,0)
 game._camera(0,true)
 game.ui.visible = true
 await shot("vogeltje-haarlem-racecamera",game,bird)
 game.queue_free()
 await process_frame
 print("BIRDS ","SETUP VALIDATION; no images" if validate_only else "CAPTURE COMPLETE","; scenarios=",scenarios,"; failures=",failures)
 quit(0 if failures==0 and scenarios==3 else 1)
