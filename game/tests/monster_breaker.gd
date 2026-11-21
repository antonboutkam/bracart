extends SceneTree
const Main = preload("res://scripts/main.gd")
const Structure = preload("res://scripts/monster/structure.gd")
const Collection = preload("res://scripts/monster/catalog.gd")
const Arena = preload("res://scripts/monster/arena.gd")
const Birds = preload("res://scripts/monster/birds.gd")
var checks = 0
var failures: Array[String] = []
var game

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures.append(message)
  push_error(message)

func _initialize() -> void:
 call_deferred("run")

func click(button: Button) -> void:
 for down in [true, false]:
  var event = InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_LEFT
  event.position = button.get_global_rect().get_center()
  event.pressed = down
  root.push_input(event, true)
  await process_frame

func key(code: Key, down: bool) -> void:
 var event = InputEventKey.new()
 event.physical_keycode = code
 event.keycode = code
 event.pressed = down
 Input.parse_input_event(event)
 Input.flush_buffered_events()

func settle(mode, gas: float = 1, boost: bool = false) -> void:
 for i in 2400:
  mode.step(1.0 / 60, gas, 0, 0, boost)
  if mode.phase in ["between", "finished"]:
   break

func controlled(id: String = Collection.DEFAULT_ID, players: int = 2):
 game.start_monster(id, players)
 var mode = game.monster_mode
 mode.set_physics_process(false)
 mode.set_process(false)
 return mode

func run() -> void:
 var entries: Array = Collection.entries()
 check(entries.size() == 12, "Ten block monsters, the refined Gifspuwer and the original dragon are selectable")
 for entry in entries:
  if entry.get("format") == "fractured": continue # Dedicated fractured_monster.gd checks.
  var model = Structure.new()
  check(model.load_monster(entry.id), "Load " + entry.id)
  check(model.total > 0 and model.unsupported_groups().is_empty(), "All original blocks have grounded face connections: " + entry.id)
  var low = Vector3(INF, INF, INF)
  var high = -low
  for cell in model.cells:
   var at: Vector3 = model.position_of(cell)
   low = low.min(at)
   high = high.max(at)
  if entry.id != "dragon":
   check(is_zero_approx(low.x + high.x) and is_equal_approx((low.z + high.z) * 0.5, -160), "Imported target is centered on the flight corridor: " + entry.id)
   check(model.total == int(entry.blocks), "Catalog matches actual supplied blocks: " + entry.id)
   check(FileAccess.get_sha256(Collection.DIRECTORY + entry.id + ".json") == entry.sha256, "Runtime JSON preserves source bytes: " + entry.id)
  var target_total: int = model.total
  model.add_tower()
  check(model.total == target_total and model.target_cells.size() == target_total and model.cells.size() > target_total, "Tower is additional structure, not extra scoring blocks: " + entry.id)
  check(model.unsupported_groups().is_empty(), "Tower supports the complete monster: " + entry.id)
  # Sweep across the two supports at a reachable flight height.
  model.strike(Vector3(-40, 30, -160), Vector3(40, 30, -160), 1.45 * Structure.SIZE_MULTIPLIER)
  var remaining_targets = 0
  for cell in model.cells:
   if model.target_cells.has(cell): remaining_targets += 1
  check(remaining_targets == 0, "Severing supports releases the entire target: " + entry.id)
 var model = Structure.new()
 model.build_dragon()
 var old_cells: Dictionary = model.cells.duplicate()
 check(not model.load_monster("../../other") and model.cells == old_cells, "Unknown / path-like IDs are rejected without replacing the model")
 for bad in [null, {}, {"id":"bad","name":"Bad","blocks":[]}, {"id":"bad","name":"Bad","blocks":[{"x":0,"y":2,"z":0,"color":"#ffffff"}]}, {"id":"bad","name":"Bad","blocks":[{"x":0.5,"y":0,"z":0,"color":"#ffffff"}]}]:
  check(not model.load_data(bad) and model.cells == old_cells, "Malformed or unsupported geometry leaves the old structure intact")
 var block = {"x":0,"y":0,"z":0,"color":"#ffffff"}
 check(not model.load_data({"id":"bad","name":"Bad","blocks":[block,block]}), "Duplicate cells are rejected")
 model.cells = {Vector3i.ZERO:Color.WHITE}
 var point: Vector3 = model.position_of(Vector3i.ZERO)
 check(model.strike(point + Vector3(0,0,100), point - Vector3(0,0,100), 0.1).size() == 1, "Fast sweep hits a one-block-deep target")
 check(model.strike(point, point, 2).is_empty(), "Removed blocks cannot be hit twice")
 check(Arena.COURSE_START == 190 and Arena.ramp_position(190).y - Arena.ramp_position(60).y > 75, "Course has a 130m descent dropping 79m, then a 60m launch ramp")
 check(is_equal_approx(Structure.CELL, 1.3 * 1.5), "Monster block spacing is 50 percent larger in every dimension")
 check(is_zero_approx(Arena.ramp_slope(60)) and Arena.ramp_slope(0) < -0.6, "Bowl is smooth and takeoff ramp is steep")
 game = Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.music.stop()
 game.audio.muted = true
 await process_frame
 var profile_before = [game.profile.coins, game.profile.selected, game.profile.character, game.profile.records.duplicate(true)]
 await click(game.ui.screen.get_node("SplashSoloTile"))
 check(game.ui.active_page == "monsters" and game.ui.monster_players == 1, "Solo splash tile opens solo monster selection")
 await click(game.ui.screen.find_child("Choose_08-robotmonster-mini", true, false))
 check(game.ui.selected_monster == "08-robotmonster-mini", "Selection changes to the actual imported robot")
 await click(game.ui.screen.get_node("StartMonster"))
 var mode = game.monster_mode
 mode.set_physics_process(false)
 mode.set_process(false)
 check(mode.player_count == 1 and mode.monster_id == "08-robotmonster-mini" and mode.arena.structure.total == 272, "Start uses the selected JSON monster and solo rules")
 check(game.track == null and game.race == null, "Race world is released for the stunt arena")
 game.go_home()
 game.ui.show_splash()
 game.ui.screen.get_node("SplashDuoTile").grab_focus()
 key(KEY_ENTER, true)
 key(KEY_ENTER, false)
 await process_frame
 check(game.ui.active_page == "monsters" and game.ui.monster_players == 2, "Keyboard accept on the duo tile chooses two players instead of bypassing splash")
 mode = controlled()
 await process_frame
 await process_frame
 var chosen: int = mode.vehicles.back()
 var target_before: Dictionary = mode.arena.structure.cells.duplicate()
 await click(mode.vehicle_buttons.back())
 check(mode.vehicle_index == chosen and mode.rocket.vehicle_index == chosen, "Clicking a vehicle before the first jump replaces the actual kart")
 check(mode.phase == "ready" and mode.scores == [0, 0] and mode.arena.structure.cells == target_before, "Vehicle choice preserves the current monster and score")
 check(is_equal_approx(mode.arena.brick_mesh.size.x, 1.23 * 1.5), "Visible bricks use the same 50 percent enlargement as collision geometry")
 var first_vehicle: int = mode.vehicle_index
 mode._camera(0, true)
 check(game.camera.position.distance_to(mode.cockpit_eye()) < 0.001 and not mode.rocket.driver_mount.visible, "Camera starts at the seat without looking through the rider")
 key(KEY_W, true)
 mode._physics_process(1.0 / 60)
 key(KEY_W, false)
 check(mode.phase == "ramp", "Race accelerate action starts the descent")
 check(not mode.vehicle_picker.visible, "Vehicle choices leave the driving view when starting")
 mode.select_vehicle(mode.vehicles.front())
 check(mode.vehicle_index == chosen, "Vehicle cannot change during a running jump")
 key(KEY_R, true)
 key(KEY_R, false)
 check(mode.phase == "ready" and mode.vehicle_index == chosen, "Restarting the approach keeps the chosen vehicle")
 mode.action()
 mode.action()
 check(mode.phase == "ramp" and mode.turn == 0, "Repeated start cannot skip a running turn")
 var x_before: float = mode.rocket.position.x
 key(KEY_D, true)
 for i in 15: mode._physics_process(1.0 / 60)
 key(KEY_D, false)
 check(mode.rocket.position.x > x_before, "Race steer action moves the kart on the ramp")
 mode._prepare_turn()
 mode.action()
 while mode.phase == "ramp": mode.step(1.0 / 60)
 check(mode.launch_speed > 65 and mode.rocket.position.y > 21 and mode.velocity.y > 35, "Long descent produces a fast upward launch")
 mode._camera(0, true)
 var camera_forward: Vector3 = (-mode.rocket.global_basis.z * 50 - mode.rocket.global_basis.y * 8).normalized()
 check(game.camera.position.distance_to(mode.cockpit_eye()) < 0.001 and (-game.camera.basis.z).dot(camera_forward) > 0.999, "Airborne camera follows the rocket with the same gentle downward view of the bonnet")
 var v_before: Vector3 = mode.velocity
 mode.step(1.0 / 60, 1, 0, 1, true)
 check(mode.velocity.x - v_before.x > 0.05 and mode.velocity.x - v_before.x < 0.1 and mode.velocity.y < v_before.y, "Air steering is small; gas/boost cannot add upward flight")
 mode.step(0.25, 0, 0, 1)
 check(mode.velocity.x > 1, "Holding air steering produces a useful lateral correction")
 mode.step(0.25, 0, 0, -1)
 mode.step(0.25, 0, 0, -1)
 check(mode.velocity.x < 0, "Opposite air steering reverses the lateral correction")
 mode.step(0.25, 0, 0, 0)
 check(is_zero_approx(mode.velocity.x), "Releasing steering settles sideways drift")
 mode.toggle_pause()
 var bird_before: Vector3 = mode.birds.birds[0].node.position
 var rocket_before: Vector3 = mode.rocket.position
 mode.step(1)
 check(mode.rocket.position == rocket_before and mode.birds.birds[0].node.position == bird_before, "Pause freezes flight and birds")
 mode.toggle_pause()
 var ascending = false
 for i in 1800:
  var z_before: float = mode.rocket.position.z
  mode.step(1.0 / 60)
  if z_before > -160 and mode.rocket.position.z <= -160: ascending = mode.velocity.y > 0
  if mode.phase == "between": break
 check(ascending and mode.scores[0] > 0, "A normal full-gas jump reaches the supplied target while still rising")
 check(mode.arena.chunks.is_empty() and mode.scores[0] == mode.arena.submerged * 10, "Points wait for water and count only target blocks")
 var remaining: int = mode.arena.structure.cells.size()
 mode.action()
 check(mode.player == 1 and mode.vehicle_index != first_vehicle and mode.arena.structure.cells.size() == remaining, "Duo handoff changes player/rocket and preserves holes")
 mode.select_vehicle(first_vehicle)
 check(mode.vehicle_index == first_vehicle and mode.arena.structure.cells.size() == remaining and mode.player == 1, "Next player can choose a vehicle without repairing the monster")
 mode.action()
 while mode.phase in ["ramp", "flight"]:
  mode.step(1.0 / 60, 1, 0, 1, true)
 settle(mode, 1, true)
 check(mode.phase == "between" and mode.turn_score == 0 and mode.miss_announced, "Steering away from the target produces a real miss")
 check(mode.sounds.counts.miss == 1, "A missed jump plays the comic cue exactly once")
 mode.step(0.2)
 check(mode.sounds.counts.miss == 1, "Waiting after a miss does not replay its sound")
 # Complete an actual solo game by coasting and steering into the two supports.
 mode = controlled(Collection.DEFAULT_ID, 1)
 var target_x: Array[float] = []
 var low_x = 100
 var high_x = -100
 for cell in mode.arena.structure.target_cells:
  low_x = mini(low_x, cell.x)
  high_x = maxi(high_x, cell.x)
 var left_x = roundi(lerpf(low_x, high_x, 0.25))
 for x in [left_x, low_x + high_x - left_x]:
  target_x.append((x - mode.arena.structure.center_offset.x) * Structure.CELL)
 for side in [-1, 1]:
  mode.action()
  for i in 2400:
   var steer = clampf((target_x[0 if side == -1 else 1] - mode.rocket.position.x) * 0.8 - mode.velocity.x * 0.7, -1, 1) if mode.phase == "flight" else 0.0
   mode.step(1.0 / 60, 0, 0, steer)
   if mode.phase in ["between", "finished"]: break
  if side == -1:
   check(mode.phase == "between", "One support shot leaves a playable damaged structure")
   var previous_vehicle: int = mode.vehicle_index
   mode.action()
   check(mode.player == 0 and mode.vehicle_index != previous_vehicle, "Solo retains one player and changes rocket each attempt")
 check(mode.phase == "finished" and mode.arena.submerged >= mode.arena.structure.total * 0.7, "Two real, coasting, steered jumps can finish a solo game")
 check(mode.title.text == "MONSTER VERSLAGEN!" and mode.scores[1] == 0, "Solo finish shows points and attempts, without a fake second player")
 check(mode.scores[0] == mode.arena.submerged * 10, "Large tower collapse awards all target blocks exactly once")
 mode.action()
 await process_frame
 check(game.monster_mode.player_count == 1 and game.monster_mode.monster_id == Collection.DEFAULT_ID and game.monster_mode.scores == [0,0], "Replay keeps selected monster and solo mode, resets scores")
 mode = controlled("09-paarse-spook", 2)
 mode.scores.assign([40, 20])
 mode.toggle_pause()
 await process_frame
 await process_frame
 var pause_grid = game.ui.overlay.find_child("PauseMonsters", true, false)
 check(pause_grid.get_child_count() == entries.size(), "Pause offers every monster as a tile")
 var panel_rect: Rect2 = game.ui.overlay.get_node("MonsterPausePanel").get_global_rect()
 for tile in pause_grid.get_children():
  check(panel_rect.encloses(tile.get_global_rect()), "Monster tile fits inside pause panel: " + tile.name)
 var old_mode = weakref(mode)
 await click(pause_grid.get_node("PauseMonster_08-robotmonster-mini"))
 mode = game.monster_mode
 mode.set_physics_process(false)
 mode.set_process(false)
 check(mode.monster_id == "08-robotmonster-mini" and mode.player_count == 2 and mode.scores == [0, 0] and not mode.paused, "Pause tile directly starts the chosen monster with the same player count and fresh points")
 check(old_mode.get_ref() == null and game.ui.overlay.get_child_count() == 0, "Changing monster releases the old match and pause previews")
 mode.phase = "finished"
 mode.scores.assign([100,200])
 mode.refresh_ui()
 check(mode.title.text == "SPELER 2 WINT!", "Duo winner is highest score, independent of final striker")
 mode.scores.assign([100,100])
 mode.refresh_ui()
 check(mode.title.text == "GELIJKSPEL!", "Equal duo scores remain a draw")
 var bird: Dictionary = mode.birds.birds[0]
 point = bird.node.position
 check(mode.birds.collide(point + Vector3(0,0,30), point - Vector3(0,0,30)) == 1, "A swept bird collision is detected")
 check(mode.birds.collide(point, point) == 0, "A dizzy bird cannot collide repeatedly")
 mode.birds.advance(2)
 check(bird.node.position.distance_to(point) > 10, "Bumped bird flies away instead of being destroyed")
 check(mode.sounds.clips.miss.get_length() > 1 and mode.sounds.clips.bird.get_length() < 0.5, "Comic miss and chirp clips are generated")
 mode = controlled(Collection.DEFAULT_ID, 1)
 mode.turn = 2
 mode._prepare_turn()
 mode.action()
 settle(mode)
 check(mode.birds.hits > 0 and mode.sounds.counts.bird > 0, "An ordinary flight can bump a passing bird and play its chirp")
 for entry in entries:
  if entry.id == "dragon" or entry.get("format") == "fractured": continue
  mode = controlled(entry.id, 1)
  mode.action()
  # The small robot is lower: slightly less throttle avoids skimming over its head.
  settle(mode, 0.8 if entry.id == "08-robotmonster-mini" else 1.0)
  check(mode.phase == "between" and mode.scores[0] > 0 and mode.arena.chunks.is_empty(), "Complete natural flight, hit, splash and scoring: " + entry.id)
  await process_frame
 check([game.profile.coins,game.profile.selected,game.profile.character,game.profile.records] == profile_before, "Stunts do not change racing progress")
 game.go_home()
 check(game.mode == "menu" and game.monster_mode == null, "Returning home releases the mode")
 game.start_race(0)
 check(game.mode == "race" and is_instance_valid(game.race), "Normal racing still starts")
 game.queue_free()
 await process_frame
 await process_frame
 print("MONSTER PROTOTYPE: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
