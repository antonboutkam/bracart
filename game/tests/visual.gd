extends SceneTree
const Main = preload("res://scripts/main.gd")
const Profile = preload("res://scripts/profile.gd")
var game
var canvas: SubViewport
var folder = "/tmp/boracer-visual"

func _initialize() -> void:
 call_deferred("run")

func shot(title: String) -> void:
 for i in 4:
  await process_frame
 await RenderingServer.frame_post_draw
 var image = canvas.get_texture().get_image()
 image.save_png(folder.path_join(title + ".png"))
 print("CAPTURED " + title)

func run() -> void:
 DirAccess.make_dir_recursive_absolute(folder)
 canvas = SubViewport.new()
 canvas.size = Vector2i(1280, 800)
 canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 canvas.own_world_3d = true
 root.add_child(canvas)
 game = Main.new()
 canvas.add_child(game)
 await process_frame
 game.audio.music.stop()
 game.audio.muted = true
 game.set_physics_process(false)
 game.profile = Profile.new("user://visual-only-profile.json")
 game.profile.coins = 240
 game.profile.records.clear()
 game.profile.selected = 4
 await shot("01-home")
 game.ui.show_worlds()
 await shot("02-worlds")
 game.ui.show_garage()
 await shot("03-garage")
 game.ui.show_settings()
 await shot("04-settings")
 for i in 6:
  game.profile.selected = i
  game.profile.character = "ravi" if i % 2 else "boaz"
  game.start_race(i)
  game.race.countdown = -2
  var distance: float = game.track.length * (0.12 if i == 2 else 0.4)
  for j in game.race.racers.size():
   var kart = game.race.racers[j]
   kart.progress = distance + (9 + j * 4 if j > 0 else 0)
   kart.speed = 32
   kart.update_visual(game.track, 0)
  game.race.elapsed = 17.4
  game.race.collected = 8
  game.race.rank = 5
  game.race.player.power = "Schild"
  game.race.player.update_visual(game.track, 0)
  game._camera(0, true)
  game.ui.update_hud(0)
  await shot("world-%d" % i)
  if i == 0:
   game.ui.show_pause()
   await shot("05-pause")
   game.ui.resume()
   game.race.elapsed = 53.67
   game.race.lap_times.assign([18.01, 17.83, 17.83])
   game.race.collected = 24
   game.race.reward = 84
   game.race.done = true
   game.race.claim_reward(game.profile, 0)
   game.ui.show_results()
   await shot("06-results")
 game.go_home()
 game.preview_vehicle(4)
 game.ui.show_vehicle(4)
 await shot("07-vehicle")
 game.ui.show_garage()
 canvas.size = Vector2i(1280, 720)
 await shot("08-garage-wide")
 canvas.size = Vector2i(800, 600)
 await shot("09-garage-compact")
 canvas.size = Vector2i(600, 900)
 await shot("10-garage-portrait")
 canvas.size = Vector2i(1280, 800)
 game.profile.settings.touch_controls = true
 game.start_race(5)
 game.race.countdown = 1
 await shot("11-touch")
 game.queue_free()
 for i in 4:
  await process_frame
 canvas.queue_free()
 for i in 4:
  await process_frame
 for suffix in ["", ".bak", ".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path("user://visual-only-profile.json" + suffix))
 quit()
