extends SceneTree
## Existing worlds with submitted CC0 meshes and actual race feedback events.
const Main = preload("res://scripts/main.gd")
var game
var output: String
var validate_only := false
var scenarios := 0
var failures := 0

func _initialize() -> void: call_deferred("run")

func shot(filename: String) -> void:
 scenarios += 1
 if not game.camera.transform.is_finite(): failures += 1
 if validate_only:
  await process_frame
  print("QUICKWINS SETUP ",filename," (no image)")
  return
 for frame in 10: await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 if picture.is_empty() or picture.save_png(output.path_join(filename+".png"))!=OK: failures += 1
 print("QUICKWINS CAPTURE ",filename)

func start(world: int) -> void:
 game.start_race(world)
 game.race.countdown = 0
 game.race.set_process(false)
 game.ui.visible = true

func player_at(progress: float, speed: float = 22) -> void:
 game.race.player.progress = progress
 game.race.player.speed = speed
 game.race.player.lateral = 0
 game.race.player.jump_height = 0
 game.race.player.jump_velocity = 0
 game.race.player.update_visual(game.track,0)
 game._camera(0,true)

func has_effect(kind: String) -> bool:
 for burst in game.race_feedback.bursts:
  if burst.active and burst.kind==kind: return true
 return false

func landing(world: int, progress: float, label: String) -> void:
 start(world)
 player_at(progress)
 game.race.jump()
 var landed := false
 for tick in 120:
  game.race.step(1.0/60,1,0,0,false)
  if tick>2 and game.race.player.jump_height==0:
   landed = true
   break
 if not landed or not has_effect("landing"): failures += 1
 game._process(0.16)
 game._camera(0,true)
 await shot(label)

func run() -> void:
 validate_only = "--validate-only" in OS.get_cmdline_user_args()
 output = OS.get_environment("BORACER_CAPTURE_DIR")
 if not validate_only and (output.is_empty() or DisplayServer.get_name()=="headless"):
  push_error("Set BORACER_CAPTURE_DIR and use native Godot rendering")
  quit(2)
  return
 root.size = Vector2i(1280,800)
 game = Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.muted = true
 game.audio.music.stop()
 game.audio.music.stream = null
 var greenery := OS.get_environment("BORACER_CAPTURE_STEP")=="stap-17-groen-cc0"
 if greenery:
  for world in [3,4]:
   start(world)
   game.ui.visible = false
   var additions = game.track.get_node_or_null("NatureAccents")
   var records: Array = additions.get_meta("instances",[]) if additions!=null else []
   if records.is_empty():
    failures += 1
    continue
   var record: Dictionary = records[0]
   var bounds: AABB = record.bounds
   var center: Vector3 = bounds.get_center()
   game.camera.fov = 55
   game.camera.position = center+Vector3(11,5,13)
   game.camera.look_at(center)
   if not game.camera.is_position_in_frustum(center): failures += 1
   await shot("groen-%s-boomdetails" % world)
   var platform: Transform3D = record.cluster_transform
   var target: Vector3 = platform.origin+Vector3.UP*2
   game.camera.position = target+platform.basis*Vector3(22,14,25)
   game.camera.look_at(target)
   await shot("groen-%s-straatcontext" % world)
 else:
  await landing(4,80,"landingsstof-asfalt")
  start(5)
  var features: Array = game.track.kitchen_features()
  var wood: float = (features[3].entry_end+features[4].start)*0.5-12
  await landing(5,wood,"landingsstof-houten-tafel")
  start(5)
  features = game.track.kitchen_features()
  var plastic: float = lerpf(features[2].start,features[2].end,0.3)
  await landing(5,plastic,"landingsstof-oranje-looping")
  start(3)
  player_at(30,28)
  game.race.player.lateral = game.track.width-0.5
  game.race.step(1.0/60,1,0,1,false)
  if not has_effect("collision"): failures += 1
  game._process(0.08)
  game._camera(0,true)
  await shot("botsingsvonken-haarlem")
  start(3)
  player_at(game.track.length*game.race.LAPS-0.08,22)
  game.race.last_lap = 2
  game.race.step(1.0/60,1,0,0,false)
  if not game.race.done or not has_effect("finish") or game.ui.overlay.get_node_or_null("FinishConfetti")==null: failures += 1
  game._process(0.12)
  game._camera(0,true)
  await shot("finishfeestje-met-uitslag")
 game.queue_free()
 await process_frame
 var expected: int = 4 if greenery else 5
 print("QUICKWINS ","SETUP VALIDATION; no images" if validate_only else "CAPTURE COMPLETE","; scenarios=",scenarios,"; failures=",failures)
 quit(0 if failures==0 and scenarios==expected else 1)
