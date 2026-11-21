extends SceneTree
const Main = preload("res://scripts/main.gd")
const Profile = preload("res://scripts/profile.gd")
const Catalog = preload("res://scripts/catalog.gd")
var checks: int = 0
var failures: Array[String] = []
var save_path = "user://integration-audit.json"

func check(ok: bool, title: String) -> void:
 checks += 1
 if not ok:
  failures.append(title)
  push_error(title)

func _initialize() -> void:
 call_deferred("run")

func settle() -> void:
 for frame in 3:
  await process_frame

func run() -> void:
 for suffix in ["", ".bak", ".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
 var legacy = FileAccess.open(save_path, FileAccess.WRITE)
 var all_models: Array = []
 for vehicle in Catalog.VEHICLES:
  all_models.append(vehicle.id)
 legacy.store_string(JSON.stringify({"coins":500, "owned":all_models, "selected":2,
  "character":"ravi", "records":{"0":999.0}, "settings":{"difficulty":0}}))
 legacy.close()
 var game = Main.new()
 root.add_child(game)
 game.set_physics_process(false)
 game.audio.muted = true
 game.audio.music.stop()
 game.profile = Profile.new(save_path)
 check(game.profile.record_for(0) == 999.0, "migrated legacy record visible before race")
 var expected_coins: int = game.profile.coins
 for world in Catalog.WORLDS.size():
  game.profile.selected = world
  game.start_race(world)
  await settle()
  check(game.race.racers.size() == 5, "world %d loads five real model/driver combinations" % world)
  game.race.auto_drive = true
  var ticks = 0
  while not game.race.done and ticks < 1400:
   game.race.step(0.25, 1, 0, 0, true)
   ticks += 1
   if ticks % 60 == 0:
    await process_frame
  check(game.race.done and game.race.lap_times.size() == 3, "world %d full three-lap race completes" % world)
  check(game.race.payout_claimed, "world %d result persisted through main finish signal" % world)
  expected_coins += game.race.reward
  check(game.profile.coins == expected_coins, "world %d payout exactly once" % world)
  check(absf(game.profile.record_for(world) - game.race.elapsed) < 0.0001, "world %d personal best matches displayed finish" % world)
  var lap_total: float = 0
  for duration in game.race.lap_times:
   lap_total += duration
  check(absf(lap_total - game.race.elapsed) < 0.0001, "world %d lap times sum to finish" % world)
  for kart in game.race.racers:
   check(kart.transform.is_finite() and absf(kart.lateral) <= game.track.width, "world %d racer stays finite and on track" % world)
  print("INTEGRATION world=%d finish=%.2fs rank=%d coins=%d sim_ticks=%d" % [world, game.race.elapsed, game.race.rank, game.profile.coins, ticks])
  game.race.claim_reward(game.profile, world)
  check(game.profile.coins == expected_coins, "world %d repeated claim does not duplicate migrated wallet reward" % world)
  game.go_home()
  await settle()
  check(game.race == null and is_instance_valid(game.preview), "world %d result returns to valid garage preview" % world)
 var loaded = Profile.new(save_path)
 check(loaded.coins == expected_coins and loaded.records.size() == 6 and loaded.character == "ravi", "all six results survive complete app profile reload")
 check(loaded.selected == 5, "vehicle selection survives migrated save reload")
 # Weapon and physical proximity use the same closed route across start/finish.
 game.start_race(5)
 game.race.countdown = 0
 var race = game.race
 var owner_kart = race.player
 var target = race.racers[1]
 owner_kart.progress = game.track.length - 4
 owner_kart.lateral = 0
 target.progress = game.track.length + 1
 target.set_meta("previous_progress", target.progress)
 target.lateral = 0
 for i in range(2, race.racers.size()):
  race.racers[i].lateral = 5
  race.racers[i].progress = game.track.length * 0.5
 race.fire(owner_kart, "bullet")
 race._update_projectiles(0.1)
 check(target.stun_time > 0, "real closed track projectile crosses start/finish seam")
 check(owner_kart.stun_time == 0, "seam projectile never hits owner")
 check(race.projectiles.is_empty(), "impact consumes seam-crossing projectile")
 owner_kart.progress = game.track.length - 0.5
 target.progress = game.track.length + 0.5
 target.lateral = 0.1
 var gap_before: float = absf(owner_kart.lateral - target.lateral)
 race._collisions(0.1)
 check(absf(owner_kart.lateral - target.lateral) > gap_before, "lap seam traffic collides in shared physical space")
 # Exercise Main's real finish handler with a denied filesystem destination.
 game.profile.storage_path = "user://missing-integration-directory/profile.json"
 var coins_before_failed_finish: int = game.profile.coins
 race.player.progress = game.track.length * 3 - 0.1
 race.player.speed = 40
 race.last_lap = 2
 race.lap_start = 25
 race.elapsed = 30
 race.lap_times.assign([12.0, 13.0])
 race.step(0.1, 1, 0, 0, false)
 check(race.done and not race.payout_claimed and game.profile.coins == coins_before_failed_finish, "real Main finish on disk failure keeps reward retryable and wallet unchanged")
 check(not game.last_save_error.is_empty(), "real failed finish exposes storage error")
 game.profile.storage_path = save_path
 check(race.claim_reward(game.profile, 5), "real pending race reward saves after writable destination restored")
 var after_retry = Profile.new(save_path)
 check(after_retry.coins == coins_before_failed_finish + race.reward, "real successful retry persists reward once")
 check(not race.claim_reward(game.profile, 5), "real retry remains idempotent after disk recovery")
 game.go_home()
 await settle()
 # Repeat actual race/home transitions, measuring nodes after deferred frees.
 var baseline_nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
 var maximum_nodes = baseline_nodes
 for cycle in 8:
  game.start_race(5)
  game.race.countdown = 0
  game.race.step(0.5, 1, 0, 0, false)
  game.go_home()
  await settle()
  var current_nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
  maximum_nodes = maxi(maximum_nodes, current_nodes)
  check(current_nodes <= baseline_nodes + 2, "restart %d releases old race, track, drivers and HUD nodes" % cycle)
 print("INTEGRATION node baseline=%d maximum_after_restart=%d" % [baseline_nodes, maximum_nodes])
 game.queue_free()
 await settle()
 for suffix in ["", ".bak", ".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
 print("INTEGRATION AUDIT: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
