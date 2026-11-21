extends SceneTree
const Birds = preload("res://scripts/worlds/birds.gd")
const Track = preload("res://scripts/track.gd")
const CameraRig = preload("res://scripts/follow_camera.gd")
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var camera := Camera3D.new()
 root.add_child(camera)
 var rig = CameraRig.new(camera)
 for world in 6:
  var track = Track.new()
  root.add_child(track)
  track.build(world)
  var bird: Node3D = Birds.install(track)
  if world == 5:
   check(bird == null and Birds.install(track) == null,"Kitchen has no bird")
   track.queue_free()
   await process_frame
   continue
  check(bird != null and Birds.install(track) == bird,"One idempotent track-owned bird per outdoor world")
  bird.set_process(false)
  check(bird.wait_remaining >= 8 and bird.wait_remaining <= 16 and not bird.flight.visible,"Initial occasional passage waits hidden")
  bird.advance(bird.wait_remaining+0.1)
  check(bird.phase == "passing" and bird.flight.visible,"Scheduler starts actual flight")
  bird.force_passage()
  var count: int = bird.find_children("*","Node",true,false).size()
  var initial: Vector3 = bird.flight.position
  var first_wing: float = bird.left_wing.rotation.z
  bird.advance(0.7)
  check(bird.flight.position.distance_to(initial) > 5,"Bird actually progresses through sky")
  check(absf(bird.left_wing.rotation.z-first_wing) > 0.05,"Wing hinges actually flap")
  bird.advance(3.2-bird.pass_elapsed)
  check(bird.gliding and absf(bird.wing_angle) < 0.001,"Glide phase holds spread wings")
  bird.advance(bird.duration*0.5-bird.pass_elapsed)
  rig.reset()
  var kart: Dictionary = {"progress":0.0,"lateral":0.0,"speed":0.0,"jump_height":0.0,"boost_time":0.0}
  rig.update(track,kart,0.016,false,true)
  var projected: Vector2 = camera.unproject_position(bird.flight.global_position)
  check(not camera.is_position_behind(bird.flight.global_position) and camera.get_viewport().get_visible_rect().has_point(projected),"Midpass bird appears in actual race-camera horizon world%d projected%s" % [world,projected])
  for index in 120:
   bird.force_passage()
   bird.advance(2+index*0.01)
   check(bird.flight.position.is_finite() and bird.flight.basis.is_finite(),"Flight pose remains finite")
   check(bird.flight.position.y-1 > bird.maximum_track_y+24,"Whole small bird safely clears highest raceway")
   check(absf(bird.left_wing.rotation.z+bird.right_wing.rotation.z) < 0.001,"Opposite wings flap symmetrically")
   check(bird.find_children("*","Node",true,false).size() == count,"Repeated passages keep fixed node count")
  bird.advance(bird.duration-bird.pass_elapsed)
  check(bird.phase == "waiting" and not bird.flight.visible and bird.wait_remaining >= 35 and bird.wait_remaining <= 65,"Completed passage starts long hidden interval")
  var prior: float = bird.elapsed
  bird.advance(NAN)
  bird.advance(-1)
  check(bird.elapsed == prior,"Invalid deltas do not corrupt schedule")
  bird.force_passage()
  bird.set_process(true)
  track.process_mode = Node.PROCESS_MODE_DISABLED
  prior = bird.elapsed
  var pose: Transform3D = bird.flight.transform
  await create_timer(0.08).timeout
  check(bird.elapsed == prior and bird.flight.transform == pose,"Inherited race pause freezes all flight and wing time")
  track.process_mode = Node.PROCESS_MODE_INHERIT
  await create_timer(0.08).timeout
  check(bird.elapsed > prior and bird.elapsed-prior < 0.4,"Resume uses new frame time without catchup")
  var old: WeakRef = weakref(bird)
  track.queue_free()
  await process_frame
  check(old.get_ref() == null,"World switch frees flight and scheduler")
 camera.queue_free()
 await process_frame
 print("BORACER BIRDS: %d checks, %d failures" % [checks,failures])
 quit(0 if failures == 0 else 1)
