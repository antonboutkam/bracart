extends SceneTree
## Independent actual static geometry/support and player-only Main effect lifecycle.
const Track = preload("res://scripts/track.gd")
const Main = preload("res://scripts/main.gd")
const CameraRig = preload("res://scripts/follow_camera.gd")
var checks = 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
 checks += 1
 if not value:
  failures.append(label)
  if failures.size() <= 15: push_error(label)
func meshes(node: Node) -> Array[MeshInstance3D]:
 var result: Array[MeshInstance3D] = []
 if node is MeshInstance3D: result.append(node)
 for child in node.get_children(): result.append_array(meshes(child))
 return result
func vector(v: Vector3) -> Array: return [v.x,v.y,v.z]
func anonymous_layout(records: Dictionary) -> Dictionary:
 # Godot @Name@123 suffixes are scene-global counters, not persistent identity.
 # Keep named ancestry and same-class anonymous sibling order from original tree.
 var layout = {}
 for path in records:
  var parent_path = ""
  for part in str(path).split("/"):
   if part.begins_with("@"):
    var key = parent_path+"|"+part.get_slice("@",1)
    if not layout.has(key): layout[key]=[]
    if not part in layout[key]: layout[key].append(part)
   parent_path = parent_path.path_join(part)
 for key in layout:
  layout[key].sort_custom(func(a,b): return int(a.get_slice("@",2))<int(b.get_slice("@",2)))
 return layout
func original_node(props: Node,path: String,layout: Dictionary) -> Node:
 var current = props
 var original_parent = ""
 for part in path.split("/"):
  if part.begins_with("@"):
   var type_name = part.get_slice("@",1)
   var ordinal: int = layout[original_parent+"|"+type_name].find(part)
   var choices = current.get_children().filter(func(child): return str(child.name).begins_with("@"+type_name+"@"))
   if ordinal>=choices.size(): return null
   current=choices[ordinal]
  else:
   current=current.get_node_or_null(NodePath(part))
   if current==null: return null
  original_parent=original_parent.path_join(part)
 return current
func check_preserved(props: Node3D) -> void:
 var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://validation/kitchen-adventure-prop-baseline.json"))
 var layout = anonymous_layout(before)
 for path in before:
  var node = original_node(props,path,layout)
  check(node is MeshInstance3D,"Additive kitchen keeps old mesh path "+path)
  if not node is MeshInstance3D: continue
  var record: Dictionary = before[path]
  check(node.mesh.get_faces().to_byte_array().hex_encode().sha256_text() == record.faces_sha256,"Original photo-object mesh triangles remain byte-equivalent")
  var t: Transform3D = node.global_transform
  var values = [vector(t.origin),vector(t.basis.x),vector(t.basis.y),vector(t.basis.z)]
  for axis in 4:
   for component in 3: check(absf(values[axis][component]-float(record.transform[axis][component]))<0.000001,"Original photo-object transforms remain unchanged")
  var material: Material = node.material_override if node.material_override!=null else node.mesh.surface_get_material(0)
  if record.has("material"):
   check(material is StandardMaterial3D,"Original photo-object material class retained")
   if material is StandardMaterial3D:
    var data: Array = record.material
    check(material.albedo_color.to_html(true)==data[0] and is_equal_approx(material.roughness,float(data[1])) and is_equal_approx(material.metallic,float(data[2])) and material.transparency==int(data[3]) and material.cull_mode==int(data[4]),"Original photo-object palette/PBR/transparency retained")
    check((material.albedo_texture.resource_path if material.albedo_texture!=null else "") == data[5],"Original photo texture is retained")
 check(before.size()==219 and meshes(props).size()==219,"Snapshot covers the same219 pre-existing mesh primitives")
func ray_hits(node: MeshInstance3D,a: Vector3,b: Vector3) -> Array[Vector3]:
 var result: Array[Vector3] = []
 var inverse = node.global_transform.affine_inverse()
 var aa: Vector3 = inverse*a
 var bb: Vector3 = inverse*b
 var faces: PackedVector3Array = node.mesh.get_faces()
 for triangle in range(0,faces.size(),3):
  var hit = Geometry3D.segment_intersects_triangle(aa,bb,faces[triangle],faces[triangle+1],faces[triangle+2])
  if hit != null: result.append(node.to_global(hit))
 return result
func contains(shape: Dictionary,point: Vector3) -> bool:
 if not shape.world_box.has_point(point): return false
 var local: Vector3 = shape.inverse*point
 if not shape.box.has_point(local): return false
 var end = local+Vector3(1432,197,571)
 var hits: Array[Vector3] = []
 var faces: PackedVector3Array = shape.faces
 for triangle in range(0,faces.size(),3):
  var hit = Geometry3D.segment_intersects_triangle(local,end,faces[triangle],faces[triangle+1],faces[triangle+2])
  if hit == null: continue
  var duplicate = false
  for previous in hits:
   if previous.distance_to(hit)<0.0001: duplicate=true
  if not duplicate: hits.append(hit)
 return hits.size()%2==1
func run() -> void:
 root.size = Vector2i(1280,800)
 var track = Track.new()
 root.add_child(track)
 track.build(5)
 check_preserved(track.get_node("KitchenProps"))
 var root_props = track.get_node("KitchenAdventureProps")
 var features: Array = track.kitchen_features()
 var by_id = {}
 for feature in features: by_id[feature.id]=feature
 check(root_props.has_node("BlackGameController") and track.get_node("LayeredWorldBackground").has_node("AdventureRoomFurniture/Bookcase") and track.get_node("LayeredWorldBackground").has_node("AdventureRoomFurniture/Stove"),"New actual controller/bookcase/kitchen furniture coexist with old photo objects")
 var camera = Camera3D.new()
 root.add_child(camera)
 var rig = CameraRig.new(camera)
 var solids: Array = []
 for node in meshes(root_props):
  if node.name.begins_with("PaperRoll_") or node.name=="HollowPVC": continue
  solids.append({"node":node,"inverse":node.global_transform.affine_inverse(),"box":node.get_aabb(),"world_box":node.global_transform*node.get_aabb(),"faces":node.mesh.get_faces()})
 for id in ["toilet_rolls","pvc_rainbow"]:
  var feature: Dictionary = by_id[id]
  var tubes: Array = []
  for node in meshes(root_props.get_node(id)):
   if node.mesh.get_surface_count()!=3: continue
   tubes.append(node)
   var inner: PackedVector3Array = node.mesh.surface_get_arrays(1)[Mesh.ARRAY_VERTEX]
   var radius = INF
   for point in inner: radius=minf(radius,Vector2(point.x,point.y).length())
   var safe_radius: float = radius*cos(PI/64)-0.05
   check(radius>10,"Actual hollow tube has a sufficiently broad inner ring")
   var box: AABB = node.get_aabb()
   check(ray_hits(node,node.to_global(Vector3(0,0,box.position.z-1)),node.to_global(Vector3(0,0,box.end.z+1))).is_empty(),"Actual axial ray passes through both open ends, without hidden full cap")
   for surface in 3:
    var arrays = node.mesh.surface_get_arrays(surface)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
    for index in vertices.size():
     var expected: Vector3 = Vector3(vertices[index].x,vertices[index].y,0).normalized()*(1 if surface==0 else -1)
     if surface==2: expected=Vector3.FORWARD if vertices[index].z<0 else Vector3.BACK
     check(normals[index].dot(expected)>0.98,"Actual tube outer/inner/rim shading normals face their correct side")
   for sample in ceili((feature.entry_end-feature.entry_start)/0.35)+1:
    var progress: float = minf(feature.entry_end,feature.entry_start+sample*0.35)
    for lane in [-7.8,0.0,7.8]:
     for height in [0.0,0.4,1.2,2.8,4.0]:
      var point: Vector3 = node.to_local(track.position_at(progress,lane,height))
      if point.z>=box.position.z and point.z<=box.end.z:
       check(Vector2(point.x,point.y).length()<safe_radius,"Whole road/vehicle envelope fits actual polygonal bore throughout tunnel and approaches")
    for lane in [-5.95,0.0,5.95]:
     var kart = {"progress":progress,"lateral":lane,"speed":56.0,"jump_height":1.2,"boost_time":3.0}
     rig.reset()
     rig.update(track,kart,0,true,true)
     var point: Vector3 = node.to_local(camera.global_position)
     if point.z>=box.position.z and point.z<=box.end.z: check(Vector2(point.x,point.y).length()<safe_radius,"Actual following camera stays inside hollow tube wall")
  check(tubes.size()==(2 if id=="toilet_rolls" else 1),"Actual two paper rolls and one PVC pipe are built")
 # Test submitted rainbow vertices against the actual opaque pipe, not feature metadata.
 var pvc: MeshInstance3D = root_props.get_node("pvc_rainbow/HollowPVC")
 var rainbow: MeshInstance3D = track.kitchen_rainbow.get_node("SoftRotatingRainbowTunnel")
 var pvc_inner: PackedVector3Array = pvc.mesh.surface_get_arrays(1)[Mesh.ARRAY_VERTEX]
 var actual_radius = INF
 for vertex in pvc_inner: actual_radius=minf(actual_radius,Vector2(vertex.x,vertex.y).length())
 var pvc_box = pvc.get_aabb()
 for vertex in rainbow.mesh.get_faces():
  var actual_point: Vector3 = pvc.to_local(rainbow.to_global(vertex))
  var radial = Vector2(actual_point.x,actual_point.y).length()
  check(absf(radial-(actual_radius-0.6))<0.002,"Actual rainbow follows straight PVC axis at inner-wall offset, never hidden beyond opaque wall")
  check(actual_point.z>=pvc_box.position.z-0.002 and actual_point.z<=pvc_box.end.z+0.002,"Rainbow geometry remains within actual open PVC length")
 for id in ["comic_ramp","card_ramp"]:
  var feature: Dictionary = by_id[id]
  var sheet: MeshInstance3D = root_props.get_node(id+"/"+("ComicAlbum" if id=="comic_ramp" else "PlayingCard"))
  for sample in 61:
   var progress = lerpf(feature.start,feature.lip,sample/60.0)
   var up: Vector3 = track.frame(progress).basis.y
   for lane in [-6.9,0.0,6.9]:
    var point: Vector3 = track.position_at(progress,lane)
    var hits = ray_hits(sheet,point+up*0.3,point-up*0.3)
    check(not hits.is_empty(),"Actual ramp sheet supports each sampled road/lane point")
    var top = -INF
    for hit in hits: top=maxf(top,(hit-point).dot(up))
    check(top>=-0.06 and top<=0.025,"Actual ramp top stays near road, without buried entry or floating lane")
  for point in sheet.mesh.get_faces(): check(sheet.to_global(point).y>=0.099,"Actual ramp underside stays above tabletop instead of burying book/card")
 for sample in ceili(track.length/0.5)+1:
  var progress: float = sample*0.5
  for lane in [-5.95,0.0,5.95]:
   for height in [0.4,1.3,2.8]:
    var point: Vector3 = track.position_at(progress,lane,height)
    for shape in solids: check(not contains(shape,point),"New actual static solids keep the complete driving corridor clear: "+str(shape.node.name))
   var kart = {"progress":progress,"lateral":lane,"speed":56.0,"jump_height":1.2,"boost_time":3.0}
   rig.reset()
   rig.update(track,kart,0,true,true)
   for shape in solids: check(not contains(shape,camera.global_position),"New actual static solids keep full follow-camera corridor clear: "+str(shape.node.name))
 camera.queue_free()
 track.queue_free()
 await process_frame
 var main = Main.new()
 root.add_child(main)
 main.set_physics_process(false)
 main.audio.muted=true
 main.audio.music.stop()
 main.audio.music.stream=null
 main.start_race(5)
 var effect = main.track.kitchen_rainbow
 var zone: Dictionary = effect.feature
 var nodes = effect.get_child_count()
 var material_id: int = effect.material.get_instance_id()
 var shader_code: String = effect.material.shader.code
 var time_pattern = RegEx.new()
 time_pattern.compile("\\bTIME\\b")
 check(time_pattern.search(shader_code)==null,"Rainbow shader never uses an unpausable engine TIME clock")
 main.race.player.progress=zone.start-20
 main.race.player.update_visual(main.track,0)
 for kart in main.race.racers.slice(1):
  kart.progress=zone.center
  kart.update_visual(main.track,0)
 await create_timer(0.6).timeout
 check(not effect.inside and effect.opacity==0 and not effect.visible,"AI inside PVC never activates player-only rainbow while player remains outside")
 main.race.player.progress=zone.center
 main.race.player.update_visual(main.track,0)
 await create_timer(0.3).timeout
 check(effect.inside and effect.visible and effect.opacity>0 and effect.opacity<=1,"Actual Main player entry activates the existing rainbow tube")
 var before_phase: float = effect.material.get_shader_parameter("phase")
 await create_timer(0.08).timeout
 check(float(effect.material.get_shader_parameter("phase"))!=before_phase,"Actual real frames advance the explicit rotating rainbow phase")
 main.ui.show_pause()
 for frame in 3: await process_frame
 var paused_elapsed: float = effect.elapsed
 var paused_opacity: float = effect.opacity
 var paused_phase: float = effect.material.get_shader_parameter("phase")
 await create_timer(0.08).timeout
 check(effect.elapsed==paused_elapsed and effect.opacity==paused_opacity and effect.material.get_shader_parameter("phase")==paused_phase,"Real Main pause freezes rainbow phase and fade, not just its visible flag")
 main.ui.resume()
 await create_timer(0.08).timeout
 check(effect.elapsed>paused_elapsed,"Actual Main resume restarts rainbow clock")
 main.race.player.progress=zone.end+20
 main.race.player.update_visual(main.track,0)
 await create_timer(0.65).timeout
 check(not effect.inside and effect.opacity==0 and not effect.visible,"Actual player exit fades effect completely away")
 effect.set_process(false)
 for repeat in 100:
  effect.update_player(zone.center,repeat%2==0)
  effect.advance(0.1)
  var phase: float = effect.material.get_shader_parameter("phase")
  check(effect.opacity>=0 and effect.opacity<=1 and phase>=0 and phase<1,"Repeated triggers retain bounded opacity and phase")
 check(effect.get_child_count()==nodes and effect.material.get_instance_id()==material_id,"Repeated entries reuse the same tube node and shader material")
 var old_effect = weakref(effect)
 main.start_race(0)
 for frame in 3: await process_frame
 check(old_effect.get_ref()==null and main.track.kitchen_rainbow==null,"Switching out of kitchen releases rainbow and leaves outside world unchanged")
 main.queue_free()
 for frame in 8: await process_frame
 print("BORACER KITCHEN ADVENTURE INDEPENDENT QA: %d checks, %d failures" % [checks,failures.size()])
 quit(1 if failures.size() else 0)
