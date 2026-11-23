extends SceneTree
const Ammo = preload("res://scripts/combat/ammo.gd")
const Main = preload("res://scripts/main.gd")
const Track = preload("res://scripts/track.gd")
const Race = preload("res://scripts/race.gd")
const Monsters = preload("res://scripts/monster/catalog.gd")
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var ammo = Ammo.new()
 for i in 5:
  check(ammo.fire(), "Shot available %d" % i)
  check(not ammo.fire(), "Fire interval blocks extra shot")
  ammo.advance(.31)
 check(ammo.remaining == 0 and ammo.reload_left > 29, "Five shots start reload")
 ammo.advance(29.0)
 check(not ammo.can_fire(), "Cannot fire before reload")
 ammo.advance(1.0)
 check(ammo.remaining == 5 and ammo.can_fire(), "Magazine reloaded after 30 seconds")
 var track = Track.new()
 root.add_child(track)
 track.build(0)
 var race = Race.new()
 root.add_child(race)
 race.setup(track, 0, "boaz", 0)
 check(not race.fire_standard(), "No firing during countdown")
 race.countdown = 0
 race.paused = true
 check(not race.fire_standard(), "No firing while paused")
 race.player.ammo.remaining = 0
 race.player.ammo.reload_left = 5
 race.step(1, 0, 0, 0, false)
 check(race.player.ammo.reload_left == 5, "Race reload pauses with the game")
 race.player.ammo.remaining = 5
 race.player.ammo.reload_left = 0
 race.paused = false
 var before = race.projectiles.size()
 check(race.fire_standard() and race.player.ammo.remaining == 4 and race.projectiles.size() == before + 1, "Player fires a real race projectile")
 check(not race.fire_standard() and race.player.ammo.remaining == 4, "Cooldown never consumes ammo")
 var opponent = race.racers[1]
 opponent.progress = race.player.progress + 10
 opponent.lateral = race.player.lateral
 opponent.set_meta("previous_progress", opponent.progress)
 race._update_projectiles(.10)
 check(opponent.stun_time > 0, "Race projectile hits a rival")
 race.player.power = "Schild"
 race.use_power()
 check(race.player.shield_time > 0, "Shooting does not interfere with power-ups")
 race.queue_free()
 track.queue_free()
 await process_frame
 var game = Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.music.stop()
 game.audio.muted = true
 await process_frame
 game.start_monster(Monsters.DEFAULT_ID, 2)
 var mode = game.monster_mode
 mode.set_process(false)
 mode.set_physics_process(false)
 check(not mode.shoot(), "No firing before a turn")
 mode.action()
 mode.paused = true
 check(not mode.shoot(), "No firing while Monsterbreker is paused")
 mode.player_ammo[0].remaining = 0
 mode.player_ammo[0].reload_left = 5
 mode.step(1)
 check(mode.player_ammo[0].reload_left == 5, "Monsterbreker reload pauses with the game")
 mode.player_ammo[0].remaining = 5
 mode.player_ammo[0].reload_left = 0
 mode.paused = false
 var piece: Dictionary = mode.arena.structure.pieces.values()[0]
 var center = Vector3.ZERO
 for point in piece.collider.points:
  center += Vector3(point[0], point[1], point[2])
 center /= piece.collider.points.size()
 center = mode.arena.structure.model_origin + (piece.pivot + center) * mode.arena.structure.MODEL_SCALE
 mode.rocket.position = Vector3(center.x, center.y - mode.STRIKE_HEIGHT.y, center.z + 12)
 mode.rocket.rotation = Vector3.ZERO
 check(mode.shoot() and mode.player_ammo[0].remaining == 4, "Monsterbreker fires with its player's ammo")
 for i in 30:
  mode._advance_shots(1.0 / 60)
  if mode.hit_count > 0: break
 check(mode.hit_count > 0 and mode.pending_points > 0 and mode.arena.chunks.any(func(chunk): return chunk.owner == 0 and chunk.target_count > 0), "Projectile releases real monster pieces for the shooter")
 check(mode.player_ammo[1].remaining == 5, "Players have separate ammunition")
 var pad = InputEventJoypadButton.new()
 pad.button_index = JOY_BUTTON_B
 pad.pressed = true
 mode.player_ammo[0].advance(.31)
 var old_ammo = mode.player_ammo[0].remaining
 root.push_input(pad, true)
 check(not mode.paused and mode.player_ammo[0].remaining == old_ammo - 1, "Controller B shoots without opening pause")
 game.queue_free()
 await process_frame
 print("STANDARD AMMO: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
