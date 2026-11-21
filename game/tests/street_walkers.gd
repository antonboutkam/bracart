extends SceneTree
const Walkers = preload("res://scripts/worlds/street_walkers.gd")
var checks := 0
var failures := 0
class TestTrack extends Node3D:
 var world_index: int = 0
func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures += 1
  if failures < 15: push_error(label)
func _initialize() -> void:
 call_deferred("run")
func mesh_bounds_inside(node: Node3D, owner: Node3D, envelope: AABB) -> void:
 if node is MeshInstance3D:
  var bounds: AABB = node.get_aabb()
  for corner in 8:
   var point: Vector3 = owner.to_local(node.to_global(bounds.get_endpoint(corner)))
   check(point.is_finite() and envelope.grow(0.001).has_point(point),"Actual animated geometry stays within reserved swept envelope")
 for child in node.get_children():
  if child is Node3D: mesh_bounds_inside(child,owner,envelope)
func run() -> void:
 var track := TestTrack.new()
 root.add_child(track)
 var specs: Array = []
 for index in 4:
  specs.append({"id":"test%d"%index,"transform":Transform3D(Basis(Vector3.UP,0.3*index),Vector3(index*30,5,0)),"half_length":7.0,"width":1.8,"ground_y":0.0,"world":0})
 var walkers = Walkers.build(track,specs)
 walkers.set_process(false)
 check(walkers.actors.size() == 4 and walkers.get_parent() == track,"Track owns four pedestrian/dog pairs")
 check(walkers.find_children("*","CollisionObject3D",true,false).is_empty(),"Decorative people introduce no race collisions")
 check(walkers.find_children("*","Skeleton3D",true,false).is_empty(),"No expensive playable-character GLBs reused")
 var initial: Vector3 = walkers.actors[0].rig.position
 var hip_before: float = walkers.actors[0].legs[0].rotation.x
 walkers.advance(1)
 check(walkers.actors[0].rig.position.distance_to(initial) > 0.1,"Walking pair progresses along actual ground path")
 check(walkers.actors[0].legs[0].rotation.x != hip_before,"Human walk animates legs")
 for frame in 101:
  walkers.elapsed = float(frame)/100*TAU/walkers.actors[0].rate
  walkers._pose()
  for actor in walkers.actors:
   var node: Node3D = actor.node
   var envelope: AABB = node.get_meta("local_aabb")
   mesh_bounds_inside(node,node,envelope)
   var a: Vector3 = node.get_meta("leash_start")
   var b: Vector3 = node.get_meta("leash_end")
   check(a.is_finite() and b.is_finite() and a.distance_to(b) > 0.2 and a.distance_to(b) < 1.5,"Leash endpoints finite and plausibly hand-to-collar")
   check(a.distance_to(actor.hand.global_position) < 0.0001 and b.distance_to(actor.collar.global_position) < 0.0001,"Leash follows animated hand and moving collar")
   check(actor.leash.basis.is_finite() and absf(actor.leash.basis.y.length()-a.distance_to(b)) < 0.001,"Visible rope geometry has exact current leash length")
 var start: Transform3D = Walkers.route_frame(0,7,1.8)
 var end: Transform3D = Walkers.route_frame(TAU,7,1.8)
 check(start.is_equal_approx(end),"Route position and heading close without teleport seam")
 check(Walkers.route_frame(TAU-0.0001,7,1.8).origin.distance_to(start.origin)<0.001,"Crossing seam is continuous")
 for actor in walkers.actors:
  var period: float = TAU/actor.rate
  walkers.elapsed = 0
  walkers._pose()
  var before: Transform3D = actor.rig.transform
  var leg: float = actor.legs[0].rotation.x
  var paw: float = actor.paws[0].rotation.x
  var tail: float = actor.tail.rotation.z
  walkers.elapsed = period
  walkers._pose()
  check(actor.rig.transform.is_equal_approx(before),"Each authored route returns to its original frame")
  check(absf(actor.legs[0].rotation.x-leg)<0.0001 and absf(actor.paws[0].rotation.x-paw)<0.0001 and absf(actor.tail.rotation.z-tail)<0.0001,"Human limbs dog paws and tail also close at route seam")
 var previous: float = walkers.elapsed
 walkers.advance(NAN)
 walkers.advance(-1)
 check(walkers.elapsed == previous,"Invalid deltas cannot poison routes")
 walkers.set_process(true)
 track.process_mode = Node.PROCESS_MODE_DISABLED
 await create_timer(0.08).timeout
 check(walkers.elapsed == previous and not walkers.can_process(),"Actual parent pause freezes pedestrian clock and poses")
 track.process_mode = Node.PROCESS_MODE_INHERIT
 await create_timer(0.08).timeout
 check(walkers.elapsed > previous and walkers.elapsed-previous < 0.3,"Resume advances only live frame time without wall-clock catchup")
 var memory_meshes: int = Walkers.meshes.size()
 var kitchen := TestTrack.new()
 kitchen.world_index = 5
 root.add_child(kitchen)
 var excluded = Walkers.build(kitchen,specs)
 check(excluded.actors.is_empty(),"Kitchen receives no walkers")
 var old: WeakRef = weakref(walkers.actors[0].dog)
 track.queue_free()
 kitchen.queue_free()
 await process_frame
 check(old.get_ref() == null,"World deletion frees walking groups and dogs")
 check(Walkers.meshes.size() == memory_meshes,"Route stepping allocates no new meshes")
 print("BORACER STREET WALKERS: %d checks, %d failures" % [checks,failures])
 quit(0 if failures == 0 else 1)
