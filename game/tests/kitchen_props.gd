extends SceneTree
const Track = preload("res://scripts/track.gd")
const Props = preload("res://scripts/worlds/kitchen_props.gd")
var checks = 0
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
 checks+=1
 if not value:
  failures.append(label)
  push_error(label)
func _initialize() -> void: call_deferred("run")
func _mesh_nodes(node: Node) -> Array[MeshInstance3D]:
 var result: Array[MeshInstance3D] = []
 if node is MeshInstance3D: result.append(node)
 for child in node.get_children(): result.append_array(_mesh_nodes(child))
 return result
func run() -> void:
 var track = Track.new()
 root.add_child(track)
 track.build(5)
 var props = track.get_node("KitchenProps")
 var objects: Array = props.get_meta("objects")
 check(objects.size()==11,"all eleven photographed object groups placed")
 check(_mesh_nodes(props).size()<500,"fewer than 500 prop mesh nodes")
 check(is_equal_approx(track.width,7.0),"table race width unchanged")
 check(track.world_index==5,"table scene index unchanged")
 for object in objects:
  var node = props.get_node(object.node)
  var min_y = INF
  for mesh in _mesh_nodes(node):
   var relative: Transform3D = node.global_transform.affine_inverse()*mesh.global_transform
   var bounds = mesh.get_aabb()
   for x in [bounds.position.x,bounds.end.x]:
    for y in [bounds.position.y,bounds.end.y]:
     for z in [bounds.position.z,bounds.end.z]:
      var p: Vector3 = relative*Vector3(x,y,z)
      check(Vector2(p.x,p.z).length()<=object.radius+0.05,"entire object including cables within declared footprint: "+object.id)
      min_y = minf(min_y,p.y)

  check(min_y>=-0.1 and min_y<=0.4,"object rests on tabletop: "+object.id)
  for i in int(ceil(track.length/0.5)):
   var q: Vector3 = track.position_at(i*0.5)
   check(Vector2(q.x-object.center.x,q.z-object.center.z).length()>=track.width+object.radius+3.7,"route incl bend and camera guard clear: "+object.id)
 var mega = props.get_node("megaphone")
 check(mega.get_node("RedTop").position.y>mega.get_node("OpenWhiteHorn").position.y+8,"red cap above upright white horn")
 var horn = Props.horn_mesh()
 var vertices: PackedVector3Array = horn.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
 var edges = {}
 var hits = 0
 for i in range(0,vertices.size(),3):
  var a = vertices[i]
  var b = vertices[i+1]
  var c = vertices[i+2]
  check((c-a).cross(b-a).length()>0.001,"horn triangles nondegenerate")
  if Geometry3D.segment_intersects_triangle(Vector3(0,-1,0),Vector3(0,7,0),a,b,c)!=null: hits+=1
  for pair in [[a,b],[b,c],[c,a]]:
   # Quantization merges sin(TAU) seam drift; UV vertex splits remain valid.
   var ids = [str(pair[0].snapped(Vector3.ONE*0.0001)),str(pair[1].snapped(Vector3.ONE*0.0001))]
   ids.sort()
   var key = ids[0]+"/"+ids[1]
   edges[key] = edges.get(key,0)+1
 check(hits==0,"megafoon mouth ray passes through actual open horn")
 for key in edges: check(edges[key]==2,"horn shell has wall thickness and closed annular rims")
 var photo_ids = {}
 for mesh in _mesh_nodes(props):
  if mesh.has_meta("photo_surface"): photo_ids[mesh.get_meta("photo_surface")]=true
 for id in ["monitor_screen","keyboard_top","remote_top","megaphone_cap","can_label"]:
  check(photo_ids.has(id),"real photo surface exists: "+id)
 var body = props.get_node("can/CyanCan")
 check(body.mesh.height/body.mesh.bottom_radius>4,"drink can has tall slim proportions")
 check(props.get_node("globe/CrystalSphere").material_override.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA,"crystal ball is translucent")
 print("KITCHEN_PROPS objects=",objects.size()," mesh_nodes=",_mesh_nodes(props).size()," checks=",checks," failures=",failures.size())
 track.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
