extends SceneTree
const Props = preload("res://scripts/worlds/kitchen_adventure_props.gd")
const Track = preload("res://scripts/track.gd")
var checks = 0
var failures: Array[String] = []
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:
  failures.append(label)
  push_error(label)
func _initialize() -> void: call_deferred("run")
func nodes(node: Node) -> Array[Node]:
 var result: Array[Node] = [node]
 for child in node.get_children(): result.append_array(nodes(child))
 return result
func run() -> void:
 var mesh = Props.tube_mesh(12.4,13.2,18)
 var triangles: Array = []
 var edges = {}
 for surface in mesh.get_surface_count():
  var arrays = mesh.surface_get_arrays(surface)
  var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
  var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
  for i in range(0,verts.size(),3):
   var a = verts[i]
   var b = verts[i+1]
   var c = verts[i+2]
   var normal = (c-a).cross(b-a)
   check(normal.length()>.001,"tube triangles nondegenerate")
   check(normal.normalized().dot(normals[i])>.999,"tube outward clockwise winding incl inner wall and annular rims")
   triangles.append([a,b,c])
   for pair in [[a,b],[b,c],[c,a]]:
    var ids = [str(pair[0].snapped(Vector3.ONE*.0001)),str(pair[1].snapped(Vector3.ONE*.0001))]
    ids.sort()
    var key = ids[0]+"/"+ids[1]
    edges[key]=edges.get(key,0)+1
 for key in edges: check(edges[key]==2,"annular tube wall is closed two-manifold, passage uncapped")
 for x in [-8.0,0.0,8.0]:
  for y in [-8.0,-5.0,1.0]:
   var hits = 0
   for triangle in triangles:
    if Geometry3D.segment_intersects_triangle(Vector3(x,y,-12),Vector3(x,y,12),triangle[0],triangle[1],triangle[2])!=null: hits+=1
   check(hits==0,"full width kart plus camera passage rays clear real triangles")
 if "--unit" not in OS.get_cmdline_user_args():
  var track = Track.new()
  root.add_child(track)
  track.build(5)
  var adventure = track.get_node("KitchenAdventureProps")
  var features: Array = adventure.get_meta("features")
  check(features.size()>=6,"all static adventure feature groups built from real course API")
  check(track.get_node("KitchenProps").get_meta("objects").size()==11,"all eleven original photo groups retained")
  check(track.has_node("LayeredWorldBackground/AdventureRoomFurniture/Bookcase"),"bookcase present at room wall")
  check(track.has_node("LayeredWorldBackground/AdventureRoomFurniture/Stove"),"existing kitchen now has stove and oven")
  for node in nodes(adventure): check(not node is CollisionObject3D,"decorative props do not change guided collision")
  for feature in features:
   if feature.kind in ["paper_tunnel","pvc_tunnel"]:
    check(absf(feature.frame.origin.y-5.3)<.05,"real tube road floor raised to safe passage chord")
    var inverse: Transform3D = feature.frame.affine_inverse()
    for offset in range(-7,8):
     var p = Vector3(offset,-feature.axis_offset,0)
     check(Vector2(p.x,p.y).length()<feature.inner_radius-.2,"real course lane safely inside circular bore")
    check(adventure.has_node(feature.id+"_entry_underlay") and adventure.has_node(feature.id+"_exit_underlay"),"tube approaches have real supporting ramps")
    var source: Dictionary
    for spec in track.kitchen_features():
     if spec.id==feature.id: source=spec
    var tunnel = adventure.get_node(feature.id)
    for child in tunnel.get_children():
     if not child is MeshInstance3D or child.mesh.get_surface_count()!=3: continue
     var tube_inverse: Transform3D = child.global_transform.affine_inverse()
     var bounds: AABB = child.get_aabb()
     var safe_radius = feature.inner_radius*cos(PI/64)-.05
     for sample in int(ceil((source.entry_end-source.entry_start)/.3))+1:
      var d = minf(source.entry_end,source.entry_start+sample*.3)
      for lane in [-7.8,0.0,7.8]:
       for lift in [0.0,.4,1.2,2.8,4.0]:
        var point: Vector3 = tube_inverse*track.position_at(d,lane,lift)
        if point.z>=bounds.position.z and point.z<=bounds.end.z:
         check(Vector2(point.x,point.y).length()<safe_radius,"actual whole approach/lane/vehicle envelope clears polygonal tube wall")
    var footprint: AABB = feature.static_aabb
    check(footprint.position.x>=-117.5 and footprint.end.x<=117.5 and footprint.position.z>=-102.5 and footprint.end.z<=102.5,"complete physical tube footprint stays on tabletop")
    print("TUBE_BOUNDS ",feature.id," ",footprint)
   if feature.kind in ["comic_album_ramp","playing_card_jenga_ramp"]:
    check(adventure.has_node(feature.support_node),"album/card has physical lip support")
    var sheet = adventure.get_node(feature.id).get_node("ComicAlbum" if feature.kind=="comic_album_ramp" else "PlayingCard")
    var sheet_vertices: PackedVector3Array = sheet.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    for vertex in sheet_vertices:
     check((sheet.global_transform*vertex).y>=.099,"closed album/card body never buried beneath tabletop")
    var interval: Vector2 = sheet.get_meta("route_interval")
    for sample in 61:
     var d = lerpf(interval.x,interval.y,float(sample)/60)
     var frame: Transform3D = track.frame(d)
     for lane in [-6.9,0.0,6.9]:
      var p: Vector3 = track.position_at(d,lane)
      var closest_gap = INF
      for i in range(0,sheet_vertices.size(),3):
       var a: Vector3 = sheet.global_transform*sheet_vertices[i]
       var b: Vector3 = sheet.global_transform*sheet_vertices[i+1]
       var c: Vector3 = sheet.global_transform*sheet_vertices[i+2]
       var hit = Geometry3D.segment_intersects_triangle(p+frame.basis.y,p-frame.basis.y*2,a,b,c)
       if hit!=null: closest_gap=minf(closest_gap,(p-hit).dot(frame.basis.y))
      check(closest_gap>-.01 and closest_gap<.025,"actual closed book/card top follows full-width guided ramp within 2.5 cm")
   if feature.kind=="overhead_cables":
    for path in feature.paths:
     for point in path:
      if absf(point.x)<=9: check(point.y-feature.cable_radius>=5,"overhead cables clear full car camera corridor")
  print("KITCHEN_ADVENTURE_PROPS groups=",features.size()," nodes=",nodes(adventure).size())
  track.queue_free()
  await process_frame
 print("KITCHEN_ADVENTURE_PROPS checks=",checks," failures=",failures.size())
 quit(0 if failures.is_empty() else 1)
