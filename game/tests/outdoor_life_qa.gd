extends SceneTree
## Independent CPU-placement, visibility, animated envelope and Main lifecycle checks.
## Dummy rendering cannot read back MultiMesh transforms: use submitted matrices.
const Track = preload("res://scripts/track.gd")
const Main = preload("res://scripts/main.gd")
const CameraRig = preload("res://scripts/follow_camera.gd")
var checks = 0
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures.append(label)
  if failures.size() <= 12: push_error(label)

func _initialize() -> void:
 call_deferred("run")

func supports(shapes: Array, point: Vector3, boxes_only: bool) -> bool:
 for shape in shapes:
  if boxes_only and not shape.box_mesh: continue
  if shape.bounds.has_point(shape.inverse*point): return true
 return false

func mesh_nodes(node: Node) -> Array[MeshInstance3D]:
 var result: Array[MeshInstance3D] = []
 if node is MeshInstance3D: result.append(node)
 for child in node.get_children(): result.append_array(mesh_nodes(child))
 return result

func terrain_top(nodes: Array[MeshInstance3D], point: Vector3) -> float:
 var highest = -INF
 for node in nodes:
  if node.mesh is BoxMesh:
   var box: AABB = node.global_transform*node.get_aabb()
   if point.x >= box.position.x and point.x <= box.end.x and point.z >= box.position.z and point.z <= box.end.z:
    highest = maxf(highest,box.end.y)
  elif node.mesh is SphereMesh:
   # Background hills/clouds are unpitched ellipsoids. The smooth primitive
   # envelope conservatively contains their tessellated triangle surface.
   var local = node.to_local(Vector3(point.x,node.global_position.y,point.z))
   var radial: float = 1.0-pow(local.x/node.mesh.radius,2)-pow(local.z/node.mesh.radius,2)
   if radial >= 0:
    var top: Vector3 = node.to_global(Vector3(local.x,node.mesh.height*0.5*sqrt(radial),local.z))
    highest = maxf(highest,top.y)
 return highest

func run() -> void:
 root.size = Vector2i(1280,800)
 var camera = Camera3D.new()
 root.add_child(camera)
 camera.current = true
 var rig = CameraRig.new(camera)
 for world in 6:
  var track = Track.new()
  root.add_child(track)
  track.build(world)
  if world == 5:
   check(not track.has_node("OutdoorLife") and not track.has_node("StreetWalkers"),"Kitchen receives no outdoor objects or walkers")
   check(track.get_node("KitchenProps").get_meta("objects").size() == 11,"Kitchen retains eleven photo-informed groups")
   track.queue_free()
   await process_frame
   continue
  var life = track.get_node("OutdoorLife")
  var walkers = track.get_node("StreetWalkers")
  var clusters: Array = life.get_meta("clusters")
  var terrain = mesh_nodes(track.get_node("LayeredWorldBackground"))
  check(clusters.size() >= 18 and walkers.actors.size() == 4,"Actual outside world has substantial clusters and four walking pairs")
  var shapes: Array = []
  for batch in life.get_children():
   var submitted: Array = batch.get_meta("instance_transforms",[])
   check(submitted.size() == batch.multimesh.instance_count,"Submitted CPU matrices cover every instanced primitive")
   for transform_value in submitted:
    shapes.append({"inverse":(batch.global_transform*transform_value).affine_inverse(),"transform":batch.global_transform*transform_value,"bounds":batch.multimesh.mesh.get_aabb(),"box_mesh":batch.multimesh.mesh is BoxMesh,"sphere_mesh":batch.multimesh.mesh is SphereMesh})
  for cluster in clusters:
   for x in [-10.8,0.0,10.8]:
    for z in [-5.8,0.0,5.8]:
     var deck: Vector3 = cluster.transform*Vector3(x,0,z)
     check(deck.y >= terrain_top(terrain,deck)+0.035,"Deck stays above final rendered background banks/hills, world%d" % world)
   check(supports(shapes,cluster.center-Vector3.UP*0.05,true),"Cluster has actual submitted solid deck geometry")
   if world in [0,1,3]:
    check(supports(shapes,cluster.center-Vector3.UP*2,false),"Elevated street furniture has a physical supporting pedestal")
   elif world == 2:
    check(supports(shapes,cluster.center-Vector3.UP*3,false),"Cloud promenade has submitted cloud-island support below deck")
    var cloud_parts = 0
    for shape in shapes:
     var local: Vector3 = cluster.transform.affine_inverse()*shape.transform.origin
     if shape.sphere_mesh and local.y < -1 and Vector2(local.x,local.z).length() < 8:
      cloud_parts += 1
      var actual: AABB = shape.transform*shape.bounds
      check(actual.end.y <= cluster.floor_y and actual.end.y > cluster.floor_y-0.6,"Cloud support top overlaps deck underside without burying cars or walkers")
    check(cloud_parts == 3,"Each cloud promenade has three individually verified support puffs")
   else:
    check(is_equal_approx(cluster.center.y,-20.85),"Uithoorn street life stands above final landscaped bank beneath elevated route")
   check(cluster.vehicle == ("steam_carriage" if world == 3 else "parked_car"),"Haarlem uses period-inspired steam carriage, other worlds parked car")
  var seen: Dictionary = {}
  for meter in range(0,ceili(track.length),3):
   var kart = {"progress":float(meter),"lateral":0.0,"speed":40.0,"jump_height":0.0,"boost_time":0.0}
   rig.reset()
   rig.update(track,kart,0,true,true)
   for cluster in clusters:
    for offset in [Vector3(4,1.5,2),Vector3(-7,6,2)]:
     var point: Vector3 = cluster.transform*offset
     var pixel: Vector2 = camera.unproject_position(point)
     if point.distance_to(camera.global_position) <= 150 and not camera.is_position_behind(point) and Rect2(40,40,1200,720).has_point(pixel): seen[cluster.id] = true
  check(seen.size() >= 4,"Multiple clusters project into real race-camera views along world%d, seen%d" % [world,seen.size()])
  var houses: Array = track.get_node("StreetDistricts").get_meta("buildings") if track.has_node("StreetDistricts") else []
  for actor in walkers.actors:
   var bounds: AABB = actor.node.get_meta("dynamic_aabb")
   for corner in 8:
    var local: Vector3 = actor.node.get_meta("local_aabb").get_endpoint(corner)
    local.y = -0.05
    check(supports(shapes,actor.node.to_global(local),true),"Whole walking envelope has submitted deck beneath it")
    var floor: Vector3 = actor.node.to_global(Vector3(local.x,0,local.z))
    check(floor.y >= terrain_top(terrain,floor)+0.035,"Whole swept walking floor stays above final background terrain")
   for meter in range(0,ceili(track.length)):
    var q: Vector3 = track.position_at(float(meter))
    var dx = maxf(maxf(bounds.position.x-q.x,q.x-bounds.end.x),0)
    var dz = maxf(maxf(bounds.position.z-q.z,q.z-bounds.end.z),0)
    check(Vector2(dx,dz).length() > track.width+2,"Swept human/dog envelope avoids full race corridor")
   if world in [0,3,4]: check(bounds.end.x < -24.5 or bounds.position.x > 24.5,"Swept human/dog envelope never enters river")
   for house in houses:
    var house_box: AABB = house.frame*AABB(Vector3(-house.width/2-0.2,-80,-house.depth/2-10),Vector3(house.width+0.4,100,house.depth+10.3))
    var overlap_x = bounds.position.x < house_box.end.x and bounds.end.x > house_box.position.x
    var overlap_z = bounds.position.z < house_box.end.z and bounds.end.z > house_box.position.z
    check(not (overlap_x and overlap_z),"Swept human/dog envelope avoids house and garden footprints")
   if world == 4:
    var tram = track.get_node("UithoornTram")
    for sample in 512:
     var q: Vector3 = tram.frame_at(tram.loop_length*sample/512.0).origin
     var dx = maxf(maxf(bounds.position.x-q.x,q.x-bounds.end.x),0)
     var dz = maxf(maxf(bounds.position.z-q.z,q.z-bounds.end.z),0)
     check(Vector2(dx,dz).length() > 6,"Swept walking envelope avoids actual tram running loop")
  walkers.set_process(false)
  for sample in 25:
   walkers.elapsed = TAU/0.21*sample/24.0
   walkers._pose()
   for actor in walkers.actors:
    var envelope: AABB = actor.node.get_meta("local_aabb")
    for mesh in mesh_nodes(actor.node):
     var relative: Transform3D = actor.node.global_transform.affine_inverse()*mesh.global_transform
     for corner in 8:
      var point: Vector3 = relative*mesh.get_aabb().get_endpoint(corner)
      check(point.is_finite() and envelope.grow(0.015).has_point(point),"Actual moving human/dog/leash mesh bounds stay in swept envelope")
    var a: Vector3 = actor.leash.to_global(Vector3(0,-0.5,0))
    var b: Vector3 = actor.leash.to_global(Vector3(0,0.5,0))
    check(a.is_finite() and b.is_finite() and a.distance_to(actor.hand.global_position)<0.001 and b.distance_to(actor.collar.global_position)<0.001,"Finite actual leash geometry connects hand to dog collar")
    check(a.distance_to(b)>0.05 and a.distance_to(b)<1.5,"Human/dog leash stays at plausible bounded length")
  print("OUTDOOR QA world=",world," clusters=",clusters.size()," projected_visible=",seen.size()," actors=",walkers.actors.size()," submitted_shapes=",shapes.size())
  var old = weakref(walkers)
  track.queue_free()
  await process_frame
  check(old.get_ref() == null,"Track deletion frees all walking rigs")
 camera.queue_free()
 await process_frame
 var main = Main.new()
 root.add_child(main)
 main.audio.muted = true
 main.audio.music.stop()
 main.audio.music.stream = null
 main.set_physics_process(false)
 main.start_race(4)
 var walkers = main.track.get_node("StreetWalkers")
 var before: float = walkers.elapsed
 await create_timer(0.08).timeout
 check(walkers.elapsed > before,"Actual Main scene advances street walkers")
 var event = InputEventAction.new()
 event.action = "pause"
 event.pressed = true
 main._unhandled_input(event)
 await process_frame
 before = walkers.elapsed
 await create_timer(0.08).timeout
 check(walkers.elapsed == before and not walkers.can_process(),"Actual Main pause freezes entire pedestrian/dog gait")
 main._unhandled_input(event)
 await create_timer(0.08).timeout
 check(walkers.elapsed > before,"Actual Main resume restarts street life")
 var old = weakref(walkers)
 main.start_race(5)
 await process_frame
 check(old.get_ref() == null and not main.track.has_node("StreetWalkers"),"Main kitchen switch frees all outside actors")
 main.queue_free()
 await process_frame
 print("BORACER OUTDOOR LIFE QA: %d checks, %d failures" % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
