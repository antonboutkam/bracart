extends SceneTree
const Architecture = preload("res://scripts/worlds/architecture.gd")
const Track = preload("res://scripts/track.gd")
var checks = 0
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures.append(label)
  push_error(label)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var mesh = Architecture.cap_mesh()
 var arrays = mesh.surface_get_arrays(0)
 var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
 var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
 var edges = {}
 var volume = 0.0
 for i in range(0,vertices.size(),3):
  var a = vertices[i]
  var b = vertices[i+1]
  var c = vertices[i+2]
  var normal = (c-a).cross(b-a)
  check(normal.length()>0.01,"nondegenerate cap triangle %d" % i)
  check(normal.normalized().dot(normals[i])>0.999,"clockwise outward face %d" % i)
  check(normals[i].dot((a+b+c)/3-Vector3(0,Architecture.RISE/3,0))>0,"normal points out of cap %d" % i)
  volume += a.dot(c.cross(b))/6
  for pair in [[a,b],[b,c],[c,a]]:
   var ids = [str(pair[0]),str(pair[1])]
   ids.sort()
   var key = ids[0]+"/"+ids[1]
   if not edges.has(key): edges[key] = []
   edges[key].append(pair[1]-pair[0])
 for key in edges:
  check(edges[key].size()==2,"watertight two triangles per edge "+key)
  if edges[key].size()==2: check((edges[key][0]+edges[key][1]).length()<0.0001,"opposite edge winding "+key)
 check(is_equal_approx(volume,Architecture.HALF_SPAN*Architecture.RISE*Architecture.HALF_DEPTH*2),"signed prism volume matches dimensions")
 # Ray cast against actual triangle geometry from every side, including gable holes.
 for origin in [Vector3(0,2,-15),Vector3(0,2,15),Vector3(-15,1,0),Vector3(15,1,0),Vector3(0,15,0),Vector3(0,-15,0)]:
  var target = Vector3(0,1.0,0)
  var hits = 0
  for i in range(0,vertices.size(),3):
   if Geometry3D.segment_intersects_triangle(origin,target,vertices[i],vertices[i+1],vertices[i+2])!=null: hits+=1
  check(hits>0,"side ray blocked by closed roof "+str(origin))
 for world in [3,4]:
  var track = Track.new()
  root.add_child(track)
  track.build(world)
  check(track.get_meta("district_house_count",0)>40,"actual world builds instanced district")
  # Exercise legacy standalone prototype separately; production housing is batched.
  for variant in 4: Architecture.house(track,Vector3(500+variant*20,0,500),variant,world==4)
  var houses = 0
  var node_count = 0
  for house in track.get_children():
   if not house.has_meta("architecture_house"): continue
   houses+=1
   node_count+=house.get_child_count()
   check(house.has_node("ClosedRoof"),"real track house has cap")
   check(house.get_node("ClosedRoof").material_override.cull_mode == BaseMaterial3D.CULL_BACK,"normal backface culling")
   for child in house.get_children():
    check(not child is CollisionObject3D,"decoration owns no collider")
    var bounds: AABB
    if child is MeshInstance3D: bounds = child.transform*child.get_aabb()
    elif child is MultiMeshInstance3D: bounds = child.transform*child.multimesh.get_aabb()
    else: continue
    check(bounds.position.x>=-6.5 and bounds.end.x<=6.5 and bounds.position.z>=-6.201 and bounds.end.z<=6.201,"all detail stays within previous horizontal footprint")
   if world==4:
    var panel = house.get_node("RoofMountedSolar")
    var angle = atan2(Architecture.RISE,Architecture.HALF_SPAN)
    var plane_normal = Vector3(sin(angle),cos(angle),0)
    check(panel.basis.y.dot(plane_normal)>0.999,"panel normal matches roof")
    var h: float = house.get_meta("eaves_height")
    for x in [-panel.mesh.size.x/2,panel.mesh.size.x/2]:
     for z in [-panel.mesh.size.z/2,panel.mesh.size.z/2]:
      var underside: Vector3 = panel.transform*Vector3(x,-panel.mesh.size.y/2,z)
      var gap = plane_normal.dot(underside-Vector3(0,h-0.15+Architecture.RISE,0))
      check(absf(gap-0.08)<0.0001,"panel underside eight cm above roof, aligned both ends")
  check(houses==4,"standalone prototype variants retain closed roof")
  print("ARCHITECTURE world=",world," houses=",houses," house_child_nodes=",node_count)
  track.queue_free()
  await process_frame
 print("ARCHITECTURE checks=",checks," failures=",failures.size())
 quit(0 if failures.is_empty() else 1)
