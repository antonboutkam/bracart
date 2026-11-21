extends SceneTree
## Render the exact centre-lane poses saved by the headless visibility test.
const Main = preload("res://scripts/main.gd")
const FOLDER = "/tmp/boracart-uithoorn-ground"
var viewport: SubViewport
var game
func _initialize() -> void: call_deferred("run")
func shot(filename: String) -> void:
 for i in 3: await process_frame
 RenderingServer.force_draw(false)
 var picture = viewport.get_texture().get_image()
 if picture.is_empty() or picture.save_png(FOLDER.path_join(filename))!=OK:
  push_error("Cannot save "+filename)
  quit(1)
 print("GROUND IMAGE ",filename)
func run() -> void:
 var path = FOLDER.path_join("subjects.json")
 if DisplayServer.get_name()=="headless" or not FileAccess.file_exists(path):
  push_error("Run uithoorn_ground_visual --validate-only first, then use native rendering")
  quit(2)
  return
 var poses = JSON.parse_string(FileAccess.get_file_as_string(path))
 viewport = SubViewport.new()
 viewport.size = Vector2i(1280,800)
 viewport.own_world_3d = true
 viewport.disable_3d = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 print("GROUND IMAGES: build game")
 game = Main.new()
 viewport.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.muted = true
 game.audio.music.stop()
 game.start_race(4)
 game.mode = "capture"
 game.ui.resume()
 game.race.set_process(false)
 game.race.countdown = -2
 game.race.elapsed = 12
 game.race.player.speed = 32
 viewport.scaling_3d_scale = 0.5
 viewport.disable_3d = false
 print("GROUND IMAGES: render poses")
 for pose in poses:
  game.ui.visible = pose.category!="overview"
  if pose.category=="overview":
   game.camera.position = Vector3(-235,590,380)
   game.camera.look_at(Vector3(-220,-20,-60))
  else:
   game.race.player.progress = pose.get("progress",10.0)
   game.race.player.update_visual(game.track,0)
   game._camera(0,true)
   game.ui.update_hud(0)
  await shot(pose.filename)
 game.free()
 viewport.free()
 print("UITHOORN GROUND CAPTURES: ",poses.size())
 quit()
