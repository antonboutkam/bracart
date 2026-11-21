extends SceneTree
## Independent actual Main/input lifecycle, geometry readback and natural timing.
const Main = preload("res://scripts/main.gd")
const Aircraft = preload("res://scripts/worlds/aircraft.gd")
var checks = 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
 checks += 1
 if not value:
  failures.append(label)
  if failures.size() <= 15: push_error(label)
func descendants(node: Node) -> Array[Node]:
 var result: Array[Node] = []
 for child in node.get_children():
  result.append(child)
  result.append_array(descendants(child))
 return result
func physical_exhaust(aircraft, engine_index: int) -> Vector3:
 var engine: MeshInstance3D = aircraft.flight.get_node("EngineLeft" if engine_index == 0 else "EngineRight")
 var a: Vector3 = engine.to_global(Vector3(0,engine.mesh.height*0.5,0))
 var b: Vector3 = engine.to_global(Vector3(0,-engine.mesh.height*0.5,0))
 var direction: Vector3 = aircraft.global_basis*(aircraft.path_end-aircraft.path_start)
 return a if (a-b).dot(direction)<0 else b
func check_geometry(aircraft) -> void:
 # Infer forward from motion and actual cylinder outlets rather than shared constants.
 var direction: Vector3 = (aircraft.global_basis*(aircraft.path_end-aircraft.path_start)).normalized()
 var points: Array[Vector3] = []
 for engine in 2:
  check(aircraft.trail_world[engine].size() == 96 and aircraft.trail_births[engine].size() == 96,"Contrail storage stays at its preallocated capacity")
  check(aircraft.trail_count[engine] <= 96,"Ring count never exceeds capacity")
  var exhaust: Vector3 = physical_exhaust(aircraft,engine)
  for index in aircraft.trail_count[engine]:
   var point: Vector3 = aircraft.trail_point(engine,index)
   points.append(point)
   check(point.is_finite() and (point-exhaust).dot(direction) <= 0.01,"Every actual trail center is behind its moving engine in world space")
 check(aircraft.trail_mesh.get_surface_count() <= 1,"Trail reuses a single bounded ImmediateMesh surface")
 if aircraft.trail_mesh.get_surface_count() == 0: return
 var arrays: Array = aircraft.trail_mesh.surface_get_arrays(0)
 var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
 var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
 check(vertices.size() <= 2*95*12 and vertices.size() == colors.size(),"Actual submitted ribbon vertices and colors have a fixed upper bound")
 for index in vertices.size():
  var world_point: Vector3 = aircraft.trail.to_global(vertices[index])
  var nearest = INF
  for point in points: nearest = minf(nearest,world_point.distance_to(point))
  check(world_point.is_finite() and nearest <= 1.901,"Actual ribbon vertices remain near emitted world-space centerpoints")
  var color: Color = colors[index]
  check(is_finite(color.a) and color.a >= 0 and color.a <= (0.301 if aircraft.night_amount>0.99 else 0.701),"Actual ribbon colors fade within day/night alpha limits")
func run() -> void:
 root.size = Vector2i(1280,800)
 var main = Main.new()
 root.add_child(main)
 main.set_process(false)
 main.set_physics_process(false)
 main.audio.muted = true
 main.audio.music.stop()
 main.audio.music.stream = null
 var previous_aircraft = null
 for world in 6:
  main.start_race(world)
  var aircraft = main.track.get_node_or_null("Aircraft")
  if aircraft != null: aircraft.set_process(false)
  await process_frame
  if previous_aircraft != null: check(previous_aircraft.get_ref() == null,"World replacement actually releases previous aircraft and trail")
  if world == 5:
   check(aircraft == null and main.track.get_node("KitchenProps").get_meta("objects").size() == 11,"Kitchen receives no aircraft and retains its eleven object groups")
   continue
  check(aircraft is Aircraft and Aircraft.install(main.track) == aircraft,"Every outdoor world installs exactly one idempotent aircraft controller")
  previous_aircraft = weakref(aircraft)
  var baseline_nodes = descendants(aircraft).size()
  var mesh_id: int = aircraft.trail_mesh.get_instance_id()
  check(baseline_nodes < 30 and aircraft.altitude >= aircraft.get_meta("maximum_track_y")+200,"Lightweight plane remains safely above the entire track")
  for child in descendants(aircraft): check(not child is CollisionObject3D and not child is AudioStreamPlayer3D,"Sky decoration introduces no collision or spatial audio emitters")
  if world == 0:
   var natural_passes = 0
   var active_ticks = 0
   var previous_phase: String = aircraft.phase
   var last_begin = -1.0
   var last_end = 0.0
   var gaps: Array[float] = []
   for tick in 1800:
    aircraft.advance(0.2)
    if aircraft.phase == "passing": active_ticks += 1
    if aircraft.phase != previous_phase:
     if aircraft.phase == "passing":
      var gap: float = aircraft.elapsed-last_end
      check(gap >= (9.7 if natural_passes == 0 else 54.7) and gap <= (20.3 if natural_passes == 0 else 100.3),"Natural passage follows first-delay/cooldown interval rather than continuous traffic")
      if natural_passes > 0: gaps.append(gap)
      natural_passes += 1
      last_begin = aircraft.elapsed
     else:
      check(aircraft.elapsed-last_begin >= 24.7 and aircraft.elapsed-last_begin <= 35.3,"Natural flight duration stays between 25 and 35 seconds")
      last_end = aircraft.elapsed
     previous_phase = aircraft.phase
   check(natural_passes >= 3 and active_ticks < 1080,"Several naturally scheduled passages occur with substantial quiet time")
   check(gaps.size() >= 2 and not is_equal_approx(gaps[0],gaps[1]),"Natural cooldown is varied rather than a fixed repeated interval")
   check(descendants(aircraft).size() == baseline_nodes and aircraft.trail_mesh.get_instance_id() == mesh_id,"Several minutes of natural passages reuse nodes and mesh resource")
  # Nonidentity placement verifies actual ribbon world/local conversion.
  aircraft.transform = Transform3D(Basis(Vector3.UP,0.35),Vector3(31,4,-12))
  aircraft.force_passage()
  for engine in 2:
   check(aircraft.trail_point(engine,0).distance_to(physical_exhaust(aircraft,engine)) <= 0.06,"First emitted point lies at the actual engine cylinder outlet, not merely a matching constant")
  aircraft.advance(0.4)
  var anchored: Vector3 = aircraft.trail_point(0,0)
  var before: Vector3 = aircraft.flight.global_position
  aircraft.advance(0.4)
  check(aircraft.flight.global_position.distance_to(before)>1 and aircraft.trail_point(0,0).is_equal_approx(anchored),"Emitted world-space trail stays fixed while aircraft advances")
  check_geometry(aircraft)
  aircraft.transform = Transform3D.IDENTITY
  aircraft.force_passage()
  var seen = 0
  var max_pixels = 0.0
  for progress in [0.1,0.3,0.5,0.7,0.9]:
   aircraft.advance(aircraft.duration*progress-aircraft.pass_elapsed)
   check_geometry(aircraft)
   for sample in 24:
    main.race.player.progress = main.track.length*sample/24.0
    main._camera(0,true)
    var point: Vector3 = aircraft.flight.global_position
    check(main.camera.global_position.distance_to(point)<main.camera.far-10,"Whole passage remains inside the actual race camera far distance")
    if main.camera.is_position_in_frustum(point):
     seen += 1
     var screen = Rect2(main.camera.unproject_position(point),Vector2.ZERO)
     for child in descendants(aircraft.flight):
      if child is MeshInstance3D:
       for corner in 8: screen = screen.expand(main.camera.unproject_position(child.global_transform*child.get_aabb().get_endpoint(corner)))
     max_pixels = maxf(max_pixels,screen.size.x)
  check(seen > 0 and max_pixels >= 3,"Actual normal race-camera poses can see a meaningful projected aircraft silhouette")
  var day: Color = aircraft.body_material.albedo_color
  main.weather.force_event("night",true)
  aircraft.advance(0.2)
  check(aircraft.flight.visible and aircraft.body_material.albedo_color.get_luminance() <= day.get_luminance(),"Actual night keeps the plane present with a subdued body tint")
  check_geometry(aircraft)
  check(descendants(aircraft).size() == baseline_nodes and aircraft.trail_mesh.get_instance_id() == mesh_id,"Forced passages/night also preserve bounded allocations")
  print("AIRCRAFT QA world=",world," normal_views=",seen," max_width_pixels=",max_pixels," nodes=",baseline_nodes)
  if world == 4:
   aircraft.force_passage()
   aircraft.set_process(true)
   main.set_process(true)
   main.ui.show_pause()
   for frame in 3: await process_frame
   var paused_time: float = aircraft.elapsed
   var paused_pose: Transform3D = aircraft.flight.global_transform
   var paused_records: String = str(aircraft.trail_world)
   await create_timer(0.08).timeout
   check(aircraft.elapsed == paused_time and aircraft.flight.global_transform == paused_pose and str(aircraft.trail_world) == paused_records,"Real Main pause freezes flight and emitted trail through actual frames")
   main.ui.resume()
   await create_timer(0.08).timeout
   check(aircraft.elapsed > paused_time and aircraft.flight.global_transform != paused_pose,"Real Main resume advances flight again")
   main.set_process(false)
 main.queue_free()
 for frame in 8: await process_frame
 print("BORACER AIRCRAFT INDEPENDENT QA: %d checks, %d failures" % [checks,failures.size()])
 quit(1 if failures.size() else 0)
