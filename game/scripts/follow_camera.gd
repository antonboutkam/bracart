extends RefCounted
## Track-relative follow position keeps the view clear on crests and tight turns.
var camera: Camera3D
var filtered_up: Vector3 = Vector3.UP
var elapsed: float = 0
var boosting: float = 0
var previous_target: Vector3 = Vector3.ZERO
var has_target: bool = false

func _init(target: Camera3D) -> void:
 camera = target

func reset() -> void:
 elapsed = 0
 boosting = 0
 filtered_up = Vector3.UP
 has_target = false

func update(track, kart, delta: float, motion: bool, snap: bool = false) -> void:
 if track.active_course() != null:
  _kitchen_camera(track,kart,delta,motion,snap)
  return
 elapsed += delta
 var speed_ratio = clampf(float(kart.speed) / 48, 0, 1)
 var back = lerpf(4.8, 6.3, speed_ratio)
 var height = lerpf(2.3, 2.9, speed_ratio)
 var lookahead = lerpf(9, 16, speed_ratio)
 var f: Transform3D = track.frame(kart.progress)
 var jump_lift = minf(1, float(kart.jump_height) * 0.35)
 var desired: Vector3 = track.position_at(kart.progress - back, kart.lateral * 0.82, height + jump_lift)
 var kart_position: Vector3 = track.position_at(kart.progress, kart.lateral, kart.jump_height + 0.04)
 var distant_target: Vector3 = track.position_at(kart.progress + lookahead, kart.lateral * 0.75, 0.9)
 # Modest anticipation keeps the player centered even in tight corners.
 var target: Vector3 = (kart_position + f.basis.y * 0.75).lerp(distant_target, 0.4)
 # Street-level landmarks need a little more horizon above the racer. Retain
 # the ordinary follow rig and steering; only the ground course looks higher.
 if track.get("ground_course") != null:
  var grade = maxf(absf(f.basis.z.y),absf(track.frame(kart.progress+20).basis.z.y))
  target += f.basis.y*0.5*(1.0-smoothstep(0.04,0.2,grade))
 var travel = kart_position - previous_target if has_target else Vector3.ZERO
 if travel.length() > 20:
  snap = true
 previous_target = kart_position
 has_target = true
 var damping = 1.0 if snap else 1 - exp(-delta * 9)
 # Carry the camera with the kart before damping the relative offset. Without
 # this feed-forward, speed adds metres of lag and corners push the kart into HUD.
 camera.position = desired if snap else (camera.position + travel).lerp(desired, damping)
 # Almost parallel up vectors on a flat street make slerp's tiny rotation axis
 # numerically unstable. Normalized lerp has the same limit without that axis.
 if snap:
  filtered_up = f.basis.y
 elif filtered_up.dot(f.basis.y)>0.9995:
  filtered_up = filtered_up.lerp(f.basis.y,minf(1,delta*5)).normalized()
 else:
  filtered_up = filtered_up.slerp(f.basis.y,minf(1,delta*5)).normalized()
 # A camera interpolating across a bend must stay above the nearby drivable surface.
 var nearest: float = track.curve.get_closest_offset(camera.position)
 var local: Vector3 = track.frame(nearest).affine_inverse() * camera.position
 var safe_height: float = track.bowl(local.x) + 0.75
 if absf(local.x) < track.width + 1 and local.y < safe_height:
  camera.position += track.frame(nearest).basis.y * (safe_height - local.y)
 var desired_transform = camera.transform.looking_at(target, filtered_up)
 if snap:
  camera.basis = desired_transform.basis
 else:
  camera.basis = camera.basis.slerp(desired_transform.basis, 1 - exp(-delta * 11)).orthonormalized()
 var boost_target = 1.0 if kart.boost_time > 0 and motion else 0.0
 boosting = boost_target if snap else lerpf(boosting, boost_target, minf(1, delta * 4))
 camera.fov = 72 + (speed_ratio * 3 + boosting * 7 if motion else 0)

func _kitchen_camera(track, kart, delta: float, motion: bool, snap: bool) -> void:
 elapsed += delta
 var f: Transform3D = track.frame(kart.progress)
 var feature: Dictionary = track.active_course().feature_at(kart.progress)
 var looping: bool = feature.get("id","") in ["orange_loop","loop","corkscrew"]
 var back: float = 4.3 if looping else 4.9
 var height: float = 3.0 if looping else 2.7
 var kart_position: Vector3 = track.position_at(kart.progress,kart.lateral,kart.jump_height+0.04)
 var desired: Vector3 = kart_position+f.basis.z*back+f.basis.y*height
 var target: Vector3 = kart_position+f.basis.y*0.65-f.basis.z*3
 var travel: Vector3 = kart_position-previous_target if has_target else Vector3.ZERO
 if travel.length() > 20: snap = true
 previous_target = kart_position
 has_target = true
 var blend: float = 1 if snap else 1-exp(-delta*12)
 camera.position = desired if snap else (camera.position+travel).lerp(desired,blend)
 if looping:
  # Current progress is authoritative; closest_offset can pick the wrong loop branch.
  var local: Vector3 = f.affine_inverse()*camera.position
  local.y = clampf(local.y,1.5,3.4)
  local.z = clampf(local.z,3.4,5.0)
  camera.position = f*local
 # A vertical bend can rise toward the camera behind the rider. Use nearby
 # actual course arc frames, never the old flat base Curve3D offset mapping.
 var nearest_frame: Transform3D = f
 var nearest_distance: float = INF
 for sample in 65:
  var candidate: Transform3D = track.frame(float(kart.progress)-8+sample*0.25)
  var distance: float = candidate.origin.distance_squared_to(camera.position)
  if distance < nearest_distance:
   nearest_distance = distance
   nearest_frame = candidate
 var surface_local: Vector3 = nearest_frame.affine_inverse()*camera.position
 var safe_height: float = track.bowl(surface_local.x)+0.78
 if absf(surface_local.x) < track.width+1 and surface_local.y < safe_height:
  camera.position += nearest_frame.basis.y*(safe_height-surface_local.y)
 filtered_up = f.basis.y
 var orientation: Transform3D = camera.transform.looking_at(target,filtered_up)
 camera.basis = orientation.basis if snap else camera.basis.slerp(orientation.basis,blend).orthonormalized()
 var boost_target: float = 1 if kart.boost_time > 0 and motion else 0
 boosting = boost_target if snap else lerpf(boosting,boost_target,minf(1,delta*4))
 camera.fov = 72+(clampf(float(kart.speed)/48,0,1)*3+boosting*7 if motion else 0)
