extends SceneTree
## Independent QA: actual Main lifecycle plus reward economy, without user saves.
const Main = preload("res://scripts/main.gd")
const Profile = preload("res://scripts/profile.gd")
const Catalog = preload("res://scripts/catalog.gd")
var checks = 0
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures.append(label)
  push_error(label)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var main = Main.new()
 root.add_child(main)
 await process_frame
 main.set_process(false)
 main.set_physics_process(false)
 main.audio.muted = true
 main.audio.music.stop()
 main.profile = Profile.new("user://game10001-integration.json")
 main.start_race(3)
 var first_weather = main.weather
 var first_track = main.track
 var first_road = main.track.road_material
 var dry_roughness: float = first_road.roughness
 check(main.race.player.vehicle_index == Catalog.DEFAULT_VEHICLE, "Actual Main race starts player on Raketfiets")
 check(first_weather.force_event("rain", true), "Haarlem accepts rain")
 main._process(0.2)
 check(first_road.roughness < dry_roughness, "Main rain changes actual road material")
 main.race.paused = true
 var elapsed: float = first_weather.elapsed
 var time_left: float = first_weather.time_left
 var before_progress: float = main.race.player.progress
 main._process(5)
 main._physics_process(5)
 check(first_weather.elapsed == elapsed and first_weather.time_left == time_left, "Main pause freezes weather")
 check(main.race.player.progress == before_progress, "Main pause freezes kart")
 main.race.paused = false
 first_weather.force_event("night", true)
 main._process(0.1)
 main.start_race(4)
 check(not first_track.is_inside_tree() and not first_weather.is_inside_tree(), "World switch detaches old weather and track immediately")
 check(is_equal_approx(first_road.roughness, dry_roughness), "World switch restores old road baseline")
 await process_frame
 check(not is_instance_valid(first_weather), "Old weather is freed after world switch")
 check(main.weather.current_event == "sun" and main.weather.rain_amount == 0 and main.weather.night_amount == 0, "Uithoorn starts fresh without Haarlem rain/night")
 var race = main.race
 race.countdown = 0
 for rival in race.racers.slice(1): rival.finish_time = 1
 # Keep one real pickup only, avoiding coincidences with nearby original rows.
 var coin: Dictionary = race.pickups[0]
 for pickup in race.pickups: pickup.cooldown = 100
 coin.cooldown = 0
 race.player.progress = coin.distance
 race.player.lateral = coin.lane
 race.player.speed = 0
 race.player.boost = 20
 race._update_pickups(0.01, race.player.progress)
 check(race.collected == 1 and race.player.boost == 24, "Shiny coin still grants exactly one coin and four boost")
 check(coin.cooldown > 0 and not coin.node.visible, "Collected coin becomes unavailable")
 race._update_pickups(0.01, race.player.progress)
 check(race.collected == 1 and race.player.boost == 24, "Coin effect cannot duplicate reward during cooldown")
 var power: Dictionary
 for pickup in race.pickups:
  if pickup.kind == "power":
   power = pickup
   break
 power.cooldown = 0
 race.player.progress = power.distance
 race.player.lateral = power.lane
 race.player.power = ""
 race._update_pickups(0.01, race.player.progress)
 check(race.player.power in Catalog.POWERS and race.collected == 1, "Power visual grants one valid power without awarding coins")
 var existing_power: String = race.player.power
 power.cooldown = 0
 race._update_pickups(0.01, race.player.progress)
 check(race.player.power == existing_power and power.cooldown == 0, "Full power slot leaves another power pickup available")
 var old_race = race
 main.start_race(5)
 await process_frame
 check(not is_instance_valid(old_race), "World switch frees pickups and reward-burst children with race")
 check(not main.weather.force_event("rain") and not main.weather.force_event("night"), "Actual kitchen race rejects outdoor weather")
 main.go_home()
 await process_frame
 check(main.mode == "menu" and main.race == null and main.ui.active_page == "home", "Returning home clears race and opens menu")
 main.queue_free()
 await process_frame
 print("BORACER GAME10001 INTEGRATION: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
