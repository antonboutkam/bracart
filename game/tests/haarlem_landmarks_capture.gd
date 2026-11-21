extends SceneTree
## Native views of the actual world-3 model instances, including ordinary race camera.
const Main = preload("res://scripts/main.gd")
const Models = preload("res://scripts/worlds/haarlem_landmarks.gd")
var output: String
var failures := 0
var subjects: Array[Dictionary] = []
func _initialize() -> void: call_deferred("run")
func shot(game, filename: String, label: String, target: Vector3) -> void:
 subjects.append({"filename":filename+".png","label":label,"category":"landmarks","world":3})
 if not game.camera.is_position_in_frustum(target): failures += 1
 for frame in 12: await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 if picture.is_empty() or picture.save_png(output.path_join(filename+".png")) != OK: failures += 1
 print("LANDMARK CAPTURE ",filename)
func run() -> void:
 output = OS.get_environment("BORACER_CAPTURE_DIR")
 if output.is_empty() or DisplayServer.get_name()=="headless":
  push_error("Native rendering and BORACER_CAPTURE_DIR required")
  quit(2)
  return
 root.size=Vector2i(1280,800)
 var game = Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.muted=true
 game.audio.music.stop()
 game.audio.music.stream=null
 game.start_race(3)
 game.race.set_process(false)
 game.race.countdown=-2
 for entry in Models.ENTRIES:
  var model = game.track.get_node("Landmark_"+str(entry.id).replace("-","_"))
  var target: Vector3 = model.global_position+Vector3.UP*8
  game.ui.visible=false
  game.camera.fov=54
  game.camera.position=model.global_transform*Vector3(30,25,-43)
  game.camera.look_at(target)
  await shot(game,entry.id+"-voorkant",entry.label+" • voorgevel in echte Haarlemwereld",target)
  game.camera.position=model.global_transform*Vector3(-29,23,36)
  game.camera.look_at(target)
  await shot(game,entry.id+"-achterkant",entry.label+" • gesloten achterzijde en dak",target)
  # Select a real approach point through the ordinary follow-camera API.
  var section_distance: float = game.track.length*Models.section_fraction(entry,6)
  var best_progress: float = section_distance-80
  var best_score: float = INF
  for lead in range(100,20,-1):
   game.race.player.progress=section_distance-lead
   game.race.player.update_visual(game.track,0)
   game._camera(0,true)
   var screen: Vector2 = game.camera.unproject_position(target)
   var to_camera: Vector3 = (game.camera.global_position-target).normalized()
   var front: Vector3 = -model.global_basis.z
   if game.camera.is_position_in_frustum(target) and front.dot(to_camera)>0.2:
    var score: float = screen.distance_to(Vector2(500,280))+game.camera.position.distance_to(target)*0.6
    if score<best_score:
     best_score=score
     best_progress=game.race.player.progress
  game.race.player.progress=best_progress
  game.race.player.update_visual(game.track,0)
  game._camera(0,true)
  print("RACE VIEW ",entry.id," progress=",best_progress," score=",best_score," screen=",game.camera.unproject_position(target))
  game.ui.update_hud(0)
  game.ui.visible=true
  await shot(game,entry.id+"-racecamera",entry.label+" • gewone racecamera vlak voor de sectie",target)
 var file = FileAccess.open(output.path_join("subjects.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(subjects,"  "))
 print("LANDMARK CAPTURES=",subjects.size()," failures=",failures)
 game.queue_free()
 await process_frame
 quit(0 if failures==0 and subjects.size()==6 else 1)
