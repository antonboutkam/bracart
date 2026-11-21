extends "res://tests/uithoorn_landmarks_visual.gd"
## Same visibility rays and normal race camera as the imported-landmark review.
func run() -> void:
 validate_only = "--validate-only" in OS.get_cmdline_user_args()
 output = "/tmp/boracart-uithoorn-ground"
 DirAccess.make_dir_recursive_absolute(output)
 var viewport = SubViewport.new()
 viewport.size = Vector2i(1280,800)
 viewport.own_world_3d = true
 viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
 root.add_child(viewport)
 print("GROUND CAPTURE: creating game")
 var game = Main.new()
 viewport.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.muted = true
 game.audio.music.stop()
 print("GROUND CAPTURE: building street circuit")
 game.start_race(4)
 game.mode = "capture"
 game.ui.resume()
 game.race.paused = false
 game.race.set_process(false)
 game.race.countdown = -2
 game.race.elapsed = 12
 game.race.player.speed = 32
 print("GROUND CAPTURE: checking visibility")
 await add_visibility_geometry(game.track)
 print("GROUND CAPTURE: visibility ready")
 filter_readable_body_points()
 viewport.scaling_3d_scale = 0.75
 if not validate_only: viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 game.race.player.progress = 10
 game.race.player.update_visual(game.track,0)
 game._camera(0,true)
 game.ui.update_hud(0)
 await shot(viewport,game.camera,"startheuvel","Afdaling vanaf de start","race",game.track.position_at(55))
 for visit in game.track.ground_course.visits:
  var model = game.track.get_node("Landmark_"+str(visit.id).replace("-","_"))
  var best = INF
  var best_progress = visit.distance-240
  var best_visibility = {}
  var visible_samples = 0
  var visible_run = 0
  var longest_run = 0
  # Remain in the centre lane and scan only this actual approach.
  for lead in range(-330,46,3):
   game.race.player.progress = visit.distance+lead
   game.race.player.update_visual(game.track,0)
   game._camera(0,true)
   var visibility = visible_score(model,game.camera)
   if is_finite(visibility.score):
    visible_samples += 1
    visible_run += 1
    longest_run = maxi(longest_run,visible_run)
   else: visible_run = 0
   if visibility.score<best:
    best = visibility.score
    best_progress = game.race.player.progress
    best_visibility = visibility
  if not is_finite(best) or longest_run<5:
   failures += 1
   push_error("Landmark body not readable along approach: "+visit.id)
  game.race.player.progress = best_progress
  game.race.player.update_visual(game.track,0)
  game._camera(0,true)
  game.ui.update_hud(0)
  print("GROUND VIEW ",visit.id," progress=",best_progress," readable_samples=",visible_samples," visibility=",best_visibility)
  await shot(viewport,game.camera,visit.id,visit.name,"race",model.global_transform*bounds_of(model).get_center(),{"progress":best_progress,"readable_samples":visible_samples,"longest_run":longest_run,"visibility":best_visibility})
 game.ui.visible = false
 game.camera.position = Vector3(-235,590,380)
 game.camera.look_at(Vector3(-220,-20,-60))
 await shot(viewport,game.camera,"overzicht","Straatcircuit en startheuvel","overview",Vector3(-220,-20,-60))
 var file = FileAccess.open(output.path_join("subjects.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(subjects,"  "))
 print("UITHOORN GROUND VIEWS: ",subjects.size()," views, ",failures," failures; setup_only=",validate_only)
 game.free()
 viewport.free()
 model_points.clear()
 collision_shapes.clear()
 visibility_space = null
 quit(0 if failures==0 else 1)

func shot(view: Viewport, camera: Camera3D, filename: String, label: String, category: String, target: Vector3, extra: Dictionary = {}) -> void:
 if validate_only:
  await super.shot(view,camera,filename,label,category,target,extra)
  return
 var item = {"filename":filename+".png","label":label,"category":category,"world":4}
 item.merge(extra)
 subjects.append(item)
 for i in 2: await process_frame
 # The host may minimize this capture window. Force the offscreen viewport draw
 # rather than waiting indefinitely for an on-screen frame_post_draw signal.
 RenderingServer.force_draw(false)
 var picture = view.get_texture().get_image()
 if picture.is_empty() or picture.save_png(output.path_join(filename+".png"))!=OK:
  failures += 1
 print("GROUND CAPTURED ",filename)

func add_visibility_geometry(track: Node3D) -> void:
 await super.add_visibility_geometry(track)
 # On a low road a small facade strip may be visible below the roof. Sample
 # inside each triangle near its vertices as well as its centre; sparse triangle
 # centres alone can all lie on one horizontal line of the window grid.
 for model in model_points:
  var points: Array[Vector3] = []
  var pending: Array[Node] = [model]
  while not pending.is_empty():
   var node = pending.pop_back()
   pending.append_array(node.get_children())
   if not node is MeshInstance3D or node.mesh == null: continue
   var faces: PackedVector3Array = node.mesh.get_faces()
   var stride = maxi(3,int(faces.size()/120.0/3)*3)
   for i in range(0,faces.size()-2,stride):
    var center = (faces[i]+faces[i+1]+faces[i+2])/3
    for vertex in [faces[i],faces[i+1],faces[i+2]]:
     points.append(node.global_transform*center.lerp(vertex,0.7))
  model_points[model] = points
