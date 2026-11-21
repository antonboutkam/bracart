extends RefCounted
## Additive seated reactions. Restores its own layer before the next animation sample.
var skeleton: Skeleton3D
var face: MeshInstance3D
var wink_index := -1
var base_poses: Array[Transform3D] = []
var shot_age := 2.0
var boost_weight := 0.0
var turn_weight := 0.0
var wink_weight := 0.0
const SHOT_DURATION := 1.25

func setup(model: Node3D, rig: Skeleton3D) -> void:
 skeleton = rig
 _find_face(model)

func _find_face(node: Node) -> void:
 if node is MeshInstance3D and node.mesh:
  for i in node.mesh.get_blend_shape_count():
   if str(node.mesh.get_blend_shape_name(i)) == "wink_left":
    face = node
    wink_index = i
 for child in node.get_children(): _find_face(child)

func fire() -> void:
 # Repeat fire holds a readable pose instead of snapping the neck to neutral.
 shot_age = 0.0 if shot_age >= SHOT_DURATION else minf(shot_age, 0.26)

func restore() -> void:
 if skeleton and base_poses.size() == skeleton.get_bone_count():
  for i in base_poses.size(): skeleton.set_bone_pose(i, base_poses[i])
 base_poses.clear()
 if face and wink_index >= 0: face.set_blend_shape_value(wink_index, 0)

func apply(delta: float, boosting: bool, allowed: bool) -> void:
 if not skeleton: return
 shot_age += delta
 var target := 0.0
 if allowed:
  target = smoothstep(0.0, 0.28, shot_age) * (1.0 - smoothstep(0.78, SHOT_DURATION, shot_age))
 turn_weight = target
 wink_weight = smoothstep(0.30, 0.40, shot_age) * (1.0 - smoothstep(0.66, 0.78, shot_age)) if allowed else 0.0
 boost_weight = move_toward(boost_weight, 1.0 if boosting and allowed else 0.0, delta * (5.0 if boosting and allowed else 3.0))
 for i in skeleton.get_bone_count(): base_poses.append(skeleton.get_bone_pose(i))
 # Keep steering arms/fingers at their animated transforms, independent of torso.
 var arms := {}
 for name in ["clavicle.L", "clavicle.R"]:
  var index := skeleton.find_bone(name)
  if index >= 0: arms[index] = skeleton.get_bone_global_pose(index)
 _rotate("spine", Vector3.RIGHT, deg_to_rad(12) * boost_weight)
 _rotate("chest", Vector3.RIGHT, deg_to_rad(6) * boost_weight)
 _rotate("chest", Vector3.UP, deg_to_rad(14) * turn_weight)
 _rotate("neck", Vector3.UP, deg_to_rad(36) * turn_weight)
 _rotate("head", Vector3.UP, deg_to_rad(100) * turn_weight)
 _rotate("head", Vector3.RIGHT, deg_to_rad(4) * boost_weight)
 for index in arms: _set_global(index, arms[index])
 if face and wink_index >= 0: face.set_blend_shape_value(wink_index, wink_weight)

func _rotate(name: String, axis: Vector3, angle: float) -> void:
 var index := skeleton.find_bone(name)
 if index < 0: return
 var pose := skeleton.get_bone_global_pose(index)
 pose.basis = Basis(axis, angle) * pose.basis
 _set_global(index, pose)

func _set_global(index: int, target: Transform3D) -> void:
 var parent := skeleton.get_bone_parent(index)
 var local := target
 if parent >= 0: local = skeleton.get_bone_global_pose(parent).affine_inverse() * target
 skeleton.set_bone_pose(index, local)
