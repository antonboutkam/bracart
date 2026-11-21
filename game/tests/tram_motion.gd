extends SceneTree
const Tram = preload("res://scripts/worlds/tram.gd")
const Routes = preload("res://scripts/worlds/routes.gd")
var checks := 0
var failures := 0
func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(label)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var holder := Node3D.new()
 root.add_child(holder)
 var tram = Tram.build(holder)
 check(tram.get_parent() == holder and tram.cars.size() == 3, "Track owns three-car tram")
 check(tram.loop_length > 400 and tram.loop_length < 550, "Ground loop has plausible metric length")
 for i in 400:
  var d: float = tram.loop_length * i / 400
  var a: Transform3D = tram.frame_at(d)
  var b: Transform3D = tram.frame_at(d + 0.1)
  check(a.origin.is_finite() and a.basis.is_finite(), "Finite pose along loop")
  check((-a.basis.z).dot((b.origin-a.origin).normalized()) > 0.98, "Heading follows running rails")
  check(a.origin.x >= 33.9 and a.origin.x <= 132.1 and a.origin.y < -20, "Tram remains east of Amstel at ground level")
 var start: Transform3D = tram.frame_at(0)
 var end: Transform3D = tram.frame_at(tram.loop_length)
 check(start.is_equal_approx(end), "Exact closed-loop seam")
 check(tram.frame_at(tram.loop_length - 0.01).origin.distance_to(start.origin) < 0.02, "No jump at seam")
 var before: Vector3 = tram.cars[0].position
 tram.advance(1)
 check(tram.cars[0].position.distance_to(before) > 8, "True transit progress rather than local oscillation")
 var old_distance: float = tram.distance
 tram.advance(-1)
 tram.advance(NAN)
 check(tram.distance == old_distance, "Invalid time cannot poison poses")
 holder.process_mode = Node.PROCESS_MODE_DISABLED
 var paused: float = tram.distance
 var timer := create_timer(0.1)
 await timer.timeout
 check(tram.distance == paused and not tram.can_process(), "Track process disable freezes actual child tram")
 holder.process_mode = Node.PROCESS_MODE_INHERIT
 await create_timer(0.1).timeout
 check(tram.distance > paused, "Tram resumes with track")
 check(tram.find_children("*", "CollisionObject3D", true, false).is_empty(), "Decoration introduces no race collider")
 var route: Array[Vector3] = Routes.points(4)
 for i in route.size():
  var phase := float(i) / route.size() * TAU
  var previous_y := 9 + sin(phase - 0.3) * 5 + sin(phase * 2) * 3
  check(absf(route[i].y - previous_y - 16) < 0.0001 and route[i].y >= 17, "Only Uithoorn raised sixteen meters above existing elevation")
 var outside: WeakRef = weakref(tram)
 holder.queue_free()
 await process_frame
 check(outside.get_ref() == null, "Track deletion cleans tram and infrastructure")
 print("BORACER TRAM: %d checks, %d failures" % [checks,failures])
 quit(0 if failures == 0 else 1)
