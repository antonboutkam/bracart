extends Node3D
signal finished
signal notice(message: String)
signal sound(kind: String)
signal feedback(kind: String, at: Vector3, intensity: float, surface: String)
const Kart = preload("res://scripts/kart.gd")
const Geo = preload("res://scripts/geometry.gd")
const Catalog = preload("res://scripts/catalog.gd")
const RewardVisuals = preload("res://scripts/effects/reward_visuals.gd")
const LAPS = 3
var track
var player
var racers: Array = []
var pickups: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var elapsed: float = 0
var countdown: float = 3.5
var lap_start: float = 0
var lap_times: Array[float] = []
var collected: int = 0
var done: bool = false
var paused: bool = false
var difficulty: int = 0
var boost_active: bool = false
var rank: int = 1
var reward: int = 0
var payout_claimed: bool = false
var last_lap: int = 0
var rng = RandomNumberGenerator.new()
var auto_drive: bool = false
var last_count: int = 4
var feedback_collision_at: float = -1.0

func setup(race_track, vehicle: int, character_id: String, level: int) -> void:
 track = race_track
 difficulty = clampi(level, 0, 2)
 rng.seed = 8124 + track.world_index
 var available = Catalog.available_indices()
 if vehicle not in available:
  vehicle = Catalog.DEFAULT_VEHICLE
 # Keep rivals distinct, and leave the player's chosen vehicle out of their pool.
 var ai_vehicles: Array = []
 for index in available:
  if index != vehicle:
   ai_vehicles.append(index)
 # A reduced asset manifest still permits a race; repeat only when unavoidable.
 if ai_vehicles.is_empty():
  ai_vehicles.append(vehicle)
 for i in 5:
  var kart = Kart.new()
  add_child(kart)
  kart.setup(vehicle if i == 0 else ai_vehicles[(i - 1) % ai_vehicles.size()], character_id if i == 0 else ("ravi" if i % 2 else "boaz"), i != 0)
  kart.racer_name = character_id.capitalize() if i == 0 else ["", "Nova", "Finn", "Luna", "Storm"][i]
  # Keep all rivals ahead of the player's follow camera at the starting grid.
  # Otherwise a kart on the following row fills the camera during the countdown.
  kart.progress = -14.0 if i == 0 else -8.0 - floori(float(i - 1) / 2) * 3.0
  kart.lateral = 0.0 if i == 0 else (-2.0 if i % 2 == 0 else 2.0)
  kart.target_lane = kart.lateral
  racers.append(kart)
  kart.update_visual(track, 0)
 player = racers[0]
 rank = ranking().find(player) + 1
 for i in range(18, int(track.length) - 8, 11):
  var lane = sin(i * 0.044) * 3.6
  _pickup("coin", i, lane)
 var power_count: int = int(ceil(track.length/95)) if track.get("v2_course") != null else 8
 for i in power_count:
  for lane in [-3.6, 0.0, 3.6]:
   _pickup("power", 38 + track.length * i / float(power_count), lane)

func _pickup(kind: String, distance: float, lane: float) -> void:
 var mesh: Node3D = RewardVisuals.create_pickup(self, kind, track.position_at(distance, lane, 1.1 if kind == "coin" else 1.2))
 pickups.append({"kind":kind, "distance":distance, "lane":lane, "node":mesh, "cooldown":0.0})

func step(delta: float, gas: float, brake: float, steer: float, boosting: bool) -> void:
 if done or paused:
  return
 if delta <= 0:
  return
 # Small fixed upper steps keep pickups and weapons reliable during a slow frame.
 var remaining = delta
 while remaining > 0.000001 and not done:
  var tick = minf(remaining, 1.0 / 60.0)
  remaining -= tick
  if countdown > 0:
   var waiting = minf(countdown, tick)
   countdown -= waiting
   tick -= waiting
   var count = ceili(countdown)
   if count != last_count and count >= 0:
    sound.emit("start")
    last_count = count
   if tick <= 0.000001:
    continue
  countdown -= tick
  _simulate(tick, gas, brake, steer, boosting)
 for kart in racers:
  kart.update_visual(track, delta)

func _simulate(delta: float, gas: float, brake: float, steer: float, boosting: bool) -> void:
 var previous_elapsed = elapsed
 elapsed += delta
 if auto_drive:
  gas = 1
  steer = clampf((sin(player.progress * 0.044) * 3.6 - player.lateral) * 0.7, -1, 1)
  boosting = true
 var old_progress: float = player.progress
 for i in racers.size():
  var kart = racers[i]
  kart.set_meta("previous_progress", kart.progress)
  _step_kart(kart, i, delta, gas, brake, steer, boosting)
 _collisions(delta)
 _update_pickups(delta, old_progress)
 _update_projectiles(delta)
 # Interpolate each line crossing: the final time is independent of frame rate.
 var lap: int = clampi(floori(player.progress / track.length), 0, LAPS)
 while lap > last_lap:
  var crossing = (last_lap + 1) * track.length
  var fraction = clampf((crossing - old_progress) / maxf(player.progress - old_progress, 0.000001), 0, 1)
  var crossing_time = player.finish_time if last_lap + 1 == LAPS and player.finish_time >= 0 else lerpf(previous_elapsed, elapsed, fraction)
  lap_times.append(crossing_time - lap_start)
  lap_start = crossing_time
  last_lap += 1
  sound.emit("lap")
  if last_lap < LAPS:
   notice.emit("Laatste ronde!" if last_lap == 2 else "Ronde 2 — lekker bezig!")
 rank = ranking().find(player) + 1
 boost_active = player.boost_time > 0
 if player.finish_time >= 0:
  elapsed = player.finish_time
  done = true
  reward = collected + [60, 40, 25, 15, 10][clampi(rank - 1, 0, 4)]
  _feedback_at(player,"finish",1.0)
  finished.emit()

func _step_kart(kart, index: int, delta: float, gas: float, brake: float, steer: float, boosting: bool) -> void:
 if kart.finish_time >= 0:
  kart.speed = move_toward(kart.speed, 0, delta * 15)
  return
 for key in ["shield_time", "magnet_time", "cannon_time", "stun_time", "boost_time", "hit_cooldown"]:
  kart.set(key, maxf(0, float(kart.get(key)) - delta))
 var stats: Dictionary = Catalog.VEHICLES[kart.vehicle_index]
 var throttle = clampf(gas, 0, 1)
 var stopping = clampf(brake, 0, 1)
 var turn = clampf(steer, -1, 1)
 var boost_now = boosting and kart.boost > 0 and gas > 0 and kart.stun_time <= 0
 if kart.ai:
  throttle = 1.0
  stopping = 0.0
  _choose_ai_lane(kart, index, delta)
  turn = clampf((kart.target_lane - kart.lateral) * 0.8, -1, 1)
  boost_now = false
  if (kart.power != "" or kart.cannon_time > 0) and rng.randf() < delta * 0.65:
   use_power(kart)
 var top: float = stats.speed
 if kart.ai:
  top *= [0.73, 0.88, 0.98][difficulty] + index * 0.009 + sin(elapsed * 0.35 + index) * 0.02
 if boost_now:
  kart.boost = maxf(0, kart.boost - delta * 30)
  kart.boost_time = maxf(kart.boost_time, 0.1)
 else:
  kart.boost = minf(100, kart.boost + delta * 9)
 if kart.boost_time > 0:
  top *= 1.45
 if kart.stun_time > 0:
  top *= 0.35
 var target = top * throttle * (1.0 - stopping)
 var acceleration: float = stats.accel if target > kart.speed else (35.0 if stopping > 0 else 8.0)
 kart.speed = move_toward(kart.speed, target, acceleration * delta)
 if track.get("ground_course") != null:
  # The start hill adds downhill speed; braking still controls the descent.
  kart.speed = clampf(kart.speed + track.frame(kart.progress).basis.z.y*9.81*(1-stopping)*delta,0,top+12)
 kart.steering = lerpf(kart.steering, turn, 1.0 - exp(-delta * 9.0))
 var lateral_speed = kart.steering * stats.handling * (1.0 + kart.speed * 0.16)
 # No sideways sliding at rest; smoothing makes a quick key release predictable.
 kart.lateral += lateral_speed * delta * clampf(kart.speed / 6.0, 0, 1)
 # Raised sides gently guide the kart back toward the center.
 kart.lateral -= signf(kart.lateral) * pow(absf(kart.lateral) / track.width, 5) * delta * 2
 var boundary: float = track.width - 0.65
 if absf(kart.lateral) > boundary:
  kart.lateral = clampf(kart.lateral, -boundary, boundary)
  kart.speed = maxf(0, kart.speed - delta * 17)
  if kart == player: _collision_feedback(kart,0.35)
 var before: float = kart.progress
 kart.progress += kart.speed * delta
 if track.get("v2_course") == null and _active_course() != null and kart.jump_height <= 0 and kart.jump_velocity <= 0:
  var launch: float = _active_course().launch_velocity(before,kart.progress)
  if launch > 0:
   kart.jump_velocity = launch
   kart.jump_height = 0.02
 var flight: Dictionary = track.get("v2_course").flight_state(kart.progress) if track.get("v2_course") != null else {}
 var landing_contact := false
 if track.get("v2_course") != null:
  for feature in track.get("v2_course").features:
   if not feature.has("landing"): continue
   var contact: float = floor(before/track.length)*track.length+feature.landing
   if before < contact and kart.progress >= contact:
    landing_contact = true
    kart.jump_height = 0
    kart.jump_velocity = 0
    _feedback_at(kart,"landing",0.8 if feature.id=="mega_jump" else 0.4)
 if not flight.is_empty():
  kart.jump_height = flight.height
  kart.jump_velocity = flight.slope*kart.speed
 elif not landing_contact and (kart.jump_height > 0 or kart.jump_velocity > 0):
  kart.jump_velocity -= 16 * delta
  kart.jump_height = maxf(0, kart.jump_height + kart.jump_velocity * delta)
  if kart.jump_height == 0:
   _landing_feedback(kart,clampf(absf(kart.jump_velocity)/8.0,0.2,1.0))
   kart.jump_velocity = 0
 _flush_landing_feedback(kart)
 if kart.progress >= LAPS * track.length:
  var fraction = clampf((LAPS * track.length - before) / maxf(kart.progress - before, 0.000001), 0, 1)
  kart.finish_time = elapsed - delta + delta * fraction
  kart.progress = LAPS * track.length

func _choose_ai_lane(kart, index: int, delta: float) -> void:
 var decision_in = float(kart.get_meta("decision_in", 0.0)) - delta
 kart.set_meta("decision_in", decision_in)
 if decision_in > 0:
  return
 kart.set_meta("decision_in", 0.45 + index * 0.08)
 var lane_limit = maxf(0.0, track.width - 1.3)
 var best_lane: float = kart.target_lane
 var best_score: float = -INF
 # Choose a readable line, avoiding close traffic and seeking useful pickups.
 for lane in [-3.6, -1.8, 0.0, 1.8, 3.6]:
  lane = clampf(lane, -lane_limit, lane_limit)
  var score = -absf(lane - kart.lateral) * 0.2
  score += sin(elapsed * 0.18 + index * 2 + lane) * 0.2
  for rival in racers:
   if rival == kart or rival.finish_time >= 0:
    continue
   var gap = wrapped_gap(kart.progress, rival.progress)
   if gap > -2 and gap < 12 and absf(rival.lateral - lane) < 1.4:
    score -= (12.0 - maxf(gap, 0)) * 0.35
  for pickup in pickups:
   if pickup.cooldown > 0 or (pickup.kind == "power" and kart.power != ""):
    continue
   var ahead = wrapped_gap(kart.progress, pickup.distance)
   if ahead > 3 and ahead < 28 and absf(pickup.lane - lane) < 1.4:
    score += (1.8 if pickup.kind == "power" else 0.7) * (1.0 - ahead / 35.0)
  if score > best_score:
   best_score = score
   best_lane = lane
 kart.target_lane = best_lane

func _collisions(delta: float) -> void:
 for i in racers.size():
  for j in range(i + 1, racers.size()):
   var a = racers[i]
   var b = racers[j]
   if a.finish_time >= 0 or b.finish_time >= 0:
    continue
   if absf(wrapped_gap(a.progress, b.progress)) < 1.8 and absf(a.lateral - b.lateral) < 0.9 and absf(a.jump_height - b.jump_height) < 0.8:
    var push = -1.0 if a.lateral < b.lateral else 1.0
    a.lateral += push * delta * 3
    b.lateral -= push * delta * 3
    a.speed = maxf(0, a.speed - delta * 4)
    b.speed = maxf(0, b.speed - delta * 4)
    if a == player or b == player:
     _collision_feedback(player,clampf(absf(a.speed-b.speed)/20.0,0.25,1.0))

func _update_pickups(delta: float, _old_progress: float) -> void:
 for pickup in pickups:
  pickup.cooldown = maxf(0, pickup.cooldown - delta)
  pickup.node.visible = pickup.cooldown <= 0
  pickup.node.rotation.y += delta * 1.7
  if pickup.cooldown > 0:
   continue
  for kart in racers:
   if kart.finish_time >= 0 or kart.progress < 0:
    continue
   var distance = absf(wrapped_gap(kart.progress, pickup.distance))
   var reach = 5.5 if kart.magnet_time > 0 and pickup.kind == "coin" else 1.3
   if distance < maxf(reach, kart.speed * delta) and absf(kart.lateral - pickup.lane) < reach and kart.jump_height < 2:
    if pickup.kind == "coin":
     if kart == player:
      collected += 1
      sound.emit("coin")
     kart.boost = minf(100, kart.boost + 4)
    elif kart.power == "":
     kart.power = Catalog.POWERS[rng.randi_range(0, Catalog.POWERS.size() - 1)]
     if kart == player:
      notice.emit(kart.power + "!  Druk op E om te gebruiken")
      sound.emit("power")
    else:
     continue
    if kart == player:
     RewardVisuals.burst(self, pickup.node.position, pickup.kind)
    pickup.cooldown = 7.0
    pickup.node.visible = false
    break

func wrapped_gap(a: float, b: float) -> float:
 return fposmod(b - a + track.length / 2, track.length) - track.length / 2

func jump() -> void:
 if countdown <= 0 and not paused and not done and player.jump_height == 0 and player.stun_time <= 0:
  player.jump_velocity = 6.3
  sound.emit("jump")

func use_power(kart = null) -> void:
 if kart == null:
  kart = player
 if countdown > 0 or paused or done or kart.finish_time >= 0:
  return
 if kart.cannon_time > 0:
  fire(kart, "bullet")
  return
 var power: String = kart.power
 if power == "":
  return
 kart.power = ""
 sound.emit("power")
 match power:
  "Boost": kart.boost_time = 3.2
  "Schild": kart.shield_time = 8
  "Magneet": kart.magnet_time = 9
  "Raket": fire(kart, "rocket")
  "Bom": fire(kart, "bomb")
  "Kanonnen":
   kart.cannon_time = 7
   fire(kart, "bullet")
 if kart == player:
  notice.emit(power + " actief" + (" — E om te schieten" if power == "Kanonnen" else ""))

func fire(owner_kart, kind: String) -> void:
 # Cooldown applies to repeat cannon fire; each activation remains time limited.
 if kind == "bullet" and owner_kart.has_meta("shot") and elapsed - float(owner_kart.get_meta("shot")) < 0.3:
  return
 if kind == "bullet":
  owner_kart.set_meta("shot", elapsed)
 owner_kart.react_to_shot()
 var mesh = Geo.ball(self, Vector3.ZERO, Vector3.ONE * (0.65 if kind == "bomb" else 0.35), Color("ff8e4b") if kind != "bomb" else Color("303b57"))
 projectiles.append({"owner":owner_kart, "kind":kind, "progress":owner_kart.progress + (-2 if kind == "bomb" else 2), "lane":owner_kart.lateral, "life":9.0 if kind == "bomb" else 3.0, "node":mesh})
 sound.emit("shot")

func _update_projectiles(delta: float) -> void:
 for i in range(projectiles.size() - 1, -1, -1):
  var p = projectiles[i]
  var previous: float = p.progress
  p.life -= delta
  if p.kind != "bomb":
   p.progress += delta * (68 if p.kind == "rocket" else 85)
  if p.kind == "rocket":
   var target = nearest_ahead(p.owner, 70)
   if target:
    p.lane = move_toward(p.lane, target.lateral, delta * 5)
  p.node.position = track.position_at(p.progress, p.lane, 0.7)
  for kart in racers:
   if kart == p.owner or kart.finish_time >= 0:
    continue
   var old_kart = float(kart.get_meta("previous_progress", kart.progress))
   var before = wrapped_gap(previous, old_kart)
   var after = wrapped_gap(p.progress, kart.progress)
   # Relative swept intersection also catches fast bullets crossing a kart.
   var crossed = before * after <= 0 and absf(before - after) < track.length * 0.5
   var radius = 2.2 if p.kind == "bomb" else 1.5
   if (crossed or absf(after) < radius) and absf(p.lane - kart.lateral) < (2.0 if p.kind == "bomb" else 1.2) and kart.jump_height < 1.6:
    _weapon_hit(kart, p.owner)
    p.life = 0
    break
  if p.life <= 0:
   p.node.queue_free()
   projectiles.remove_at(i)

func _weapon_hit(kart, attacker) -> void:
 var shielded: bool = kart.shield_time > 0
 var protected: bool = kart.hit_cooldown > 0
 var hit: bool = kart.take_hit()
 if hit and (kart == player or attacker == player):
  _feedback_at(kart,"hit",0.9)
 if kart == player:
  if hit:
   notice.emit("Geraakt! Je rijdt zo weer verder")
   sound.emit("hit")
  elif shielded and not protected:
   notice.emit("Je schild vangt de klap op!")
   sound.emit("power")
 elif attacker == player:
  if hit:
   notice.emit("Raak! " + kart.racer_name + " is even afgeremd")
   sound.emit("hit")
  elif shielded and not protected:
   notice.emit(kart.racer_name + " blokkeert met een schild")

func _collision_feedback(kart, intensity: float) -> void:
 if elapsed-feedback_collision_at < 0.3: return
 feedback_collision_at = elapsed
 _feedback_at(kart,"collision",intensity)

func _landing_feedback(kart, intensity: float) -> void:
 if kart.has_meta("feedback_landing"):
  var pending: Dictionary = kart.get_meta("feedback_landing")
  pending.intensity = maxf(float(pending.intensity),intensity)
  return
 if _active_course() != null:
  var lap_progress: float = fposmod(kart.progress,track.length)
  for feature in _active_course().features:
   if feature.has("lip") and lap_progress > feature.lip and lap_progress < feature.landing:
    # The arcade jump can settle onto its virtual guide while still above
    # the empty ramp gap. Only announce physical contact at the table landing.
    kart.set_meta("feedback_landing",{"distance":kart.progress-lap_progress+float(feature.landing),"intensity":intensity})
    return
 _feedback_at(kart,"landing",intensity)

func _flush_landing_feedback(kart) -> void:
 if not kart.has_meta("feedback_landing") or kart.jump_height > 0: return
 var pending: Dictionary = kart.get_meta("feedback_landing")
 if kart.progress < float(pending.distance): return
 kart.remove_meta("feedback_landing")
 _feedback_at(kart,"landing",float(pending.intensity),"wood")

func _feedback_at(kart, kind: String, intensity: float, surface_override: String = "") -> void:
 if paused or (done and kind != "finish"): return
 var surface: String = "asphalt"
 if track.get("world_index") == 5:
  surface = "wood"
  if track.kitchen_course != null:
   var feature: Dictionary = track.kitchen_course.feature_at(kart.progress)
   var feature_id: String = str(feature.get("id",""))
   if feature_id in ["toilet_rolls","comic_ramp","card_ramp"]: surface = "paper"
   elif feature_id in ["orange_loop","pvc_rainbow"]: surface = "plastic"
 if not surface_override.is_empty(): surface = surface_override
 feedback.emit(kind,track.position_at(kart.progress,kart.lateral,0.12),clampf(intensity,0,1),surface)

func nearest_ahead(kart, reach: float):
 var best = null
 var gap = reach
 for rival in racers:
  if rival == kart or rival.finish_time >= 0:
   continue
  var distance = wrapped_gap(kart.progress, rival.progress)
  if distance > 0 and distance < gap:
   best = rival
   gap = distance
 return best

func ranking() -> Array:
 var sorted = racers.duplicate()
 sorted.sort_custom(func(a, b):
  if a.finish_time >= 0 and b.finish_time >= 0:
   return a.finish_time < b.finish_time
  if a.finish_time >= 0: return true
  if b.finish_time >= 0: return false
  return a.progress > b.progress)
 return sorted

func claim_reward(profile, world: int) -> bool:
 if not done or payout_claimed:
  return false
 if not profile.record_race(world, elapsed, reward):
  notice.emit("Opslaan is niet gelukt. Je kunt het opnieuw proberen.")
  return false
 payout_claimed = true
 return true

func _active_course():
 return track.active_course() if track.has_method("active_course") else null
