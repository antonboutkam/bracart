extends SceneTree
const Race = preload("res://scripts/race.gd")
const Kart = preload("res://scripts/kart.gd")
var checks = 0
var failures: Array[String] = []

class FlatTrack extends RefCounted:
 var length = 200.0
 var width = 7.0
 func position_at(distance: float, lane: float = 0, height: float = 0) -> Vector3:
  return Vector3(lane, height, -distance)

class TestKart extends Kart:
 func update_visual(_track, _delta: float) -> void:
  pass

class TestProfile extends RefCounted:
 var attempts = 0
 var coins = 0
 var can_save = false
 func record_race(_world: int, _time: float, reward: int) -> bool:
  attempts += 1
  if not can_save:
   return false
  coins += reward
  return true

func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures.append(label)
  push_error(label)

func make_race():
 var race = Race.new()
 root.add_child(race)
 race.track = FlatTrack.new()
 race.countdown = 0
 for i in 5:
  var kart = TestKart.new()
  kart.vehicle_index = 4
  kart.racer_name = "Test %d" % i
  kart.ai = i != 0
  kart.progress = 20.0 + i * 30.0
  kart.lateral = 0
  race.add_child(kart)
  race.racers.append(kart)
 race.player = race.racers[0]
 race.rng.seed = 42
 return race

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var race = make_race()
 race.countdown = 0.5
 race.step(0.75, 1, 0, 0, false)
 check(absf(race.elapsed - 0.25) < 0.0001, "Countdown overshoot only advances remaining race time")
 check(race.player.progress > 20 and race.player.speed < 5, "Countdown does not secretly accelerate")
 race.paused = true
 var frozen: float = race.elapsed
 race.step(2, 1, 0, 0, true)
 check(race.elapsed == frozen, "Pause freezes timers and motion")
 race.paused = false
 race.player.speed = 0
 race.player.lateral = 0
 race._step_kart(race.player, 0, 0.1, 0, 0, 1, false)
 check(race.player.lateral == 0, "Steering while stopped cannot slide kart sideways")
 race.step(2, 1, 0, 0, false)
 var moving_speed: float = race.player.speed
 race.step(0.5, 1, 1, 0, false)
 check(race.player.speed < moving_speed - 10, "Brake wins over throttle")
 race.player.power = "Boost"
 race.use_power()
 check(race.player.power == "" and race.player.boost_time > 3, "Boost consumes one item and starts timer")
 race.player.cannon_time = 0
 race.player.power = "Kanonnen"
 race.use_power()
 var shots: int = race.projectiles.size()
 race.use_power()
 race.use_power()
 check(race.projectiles.size() == shots, "Rapid repeated cannon presses respect cooldown")
 race.elapsed += 0.31
 race.use_power()
 check(race.projectiles.size() == shots + 1, "Cannons can fire again after cooldown")
 race.player.cannon_time = 0
 race.player.power = "Schild"
 race.use_power()
 var protected_speed: float = race.player.speed
 race._weapon_hit(race.player, race.racers[1])
 check(race.player.shield_time == 0 and race.player.speed == protected_speed, "Shield absorbs exactly one hit without slowing")
 race._weapon_hit(race.player, race.racers[1])
 check(race.player.speed == protected_speed, "Hit grace prevents immediate second damage")
 race.player.hit_cooldown = 0
 race._weapon_hit(race.player, race.racers[1])
 check(race.player.speed < protected_speed and race.player.stun_time > 0, "Unshielded projectile causes temporary slowdown")
 var jumping = race.player.jump_velocity
 race.jump()
 check(race.player.jump_velocity == jumping, "Stunned racer cannot evade by starting a jump")
 race.free()

 race = make_race()
 race.player.progress = 20
 race.player.speed = 40
 var rival = race.racers[1]
 rival.progress = 30
 rival.speed = 0
 race.fire(race.player, "bullet")
 race._update_projectiles(0.2)
 check(rival.stun_time > 0 and race.projectiles.is_empty(), "Fast projectile crossing a rival hits instead of tunnelling")
 rival.hit_cooldown = 0
 rival.stun_time = 0
 rival.jump_height = 2
 race.fire(race.player, "bullet")
 race._update_projectiles(0.2)
 check(rival.stun_time == 0, "Airborne rival can jump over a projectile")
 race.free()

 race = make_race()
 race.player.progress = 50
 var pursuer = race.racers[1]
 pursuer.progress = 48
 pursuer.speed = 20
 race.fire(race.player, "bomb")
 race._update_projectiles(0.01)
 check(pursuer.stun_time > 0 and race.player.stun_time == 0, "Dropped bomb hits following racer and never owner")
 race._pickup("coin", 50, 4.0)
 race.player.magnet_time = 0
 race._update_pickups(0.01, 50)
 check(race.collected == 0, "Distant coin stays outside normal pickup reach")
 race.player.magnet_time = 5
 race._update_pickups(0.01, 50)
 check(race.collected == 1, "Magnet attracts coin across a lane")
 race._update_pickups(0.01, 50)
 check(race.collected == 1, "A collected coin cannot immediately pay twice")
 race.free()

 race = make_race()
 var ai = race.racers[1]
 ai.progress = 30
 ai.lateral = 0
 race.player.progress = 34
 race.player.lateral = 0
 race._choose_ai_lane(ai, 1, 0.1)
 check(absf(ai.target_lane) >= 1.8, "AI chooses an overtaking lane around close traffic")
 race.player.progress = 100
 ai.set_meta("decision_in", 0)
 race._pickup("power", 40, 3.6)
 race._choose_ai_lane(ai, 1, 0.1)
 check(ai.target_lane > 1, "AI seeks an available power pickup")
 ai.target_lane = 0
 ai.steering = 0
 ai.lateral = 0
 ai.set_meta("decision_in", 100)
 race.difficulty = 0
 for i in 600:
  race._step_kart(ai, 1, 1.0 / 60, 0, 0, 0, false)
 var easy_speed: float = ai.speed
 ai.speed = 0
 ai.progress = 30
 race.difficulty = 2
 for i in 600:
  race._step_kart(ai, 1, 1.0 / 60, 0, 0, 0, false)
 check(ai.speed > easy_speed + 5, "Difficulty changes rival pace with no teleporting")
 race.free()

 race = make_race()
 for kart in race.racers:
  kart.progress = 0
  kart.lateral = -4 if kart == race.player else 4
 race.player.speed = 41
 race.player.progress = 599.8
 race.last_lap = 2
 race.elapsed = 10
 race.lap_start = 7
 race.lap_times.assign([3.0, 4.0])
 race.step(0.2, 1, 0, 0, false)
 check(race.done and race.last_lap == 3, "Finish occurs after exactly three laps")
 check(absf(race.elapsed - (10 + 0.2 / 41)) < 0.001, "Final time interpolates the finish crossing")
 check(absf(race.lap_times[2] - (race.elapsed - 7)) < 0.0001, "Final lap and total finish times agree")
 var final_time: float = race.elapsed
 race.step(1, 1, 0, 0, false)
 check(race.elapsed == final_time, "Finished race remains frozen")
 var profile = TestProfile.new()
 check(not race.claim_reward(profile, 0) and not race.payout_claimed, "Save failure leaves reward retryable")
 profile.can_save = true
 check(race.claim_reward(profile, 0) and profile.coins == race.reward, "Successful retry pays reward once")
 check(not race.claim_reward(profile, 0) and profile.attempts == 2, "Repeated claim cannot pay again")
 race.free()
 race = make_race()
 race.player.power = "Magneet"
 race.use_power()
 race.step(9.2, 0, 0, 0, false)
 check(race.player.magnet_time == 0, "Magnet expires after its advertised duration")
 race.player.power = "Schild"
 race.use_power()
 race.step(8.2, 0, 0, 0, false)
 check(race.player.shield_time == 0, "Unused shield expires naturally")
 race.player.power = "Kanonnen"
 race.use_power()
 race.step(7.2, 0, 0, 0, false)
 var remaining_shots: int = race.projectiles.size()
 race.use_power()
 check(race.player.cannon_time == 0 and race.projectiles.size() == remaining_shots, "Expired cannons cannot keep firing")
 race.free()
 var coarse = make_race()
 var fine = make_race()
 coarse.step(2, 1, 0, 0.4, false)
 for i in 120:
  fine.step(1.0 / 60, 1, 0, 0.4, false)
 check(absf(coarse.player.progress - fine.player.progress) < 0.001, "Slow frames preserve race progress")
 check(absf(coarse.player.lateral - fine.player.lateral) < 0.001, "Slow frames preserve steering and edge guidance")
 coarse.free()
 fine.free()
 var fresh = make_race()
 check(not fresh.done and fresh.elapsed == 0 and fresh.collected == 0 and fresh.projectiles.is_empty(), "New race starts without previous race state")
 fresh.free()
 await process_frame
 print("BORACER RACE BEHAVIOR: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
