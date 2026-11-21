extends Node3D
const DriverReactions = preload("res://scripts/driver_reactions.gd")
var reactions = DriverReactions.new()
const Geo = preload("res://scripts/geometry.gd")
const Catalog = preload("res://scripts/catalog.gd")
var vehicle_index: int
var driver: String
var progress: float = 0
var lateral: float = 0
var speed: float = 0
var target_lane: float = 0
var ai: bool = false
var racer_name: String
var jump_height: float = 0
var jump_velocity: float = 0
var boost: float = 100
var shield_time: float = 0
var magnet_time: float = 0
var cannon_time: float = 0
var stun_time: float = 0
var boost_time: float = 0
var hit_cooldown: float = 0
var power: String = ""
var finish_time: float = -1
var visual: Node3D
var wheel_nodes: Array[Node3D] = []
var flame: MeshInstance3D
var shield_mesh: MeshInstance3D
var cannons: Array[Node3D] = []
var steering: float = 0
var animation: AnimationPlayer
var driver_mount: Node3D
var driver_model: Node3D
var driver_seat: Vector3 = Vector3(0, 0.32, 0.12)
var clips: Dictionary = {}
var driver_state: String = ""
var wheel_radii: Array[float] = []
var wheel_rest: Array[Basis] = []
var wheel_spin: float = 0
var magnet_ring: MeshInstance3D
var effect_time: float = 0
var hit_reaction: float = 0
var shield_flash: float = 0
var smoothed_steering: float = 0
var vehicle_scale: float = 1
# Fallback for models without a named humanoid skeleton.
const DRIVER_HIP_HEIGHT = 0.44
var driver_hip_height: float = DRIVER_HIP_HEIGHT
static var normalized_bounds: Dictionary = {}

func setup(index: int, character_id: String, computer: bool) -> void:
 vehicle_index = index
 driver = character_id
 ai = computer
 racer_name = character_id.capitalize()
 visual = Node3D.new()
 add_child(visual)
 var model_path = "res://assets/models/%s.glb" % Catalog.VEHICLES[index].id
 if ResourceLoader.exists(model_path):
  var scene: PackedScene = load(model_path)
  var model: Node3D = scene.instantiate()
  visual.add_child(model)
  var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/manifest.json"))
  var asset: Dictionary = manifest.get(Catalog.VEHICLES[index].id, {})
  # Legacy raw exports use Z-up with different forward axes. Improved GLBs use Y-up.
  var legacy: bool = not "-improved" in str(asset.get("source", ""))
  if legacy:
   if index == 0:
    model.basis = Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP)
   else:
    model.basis = Basis(Vector3.FORWARD, Vector3.LEFT, Vector3.UP)
  # Old GLBs vary in scale and origin. Normalize the copy within its wrapper.
  if not normalized_bounds.has(model_path):
   normalized_bounds[model_path] = _bounds(model, Transform3D.IDENTITY)
  var bounds: AABB = normalized_bounds[model_path]
  var factor = 1.95 / maxf(bounds.size.z, 0.01)
  vehicle_scale = factor
  model.scale *= factor
  model.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * factor
  var seat = _find_part(model, "Seat_Cushion")
  if seat:
   # Cushion surface is more reliable than centering the driver on the body AABB.
   var seat_transform = _relative_transform(seat, visual)
   driver_seat = seat_transform.origin
   driver_seat.y += 0.033 * factor
  else:
   # Toxic's static export merges the seat; this is its authored cushion surface.
   driver_seat = model.transform * Vector3(0, 0.317, 0.105)
  _collect_wheels(model)
  _fallback_materials(model, Color(Catalog.VEHICLES[index].color), int(asset.get("materials", 1)) == 0)
 else:
  Geo.ball(visual, Vector3(0, 0.5, 0), Vector3(0.9, 0.7, 2), Color(Catalog.VEHICLES[index].color))
 _add_side_mirrors()
 var driver_path = "res://assets/models/%s.glb" % character_id
 if ResourceLoader.exists(driver_path):
  driver_mount = Node3D.new()
  visual.add_child(driver_mount)
  driver_mount.position = driver_seat
  driver_model = load(driver_path).instantiate()
  driver_mount.add_child(driver_model)
  # Keep the hips on the seat even when differently sized exports are normalized.
  var driver_scale = clampf(vehicle_scale * 0.92, 0.74, 1.04)
  var skeleton = _find_skeleton(driver_model)
  if skeleton:
   var hip = skeleton.find_bone("hips")
   if hip >= 0:
    driver_hip_height = driver_model.to_local(skeleton.to_global(skeleton.get_bone_global_rest(hip).origin)).y
  driver_model.scale = Vector3.ONE * driver_scale
  driver_model.position.y = -driver_hip_height * driver_scale
  reactions.setup(driver_model, skeleton)
  animation = _find_animation(driver_model)
  if animation:
   animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
   _prepare_driver_clips()
   _set_driver_state("sit")
 var shield_shape = SphereMesh.new()
 shield_shape.radial_segments = 20
 shield_shape.rings = 10
 shield_mesh = Geo.mesh(visual, shield_shape, Vector3(0, 0.65, 0), Color(0.3, 0.85, 1, 0.23))
 shield_mesh.scale = Vector3(1.7, 1.8, 2.8)
 shield_mesh.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 shield_mesh.visible = false
 flame = Geo.ball(visual, Vector3(0, 0.35, 1.02), Vector3(0.22, 0.22, 1), Color("ffb750"))
 flame.material_override = Geo.material(Color("ffb750"), 1.5)
 flame.visible = false
 var ring_shape = TorusMesh.new()
 ring_shape.inner_radius = 0.78
 ring_shape.outer_radius = 0.81
 ring_shape.rings = 24
 ring_shape.ring_segments = 6
 magnet_ring = Geo.mesh(visual, ring_shape, Vector3(0, 0.26, 0), Color("ffe07a"))
 magnet_ring.material_override = Geo.material(Color("ffe07a"), 1.4)
 magnet_ring.scale = Vector3(1.0, 1.0, 1.5)
 magnet_ring.visible = false
 for side in [-1, 1]:
  var gun = Geo.cylinder(visual, Vector3(side * 0.65, 0.65, -0.3), 0.1, 1, Color("51637e"))
  gun.rotation.x = PI / 2
  gun.visible = false
  cannons.append(gun)

func _add_side_mirrors() -> void:
 # Runtime wrapper coordinates are normalized metres, independent of GLB axes.
 var mounts = Node3D.new()
 mounts.name = "SideMirrors"
 visual.add_child(mounts)
 var height: float = maxf(driver_seat.y+0.38,0.72)
 for side in [-1,1]:
  var mirror = Node3D.new()
  mirror.name = "LeftMirror" if side < 0 else "RightMirror"
  mounts.add_child(mirror)
  Geo.beam(mirror,Vector3(side*0.37,height-0.22,-0.38),Vector3(side*0.73,height,-0.5),0.025,Color("283b50"))
  var housing = Geo.ball(mirror,Vector3(side*0.76,height,-0.5),Vector3(0.34,0.23,0.09),Color("233548"))
  housing.name = "Housing"
  var glass = Geo.ball(mirror,Vector3(side*0.76,height,-0.447),Vector3(0.285,0.18,0.025),Color("b6e2ed"))
  glass.name = "Glass"
  glass.material_override.metallic = 0.82
  glass.material_override.roughness = 0.12

func _bounds(node: Node3D, parent_transform: Transform3D) -> AABB:
 var t = parent_transform * node.transform
 var result = AABB()
 if node is MeshInstance3D:
  # Rotating a mesh AABB twice inflates wheel bounds and lifts the whole kart.
  # Transform actual vertices once; cache the complete result per model above.
  var first = true
  for surface in node.mesh.get_surface_count():
   var vertices: PackedVector3Array = node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
   for vertex in vertices:
    var point = t * vertex
    if first:
     result = AABB(point, Vector3.ZERO)
     first = false
    else:
     result = result.expand(point)
 for child in node.get_children():
  if child is Node3D:
   var sub = _bounds(child, t)
   if sub.size != Vector3.ZERO:
    result = sub if result.size == Vector3.ZERO else result.merge(sub)
 return result

func _fallback_materials(node: Node, color: Color, force: bool = false) -> void:
 if node is MeshInstance3D:
  for surface in node.mesh.get_surface_count():
   if force or node.get_active_material(surface) == null:
    var paint = color
    var part = str(node.name).to_lower()
    if "gold" in part or "yellow" in part:
     paint = Color("ffd064")
    elif "pink" in part:
     paint = Color("ef85ba")
    elif "turquoise" in part or "blue" in part:
     paint = Color("2eb8cd")
    elif "red" in part:
     paint = Color("e74c53")
    elif "white" in part or "chrome" in part or "spoke" in part or "rim" in part or "hub" in part:
     paint = Color("d6e5e5")
    elif "tire" in part or "rubber" in part or "dark" in part or "seat" in part or "frame" in part or "rail" in part or "wheel" in part:
     paint = Color("233344")
    elif "light" in part or "glow" in part or "lens" in part:
     paint = Color("ffe8a1")
    node.set_surface_override_material(surface, Geo.material(paint))
 for child in node.get_children():
  _fallback_materials(child, color, force)

func _collect_wheels(node: Node) -> void:
 if node is Node3D and str(node.name).begins_with("Wheel_") and not node is MeshInstance3D:
  wheel_nodes.append(node)
  wheel_rest.append(node.basis)
  wheel_radii.append(maxf(_bounds(node, Transform3D.IDENTITY).size.y * vehicle_scale * 0.5, 0.05))
  return
 for child in node.get_children():
  _collect_wheels(child)

func _find_part(node: Node, part_name: String) -> Node3D:
 if node is Node3D and str(node.name).begins_with(part_name):
  return node
 for child in node.get_children():
  var found = _find_part(child, part_name)
  if found:
   return found
 return null

func _relative_transform(node: Node3D, ancestor: Node3D) -> Transform3D:
 var result = node.transform
 var parent = node.get_parent()
 while parent != ancestor and parent is Node3D:
  result = parent.transform * result
  parent = parent.get_parent()
 return result

func _prepare_driver_clips() -> void:
 for clip in animation.get_animation_list():
  for key in ["Kart_Sit", "Kart_Steer", "Jump", "Cheer"]:
   if str(clip).ends_with(key):
    clips[key] = clip
 if not clips.has("Kart_Sit"):
  return
 # Duplicate imported resources: never change shared GLB animation libraries.
 var library = AnimationLibrary.new()
 var seated: Animation = animation.get_animation(clips.Kart_Sit)
 for pair in [["sit", "Kart_Sit"], ["steer", "Kart_Steer"], ["jump", "Jump"], ["finish", "Cheer"]]:
  if not clips.has(pair[1]):
   continue
  var source: Animation = animation.get_animation(clips[pair[1]])
  var adjusted: Animation = source.duplicate(true)
  if pair[0] in ["jump", "finish"]:
   # Jump/Cheer were authored standing. Preserve the seated hip/leg/finger tracks.
   for t in adjusted.get_track_count():
    var path = str(adjusted.track_get_path(t)).to_lower()
    var upper_body = "upper_arm" in path or "forearm" in path or "chest" in path or "head" in path or "spine" in path or "cape_" in path
    if upper_body:
     continue
    var seat_track = seated.find_track(adjusted.track_get_path(t), adjusted.track_get_type(t))
    if seat_track < 0 or seated.track_get_key_count(seat_track) == 0:
     continue
    var value = seated.track_get_key_value(seat_track, 0)
    for k in adjusted.track_get_key_count(t):
     adjusted.track_set_key_value(t, k, value)
  adjusted.loop_mode = Animation.LOOP_LINEAR if pair[0] in ["sit", "finish"] else Animation.LOOP_NONE
  library.add_animation(pair[0], adjusted)
 animation.add_animation_library("racing", library)

func _set_driver_state(state: String) -> void:
 if not animation or state == driver_state:
  return
 var clip = "racing/" + state
 if not animation.has_animation(clip):
  clip = "racing/sit"
 if not animation.has_animation(clip):
  return
 driver_state = state
 animation.speed_scale = 0.0 if state == "steer" else 1.0
 animation.play(clip, 0.12)
 animation.advance(0)

func _find_skeleton(node: Node) -> Skeleton3D:
 if node is Skeleton3D:
  return node
 for child in node.get_children():
  var found = _find_skeleton(child)
  if found:
   return found
 return null

func _find_animation(node: Node) -> AnimationPlayer:
 if node is AnimationPlayer:
  return node
 for child in node.get_children():
  var found = _find_animation(child)
  if found:
   return found
 return null

func update_visual(track, delta: float) -> void:
 var f: Transform3D = track.frame(progress)
 transform = f
 position = track.position_at(progress, lateral, jump_height + 0.04)
 update_effects(delta)

func update_effects(delta: float) -> void:
 # Called independently by garage previews as well as the race renderer.
 effect_time += delta
 hit_reaction = maxf(0, hit_reaction - delta)
 shield_flash = maxf(0, shield_flash - delta)
 smoothed_steering = move_toward(smoothed_steering, steering, delta * 5.0)
 visual.rotation.y = -smoothed_steering * 0.18
 visual.rotation.z = -smoothed_steering * minf(speed / 35.0, 1) * 0.1
 visual.rotation.x = clampf(-jump_velocity * 0.016, -0.14, 0.14)
 if hit_reaction > 0:
  visual.rotation.z += sin(effect_time * 38) * 0.11 * hit_reaction
 wheel_spin = fmod(wheel_spin + speed * delta, TAU * 100)
 for i in wheel_nodes.size():
  var front_angle = -smoothed_steering * 0.32 if "Front" in str(wheel_nodes[i].name) else 0.0
  wheel_nodes[i].basis = wheel_rest[i] * Basis(Vector3.UP, front_angle) * Basis(Vector3.RIGHT, -wheel_spin / wheel_radii[i])
 flame.visible = speed > 5 and finish_time < 0
 flame.scale.z = (1.8 if boost_time > 0 else 0.5) + (sin(effect_time * 37) + 1) * 0.15
 shield_mesh.visible = shield_time > 0 or shield_flash > 0
 var pulse = 1.0 + sin(effect_time * 5) * 0.025
 shield_mesh.scale = Vector3(1.7, 1.8, 2.8) * pulse * (1.15 if shield_flash > 0 else 1.0)
 magnet_ring.visible = magnet_time > 0
 magnet_ring.rotation.y = effect_time * 1.3
 magnet_ring.position.y = 0.28 + sin(effect_time * 4) * 0.09
 for gun in cannons:
  gun.visible = cannon_time > 0
 if driver_mount:
  reactions.restore()
  driver_mount.rotation.x = -minf(hit_reaction, 0.4) * 0.36
  driver_mount.rotation.z = -smoothed_steering * 0.045
  if finish_time >= 0:
   _set_driver_state("finish")
  elif jump_height > 0.08:
   _set_driver_state("jump")
  elif absf(smoothed_steering) > 0.07 and speed > 1:
   _set_driver_state("steer")
   if animation and driver_state == "steer":
    # Sample matching left/right pose instead of cycling independently of input.
    var duration = animation.current_animation_length
    var phase = 0.25 if smoothed_steering < 0 else 0.75
    animation.seek(duration * lerpf(0.5, phase, absf(smoothed_steering)), true)
  else:
   _set_driver_state("sit")
  if animation: animation.advance(delta)
  reactions.apply(delta, boost_time > 0, finish_time < 0 and jump_height <= 0.08)

func react_to_shot() -> void:
 reactions.fire()

func take_hit() -> bool:
 if hit_cooldown > 0 or finish_time >= 0:
  return false
 hit_cooldown = 1.4
 if shield_time > 0:
  shield_time = 0
  shield_flash = 0.3
  return false
 hit_reaction = 0.8
 stun_time = 1.1
 speed *= 0.42
 return true
