extends SceneTree
const Main = preload("res://scripts/main.gd")
const Profile = preload("res://scripts/profile.gd")
const Catalog = preload("res://scripts/catalog.gd")
var checks: int = 0
var failures: Array[String] = []

func check(condition: bool, title: String) -> void:
 checks += 1
 if not condition:
  failures.append(title)
  push_error("FAIL: " + title)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var profile_path = "user://smoke-profile.json"
 for path in [profile_path, profile_path + ".bak"]:
  if FileAccess.file_exists(path):
   DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 var profile = Profile.new(profile_path)
 check(profile.selected == Catalog.DEFAULT_VEHICLE and "retro" in profile.owned and "raketfiets" in profile.owned, "new profile starts with Raketfiets and keeps free garage")
 check(not profile.buy_or_select(2), "insufficient coins cannot buy")
 profile.coins = 200
 check(profile.buy_or_select(2), "purchase succeeds")
 check(profile.coins == 60, "purchase charges exactly once")
 check(profile.buy_or_select(2) and profile.coins == 60, "owned kart is free to reselect")
 var loaded = Profile.new(profile_path)
 check(loaded.selected == 2 and loaded.coins == 60, "purchase survives reload")
 check(not loaded.buy_or_select(99), "invalid catalog slot rejected")
 var live_profile = Profile.new("user://smoke-availability.json")
 for id in ["retro", "golden-rocket-racer", "raketfiets", "purple-passion", "toxic-turbo", "rainbow"]:
  check(Catalog.vehicle_index(id) in live_profile.available, "original vehicle is available: " + id)
 var main = Main.new()
 root.add_child(main)
 await process_frame
 main.set_process(false)
 main.set_physics_process(false)
 main.audio.muted = true
 main.audio.music.stop()
 profile.selected = 4
 main.profile = profile
 for page in [main.ui.show_worlds, main.ui.show_garage, main.ui.show_settings, main.ui.show_home]:
  page.call()
  await process_frame
 check(main.track.length > 350, "full size smooth circuit")
 for world in 6:
  main.start_race(world)
  var race = main.race
  var track = main.track
  check(track.position_at(0).distance_to(track.position_at(track.length)) < 0.001, "world %d closes without gap" % world)
  check(track.frame(0).basis.z.dot(track.frame(track.length - 0.01).basis.z) > 0.99, "world %d continuous finish tangent" % world)
  check(track.bowl(track.width) == 0 if world in [4, 5] else track.bowl(track.width) > 1, "world %d correct road profile" % world)
  check(track.bowl(track.width * 4) <= 1.9, "scenic offsets outside road do not extrapolate bowl height")
  if world == 5:
   check(track.kitchen_features().size() == 6 and track.frame(track.kitchen_features()[2].center).basis.y.y < -0.8, "kitchen includes a genuinely inverted course and supported household features")
  check(race.rank == 5 and race.racers.all(func(k): return k == race.player or k.progress > race.player.progress), "starting grid leaves the player camera clear and ranking correct")
  var start: float = race.player.progress
  race.step(1.0 / 60, 1, 0, 0, false)
  check(race.player.progress == start, "countdown prevents early starts")
  race.countdown = -1
  for i in 120:
   race.step(1.0 / 60, 1, 0, 0.2, false)
  check(race.player.speed > 20 and race.player.progress > start, "world %d player accelerates" % world)
  check(race.racers[1].progress > start, "AI races independently")
  race.paused = true
  var before: float = race.elapsed
  race.step(1, 1, 0, 0, false)
  check(race.elapsed == before, "pause freezes simulation")
  race.paused = false
  for power in ["Boost", "Schild", "Magneet", "Raket", "Bom", "Kanonnen"]:
   race.player.cannon_time = 0
   race.player.power = power
   race.use_power()
   check(race.player.power == "", power + " consumes slot")
  check(race.player.shield_time > 0 and race.player.magnet_time > 0, "timed effects activate")
  race.player.hit_cooldown = 0
  check(not race.player.take_hit() and race.player.shield_time == 0, "shield absorbs a hit")
  race.player.hit_cooldown = 0
  check(race.player.take_hit() and race.player.stun_time > 0, "unshielded hits slow kart")
  race.jump()
  check(race.player.jump_velocity == 0, "stunned kart cannot jump")
  race.player.stun_time = 0
  race.jump()
  check(race.player.jump_velocity > 0, "recovered kart can jump")
  for pickup in race.pickups:
   if pickup.kind == "coin":
    pickup.cooldown = 0.0
    race.player.progress = pickup.distance
    race.player.lateral = pickup.lane
    race.player.jump_height = 0
    race.player.magnet_time = 0
    var old_coins: int = race.collected
    race._update_pickups(0.01, race.player.progress)
    check(race.collected > old_coins, "coin pickup rewards player")
    break
  var safety = 0
  race.auto_drive = true
  while not race.done and safety < 18000:
   race.step(1.0 / 60, 1, 0, 0, false)
   safety += 1
  check(race.done and race.lap_times.size() == 3, "world %d completes three real laps" % world)
  check(race.rank >= 1 and race.rank <= 5, "valid final ranking")
  var balance: int = profile.coins
  check(not race.claim_reward(profile, world) and profile.coins == balance, "cannot claim finish reward twice")
  check(profile.records.has(main.Catalog.world_id(world)), "world record saved")
  main.ui.update_hud(0.1)
  await process_frame
 loaded = Profile.new(profile_path)
 check(loaded.records.size() == 6 and loaded.coins > 60, "six race records and rewards survive reload")
 main.go_home()
 check(main.race == null and is_instance_valid(main.preview), "return home frees race and restores preview")
 main.queue_free()
 await process_frame
 DirAccess.remove_absolute(ProjectSettings.globalize_path(profile_path))
 print("BORACER TESTS: %d checks, %d failures" % [checks, failures.size()])
 for failure in failures:
  print("  FAIL: " + failure)
 quit(0 if failures.is_empty() else 1)
