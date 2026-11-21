extends SceneTree
const Main = preload("res://scripts/main.gd")
const ID = "gifspuwer-breekbaar"
const FOLDER = "/tmp/boracart-gifspuwer-visual"
var game
var canvas: SubViewport

func _initialize() -> void:
 call_deferred("run")

func shot(label: String) -> void:
 for i in 4:
  resume_capture()
  await process_frame
 resume_capture()
 await RenderingServer.frame_post_draw
 canvas.get_texture().get_image().save_png(FOLDER.path_join(label + ".png"))
 print("CAPTURED " + label)

func resume_capture() -> void:
 # Desktop focus can change while this automated capture runs. Only the test
 # resumes automatically; the real game's focus-loss pause remains intact.
 if is_instance_valid(game.monster_mode) and game.monster_mode.paused:
  game.monster_mode.toggle_pause()

func overview() -> void:
 game.camera.position = Vector3(70, 85, -65)
 game.camera.look_at(Vector3(0, 63, -160))

func run() -> void:
 DirAccess.make_dir_recursive_absolute(FOLDER)
 canvas = SubViewport.new()
 canvas.size = Vector2i(1280, 800)
 canvas.own_world_3d = true
 canvas.disable_3d = true
 canvas.scaling_3d_scale = 0.5
 canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(canvas)
 game = Main.new()
 canvas.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.music.stop()
 game.audio.muted = true
 game.choose_monster(1)
 game.ui._select_monster(ID)
 await shot("01-selection")
 game.start_monster(ID, 1)
 canvas.disable_3d = false
 var mode = game.monster_mode
 mode.set_process(false)
 mode.set_physics_process(false)
 mode.vehicle_picker.hide()
 overview()
 await shot("02-intact")
 resume_capture()
 mode.action()
 for i in 2400:
  mode.step(1.0 / 60)
  if mode.rocket.position.z < -125 or mode.phase in ["between", "finished"]: break
 mode._camera(0, true)
 await shot("03-approach")
 resume_capture()
 for i in 2400:
  mode.step(1.0 / 60)
  if mode.phase in ["between", "finished"]: break
 assert(mode.scores[0] > 0)
 overview()
 await shot("04-damaged")
 resume_capture()
 mode.arena.impact(Vector3(-60,30,-160), Vector3(60,30,-160), 3, 0)
 mode.phase = "settling"
 for i in 60: mode.step(1.0 / 60)
 overview()
 await shot("05-collapse")
 resume_capture()
 for i in 1200:
  mode.step(1.0 / 60)
  if mode.phase == "finished": break
 assert(mode.phase == "finished" and mode.scores[0] == 10000)
 await shot("06-finished")
 game.queue_free()
 await process_frame
 canvas.queue_free()
 await process_frame
 quit()
