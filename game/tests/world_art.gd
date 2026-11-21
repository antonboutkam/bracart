extends SceneTree
## Art contracts: bounded static detail, genuine surface maps and no gameplay blockers.
const Track = preload("res://scripts/track.gd")
const Art = preload("res://scripts/worlds/world_art.gd")
var checks = 0
var failures: Array[String] = []
func check(ok: bool, title: String) -> void:
 checks += 1
 if not ok:
  failures.append(title)
  push_error(title)
func _initialize() -> void:
 call_deferred("run")
func count_nodes(node: Node, kind: String) -> int:
 var count = 1 if node.is_class(kind) else 0
 for child in node.get_children(): count += count_nodes(child,kind)
 return count
func check_soft_surfaces(node: Node) -> void:
 if node is MeshInstance3D and node.get_meta("scenery_semantic","") in ["cloud","steam"]:
  check(node.material_override.albedo_texture == null,"clouds and steam remain soft, without masonry grain")
  check(node.material_override.roughness > 0.9,"clouds and steam remain matte")
 for child in node.get_children(): check_soft_surfaces(child)
func run() -> void:
 for kind in ["wood","brick","grass","stone","roof","metal","paper","solar"]:
  var mat = Art.material(kind)
  check(mat.albedo_texture != null,kind + " has a real texture")
  check(mat.uv1_triplanar and mat.uv1_world_triplanar,kind + " has continuous world projection")
  check(mat.roughness > 0.1 and mat.roughness <= 1,kind + " sensible surface roughness")
  if kind in ["grass","stone","roof","metal","paper","solar"]:
   check(mat.normal_enabled and mat.normal_texture != null,kind + " has surface relief")
 for world in 6:
  var track = Track.new()
  root.add_child(track)
  track.build(world)
  check(track.get_meta("world_art_version",0) == 3,"world %d art is installed" % world)
  check(track.has_node("LayeredWorldBackground"),"world %d has dimensional background" % world)
  check(count_nodes(track,"CollisionObject3D") == 0,"world %d art creates no collision blockers" % world)
  check(count_nodes(track,"Node") < 4200,"world %d bounded art node count" % world)
  check_soft_surfaces(track)
  var bg = track.get_node("LayeredWorldBackground")
  if world in [3,4]:
   check(bg.get_child_count()>=4,"Dutch worlds retain existing nearby banks")
   check(track.has_node("DutchHorizons"),"Dutch world replaces old hills with dedicated horizon")
   var horizon = track.get_node("DutchHorizons")
   check(horizon.get_meta("geometry_records",[]).size()>100,"Dutch horizon has substantive field/dune geometry")
   var submitted = 0
   for batch in horizon.get_children():
    if batch is MultiMeshInstance3D: submitted+=batch.get_meta("instance_transforms",[]).size()
   check(submitted>100,"Dutch horizon shapes are genuinely submitted in batches")
  else:
   check(bg.get_child_count() >= 40,"world %d has layered depth beyond the road" % world)
  if world == 1: check(count_nodes(track,"MultiMeshInstance3D") >= 30,"city repeated windows are batched")
  if world == 5:
   var tabletop = false
   for child in track.get_children():
    if child is MeshInstance3D and child.mesh is BoxMesh and child.mesh.size.x == 235:
     tabletop = child.get_meta("world_material","") == "wood"
   check(tabletop,"kitchen real wood covers the driving surface")
  var env = Environment.new()
  var sun = DirectionalLight3D.new()
  Art.setup_environment(env,sun,world)
  check(env.fog_enabled and env.fog_density < 0.002,"world %d subtle depth atmosphere" % world)
  sun.free()
  track.queue_free()
  await process_frame
 print("WORLD ART: %d checks, %d failures" % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
