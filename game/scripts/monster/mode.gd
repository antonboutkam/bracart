extends Node3D
## Cockpit stunt mode; one player or local alternating turns, with imported targets.
const Ammo = preload("res://scripts/combat/ammo.gd")
const Geo = preload("res://scripts/geometry.gd")
const Arena = preload("res://scripts/monster/arena.gd")
const Kart = preload("res://scripts/kart.gd")
const Catalog = preload("res://scripts/catalog.gd")
const MonsterCatalog = preload("res://scripts/monster/catalog.gd")
const Birds = preload("res://scripts/monster/birds.gd")
const Sounds = preload("res://scripts/monster/sounds.gd")
const MonsterPreview = preload("res://scripts/monster/preview.gd")
const Models = preload("res://scripts/monster/models.gd")
const ImpactReplay = preload("res://scripts/monster/impact_replay.gd")
const Structure = preload("res://scripts/monster/structure.gd")
const FlightRings = preload("res://scripts/monster/flight_rings.gd")
const WIN_FRACTION = 0.70
const TICK = 1.0 / 60
const GRAVITY = 12.0
const AIR_CONTROL_ACCEL = 4.5
const AIR_STEER_SPEED = 10.0
const ROAD_TOP_SPEED = 70.0
const IMPACT_RADIUS = 1.7
const DIVE_RADIUS = 2.55
const DIVE_MIN_TIME = 0.30
const DIVE_KICK = Vector3(0, -17, -10)
const DIVE_NOTICE_TIME = 0.65
const STRIKE_HEIGHT = Vector3(0, 0.7, 0)
const AIM_INTERVAL = 0.08
var game
var arena
var rocket
var birds
var sounds
var impact_replay = ImpactReplay.new()
var rings = FlightRings.new()
var player_count: int = 2
var monster_id: String = MonsterCatalog.DEFAULT_ID
var phase: String = "ready"
var paused: bool = false
var player: int = 0
var turn: int = 0
var scores: Array[int] = [0, 0]
var turn_score: int = 0
var vehicles: Array = []
var vehicle_index: int = 0
var velocity = Vector3.ZERO
var road_z: float = Arena.COURSE_START
var road_speed: float = 0
var road_steering: float = 0
var lateral_speed: float = 0
var launch_speed: float = 0
var phase_time: float = 0
var turn_time: float = 0
var hit_count: int = 0
var pending_points: int = 0
var miss_announced: bool = false
var bird_notice: float = 0
var hit_sound_timer: float = 0
var boost_held: bool = false
var dive_used: bool = false
var dive_notice: float = 0
var ring_notice: float = 0
var aim_timer: float = 0
var aim_point: Vector3 = Vector3.INF
var aim_text: String = ""
var aim_ring: int = -1
var title: Label
var status: Label
var score_labels: Array[Label] = []
var progress_label: Label
var progress_bar: ProgressBar
var turn_label: Label
var action_button: Button
var pause_button: Button
var speed_label: Label
var detail_label: Label
var controls_label: Label
var aim_marker: Panel
var aim_style: StyleBoxFlat
var aim_caption: Label
var vehicle_picker: PanelContainer
var vehicle_buttons: Array[Button] = []
var player_ammo: Array = [Ammo.new(), Ammo.new()]
var shots: Array[Dictionary] = []
var shoot_button: Button

func setup(owner_game, model, players: int = 2) -> void:
 game = owner_game
 player_count = clampi(players, 1, 2)
 monster_id = model.monster_id
 vehicles = Catalog.available_indices()
 if vehicles.is_empty():
  vehicles = [0, 4]
 arena = Models.arena_for(model)
 add_child(arena)
 arena.build(model)
 add_child(impact_replay)
 add_child(rings)
 birds = Birds.new()
 add_child(birds)
 sounds = Sounds.new()
 add_child(sounds)
 var env = Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("526c82")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("a7bdcc")
 env.ambient_light_energy = 0.27
 env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 env.tonemap_exposure = 0.74
 env.tonemap_white = 2.5
 env.fog_enabled = true
 env.fog_light_color = Color("526c82")
 env.fog_density = 0.0009
 game.environment.environment = env
 game.sun.light_color = Color("fff0d3")
 game.sun.light_energy = 0.58
 _build_ui()
 _prepare_turn()
 _camera(0, true)

func _build_ui() -> void:
 var ui = game.ui
 ui.clear(ui.screen)
 ui.clear(ui.hud)
 ui.clear(ui.overlay)
 ui.screen.show()
 ui.hud.hide()
 ui.active_page = "monster"
 var top = ui.panel(ui.screen, Rect2(24, 16, 1232, 96), Color("071a34"))
 var row = HBoxContainer.new()
 row.add_theme_constant_override("separation", 30)
 top.add_child(row)
 for i in player_count:
  var box = VBoxContainer.new()
  box.custom_minimum_size.x = 230
  row.add_child(box)
  ui.label(box, "SOLO · BOAZ" if player_count == 1 else "SPELER %d · %s" % [i + 1, "BOAZ" if i == 0 else "RAVI"], 15, ui.CYAN if i == 0 else ui.GOLD)
  score_labels.append(ui.label(box, "0 punten", 28))
 var progress_box = VBoxContainer.new()
 progress_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_child(progress_box)
 progress_label = ui.label(progress_box, "", 17, ui.GOLD)
 progress_bar = ProgressBar.new()
 progress_bar.custom_minimum_size = Vector2(300, 16)
 progress_bar.max_value = 100
 progress_bar.show_percentage = false
 progress_box.add_child(progress_bar)
 var scoring = "Grotere stukken leveren meer punten · meeste punten wint" if arena.structure.score_multiplier == 1 else "1 monsterblokje = 10 punten · meeste punten wint"
 ui.label(progress_box, "Versla het monster in zo weinig mogelijk sprongen" if player_count == 1 else scoring, 14, ui.MUTED)
 title = ui.at(ui.screen, "", Vector2(32, 123), 25)
 turn_label = ui.at(ui.screen, "", Vector2(34, 160), 16, ui.GOLD)
 status = ui.at(ui.screen, "", Vector2(34, 192), 17)
 for caption in [title, turn_label, status]:
  caption.add_theme_color_override("font_outline_color", Color("071a34"))
  caption.add_theme_constant_override("outline_size", 5)
 pause_button = ui.button(ui.screen, "Pauze", toggle_pause)
 pause_button.position = Vector2(1110, 124)
 pause_button.size.x = 140
 var bottom = ui.panel(ui.screen, Rect2(24, 658, 1232, 120), Color("071a34"))
 var column = VBoxContainer.new()
 column.add_theme_constant_override("separation", 7)
 bottom.add_child(column)
 var controls = HBoxContainer.new()
 controls.add_theme_constant_override("separation", 24)
 column.add_child(controls)
 speed_label = ui.label(controls, "0 KM/U", 30)
 speed_label.custom_minimum_size.x = 200
 detail_label = ui.label(controls, "", 17, ui.GOLD)
 detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 shoot_button = ui.button(controls, "Schiet 5/5", shoot)
 shoot_button.name = "ShootButton"
 shoot_button.custom_minimum_size.x = 135
 action_button = ui.button(controls, "Start afdaling", action, true)
 action_button.custom_minimum_size.x = 230
 controls_label = ui.label(column, "", 14, ui.MUTED)
 aim_marker = Panel.new()
 aim_marker.name = "FlightAim"
 aim_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
 aim_marker.size = Vector2(28, 28)
 aim_style = StyleBoxFlat.new()
 aim_style.bg_color = Color("071a3466")
 aim_style.set_border_width_all(2)
 aim_style.set_corner_radius_all(14)
 aim_style.shadow_color = Color("071a34bb")
 aim_style.shadow_size = 2
 aim_marker.add_theme_stylebox_override("panel", aim_style)
 ui.screen.add_child(aim_marker)
 aim_caption = ui.at(aim_marker, "", Vector2(-76, 28), 15)
 aim_caption.size.x = 180
 aim_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 aim_caption.add_theme_color_override("font_outline_color", ui.INK)
 aim_caption.add_theme_constant_override("outline_size", 5)
 aim_marker.hide()
 vehicle_picker = ui.panel(ui.screen, Rect2(24, 244, 1232, 156), Color("071a34"))
 vehicle_picker.name = "VehiclePicker"
 var choices = VBoxContainer.new()
 vehicle_picker.add_child(choices)
 ui.label(choices, "Kies je voertuig voor deze sprong", 18)
 var scroll = ScrollContainer.new()
 scroll.name = "VehicleScroll"
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
 scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus = true
 scroll.custom_minimum_size = Vector2(0, 105)
 scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 choices.add_child(scroll)
 var options = HBoxContainer.new()
 options.add_theme_constant_override("separation", 8)
 scroll.add_child(options)
 for index in vehicles:
  var choice = ui.button(options, Catalog.VEHICLES[index].name, func(): select_vehicle(index))
  choice.name = "Vehicle_" + Catalog.VEHICLES[index].id
  choice.custom_minimum_size = Vector2(150, 90)
  choice.add_theme_font_size_override("font_size", 13)
  choice.tooltip_text = Catalog.VEHICLES[index].name
  choice.expand_icon = true
  choice.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
  choice.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
  var thumbnail_path = "res://assets/vehicle-thumbnails/%s.jpg" % Catalog.VEHICLES[index].id
  if ResourceLoader.exists(thumbnail_path):
   choice.icon = load(thumbnail_path)
  vehicle_buttons.append(choice)

func _prepare_turn(keep_vehicle: bool = false) -> void:
 impact_replay.reset()
 for shot in shots:
  shot.node.queue_free()
 shots.clear()
 phase = "ready"
 phase_time = 0
 turn_time = 0
 turn_score = 0
 hit_count = 0
 pending_points = 0
 miss_announced = false
 bird_notice = 0
 hit_sound_timer = 0
 boost_held = false
 dive_used = false
 dive_notice = 0
 ring_notice = 0
 aim_timer = 0
 aim_point = Vector3.INF
 aim_text = ""
 aim_ring = -1
 rings.reset()
 aim_marker.hide()
 road_z = Arena.COURSE_START
 road_speed = 0
 road_steering = 0
 lateral_speed = 0
 velocity = Vector3.ZERO
 if not keep_vehicle:
  vehicle_index = vehicles[turn % vehicles.size()]
 _spawn_vehicle()
 birds.reset(turn)
 vehicle_picker.show()
 action_button.text = "Start afdaling  →"
 action_button.disabled = false
 action_button.grab_focus()
 refresh_ui()
 _camera(0, true)

func select_vehicle(index: int) -> void:
 if paused or phase != "ready" or not vehicles.has(index):
  return
 vehicle_index = index
 _spawn_vehicle()
 refresh_ui()
 _camera(0, true)

func _spawn_vehicle() -> void:
 if is_instance_valid(rocket):
  remove_child(rocket)
  rocket.queue_free()
 rocket = Kart.new()
 add_child(rocket)
 rocket.setup(vehicle_index, "boaz" if player == 0 else "ravi", false)
 rocket.position = Arena.ramp_position(road_z) + Vector3(0, 0.1, 0)
 rocket.scale = Vector3.ONE * 2.1
 # Keep the bonnet visible from just behind the seat, without an obstructing rider.
 if is_instance_valid(rocket.driver_mount):
  rocket.driver_mount.hide()
 for i in vehicle_buttons.size():
  var selected: bool = vehicles[i] == vehicle_index
  vehicle_buttons[i].text = ("✓ " if selected else "") + Catalog.VEHICLES[vehicles[i]].name
  var style: StyleBoxFlat = vehicle_buttons[i].get_theme_stylebox("normal").duplicate()
  style.border_color = game.ui.GOLD if selected else Color("258ecb")
  style.set_border_width_all(3 if selected else 2)
  vehicle_buttons[i].add_theme_stylebox_override("normal", style)

func action() -> void:
 if paused:
  return
 if phase == "ready":
  vehicle_picker.hide()
  phase = "ramp"
  phase_time = 0
  road_speed = 12
  action_button.release_focus()
  action_button.disabled = true
  action_button.text = "Onderweg…"
 elif phase == "between":
  player = (player + 1) % player_count
  turn += 1
  _prepare_turn()
 elif phase == "replay":
  _finish_replay()
 elif phase == "finished":
  game.start_monster(monster_id, player_count)
  return
 refresh_ui()

func _physics_process(delta: float) -> void:
 if paused:
  return
 var gas = Input.get_action_strength("accelerate")
 var brake = Input.get_action_strength("brake")
 if game.profile.settings.auto_accelerate and brake < 0.1 and phase == "ramp":
  gas = 1
 if phase == "ready" and Input.is_action_just_pressed("accelerate"):
  action()
 step(delta, gas, brake, Input.get_axis("steer_left", "steer_right"), Input.is_action_pressed("boost"))

func step(delta: float, gas: float = 1, brake: float = 0, steer: float = 0, boost: bool = false) -> void:
 if paused or phase == "finished" or delta <= 0 or not is_finite(delta):
  return
 var remaining = minf(delta, 0.25)
 var boost_pressed = boost and not boost_held
 boost_held = boost
 while remaining > 0.00001:
  var tick = minf(remaining, TICK)
  _simulate(tick, clampf(gas, 0, 1), clampf(brake, 0, 1), clampf(steer, -1, 1), boost, boost_pressed)
  boost_pressed = false
  remaining -= tick
 refresh_ui()

func _simulate(delta: float, gas: float, brake: float, steer: float, boost: bool, boost_pressed: bool) -> void:
 if phase == "replay":
  if impact_replay.advance(delta):
   _finish_replay()
  return
 phase_time += delta
 for ammo in player_ammo:
  ammo.advance(delta)
 _advance_shots(delta)
 bird_notice = maxf(0, bird_notice - delta)
 hit_sound_timer = maxf(0, hit_sound_timer - delta)
 dive_notice = maxf(0, dive_notice - delta)
 ring_notice = maxf(0, ring_notice - delta)
 rings.advance(delta)
 if phase in ["ramp", "flight", "settling"]:
  turn_time += delta
 birds.advance(delta)
 for landed in arena.advance(delta):
  var points: int = landed.count * arena.structure.score_multiplier
  scores[landed.owner] += points
  turn_score += points
  pending_points -= points
 if phase == "ramp":
  var slope = Arena.ramp_slope(road_z)
  road_speed = _next_road_speed(road_speed, slope, gas, brake, boost, delta)
  road_steering = lerpf(road_steering, steer, 1 - exp(-delta * 9))
  lateral_speed = _road_lateral_speed(road_speed, road_steering)
  var x: float = rocket.position.x + lateral_speed * delta
  if absf(x) > 5.4:
   x = clampf(x, -5.4, 5.4)
   road_speed = maxf(0, road_speed - delta * 17)
  road_z = maxf(0, road_z - road_speed * delta / sqrt(1 + slope * slope))
  rocket.position = Arena.ramp_position(road_z) + Vector3(x, 0.1, 0)
  rocket.rotation = Vector3(-atan(Arena.ramp_slope(road_z)), -road_steering * 0.10, 0)
  rocket.speed = road_speed
  if road_z <= 0:
   launch_speed = road_speed
   velocity = _launch_velocity(road_speed, lateral_speed)
   phase = "flight"
   phase_time = 0
   aim_timer = 0
   action_button.text = "In de lucht"
   sounds.play("launch", game.audio.sound_volume, game.audio.muted)
  elif phase_time > 45:
   _splash_down()
 elif phase == "flight":
  if boost_pressed and _can_dive():
   dive_used = true
   dive_notice = DIVE_NOTICE_TIME
   velocity += DIVE_KICK
   aim_timer = 0
   sounds.play("dive", game.audio.sound_volume, game.audio.muted)
  var before: Vector3 = rocket.position
  velocity = _next_air_velocity(velocity, steer, delta)
  rocket.position += velocity * delta
  if rings.taken < 0:
   var ring = FlightRings.crossed(before, rocket.position)
   if ring >= 0:
    rings.take(ring)
    velocity += FlightRings.ROUTES[ring].impulse
    ring_notice = 1.25
    aim_timer = 0
    sounds.play("ring", game.audio.sound_volume, game.audio.muted)
  rocket.rotation = Vector3(atan2(velocity.y, -velocity.z), atan2(-velocity.x, -velocity.z), 0)
  rocket.speed = velocity.length()
  var bird_hits: int = birds.collide(before, rocket.position)
  if bird_hits > 0:
   velocity.x += (2.5 if turn % 2 == 0 else -2.5)
   velocity.y -= 2
   bird_notice = 2
   aim_timer = 0
   sounds.play("bird", game.audio.sound_volume, game.audio.muted)
  var chunk_start: int = arena.chunks.size()
  var momentum = velocity * (0.26 if dive_used else 0.12)
  var broken: int = arena.impact(before + STRIKE_HEIGHT, rocket.position + STRIKE_HEIGHT, _impact_radius(), player, momentum)
  if broken > 0:
   if game.profile.settings.impact_replay:
    impact_replay.mark_hit(rocket.position)
   hit_count += broken
   for i in range(chunk_start, arena.chunks.size()):
    pending_points += arena.chunks[i].target_count * arena.structure.score_multiplier
   if hit_sound_timer <= 0:
    game.audio.cue("hit")
    hit_sound_timer = 0.12
  if _past_target(rocket.position.z):
   if hit_count == 0:
    _announce_miss()
   elif not _past_target(before.z):
    action_button.text = "Brokken vallen…"
    _camera(0, true)
  if rocket.position.y <= 0 or phase_time >= 16:
   _splash_down()
 elif phase == "settling" and arena.chunks.is_empty() and shots.is_empty() and phase_time >= 1.4 and not impact_replay.pending():
  if float(arena.submerged) / arena.structure.total >= WIN_FRACTION:
   phase = "finished"
   action_button.text = "Nog een keer" if player_count == 1 else "Nog een duel"
   game.audio.cue("lap")
  else:
   phase = "between"
   action_button.text = "Volgende sprong" if player_count == 1 else "Volgende speler"
  action_button.disabled = false
  action_button.grab_focus()
 rocket.update_effects(delta)
 if game.profile.settings.impact_replay and phase in ["flight", "settling"]:
  impact_replay.record(delta, self)
 if phase == "settling" and impact_replay.complete():
  phase = "replay"
  impact_replay.begin(self)
  action_button.text = "Replay overslaan"
  action_button.disabled = false
  action_button.grab_focus()
  _camera(0, true)
 _update_aim(delta, gas, brake, steer, boost)

func _next_road_speed(speed: float, slope: float, gas: float, brake: float, boost: bool, delta: float) -> float:
 var acceleration = gas * 14 + 24 * slope / sqrt(1 + slope * slope) - brake * 38 - 1.5
 if boost and gas > 0.1 and brake < 0.1:
  acceleration += 18
 return clampf(speed + acceleration * delta, 0, 86 if boost else ROAD_TOP_SPEED)

func _road_lateral_speed(speed: float, steering: float) -> float:
 return steering * (1 + speed * 0.16) * clampf(speed / 6, 0, 1)

func _launch_velocity(speed: float, side_speed: float) -> Vector3:
 var pitch = -atan(Arena.ramp_slope(0))
 return Vector3(side_speed * 1.5, speed * sin(pitch), -speed * cos(pitch))

func _next_air_velocity(current: Vector3, steer: float, delta: float) -> Vector3:
 current.x = move_toward(current.x, steer * AIR_STEER_SPEED, AIR_CONTROL_ACCEL * delta)
 current.y -= GRAVITY * delta
 return current

func _impact_radius() -> float:
 return DIVE_RADIUS if dive_used else IMPACT_RADIUS

func _past_target(z: float) -> bool:
 return z < arena.hit_bounds.position.z - _impact_radius()

func _can_dive() -> bool:
 return not dive_used and hit_count == 0 and phase_time >= DIVE_MIN_TIME and not _past_target(rocket.position.z)

func _update_aim(delta: float, gas: float, brake: float, steer: float, boost: bool) -> void:
 if not ((phase == "ramp" and road_z <= 85) or (phase == "flight" and hit_count == 0 and not _past_target(rocket.position.z))):
  aim_point = Vector3.INF
  aim_text = ""
  aim_ring = -1
  return
 aim_timer -= delta
 if aim_timer > 0:
  return
 aim_timer = AIM_INTERVAL
 aim_point = Vector3.INF
 aim_text = ""
 aim_ring = -1
 var at: Vector3 = rocket.position
 var speed: Vector3 = velocity
 if phase == "ramp":
  # Preview the takeoff if the player keeps the current inputs.
  var z = road_z
  var x = at.x
  var forward_speed = road_speed
  var steering = road_steering
  var side_speed = lateral_speed
  for i in 6 * 60:
   var slope = Arena.ramp_slope(z)
   forward_speed = _next_road_speed(forward_speed, slope, gas, brake, boost, TICK)
   steering = lerpf(steering, steer, 1 - exp(-TICK * 9))
   side_speed = _road_lateral_speed(forward_speed, steering)
   x += side_speed * TICK
   if absf(x) > 5.4:
    x = clampf(x, -5.4, 5.4)
    forward_speed = maxf(0, forward_speed - TICK * 17)
   z -= forward_speed * TICK / sqrt(1 + slope * slope)
   if z <= 0 or forward_speed <= 0:
    break
  if z > 0:
   aim_text = "Meer vaart nodig"
   return
  at = Arena.ramp_position(0) + Vector3(x, 0.1, 0)
  speed = _launch_velocity(forward_speed, side_speed)
 _trace_aim(at, speed, steer)

func _trace_aim(at: Vector3, speed: Vector3, steer: float) -> void:
 var radius = _impact_radius()
 var bounds: AABB = arena.hit_bounds.grow(radius)
 var target_z = Structure.ORIGIN.z
 for segment in 16 * 15:
  var before = at
  # Integrate like the rocket, then query a short sweep through the target.
  for i in 4:
   var previous = at
   speed = _next_air_velocity(speed, steer, TICK)
   at += speed * TICK
   if rings.taken < 0 and aim_ring < 0:
    var ring = FlightRings.crossed(previous, at)
    if ring >= 0:
     aim_ring = ring
     speed += FlightRings.ROUTES[ring].impulse
  if at.y <= 0:
   at = before.lerp(at, clampf(before.y / (before.y - at.y), 0, 1))
  if at.z <= bounds.end.z and before.z >= bounds.position.z:
   var contact: Dictionary = arena.aim_contact(before + STRIKE_HEIGHT, at + STRIKE_HEIGHT, radius)
   if not contact.is_empty():
    aim_point = contact.point
    aim_text = "Monster" if contact.target else "Steun"
    return
  if before.z > target_z and at.z <= target_z:
   aim_point = before.lerp(at, (target_z - before.z) / (at.z - before.z)) + STRIKE_HEIGHT
   aim_text = "Geen treffer"
  if at.z < minf(target_z, bounds.position.z):
   return
  if at.y <= 0.001:
   if aim_text.is_empty():
    aim_text = "Te kort"
   return

func shoot() -> bool:
 if paused or phase not in ["ramp", "flight"] or not is_instance_valid(rocket):
  return false
 var ammo = player_ammo[player]
 if not ammo.fire(): return false
 var direction = (-rocket.basis.z).normalized()
 var start = rocket.position + STRIKE_HEIGHT + direction * 3.0
 var node = Geo.ball(self, start, Vector3.ONE * 1.2, Color("ffb24a"))
 shots.append({"node":node, "direction":direction, "life":3.5, "owner":player})
 game.audio.cue("shot")
 return true

func _advance_shots(delta: float) -> void:
 for i in range(shots.size() - 1, -1, -1):
  var shot: Dictionary = shots[i]
  var before: Vector3 = shot.node.position
  var after: Vector3 = before + shot.direction * 180.0 * delta
  var chunk_start = arena.chunks.size()
  var broken = arena.impact(before, after, 1.0, shot.owner, shot.direction * 30.0)
  if broken > 0:
   hit_count += broken
   for j in range(chunk_start, arena.chunks.size()):
    pending_points += arena.chunks[j].target_count * arena.structure.score_multiplier
   game.audio.cue("hit")
  shot.node.position = after
  shot.life -= delta
  if broken > 0 or shot.life <= 0 or after.y < 0:
   shot.node.queue_free()
   shots.remove_at(i)

func _finish_replay() -> void:
 impact_replay.finish()
 phase = "settling"
 action_button.text = "Even wachten…"
 action_button.disabled = true
 action_button.release_focus()
 _camera(0, true)

func _announce_miss() -> void:
 if miss_announced:
  return
 miss_announced = true
 sounds.play("miss", game.audio.sound_volume, game.audio.muted)

func _splash_down() -> void:
 if hit_count == 0:
  _announce_miss()
 arena.splash(rocket.position, 3)
 rocket.hide()
 phase = "settling"
 phase_time = 0
 action_button.text = "Plons!"

func refresh_ui() -> void:
 for i in player_count:
  score_labels[i].text = "%d punten%s" % [scores[i], " ◀" if player_count == 2 and player == i and phase != "finished" else ""]
 var percentage = float(arena.submerged) / arena.structure.total * 100
 progress_label.text = "MONSTER IN HET WATER  %d%% / 70%%" % floori(percentage)
 progress_bar.value = percentage
 turn_label.text = "%s %d · %s%s" % ["SPRONG" if player_count == 1 else "BEURT", turn + 1, "SPELER %d · " % (player + 1) if player_count == 2 else "", Catalog.VEHICLES[vehicle_index].name]
 title.text = "MONSTERBREKER · " + arena.structure.monster_name.to_upper()
 speed_label.text = "%d KM/U" % roundi(rocket.speed * 3.6)
 shoot_button.text = "F / B · " + player_ammo[player].label()
 shoot_button.disabled = paused or phase not in ["ramp", "flight"] or not player_ammo[player].can_fire()
 controls_label.text = "W / ↑ / RT: gas · S / ↓ / LT: rem · A/D / ← → / stick: sturen · Shift / RB: boost · F / B: schieten · R / Y: herstart"
 detail_label.text = "+%d punten · %d %s los" % [turn_score, hit_count, arena.structure.debris_label]
 if phase in ["flight", "settling"] and pending_points > 0:
  detail_label.text = "%d punten onderweg naar het water · +%d binnen" % [pending_points, turn_score]
 match phase:
  "ready":
   status.text = "Stuur door een luchtring of vlieg rechtstreeks naar het monster."
   detail_label.text = "190 m aanloop · volg de richtcirkel bij de schans"
  "ramp":
   status.text = "%d m tot de sprong · gas voor hoogte, uitrollen voor de steunen" % ceili(road_z)
   detail_label.text = aim_text if not aim_point.is_finite() else "Verwacht: " + aim_text.to_lower()
   if aim_ring >= 0:
    detail_label.text = FlightRings.ROUTES[aim_ring].name + " op je koers · " + detail_label.text
  "flight":
   controls_label.text = "A/D / ← → / stick: bijsturen · Shift / RB: duikboost · F / B: schieten"
   if hit_count > 0:
    status.text = _hit_status()
    if _past_target(rocket.position.z):
     controls_label.text = ""
   elif miss_announced:
    status.text = "Wie wo weeuh… MIS!"
    detail_label.text = "Richt bij je volgende sprong op het monster of een steun"
   elif bird_notice > 0:
    status.text = "OEPS, EEN VOGEL! Stuur bij."
   elif ring_notice > 0:
    status.text = FlightRings.ROUTES[rings.taken].feedback
   elif aim_ring >= 0:
    status.text = "Op koers voor de " + FlightRings.ROUTES[aim_ring].name.to_lower()
   else:
    status.text = "DUIKBOOST!" if dive_notice > 0 else "Vrije vlucht · stuur de richtcirkel naar je doel"
   if hit_count == 0 and not miss_announced:
    if aim_text == "Te kort":
     detail_label.text = "Te kort · neem de schans met meer vaart"
    elif dive_used:
     detail_label.text = "Duikboost gebruikt"
    elif boost_held:
     detail_label.text = "Laat Shift / RB los en druk opnieuw om te duiken"
    else:
     detail_label.text = "Shift / RB: duikboost voor een lagere, hardere treffer"
  "settling":
   status.text = _hit_status() if hit_count > 0 else "Plons! Deze sprong leverde geen punten op."
   controls_label.text = ""
  "replay":
   title.text = "IMPACT REPLAY"
   status.text = "Dezelfde klap, vanuit een andere hoek · vertraagd"
   speed_label.text = "REPLAY"
   detail_label.text = "Spatie / A: overslaan"
  "between":
   status.text = "Geef de bediening aan speler %d." % (2 - player) if player_count == 2 else ("Klaar voor je volgende sprong?" if turn_score > 0 else "Probeer bij je volgende sprong een andere lijn.")
  "finished":
   if player_count == 1:
    title.text = "MONSTER VERSLAGEN!"
    status.text = "%d punten in %d sprongen. Kun jij het in minder pogingen?" % [scores[0], turn + 1]
   else:
    title.text = "GELIJKSPEL!" if scores[0] == scores[1] else "SPELER %d WINT!" % (1 if scores[0] > scores[1] else 2)
    status.text = "Boaz: %d punten · Ravi: %d punten" % [scores[0], scores[1]]

func _hit_status() -> String:
 if pending_points + turn_score == 0:
  return "STEUN GERAAKT!"
 return "RAAK! %d punten uit deze sprong" % (pending_points + turn_score)

func _process(delta: float) -> void:
 if not paused:
  _camera(delta)

func cockpit_eye() -> Vector3:
 return rocket.to_global(rocket.driver_seat + Vector3(0, 1.1, 1.65))

func _camera(delta: float, snap: bool = false) -> void:
 game.camera.near = 0.08
 if phase == "replay":
  var focus: Vector3 = impact_replay.hit_position.lerp(arena.hit_bounds.get_center(), 0.35)
  game.camera.position = focus + Vector3(72 if impact_replay.hit_position.x >= 0 else -72, 26, 62)
  game.camera.look_at(focus)
  game.camera.fov = 60
 elif phase in ["ready", "ramp", "flight"] and not (phase == "flight" and hit_count > 0 and _past_target(rocket.position.z)):
  game.camera.position = cockpit_eye()
  arena.clear_camera_space(game.camera.position)
  var forward: Vector3 = -rocket.global_basis.z.normalized()
  var up: Vector3 = rocket.global_basis.y.normalized()
  # Follow the vehicle with a small downward tilt to keep its bonnet above the HUD.
  game.camera.look_at(game.camera.position + forward * 50 - up * 8, up)
  game.camera.fov = 72 + (clampf(rocket.speed / 86, 0, 1) * 7 if game.profile.settings.camera_motion else 0)
  if game.profile.settings.camera_motion:
   game.camera.fov += 5 * dive_notice / DIVE_NOTICE_TIME + 3 * hit_sound_timer / 0.12 + 4 * minf(ring_notice, 0.5) / 0.5
 else:
  # Watch the debris as soon as the kart clears the monster.
  var focus: Vector3 = arena.hit_bounds.get_center() + Vector3(0, 0, -5)
  var side = -1 if hit_count > 0 and impact_replay.hit_position.x < 0 else 1
  var at = focus + Vector3(side * 108, 32, -90)
  game.camera.position = at if snap else game.camera.position.lerp(at, 1 - exp(-delta * 4))
  game.camera.look_at(focus)
  game.camera.fov = 60
  arena.clear_camera_space(game.camera.position)
 _position_aim_marker()

func _position_aim_marker() -> void:
 if not aim_point.is_finite() or hit_count > 0 or phase not in ["ramp", "flight"] or game.camera.is_position_behind(aim_point):
  aim_marker.hide()
  return
 var ui = game.ui
 var inverse: Transform2D = ui.layout_root.get_global_transform_with_canvas().affine_inverse()
 var projected: Vector2 = inverse * game.camera.unproject_position(aim_point)
 var pinned = projected.clamp(Vector2(85, 230), Vector2(1195, 600))
 var caption = aim_text
 if projected.x < pinned.x:
  caption = "← " + caption
 elif projected.x > pinned.x:
  caption += " →"
 if projected.y < pinned.y:
  caption += " ↑"
 elif projected.y > pinned.y:
  caption += " ↓"
 aim_marker.position = pinned - aim_marker.size * 0.5
 if aim_caption.text != caption:
  var color: Color = ui.WHITE
  if aim_text == "Monster":
   color = ui.CYAN
  elif aim_text == "Steun":
   color = ui.GOLD
  aim_style.border_color = color
  aim_caption.text = caption
  aim_caption.add_theme_color_override("font_color", color)
 aim_marker.show()

func _input(event: InputEvent) -> void:
 if paused or phase not in ["ramp", "flight"]:
  return
 if event.is_action_pressed("shoot") and not event.is_echo():
  shoot()
  get_viewport().set_input_as_handled()
 elif event is InputEventKey and event.physical_keycode in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
  get_viewport().set_input_as_handled()
 elif event is InputEventJoypadMotion:
  get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
 if event.is_echo():
  return
 if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
  toggle_pause()
  get_viewport().set_input_as_handled()
 elif event.is_action_pressed("jump"):
  action()
  get_viewport().set_input_as_handled()
 elif event.is_action_pressed("reset_kart") and phase == "ramp" and not paused:
  _prepare_turn(true)
  get_viewport().set_input_as_handled()

func toggle_pause() -> void:
 paused = not paused
 sounds.pause(paused)
 var ui = game.ui
 ui.clear(ui.overlay)
 if not paused:
  action_button.grab_focus() if not action_button.disabled else pause_button.grab_focus()
  return
 ui.dim(ui.overlay, 0.7)
 var panel = ui.panel(ui.overlay, Rect2(36, 60, 1208, 680))
 panel.name = "MonsterPausePanel"
 var box = VBoxContainer.new()
 box.add_theme_constant_override("separation", 12)
 panel.add_child(box)
 ui.label(box, "Even pauze", 36)
 var actions = HBoxContainer.new()
 actions.add_theme_constant_override("separation", 16)
 box.add_child(actions)
 ui.button(actions, "Verder spelen  →", toggle_pause, true).grab_focus()
 ui.button(actions, "Opnieuw beginnen", func(): game.start_monster(monster_id, player_count))
 ui.button(actions, "Hoofdmenu", game.go_home)
 ui.label(box, "Speel een ander monster", 26)
 ui.label(box, "Klik op een tegel om opnieuw te beginnen. Je punten beginnen dan weer bij 0.", 16, ui.MUTED)
 var scroll = ScrollContainer.new()
 scroll.follow_focus = true
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 box.add_child(scroll)
 var grid = GridContainer.new()
 grid.name = "PauseMonsters"
 grid.columns = 6
 grid.add_theme_constant_override("h_separation", 12)
 grid.add_theme_constant_override("v_separation", 12)
 scroll.add_child(grid)
 for entry in MonsterCatalog.entries():
  var id: String = entry.id
  var tile = ui.button(grid, "", func(): game.start_monster(id, player_count))
  tile.name = "PauseMonster_" + id
  tile.accessibility_name = entry.name
  tile.tooltip_text = entry.name + " — start een nieuw spel"
  tile.custom_minimum_size = Vector2(184, 190)
  var preview = MonsterPreview.new()
  tile.add_child(preview)
  preview.position = Vector2(8, 8)
  preview.size = Vector2(168, 124)
  preview.setup(id, Vector2i(252, 186))
  var caption = ui.label(tile, ("✓ " if id == monster_id else "") + entry.name, 15)
  caption.position = Vector2(8, 138)
  caption.size = Vector2(168, 44)
  caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  caption.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(game) and is_instance_valid(sounds) and not paused:
  toggle_pause()
