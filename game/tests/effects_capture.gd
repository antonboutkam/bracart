extends SceneTree
## Real in-game Compatibility frames; run only with the studio's native-render slot.
const Main = preload("res://scripts/main.gd")
const Weather = preload("res://scripts/effects/weather.gd")
const Rewards = preload("res://scripts/effects/reward_visuals.gd")
var output: String
var failures = 0
func _initialize() -> void:
 call_deferred("run")
func shot(filename: String) -> void:
 for i in 10: await process_frame
 await RenderingServer.frame_post_draw
 var image = root.get_texture().get_image()
 var error = image.save_png(output.path_join(filename + ".png"))
 if error != OK or image.is_empty(): failures += 1
 print("EFFECT CAPTURE ", filename, " ", image.get_size(), " error=", error)
func run() -> void:
 output = OS.get_environment("BORACER_CAPTURE_DIR")
 if output.is_empty() or DisplayServer.get_name() == "headless":
  push_error("Native rendering and BORACER_CAPTURE_DIR are required")
  quit(2)
  return
 DirAccess.make_dir_recursive_absolute(output)
 root.size = Vector2i(1280, 720)
 var game = Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 for world_index in [3, 4]:
  game.start_race(world_index)
  game.race.countdown = 0
  game.race.player.progress = game.track.length * 0.12
  game.race.player.speed = 0
  game.race.player.update_visual(game.track, 0)
  game._camera(0, true)
  game.ui.update_hud(0)
  var weather = game.track.get_node_or_null("Weather")
  if weather == null:
   weather = Weather.new()
   game.track.add_child(weather)
   weather.setup(game.track, game.environment.environment, game.sun, game.camera, 42)
  for event in ["sun", "rain", "rainbow", "night"]:
   weather.force_event(event, true)
   weather.advance(0.01, game.race.player.global_position)
   await shot(("haarlem-1888" if world_index == 3 else "uithoorn-2056") + "-" + event)
  weather.force_event("sun", true)
  weather.advance(0.01, game.race.player.global_position)
  # Close-up within the live track, retaining its actual lighting and background.
  var at = game.track.position_at(game.race.player.progress + 9, 0, 1.8)
  var coin = Rewards.create_pickup(game.track, "coin", at + Vector3(-1, 0, 0))
  var power = Rewards.create_pickup(game.track, "power", at + Vector3(1, 0, 0))
  coin.rotation.y = 0.35
  power.rotation.y = -0.3
  game.camera.global_position = at + Vector3(0, 1.5, 5)
  game.camera.look_at(at)
  await shot(("haarlem" if world_index == 3 else "uithoorn") + "-reward-details")
 game.queue_free()
 await process_frame
 print("EFFECT CAPTURE COMPLETE failures=", failures)
 quit(0 if failures == 0 else 1)
