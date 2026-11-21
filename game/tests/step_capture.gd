extends SceneTree
## Explicit native runtime evidence, never a headless placeholder.
const Main = preload("res://scripts/main.gd")
const Kart = preload("res://scripts/kart.gd")
const Catalog = preload("res://scripts/catalog.gd")
var output: String
var canvas: SubViewport
var stage: Node3D
var camera: Camera3D
var failures := 0
var validate_only := false
var scenarios := 0

func _initialize() -> void:
 call_deferred("run")

func shot(filename: String, viewport: Viewport) -> void:
 scenarios += 1
 if validate_only:
  await process_frame
  var active_camera := viewport.get_camera_3d()
  if active_camera == null or not active_camera.global_transform.is_finite():
   failures += 1
  print("CAPTURE SETUP ", filename, " (no image)")
  return
 for frame in 10:
  await process_frame
 await RenderingServer.frame_post_draw
 var picture := viewport.get_texture().get_image()
 var error := picture.save_png(output.path_join(filename + ".png"))
 if error != OK or picture.is_empty():
  failures += 1
 print("STEP CAPTURE ", filename, " ", picture.get_size(), " error=", error)

func run() -> void:
 validate_only = "--validate-only" in OS.get_cmdline_user_args()
 output = OS.get_environment("BORACER_CAPTURE_DIR")
 if not validate_only and (output.is_empty() or DisplayServer.get_name() == "headless"):
  push_error("Set BORACER_CAPTURE_DIR and use native Godot rendering")
  quit(2)
  return
 canvas = SubViewport.new()
 canvas.size = Vector2i(1000, 1000)
 canvas.own_world_3d = true
 canvas.msaa_3d = Viewport.MSAA_4X
 canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(canvas)
 stage = Node3D.new()
 canvas.add_child(stage)
 var world := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("24394d")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("d5e2ed")
 env.ambient_light_energy = 0.6
 world.environment = env
 stage.add_child(world)
 for spec in [[Vector3(-35,-30,0),1.1,Color("fff0d6")],[Vector3(-20,120,0),0.65,Color("c3dbff")]]:
  var light := DirectionalLight3D.new()
  light.rotation_degrees = spec[0]
  light.light_energy = spec[1]
  light.light_color = spec[2]
  stage.add_child(light)
 camera = Camera3D.new()
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.current = true
 stage.add_child(camera)
 for character in ["boaz", "ravi"]:
  # Full-body authored candidate shows clothing independent of seated occlusion.
  var document := GLTFDocument.new()
  var state := GLTFState.new()
  var source := ProjectSettings.globalize_path("res://../persons/%s/%s.glb" % [character,character])
  if document.append_from_file(source, state) != OK:
   failures += 1
   continue
  var model := document.generate_scene(state)
  stage.add_child(model)
  camera.size = 1.55
  for view in [["front",Vector3(0,0.8,-3)],["quarter",Vector3(1.8,1.1,-3)]]:
   camera.position = view[1]
   camera.look_at(Vector3(0,0.63,0))
   await shot(character + "-full-" + view[0], canvas)
  model.queue_free()
  await process_frame
  var kart := Kart.new()
  stage.add_child(kart)
  kart.setup(Catalog.DEFAULT_VEHICLE, character, false)
  camera.size = 3.0
  for view in [["front",Vector3(0,1.25,-4)],["quarter",Vector3(3,1.8,-4)]]:
   camera.position = view[1]
   camera.look_at(Vector3(0,0.65,0))
   await shot(character + "-raketfiets-sit-" + view[0], canvas)
  kart.queue_free()
  await process_frame
 canvas.queue_free()
 await process_frame
 root.size = Vector2i(1280,720)
 var game := Main.new()
 root.add_child(game)
 game.audio.muted = true
 game.audio.music.stop()
 game.audio.music.stream = null
 game.set_physics_process(false)
 game.set_process(false)
 game.profile.selected = Catalog.DEFAULT_VEHICLE
 for character in ["boaz", "ravi"]:
  game.profile.character = character
  for world_index in [3,4]:
   game.start_race(world_index)
   game.race.countdown = 0
   var distance: float = game.track.length * 0.12
   for index in game.race.racers.size():
    var racer = game.race.racers[index]
    racer.progress = distance + (7 + index * 4 if index > 0 else 0)
    racer.speed = 22
    racer.update_visual(game.track, 0)
   game.race.rank = game.race.ranking().find(game.race.player) + 1
   game.race.elapsed = 17.4
   game.race.collected = 8
   game.race.player.power = "Raket"
   game._camera(0, true)
   game.ui.update_hud(0)
   await shot(character + "-hud-" + Catalog.world_id(world_index), root)
 if OS.get_environment("BORACER_CAPTURE_STEP") == "stap-06-werelden":
  for world_index in [3,4]:
   game.start_race(world_index)
   var district = game.track.get_node_or_null("StreetDistricts")
   var houses: Array = district.get_meta("buildings",[]) if district != null else []
   if houses.is_empty():
    failures += 1
    continue
   var house: Dictionary = houses[0]
   for candidate in houses:
    if candidate.frame.origin.distance_to(game.race.player.position) < house.frame.origin.distance_to(game.race.player.position):
     house = candidate
   var base: Vector3 = district.to_global(house.frame.origin)
   var orientation: Basis = district.global_basis * house.frame.basis
   var h: float = house.height * 0.72
   var focus := base + Vector3(0,h+1,0)
   game.ui.visible = false
   game.camera.fov = 60
   for view in [["front-left",Vector3(-16,h+1,-19)], ["front-right",Vector3(16,h+1,-19)], ["back",Vector3(0,h+1,20)], ["roof",Vector3(14,h+12,8)]]:
    game.camera.global_position = base + orientation * view[1]
    game.camera.look_at(focus)
    await shot(Catalog.world_id(world_index) + "-building-" + view[0], root)
   game.ui.visible = true
  game.start_race(4)
  game.ui.visible = false
  var tram = game.track.get_node_or_null("UithoornTram")
  if tram == null:
   failures += 1
  else:
   tram.set_process(false)
   tram.distance = tram.loop_length * 0.9
   tram._pose()
   game.camera.fov = 65
   game.camera.position = game.track.position_at(game.track.length * 0.18,0,4)
   game.camera.look_at(tram.cars[0].global_position + Vector3.UP * 2)
   await shot("uithoorn-boven-wijk-met-tram", root)
   # Two real staged moments demonstrate a second position on the visible rails.
   tram.advance(3.0)
   await shot("uithoorn-tram-drie-seconden-later", root)
  game.ui.visible = true
 if OS.get_environment("BORACER_CAPTURE_STEP") == "stap-08-interface":
  game.go_home()
  game.ui.show_splash()
  await shot("splash", root)
  game.ui.show_home()
  await shot("dashboard", root)
  game.ui.show_worlds()
  await shot("wereldselectie", root)
  game.ui.show_garage()
  await shot("garage", root)
  game.ui.show_settings()
  await shot("instellingen", root)
  game.profile.settings.touch_controls = true
  game.start_race(4)
  game.race.countdown = 0
  game.race.player.progress = game.track.length * 0.12
  game.race.player.speed = 32
  game.race.player.update_visual(game.track, 0)
  game._camera(0, true)
  game.ui.update_hud(0)
  await shot("touch-dashboard", root)
  game.weather.force_event("night", true)
  game.weather.advance(0.01, game.race.player.global_position)
  await shot("nacht-dashboard", root)
  root.size = Vector2i(800, 600)
  game.ui._resize_layout()
  await shot("touch-dashboard-compact", root)
 game.queue_free()
 await process_frame
 if validate_only:
  print("CAPTURE SETUP VALIDATION; no images; scenarios=", scenarios, "; failures=", failures)
 else:
  print("STEP CAPTURE COMPLETE failures=", failures)
 quit(0 if failures == 0 else 1)
