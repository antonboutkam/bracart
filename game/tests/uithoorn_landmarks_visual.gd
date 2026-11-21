extends SceneTree
## Same embedded-material GLBs in a neutral studio and in both actual Uithoorn tracks.
const Main = preload("res://scripts/main.gd")
const IDS = ["rechthuis", "schanskerk", "fort-aan-de-drecht", "irenebrug", "thamerkerk", "de-hoeksteen"]
var output: String
var validate_only := false
var failures := 0
var subjects: Array[Dictionary] = []
const VISIBILITY_LAYER := 1 << 19
var visibility_space: PhysicsDirectSpaceState3D
var model_points: Dictionary = {}
var collision_shapes: Dictionary = {}

func collision_copy(parent: Node3D, mesh: Mesh, transform: Transform3D, owner: Node3D) -> void:
 if not collision_shapes.has(mesh):
  var generated := mesh.create_trimesh_shape()
  if generated == null:
   return
  # The track is explicitly rendered double-sided, including its underside.
  # Godot's generated concave collision defaults to front faces only.
  generated.backface_collision = true
  collision_shapes[mesh] = generated
 var body := StaticBody3D.new()
 body.collision_layer = VISIBILITY_LAYER
 body.collision_mask = 0
 body.set_meta("visible_owner",owner)
 parent.add_child(body)
 body.global_transform = transform
 var shape := CollisionShape3D.new()
 shape.shape = collision_shapes[mesh]
 body.add_child(shape)

func add_visibility_geometry(track: Node3D) -> void:
 # Temporary capture-only ray geometry mirrors the actual opaque meshes. The
 # released game and its collision contract remain untouched.
 var helper := Node3D.new()
 helper.name = "CaptureVisibilityGeometry"
 track.add_child(helper)
 var pending: Array[Node] = [track]
 while not pending.is_empty():
  var node: Node = pending.pop_back()
  if node==helper:
   continue
  pending.append_array(node.get_children())
  if node is MeshInstance3D and node.visible and node.mesh != null:
   var owner: Node3D = node
   var ancestor: Node = node
   while ancestor != track and ancestor != null:
    if ancestor.has_meta("uithoorn_landmark"):
     owner = ancestor
     break
    ancestor = ancestor.get_parent()
   collision_copy(helper,node.mesh,node.global_transform,owner)
   if owner.has_meta("uithoorn_landmark"):
    if not model_points.has(owner):
     model_points[owner] = []
    var faces: PackedVector3Array = node.mesh.get_faces()
    # Evenly sample authored triangle centres rather than empty AABB corners.
    var stride: int = maxi(3,int(faces.size()/60.0/3)*3)
    for index in range(0,faces.size()-2,stride):
     var point: Vector3 = node.global_transform*((faces[index]+faces[index+1]+faces[index+2])/3)
     model_points[owner].append(point)
  elif node is MultiMeshInstance3D and node.visible and node.multimesh != null:
   var mm: MultiMesh = node.multimesh
   for index in mm.instance_count:
    collision_copy(helper,mm.mesh,node.global_transform*mm.get_instance_transform(index),node)
 await physics_frame
 await physics_frame
 visibility_space = track.get_world_3d().direct_space_state

func visible_score(model: Node3D, camera: Camera3D) -> Dictionary:
 var pixels: Array[Vector2] = []
 var bounds: AABB = model.global_transform*bounds_of(model)
 var lower_visible := 0
 var viewport_size: Vector2 = camera.get_viewport().get_visible_rect().size
 for point: Vector3 in model_points.get(model,[]):
  if not camera.is_position_in_frustum(point):
   continue
  var pixel := camera.unproject_position(point)
  # HUD-safe region, shared by the visible screenshot and our score.
  var normal_pixel := pixel/viewport_size
  if normal_pixel.x<0.22 or normal_pixel.x>0.79 or normal_pixel.y<0.27 or normal_pixel.y>0.74:
   continue
  var query := PhysicsRayQueryParameters3D.create(camera.global_position,point+(point-camera.global_position).normalized()*0.12,VISIBILITY_LAYER)
  var hit := visibility_space.intersect_ray(query)
  if hit.is_empty() or hit.collider.get_meta("visible_owner",null) != model:
   continue
  # A lower facade sample hidden behind the same building's own roof must
  # not count as visible body merely because the first hit has the same owner.
  if hit.position.distance_to(point)>0.3:
   continue
  pixels.append(pixel)
  if point.y<bounds.position.y+bounds.size.y*0.80:
   lower_visible += 1
 if pixels.size()<3 or lower_visible==0:
  return {"score":INF,"visible_points":pixels.size(),"body_points":lower_visible}
 var screen_bounds := Rect2(pixels[0],Vector2.ZERO)
 for pixel in pixels:
  screen_bounds = screen_bounds.expand(pixel)
 var size := screen_bounds.size
 if size.x<24 or size.y<14:
  return {"score":INF,"visible_points":pixels.size(),"body_points":lower_visible}
 return {"score":screen_bounds.get_center().distance_to(viewport_size*Vector2(0.5,0.5))-minf(size.x*size.y,100000)*0.01-pixels.size()*2,"visible_points":pixels.size(),"body_points":lower_visible,"pixel_size":[size.x,size.y],"viewport_size":[viewport_size.x,viewport_size.y]}

func filter_readable_body_points() -> void:
 # Recognisable walls/windows rather than roof accessories or spire tips.
 # These bounds refer to the actual audited GLB geometry, in model metres.
 for model: Node3D in model_points.keys():
  var id: String = model.get_meta("uithoorn_landmark","")
  if id not in ["schanskerk","de-hoeksteen"]:
   continue
  var inverse := model.global_transform.affine_inverse()
  var facade: Array[Vector3] = []
  for point: Vector3 in model_points[model]:
   var local: Vector3 = inverse*point
   if id=="schanskerk" and local.y>2 and local.y<14:
    facade.append(point)
   elif id=="de-hoeksteen" and absf(local.z)>12.3 and local.y>2 and local.y<11.5 and absf(local.x)<11:
    facade.append(point)
  model_points[model] = facade

func _initialize() -> void:
 call_deferred("run")

func bounds_of(node: Node3D) -> AABB:
 var result := AABB()
 var found := false
 var pending: Array[Node] = [node]
 while not pending.is_empty():
  var current: Node = pending.pop_back()
  pending.append_array(current.get_children())
  if current is MeshInstance3D:
   var box: AABB = node.global_transform.affine_inverse() * current.global_transform * current.get_aabb()
   result = result.merge(box) if found else box
   found = true
 return result

func shot(view: Viewport, camera: Camera3D, filename: String, label: String, category: String, target: Vector3, extra: Dictionary = {}) -> void:
 var item := {"filename":filename+".png", "label":label, "category":category, "world":4}
 item.merge(extra)
 subjects.append(item)
 if not camera.global_transform.is_finite() or not camera.is_position_in_frustum(target):
  failures += 1
  push_error("Landmark outside view: "+filename)
 if validate_only:
  await process_frame
  print("UITHOORN VIEW SETUP ",filename," (no image)")
  return
 for frame in 10:
  await process_frame
 await RenderingServer.frame_post_draw
 var picture := view.get_texture().get_image()
 print("UITHOORN FRAME ",filename," image=",picture.get_size()," viewport=",camera.get_viewport().get_visible_rect().size," current=",camera.is_current()," target_pixel=",camera.unproject_position(target)," camera=",camera.global_position)
 if picture.is_empty() or picture.get_width()<640 or picture.save_png(output.path_join(filename+".png")) != OK:
  failures += 1
 print("UITHOORN CAPTURE ",filename)

func studio_views() -> void:
 var viewport := SubViewport.new()
 viewport.size = Vector2i(1280,800)
 viewport.own_world_3d = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var studio := Node3D.new()
 viewport.add_child(studio)
 var environment := WorldEnvironment.new()
 environment.environment = Environment.new()
 environment.environment.background_mode = Environment.BG_COLOR
 environment.environment.background_color = Color("c8d4df")
 environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color = Color.WHITE
 environment.environment.ambient_light_energy = 0.65
 studio.add_child(environment)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-45,-35,0)
 sun.light_energy = 1.0
 sun.shadow_enabled = true
 studio.add_child(sun)
 var camera := Camera3D.new()
 camera.fov = 42
 camera.far = 1000
 studio.add_child(camera)
 camera.make_current()
 for id in IDS:
  var path: String = "res://assets/models/uithoorn-"+id+".glb"
  if not ResourceLoader.exists(path):
   failures += 1
   push_error("Missing standalone model: "+path)
   continue
  var packed = load(path)
  var model: Node3D = packed.instantiate()
  studio.add_child(model)
  var bounds := bounds_of(model)
  var target := bounds.get_center()
  var extent := maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
  var ground := MeshInstance3D.new()
  var mesh := BoxMesh.new()
  mesh.size = Vector3(extent*4,0.1,extent*4)
  ground.mesh = mesh
  var mat := StandardMaterial3D.new()
  mat.albedo_color = Color("d5dde2")
  mat.roughness = 0.95
  ground.material_override = mat
  ground.position.y = bounds.position.y-0.06
  studio.add_child(ground)
  for side in ["voor", "achter"]:
   var direction := Vector3(0.9,0.65,1.3) if side=="voor" else Vector3(-0.9,0.65,-1.3)
   camera.position = target+direction.normalized()*extent*2.05
   camera.look_at(target)
   await shot(viewport,camera,id+"-studio-"+side,id+" · zelfstandig GLB met ingebedde materialen · "+side,"standalone",target,{"id":id,"model_path":path})
  studio.remove_child(model)
  model.queue_free()
  studio.remove_child(ground)
  ground.queue_free()
 viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
 root.remove_child(viewport)
 viewport.queue_free()
 await process_frame

func world_views() -> void:
 var models = load("res://scripts/worlds/uithoorn_landmarks.gd")
 # The host desktop may resize its native window while the project retains a
 # 1280x800 logical canvas. Capture the complete real game in a fixed viewport
 # so unprojected coordinates, HUD layout and rendered pixels share one size.
 var viewport := SubViewport.new()
 viewport.size = Vector2i(1280,800)
 viewport.own_world_3d = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var game = Main.new()
 viewport.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.muted = true
 game.audio.music.stop()
 game.audio.music.stream = null
 for track_index in [4,10]:
  model_points.clear()
  game.start_race(track_index)
  # Focus loss on the user's host desktop must not overlay the controlled
  # capture pose with a pause menu. The same actual race/camera/HUD stay active.
  game.mode = "capture"
  game.ui.resume()
  game.race.paused = false
  game.race.set_process(false)
  game.race.countdown = -2
  game.race.elapsed = 12
  await add_visibility_geometry(game.track)
  # The special front-glass/nave mask addresses the two classic-course
  # placements. Other orientations retain their already reviewed body views.
  if track_index==4:
   filter_readable_body_points()
  var all_bounds := AABB()
  var have_bounds := false
  for entry in models.ENTRIES:
   var model: Node3D = game.track.get_node_or_null("Landmark_"+str(entry.id).replace("-","_"))
   if model == null:
    failures += 1
    push_error("Missing placed landmark "+str(entry.id)+" on track "+str(track_index))
    continue
   var bounds := bounds_of(model)
   var world_bounds: AABB = model.global_transform*bounds
   all_bounds = all_bounds.merge(world_bounds) if have_bounds else world_bounds
   have_bounds = true
   var target := model.global_transform*bounds.get_center()
   var extent := maxf(world_bounds.size.x,maxf(world_bounds.size.y,world_bounds.size.z))
   var prefix := str(entry.id)+"-v"+str(1 if track_index==4 else 2)
   game.ui.visible = false
   game.camera.make_current()
   game.camera.fov = 50
   var context_score := INF
   var context_position := target+Vector3.UP*extent*2
   var context_visibility: Dictionary = {}
   for angle in [0.45,-0.45,0.0,1.0,-1.0,PI]:
    for elevation in [0.65,1.1,1.8]:
     var direction := Vector3(sin(angle),elevation,cos(angle)).normalized()
     game.camera.position = target+model.global_basis*direction*maxf(extent*1.8,25)
     game.camera.look_at(target)
     var visibility := visible_score(model,game.camera)
     if visibility.score<context_score:
      context_score = visibility.score
      context_position = game.camera.position
      context_visibility = visibility
   game.camera.position = context_position
   game.camera.look_at(target)
   if not is_finite(context_score):
    failures += 1
    push_error("No unobstructed context view for "+prefix)
   await shot(viewport,game.camera,prefix+"-omgeving",entry.label+" · in de echte Uithoornwereld · versie "+str(1 if track_index==4 else 2),"world",target,{"id":entry.id,"track":track_index,"visibility":context_visibility})
   # Search the real course using the ordinary follow rig; never aim the race camera at the landmark.
   var best_progress := 0.0
   var best_lateral := 0.0
   var best_score := INF
   var best_visibility: Dictionary = {}
   for lane in [0.0,-0.75,0.75,-0.9,0.9]:
    game.race.player.lateral = game.track.width*lane
    for sample in 320:
     var progress: float = game.track.length*sample/320.0
     game.race.player.progress = progress
     game.race.player.update_visual(game.track,0)
     game._camera(0,true)
     if not game.camera.is_position_in_frustum(target):
      continue
     var visibility := visible_score(model,game.camera)
     var score: float = visibility.score
     if score<best_score:
      best_score = score
      best_progress = progress
      best_lateral = game.race.player.lateral
      best_visibility = visibility
   game.race.player.progress = best_progress
   game.race.player.lateral = best_lateral
   game.race.player.update_visual(game.track,0)
   game._camera(0,true)
   game.ui.update_hud(0)
   game.ui.visible = true
   print("UITHOORN RACE ",prefix," progress=",best_progress," score=",best_score)
   if not is_finite(best_score):
    failures += 1
    push_error("No readable unobstructed race view for "+prefix)
   await shot(viewport,game.camera,prefix+"-racecamera",entry.label+" · gewone racecamera · versie "+str(1 if track_index==4 else 2),"race",target,{"id":entry.id,"track":track_index,"progress":best_progress,"lateral":best_lateral,"score":best_score,"visibility":best_visibility})
  if have_bounds:
   var center := all_bounds.get_center()
   var span := maxf(all_bounds.size.x,all_bounds.size.z)
   game.ui.visible = false
   game.camera.fov = 55
   game.camera.position = center+Vector3(0.5,1.3,0.9).normalized()*span*1.6
   game.camera.look_at(center)
   await shot(viewport,game.camera,"uithoorn-v"+str(1 if track_index==4 else 2)+"-overzicht","Zes landmarks in Uithoorn · versie "+str(1 if track_index==4 else 2),"overview",center,{"track":track_index})
 game.queue_free()
 await process_frame
 viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
 root.remove_child(viewport)
 viewport.queue_free()
 await process_frame
 model_points.clear()
 collision_shapes.clear()
 visibility_space = null
 await process_frame

func run() -> void:
 validate_only = "--validate-only" in OS.get_cmdline_user_args()
 output = OS.get_environment("BORACER_CAPTURE_DIR")
 if not validate_only and (output.is_empty() or DisplayServer.get_name()=="headless"):
  push_error("Use native rendering and set BORACER_CAPTURE_DIR")
  quit(2)
  return
 root.size = Vector2i(1280,800)
 root.gui_disable_input = true
 await studio_views()
 await world_views()
 if not validate_only:
  var file := FileAccess.open(output.path_join("subjects.json"),FileAccess.WRITE)
  file.store_string(JSON.stringify(subjects,"  "))
 print("UITHOORN VIEWS=",subjects.size()," failures=",failures," setup_only=",validate_only)
 quit(0 if failures==0 and subjects.size()==38 else 1)
