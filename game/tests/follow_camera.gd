extends SceneTree
const Track = preload("res://scripts/track.gd")
const CameraRig = preload("res://scripts/follow_camera.gd")
var checks: int = 0
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
 checks += 1
 if not condition:
  failures.append(message)
  push_error(message)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var camera = Camera3D.new()
 root.add_child(camera)
 var rig = CameraRig.new(camera)
 for world in 6:
  var track = Track.new()
  root.add_child(track)
  track.build(world)
  var kart = {"progress":0.0, "lateral":0.0, "speed":44.0, "jump_height":0.0, "boost_time":0.0}
  for i in 80:
   kart.progress = track.length * i / 79
   kart.lateral = sin(i * 0.3) * (track.width - 1)
   rig.update(track, kart, 1.0 / 60, true, true)
   check(camera.position.is_finite() and camera.basis.is_finite(), "camera is finite around world %d" % world)
   check(absf(camera.basis.determinant() - 1) < 0.001, "camera stays orthonormal")
   var nearest: float = track.curve.get_closest_offset(camera.position)
   if world == 5:
    # Base Curve3D offsets are not KitchenCourse arc lengths. Query the actual
    # complete 3D course, including both separated sides of the vertical loop.
    var best_distance: float = INF
    for sample in int(ceil(track.length / 0.2)):
     var progress: float = sample * 0.2
     var distance: float = track.frame(progress).origin.distance_squared_to(camera.position)
     if distance < best_distance:
      best_distance = distance
      nearest = progress
   var local: Vector3 = track.frame(nearest).affine_inverse() * camera.position
   check(absf(local.x) >= track.width + 1 or local.y >= track.bowl(local.x) + 0.74, "camera stays above nearby track surface world=%d i=%d progress=%.3f nearest=%.3f local=%s camera=%s" % [world,i,kart.progress,nearest,local,camera.position])
  kart.boost_time = 3
  rig.update(track, kart, 0.1, false, true)
  check(is_equal_approx(camera.fov, 72), "calm camera disables speed/boost FOV motion")
  rig.update(track, kart, 0.1, true, true)
  check(camera.fov > 78, "boost camera has wider useful view")
  kart.progress = track.length - 0.1
  rig.update(track, kart, 0, true, true)
  var old_pos: Vector3 = camera.position
  var old_forward = -camera.basis.z
  kart.progress += 0.2
  rig.update(track, kart, 1.0 / 60, true)
  check(camera.position.distance_to(old_pos) < 1, "camera doesn't teleport at finish seam")
  check(old_forward.dot(-camera.basis.z) > 0.95, "camera doesn't flip at finish seam")
  track.queue_free()
  await process_frame
 camera.queue_free()
 await process_frame
 print("BORACER FOLLOW CAMERA: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
