extends SceneTree
const Aircraft = preload("res://scripts/worlds/aircraft.gd")
var checks := 0
var failures := 0
class SkyTrack extends Node3D:
 var world_index: int = 0
 var length: float = 600
 func position_at(distance: float) -> Vector3:
  return Vector3(distance,20+sin(distance/600*TAU)*10,0)
 func frame(_distance: float) -> Transform3D:
  return Transform3D(Basis.IDENTITY,Vector3(0,20,0))
func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures += 1
  if failures < 15: push_error(label)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var track := SkyTrack.new()
 root.add_child(track)
 var aircraft = Aircraft.install(track)
 aircraft.set_process(false)
 check(aircraft.wait_remaining >= 10 and aircraft.wait_remaining <= 20,"First occasional passage waits ten to twenty seconds")
 check(aircraft.altitude >= 30+180 and aircraft.altitude <= 30+250,"Plane flies well above the highest route point")
 check(Aircraft.install(track) == aircraft and track.get_child_count() == 1,"One aircraft controller per world")
 check(not aircraft.flight.visible and aircraft.trail_mesh.get_surface_count() == 0,"No plane or static contrail during initial wait")
 var first_delay: float = aircraft.wait_remaining
 aircraft.advance(first_delay-0.1)
 check(aircraft.phase == "waiting" and not aircraft.flight.visible,"Scheduler keeps aircraft hidden until first due passage")
 aircraft.advance(0.2)
 check(aircraft.phase == "passing" and aircraft.flight.visible,"Scheduler actually starts after its first wait")
 aircraft.force_passage()
 check(aircraft.duration >= 25 and aircraft.duration <= 35,"Passage duration is between twenty-five and thirty-five seconds")
 check(aircraft.flight.visible and aircraft.phase == "passing","Explicit capture API starts an actual passage")
 var count_nodes: int = aircraft.find_children("*","Node",true,false).size()
 var initial: Vector3 = aircraft.flight.global_position
 aircraft.advance(5)
 check(aircraft.flight.global_position.distance_to(initial) > 100,"Aircraft actually traverses the sky")
 check(aircraft.trail_mesh.get_surface_count() == 1 and aircraft.trail_count[0] > 10,"Bounded mesh contains two emitted engine trails")
 var fixed: Vector3 = aircraft.trail_point(0,0)
 aircraft.advance(1)
 check(aircraft.trail_point(0,0).is_equal_approx(fixed),"Old engine emission stays fixed in worldspace rather than following the airplane")
 for index in 80:
  aircraft.advance(0.2)
  for engine in 2:
   for point in aircraft.trail_count[engine]:
    var world: Vector3 = aircraft.trail_point(engine,point)
    var local: Vector3 = aircraft.flight.to_local(world)
    check(world.is_finite() and local.z >= 1.0,"All retained emissions stay behind the nose at actual engine world positions")
  check(aircraft.trail_count[0] <= Aircraft.MAX_TRAIL_POINTS and aircraft.trail_count[1] <= Aircraft.MAX_TRAIL_POINTS,"Emission pools cannot grow")
 check(aircraft.find_children("*","Node",true,false).size() == count_nodes,"Long passage adds no trail nodes")
 var vertices: PackedVector3Array = aircraft.trail_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
 var colors: PackedColorArray = aircraft.trail_mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
 check(vertices.size() <= Aircraft.MAX_TRAIL_POINTS*2*12,"ImmediateMesh vertex buffer remains bounded")
 var least_alpha: float = 1
 var most_alpha: float = 0
 for color in colors:
  least_alpha = minf(least_alpha,color.a)
  most_alpha = maxf(most_alpha,color.a)
 check(least_alpha < most_alpha and most_alpha > 0.1,"Older contrail vertices visibly fade")
 aircraft.advance(aircraft.duration-aircraft.pass_elapsed+0.01)
 check(aircraft.phase == "waiting" and not aircraft.flight.visible and aircraft.wait_remaining >= 54.9 and aircraft.wait_remaining <= 100,"Only completed passage starts the fifty-five to hundred second gap")
 aircraft.advance(Aircraft.TRAIL_LIFETIME+0.5)
 check(aircraft.trail_count[0] == 0 and aircraft.trail_count[1] == 0 and aircraft.trail_mesh.get_surface_count() == 0,"Old trails expire instead of leaving a permanent stripe")
 var before: float = aircraft.elapsed
 aircraft.advance(NAN)
 aircraft.advance(-1)
 check(aircraft.elapsed == before,"Invalid time cannot poison the scheduler")
 aircraft.force_passage()
 aircraft.set_process(true)
 track.process_mode = Node.PROCESS_MODE_DISABLED
 var paused: float = aircraft.elapsed
 var paused_position: Vector3 = aircraft.flight.position
 await create_timer(0.1).timeout
 check(aircraft.elapsed == paused and aircraft.flight.position == paused_position,"Inherited game pause freezes flight and trail time")
 track.process_mode = Node.PROCESS_MODE_INHERIT
 await create_timer(0.1).timeout
 check(aircraft.elapsed > paused and aircraft.elapsed-paused < 0.3,"Resume advances live frames without wallclock catchup")
 var kitchen := SkyTrack.new()
 kitchen.world_index = 5
 root.add_child(kitchen)
 check(Aircraft.install(kitchen) == null and kitchen.get_child_count() == 0,"Kitchen has no outdoor airplane")
 var old: WeakRef = weakref(aircraft)
 track.queue_free()
 kitchen.queue_free()
 await process_frame
 check(old.get_ref() == null,"World deletion frees model and fixed trail pool")
 print("BORACER AIRCRAFT: %d checks, %d failures" % [checks,failures])
 quit(0 if failures == 0 else 1)
