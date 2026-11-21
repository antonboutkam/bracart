extends SceneTree
const Rewards = preload("res://scripts/effects/reward_visuals.gd")
const Weather = preload("res://scripts/effects/weather.gd")
class TestTrack extends Node3D:
 var world_index: int = 3
 var road_material = StandardMaterial3D.new()
 var paused = false
var checks = 0
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures.append(message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var track = TestTrack.new()
 root.add_child(track)
 var sun = DirectionalLight3D.new()
 track.add_child(sun)
 var camera = Camera3D.new()
 track.add_child(camera)
 var env = Environment.new()
 env.sky = Sky.new()
 env.sky.sky_material = ProceduralSkyMaterial.new()
 var original_sky = env.sky.sky_material
 var original_color = original_sky.sky_top_color
 var original_roughness = track.road_material.roughness
 var weather = Weather.new()
 track.add_child(weather)
 weather.setup(track, env, sun, camera, 42)
 check(weather.drops.multimesh.instance_count == 160, "rain has bounded GPU instances")
 check(weather.force_event("rain", true), "outdoor rain accepted")
 weather.advance(0.1, Vector3(20, 2, 0))
 check(weather.drops.visible and weather.drops.global_position == Vector3(20, 2, 0), "rain follows racer")
 check(track.road_material.roughness < original_roughness, "rain gives road wet highlights")
 var saved_time = weather.time_left
 var saved_elapsed = weather.elapsed
 weather.advance(10, Vector3.ZERO, true)
 check(weather.time_left == saved_time and weather.elapsed == saved_elapsed, "pause freezes weather timers and animation")
 weather.time_left = 0.01
 weather.advance(0.1, Vector3.ZERO)
 check(weather.current_event == "rainbow", "clearing rain leads to rainbow")
 weather.force_event("rainbow", true)
 weather.advance(0.1, Vector3.ZERO)
 check(weather.rainbow.visible and weather.rainbow.mesh.get_surface_count() == 1, "rainbow is visible real mesh")
 check(weather.force_event("night", true), "night accepted")
 weather.advance(0.1, Vector3.ZERO)
 check(sun.light_energy >= 0.2 and env.ambient_light_energy >= 0.5 and weather.fill.light_energy > 0.5, "night retains usable scene lighting")
 check(original_sky.sky_top_color == original_color, "source sky material unchanged")
 check(not weather.force_event("typo"), "unknown event rejected")
 track.world_index = 5
 var indoor = Weather.new()
 track.add_child(indoor)
 indoor.setup(track, Environment.new(), sun, camera, 4)
 check(not indoor.force_event("rain") and not indoor.force_event("night"), "kitchen rejects outdoor events")
 indoor.advance(100, Vector3.ZERO)
 check(indoor.current_event == "sun", "kitchen never randomly changes weather")
 var coin = Rewards.create_pickup(track, "coin", Vector3(0, 2, 0))
 var power = Rewards.create_pickup(track, "power", Vector3.ZERO)
 check(coin.position == Vector3(0, 2, 0) and coin.get_meta("reward_visual_version") == 1, "coin position and version")
 check(coin.get_child(0).material_override.metallic > 0.7, "coin has genuine metallic surface")
 check(coin.get_child_count() >= 6, "coin includes raised rims and double sided detail")
 check(power.get_child_count() == 14, "powerbox has core, twelve edges and clear label")
 var burst = Rewards.burst(track, Vector3.ZERO, "coin")
 check(burst.rays.size() == 6, "pickup burst is bounded")
 track.paused = true
 burst._process(0.2)
 check(burst.age == 0, "reward animation respects race pause")
 track.paused = false
 burst._process(1.0)
 check(burst.is_queued_for_deletion(), "reward burst cleans itself up")
 indoor.free()
 weather.free()
 check(track.road_material.roughness == original_roughness, "weather exit restores road")
 track.free()
 print("REWARD_WEATHER: %d checks; %d failures" % [checks, failures.size()])
 for failure in failures: push_error(failure)
 quit(0 if failures.is_empty() else 1)
