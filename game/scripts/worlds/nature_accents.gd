extends RefCounted
## Small, supported CC0 accents. Existing primitive trees remain the fallback.
const DIRECTORY = "res://assets/third_party/kenney/nature/"
const MODELS = ["tree_oak", "tree_default", "plant_bush", "flower_redA"]
const HEIGHTS = [4.5, 4.5, 1.2, 1.1]

static func build(track: Node3D, clusters: Array[Dictionary]) -> Node3D:
 if track.world_index not in [3, 4] or clusters.is_empty(): return null
 if track.has_node("NatureAccents"): return track.get_node("NatureAccents")
 var root = Node3D.new()
 root.name = "NatureAccents"
 var records: Array[Dictionary] = []
 for model_index in MODELS.size():
  var path = DIRECTORY+MODELS[model_index]+".glb"
  if not ResourceLoader.exists(path): continue
  var scene = load(path) as PackedScene
  if scene == null: continue
  var prototype = scene.instantiate() as Node3D
  if prototype == null: continue
  var geometry: Array[Dictionary] = []
  _geometry(prototype, Transform3D.IDENTITY, geometry)
  # These pinned original GLBs each contain exactly one static mesh.
  if geometry.size()!=1:
   prototype.free()
   continue
  var source_mesh: Mesh = geometry[0].mesh
  var source_transform: Transform3D = geometry[0].transform
  var bounds: AABB = source_transform*source_mesh.get_aabb()
  var mesh = source_mesh.duplicate() as Mesh
  for surface in mesh.get_surface_count():
   var material = mesh.surface_get_material(surface)
   if material is BaseMaterial3D:
    material = material.duplicate()
    material.cull_mode = BaseMaterial3D.CULL_BACK
    material.roughness = 0.85
    mesh.surface_set_material(surface, material)
  var factor: float = HEIGHTS[model_index]/bounds.size.y
  var center = bounds.get_center()
  var normalization = Transform3D(Basis.from_scale(Vector3.ONE*factor),Vector3(-center.x,-bounds.position.y,-center.z)*factor)
  var transforms: Array[Transform3D] = []
  var total_bounds = AABB()
  for repeat in 3:
   var cluster_index = repeat*MODELS.size()+model_index
   if cluster_index>=clusters.size(): break
   var cluster: Dictionary = clusters[cluster_index]
   # Unused rear strip: outside walkers, old tree, bicycle rack and parked car.
   var placement = Transform3D(Basis(Vector3.UP,repeat*0.8),Vector3(-2.8,0,3.8))
   var transform: Transform3D = cluster.transform*placement*normalization*source_transform
   var actual_bounds: AABB = transform*mesh.get_aabb()
   # Keep the complete asset footprint on the existing 22 x 12 supported deck.
   var local_bounds: AABB = (placement*normalization*source_transform)*mesh.get_aabb()
   if local_bounds.position.x < -10.9 or local_bounds.end.x > 10.9 or local_bounds.position.z < -5.9 or local_bounds.end.z > 5.9: continue
   total_bounds = actual_bounds if transforms.is_empty() else total_bounds.merge(actual_bounds)
   transforms.append(transform)
   records.append({"model":MODELS[model_index],"source":path,"cluster_id":cluster.id,"transform":transform,"bounds":actual_bounds,"support_y":cluster.floor_y,"cluster_transform":cluster.transform,"height":HEIGHTS[model_index]})
  prototype.free()
  if transforms.is_empty(): continue
  var instances = MultiMesh.new()
  instances.transform_format = MultiMesh.TRANSFORM_3D
  instances.mesh = mesh
  instances.instance_count = transforms.size()
  instances.custom_aabb = total_bounds
  for index in transforms.size(): instances.set_instance_transform(index,transforms[index])
  var node = MultiMeshInstance3D.new()
  node.name = MODELS[model_index]
  node.multimesh = instances
  node.visibility_range_end = 350.0
  node.visibility_range_end_margin = 25.0
  node.set_meta("instance_transforms",transforms)
  node.set_meta("source",path)
  root.add_child(node)
 if records.is_empty():
  root.free()
  return null
 root.set_meta("instances",records)
 root.set_meta("source_license","CC0-1.0")
 root.set_meta("world",track.world_index)
 track.add_child(root)
 return root

static func _geometry(node: Node3D, parent_transform: Transform3D, result: Array[Dictionary]) -> void:
 var transform = parent_transform*node.transform
 if node is MeshInstance3D and node.mesh!=null:
  result.append({"mesh":node.mesh,"transform":transform})
 for child in node.get_children():
  if child is Node3D: _geometry(child,transform,result)
