extends "res://scripts/monster/arena.gd"
## Reuse deterministic falling chunks and water scoring; no debris-to-debris physics.
var piece_root: Node3D
var piece_nodes: Dictionary = {}

func rebuild_standing() -> void:
 if structure.tower_added:
  super.rebuild_standing()
 if is_instance_valid(piece_root):
  return
 piece_root = structure.instantiate_visual()
 add_child(piece_root)
 for id in structure.pieces:
  piece_nodes[id] = piece_root.find_child(id, true, false)

func impact(from: Vector3, to: Vector3, radius: float, owner_index: int, momentum: Vector3 = Vector3.ZERO) -> int:
 var count = super.impact(from, to, radius, owner_index, momentum)
 if hit_bounds.grow(radius).intersects_segment(from, to) == null and not hit_bounds.grow(radius).has_point(from) and not hit_bounds.grow(radius).has_point(to):
  return count
 for id in structure.release_pieces(from, to, radius):
  var mesh: MeshInstance3D = piece_nodes[id]
  var transform: Transform3D = piece_root.transform * mesh.transform
  var node = Node3D.new()
  add_child(node)
  node.position = transform.origin
  piece_root.remove_child(mesh)
  node.add_child(mesh)
  mesh.transform = Transform3D(transform.basis, Vector3.ZERO)
  var box: AABB = mesh.transform * mesh.get_aabb()
  var push = debris_velocity(node.position, to, momentum, maxi(1, structure.weights[id] / 120))
  chunks.append({"node":node, "velocity":push, "count":1,
   "target_count":structure.weights[id], "owner":owner_index, "lowest":box.position.y,
   "highest":box.end.y, "wet":false, "piece_id":id})
  piece_nodes.erase(id)
  count += 1
 return count

func clear_camera_space(_eye: Vector3) -> void:
 # A single named piece can contain a large part of the body. Never hide it as dust.
 pass
