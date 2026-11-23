extends Node3D
const Catalog = preload("res://scripts/catalog.gd")
const Profile = preload("res://scripts/profile.gd")
const Track = preload("res://scripts/track.gd")
const Race = preload("res://scripts/race.gd")
const Kart = preload("res://scripts/kart.gd")
const Interface = preload("res://scripts/interface.gd")
const Sound = preload("res://scripts/audio.gd")
const VehicleAudio = preload("res://scripts/effects/vehicle_audio.gd")
const RaceFeedback = preload("res://scripts/effects/race_feedback.gd")
const FinishConfetti = preload("res://scripts/ui/finish_confetti.gd")
const RearView = preload("res://scripts/rear_view.gd")
const FollowCamera = preload("res://scripts/follow_camera.gd")
const WorldArt = preload("res://scripts/worlds/world_art.gd")
const Weather = preload("res://scripts/effects/weather.gd")
const MonsterMode = preload("res://scripts/monster/mode.gd")
const MonsterModels = preload("res://scripts/monster/models.gd")
const MonsterCatalog = preload("res://scripts/monster/catalog.gd")
var monster_mode
var profile
var track
var race
var ui
var audio
var vehicle_audio
var race_feedback
var camera: Camera3D
var sun: DirectionalLight3D
var environment: WorldEnvironment
var world_index: int = 0 # Landscape only (weather/audio/art).
var track_index: int = 0 # Selection and persistent race records, 0..11.
var preview
var menu_time: float = 0
var mode: String = "menu"
var follow_camera
var rear_view
var last_save_error: String = ""
var weather

func _ready() -> void:
 _inputs()
 profile = Profile.new()
 apply_render_resolution()
 get_viewport().size_changed.connect(apply_render_resolution)
 audio = Sound.new()
 audio.music_volume = profile.settings.music
 audio.sound_volume = profile.settings.sound
 add_child(audio)
 vehicle_audio = VehicleAudio.new()
 add_child(vehicle_audio)
 environment = WorldEnvironment.new()
 add_child(environment)
 sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-32, -35, 0)
 sun.light_energy = 1.25
 sun.shadow_enabled = profile.settings.shadows
 sun.directional_shadow_max_distance = 130
 sun.shadow_bias = 0.08
 add_child(sun)
 camera = Camera3D.new()
 camera.fov = 72
 camera.far = 1600
 camera.current = true
 add_child(camera)
 follow_camera = FollowCamera.new(camera)
 rear_view = RearView.new()
 add_child(rear_view)
 rear_view.setup(camera)
 Input.joy_connection_changed.connect(_rear_device_changed)
 ui = Interface.new()
 add_child(ui)
 ui.setup(self)
 go_home()
 if "--monster" in OS.get_cmdline_user_args() or "--solo" in OS.get_cmdline_user_args():
  choose_monster(1 if "--solo" in OS.get_cmdline_user_args() else 2)
 elif "--demo" in OS.get_cmdline_user_args():
  start_race(0)
  race.auto_drive = true
 else:
  ui.show_splash()

func apply_render_resolution() -> void:
 var viewport = get_viewport()
 # Window/SubViewport.size uses actual pixels, unlike the stretched UI's visible rect.
 var pixels: Vector2i = viewport.get("size")
 var limit: int = profile.settings.render_height
 viewport.msaa_3d = Viewport.MSAA_2X if profile.settings.antialias else Viewport.MSAA_DISABLED
 viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
 viewport.scaling_3d_scale = minf(1.0, float(limit) / maxi(1, pixels.y)) if limit > 0 else 1.0

func _inputs() -> void:
 var bindings = {
  "accelerate":[KEY_W, KEY_UP], "brake":[KEY_S, KEY_DOWN],
  "steer_left":[KEY_A, KEY_LEFT], "steer_right":[KEY_D, KEY_RIGHT],
  "boost":[KEY_SHIFT], "power":[KEY_E], "shoot":[KEY_F], "jump":[KEY_SPACE],
  "pause":[KEY_ESCAPE, KEY_P], "reset_kart":[KEY_R], "rear_look":[KEY_C]
 }
 for action in bindings:
  if not InputMap.has_action(action):
   InputMap.add_action(action)
  for code in bindings[action]:
   var key = InputEventKey.new()
   key.physical_keycode = code
   InputMap.action_add_event(action, key)
 var buttons = {"jump":JOY_BUTTON_A, "power":JOY_BUTTON_X, "shoot":JOY_BUTTON_B, "boost":JOY_BUTTON_RIGHT_SHOULDER, "pause":JOY_BUTTON_START, "reset_kart":JOY_BUTTON_Y, "rear_look":JOY_BUTTON_LEFT_SHOULDER}
 for action in buttons:
  var event = InputEventJoypadButton.new()
  event.button_index = buttons[action]
  InputMap.action_add_event(action, event)
 for entry in [["accelerate", JOY_AXIS_TRIGGER_RIGHT, 1], ["brake", JOY_AXIS_TRIGGER_LEFT, 1], ["steer_left", JOY_AXIS_LEFT_X, -1], ["steer_right", JOY_AXIS_LEFT_X, 1]]:
  var axis = InputEventJoypadMotion.new()
  axis.axis = entry[1]
  axis.axis_value = entry[2]
  InputMap.action_add_event(entry[0], axis)
  InputMap.action_set_deadzone(entry[0], 0.15)

func _make_world(index: int) -> void:
 if is_instance_valid(track):
  remove_child(track)
  track.queue_free()
 track = Track.new()
 add_child(track)
 track.build(index)
 index = track.world_index
 var world: Dictionary = Catalog.WORLDS[index]
 var env = Environment.new()
 env.background_mode = Environment.BG_SKY
 var sky_material = ProceduralSkyMaterial.new()
 sky_material.sky_top_color = Color(world.sky).darkened(0.25)
 sky_material.sky_horizon_color = Color(world.sky).lightened(0.18)
 sky_material.ground_bottom_color = Color(world.ground)
 sky_material.ground_horizon_color = Color(world.sky).lightened(0.13)
 sky_material.sun_angle_max = 15
 var sky = Sky.new()
 sky.sky_material = sky_material
 env.sky = sky
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("b2c5e5")
 env.ambient_light_energy = 0.4 if index in [1, 2] else 0.55
 env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 env.tonemap_exposure = 0.72 if index == 2 else 0.92
 env.tonemap_white = 2.5
 env.fog_enabled = true
 env.fog_light_color = Color(world.sky)
 env.fog_density = 0.0016 if index != 5 else 0.0008
 environment.environment = env
 sun.light_color = Color("ffddb2") if index in [0, 3, 5] else Color("f1f6ff")
 sun.light_energy = 0.6 if index == 1 else 0.9
 WorldArt.setup_environment(env, sun, index, track)
 weather = Weather.new()
 track.add_child(weather)
 weather.setup(track, env, sun, camera)

func _clear_race() -> void:
 if is_instance_valid(monster_mode):
  remove_child(monster_mode)
  monster_mode.queue_free()
 monster_mode = null
 rear_view.reset()
 if is_instance_valid(race_feedback):
  race_feedback.clear()
 race_feedback = null
 if is_instance_valid(audio):
  audio.clear_impacts()
 if is_instance_valid(vehicle_audio):
  vehicle_audio.clear()
 if is_instance_valid(race):
  remove_child(race)
  race.queue_free()
 race = null
 if is_instance_valid(preview):
  remove_child(preview)
  preview.queue_free()
 preview = null

func go_home() -> void:
 _clear_race()
 mode = "menu"
 _make_world(track_index)
 refresh_preview()
 ui.show_home()

func refresh_preview() -> void:
 preview_vehicle(profile.selected)

func set_home_presentation(active: bool) -> void:
 if is_instance_valid(preview):
  preview.visible = not active

func preview_vehicle(index: int) -> void:
 if is_instance_valid(preview):
  remove_child(preview)
  preview.queue_free()
 preview = Kart.new()
 add_child(preview)
 preview.setup(index, profile.character, false)
 preview.visible = not (is_instance_valid(ui) and ui.active_page == "home")
 preview.progress = 17
 preview.lateral = 0
 preview.update_visual(track, 0)
 menu_time = 0

func start_race(index: int) -> void:
 _clear_race()
 track_index = clampi(index,0,Catalog.TRACKS.size()-1)
 world_index = Catalog.TRACKS[track_index].world
 mode = "race"
 follow_camera.reset()
 _make_world(index)
 race = Race.new()
 add_child(race)
 race.setup(track, profile.selected, profile.character, profile.settings.difficulty)
 race_feedback = RaceFeedback.new()
 race_feedback.name = "RaceFeedback"
 race.add_child(race_feedback)
 race_feedback.bind(race)
 var vehicle_audio_ready: bool = vehicle_audio.bind(race)
 race.finished.connect(_finish)
 race.notice.connect(ui.notify)
 race.sound.connect(_race_sound)
 race.feedback.connect(_on_race_feedback)
 ui.show_hud()
 if not vehicle_audio_ready:
  ui.notify("Voertuiggeluid kan niet worden geladen.")
 _camera(0, true)

func choose_monster(players: int = 2) -> void:
 if mode != "menu":
  go_home()
 ui.show_monsters(players)

func start_monster(id: String = MonsterCatalog.DEFAULT_ID, players: int = 2) -> void:
 var model = MonsterModels.create(id)
 if not model.load_monster(id):
  ui.show_message(model.last_error)
  return
 _clear_race()
 if is_instance_valid(track):
  remove_child(track)
  track.queue_free()
 track = null
 weather = null
 mode = "monster"
 monster_mode = MonsterMode.new()
 add_child(monster_mode)
 monster_mode.setup(self, model, players)

func _race_sound(kind: String) -> void:
 # The material event already supplies nearby hits; retain the old cue as fallback.
 if kind=="hit" and audio.impact_ready: return
 audio.cue(kind)

func _on_race_feedback(kind: String, at: Vector3, intensity: float, surface: String) -> void:
 if mode!="race" or not is_instance_valid(race) or race.paused: return
 audio.play_impact(kind,at,intensity,surface,race.player.global_position)

func _finish() -> void:
 rear_view.reset()
 vehicle_audio.clear()
 if not race.claim_reward(profile, track_index):
  last_save_error = profile.last_error
 else:
  last_save_error = ""
 audio.cue("lap")
 ui.show_results()
 var celebration = FinishConfetti.new()
 celebration.race = race
 ui.overlay.add_child(celebration)

func persist() -> void:
 if not profile.save_profile():
  ui.show_message("Opslaan lukt niet. Controleer de schrijfrechten van de gebruikersmap.")

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("pause") and not event.is_echo():
  if mode == "race" and is_instance_valid(race) and not race.done:
   if race.paused:
    ui.resume()
   else:
    rear_view.reset()
    ui.show_pause()
   get_viewport().set_input_as_handled()
  elif mode == "menu":
   refresh_preview()
   ui.show_home()

func _physics_process(delta: float) -> void:
 if mode != "race" or not is_instance_valid(race):
  return
 if not race.paused and not race.done:
  if Input.is_action_just_pressed("jump"):
   race.jump()
  if Input.is_action_just_pressed("shoot"):
   race.fire_standard()
  if Input.is_action_pressed("power"):
   if Input.is_action_just_pressed("power") or race.player.cannon_time > 0:
    race.use_power()
  if Input.is_action_just_pressed("reset_kart"):
   race.player.lateral = 0
   race.player.speed *= 0.5
   ui.notify("Weer midden op de baan!")
 var gas = Input.get_action_strength("accelerate")
 if profile.settings.auto_accelerate and Input.get_action_strength("brake") < 0.1:
  gas = 1.0
 race.step(delta, gas, Input.get_action_strength("brake"), Input.get_axis("steer_left", "steer_right"), Input.is_action_pressed("boost"))

func _process(delta: float) -> void:
 if is_instance_valid(ui):
  ui.update_fps(delta)
 if not is_instance_valid(track):
  return
 var freeze_race = mode == "race" and is_instance_valid(race) and race.paused
 audio.advance_feedback(delta,freeze_race)
 if is_instance_valid(race_feedback):
  race_feedback.advance(delta,freeze_race)
 if track.world_index == 5 and is_instance_valid(track.kitchen_rainbow):
  track.kitchen_rainbow.update_player(race.player.progress if mode == "race" and is_instance_valid(race) else 0,mode == "race" and is_instance_valid(race) and not race.done)
 if is_instance_valid(weather):
  var focus_position = race.player.global_position if mode == "race" and is_instance_valid(race) else camera.global_position
  weather.advance(delta, focus_position, freeze_race)
 track.process_mode = Node.PROCESS_MODE_DISABLED if freeze_race else Node.PROCESS_MODE_INHERIT
 if is_instance_valid(race):
  race.process_mode = Node.PROCESS_MODE_DISABLED if freeze_race else Node.PROCESS_MODE_INHERIT
 if mode == "menu" and is_instance_valid(preview):
  preview.visible = ui.active_page != "home"
  menu_time += delta
  var f: Transform3D = track.frame(preview.progress)
  var orbit = sin(menu_time * 0.15) * 0.65
  camera.position = preview.position + f.basis * Vector3(3.5 + orbit, 1.9, 4.9)
  camera.look_at(preview.position + f.basis.y * 0.55, f.basis.y)
  camera.fov = 45
  if preview.has_method("update_effects"):
   preview.update_effects(delta)
 else:
  _camera(delta)
 var vehicle_gas: float = Input.get_action_strength("accelerate")
 if profile.settings.auto_accelerate and Input.get_action_strength("brake") < 0.1:
  vehicle_gas = 1.0
 vehicle_audio.update(delta, audio.sound_volume, audio.muted, mode == "race" and is_instance_valid(race) and not freeze_race and not race.done, vehicle_gas)
 ui.update_hud(delta)

func _camera(delta: float, snap: bool = false) -> void:
 if not is_instance_valid(race):
  return
 if race.paused and not snap:
  rear_view.reset()
  return
 follow_camera.update(track, race.player, delta, profile.settings.camera_motion, snap)
 rear_view.update(track,race.player,not race.paused and not race.done)

func _rear_device_changed(_device: int, connected: bool) -> void:
 if not connected:
  rear_view.reset()
  Input.action_release("rear_look")

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(rear_view):
  rear_view.reset()
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == "race" and is_instance_valid(race) and not race.done:
  ui.show_pause()
