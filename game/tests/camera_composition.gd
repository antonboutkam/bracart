extends SceneTree
## Projection-only moving-camera regression: no GPU is needed for Camera3D math.
const Track = preload("res://scripts/track.gd")
const CameraRig = preload("res://scripts/follow_camera.gd")
var checks: int = 0
var failures: Array[String] = []
var viewport: SubViewport
var camera: Camera3D
var min_screen = Vector2(INF, INF)
var max_screen = Vector2(-INF, -INF)
var min_distance: float = INF
var max_distance: float = 0

func check(ok: bool, title: String) -> void:
 checks += 1
 if not ok:
  if failures.size() < 12:
   push_error(title)
  failures.append(title)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 viewport = SubViewport.new()
 viewport.size = Vector2i(1280, 800)
 viewport.own_world_3d = true
 root.add_child(viewport)
 camera = Camera3D.new()
 camera.current = true
 viewport.add_child(camera)
 await process_frame
 var rig = CameraRig.new(camera)
 for world in 6:
  var track = Track.new()
  viewport.add_child(track)
  track.build(world)
  for lane_fraction in [-0.85, 0.0, 0.85, 2.0]:
   for motion in [true, false]:
    var kart = {"progress":0.0, "lateral":0.0 if lane_fraction == 2.0 else track.width * lane_fraction, "speed":56.0, "jump_height":0.0, "boost_time":3.0}
    rig.reset()
    rig.update(track, kart, 0, motion, true)
    var render_clock = 0.0
    var physics_clock = 0.0
    var frames = ceili((track.length + 12) / kart.speed * 100)
    for frame in frames:
     render_clock += 0.01
     while physics_clock + 1.0 / 60 <= render_clock + 0.000001:
      physics_clock += 1.0 / 60
      kart.progress += kart.speed / 60
      if lane_fraction == 2.0:
       kart.lateral = track.width * 0.85 * sin(physics_clock * 1.4)
      # Include a real-height jump once per quarter lap, on every lane.
      var jump_t = fposmod(physics_clock, 4.0)
      kart.jump_height = maxf(0, 6.3 * jump_t - 8 * jump_t * jump_t) if jump_t < 0.8 else 0
     rig.update(track, kart, 0.01, motion)
     var kart_position: Vector3 = track.position_at(kart.progress, kart.lateral, kart.jump_height + 0.04)
     var distance = camera.position.distance_to(kart_position)
     min_distance = minf(min_distance, distance)
     max_distance = maxf(max_distance, distance)
     var label = "world%d lane%.2f motion%s frame%d" % [world, lane_fraction, str(motion), frame]
     check(camera.transform.is_finite() and absf(camera.basis.determinant() - 1) < 0.001, label + ": finite orthonormal moving camera")
     check(distance > 4.0 and distance < 9.0, label + ": bounded following distance %.3f" % distance)
     if not motion:
      check(is_equal_approx(camera.fov, 72), label + ": calm camera keeps fixed FOV")
     for height in [0.55, 1.0]:
      var point = track.position_at(kart.progress, kart.lateral, kart.jump_height + height)
      var screen: Vector2 = camera.unproject_position(point) / Vector2(viewport.size)
      min_screen = min_screen.min(screen)
      max_screen = max_screen.max(screen)
      check(not camera.is_position_behind(point), label + ": player remains in front of camera")
      check(screen.x > 0.26 and screen.x < 0.74 and screen.y > 0.22 and screen.y < 0.79, label + ": player head/center stays clear of corner HUD (%.3f, %.3f)" % [screen.x, screen.y])
  track.queue_free()
  await process_frame
 print("CAMERA COMPOSITION distance=%.3f..%.3fm head/center normalized_screen=%s..%s" % [min_distance, max_distance, min_screen, max_screen])
 camera.queue_free()
 viewport.queue_free()
 await process_frame
 print("CAMERA COMPOSITION: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
