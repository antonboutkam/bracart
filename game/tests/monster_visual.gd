extends SceneTree
## Native screenshots: UI-only splash, imported preview, then real cockpit/arena rendering.
const Main = preload("res://scripts/main.gd")
var game
var canvas: SubViewport
const FOLDER = "/tmp/boracart-monster-prototype"

func _initialize() -> void:
 call_deferred("run")

func shot(title: String) -> void:
 for i in 3:
  await process_frame
 await RenderingServer.frame_post_draw
 canvas.get_texture().get_image().save_png(FOLDER.path_join(title + ".png"))
 print("CAPTURED " + title)

func run() -> void:
 DirAccess.make_dir_recursive_absolute(FOLDER)
 canvas = SubViewport.new()
 canvas.size = Vector2i(1280, 800)
 canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 canvas.own_world_3d = true
 canvas.disable_3d = true
 root.add_child(canvas)
 game = Main.new()
 canvas.add_child(game)
 game.audio.music.stop()
 game.audio.muted = true
 game.set_process(false)
 game.set_physics_process(false)
 await shot("01-splash")
 game.ui.show_garage()
 await shot("01b-garage")
 game.choose_monster(1)
 await shot("02-monster-choice")
 game.start_monster("gifspuwer-breekbaar", 1)
 canvas.disable_3d = false
 canvas.scaling_3d_scale = 0.5
 var mode = game.monster_mode
 mode.set_physics_process(false)
 mode.set_process(false)
 mode._camera(0, true)
 await shot("03-cockpit-start")
 mode.toggle_pause()
 await shot("03b-pause-monsters")
 mode.toggle_pause()
 mode.action()
 while mode.road_z > 120:
  mode.step(1.0 / 60)
 mode._camera(0, true)
 await shot("04-downhill")
 while mode.phase == "ramp":
  mode.step(1.0 / 60)
 for i in 100:
  mode.step(1.0 / 60)
 mode._camera(0, true)
 await shot("05-free-flight")
 while mode.rocket.position.z > -158:
  mode.step(1.0 / 60)
 mode._camera(0, true)
 await shot("06-target")
 for i in 900:
  mode.step(1.0 / 60)
 mode._camera(0, true)
 await shot("07-score")
 mode.sounds.clips.miss.save_to_wav(FOLDER.path_join("wie-wo-weeuh.wav"))
 game.queue_free()
 await process_frame
 canvas.queue_free()
 await process_frame
 quit()
