extends Node3D
const Geo = preload("res://scripts/geometry.gd")
const Structure = preload("res://scripts/monster/structure.gd")
var structure = Structure.new()
var standing: Node3D
var chunks: Array = []
var splashes: Array = []
var submerged: int = 0
var brick_mesh: BoxMesh
var stud_mesh: CylinderMesh
var brick_material: StandardMaterial3D
var hit_bounds: AABB
const COURSE_START = 190.0

func prepare_blocks() -> void:
 brick_mesh = BoxMesh.new()
 brick_mesh.size = Vector3.ONE * 1.23 * Structure.SIZE_MULTIPLIER
 stud_mesh = CylinderMesh.new()
 stud_mesh.top_radius = 0.27 * Structure.SIZE_MULTIPLIER
 stud_mesh.bottom_radius = stud_mesh.top_radius
 stud_mesh.height = 0.15 * Structure.SIZE_MULTIPLIER
 stud_mesh.radial_segments = 8
 brick_material = Geo.material(Color.WHITE)
 brick_material.vertex_color_use_as_albedo = true
 brick_material.roughness = 0.32

func build(model = null) -> void:
 prepare_blocks()
 Geo.box(self, Vector3(0, -2, -90), Vector3(900, 3.8, 1100), Color("177f9d"))
 Geo.box(self, Vector3(0, 40, 208), Vector3(34, 84, 36), Color("687e83"))
 # 130 m horizontal descent, then a 60 m rising ramp. Continuous surface and tangent.
 for i in 95:
  var z1 = COURSE_START - i * 2.0
  var z2 = z1 - 2.0
  var a = ramp_position(z1)
  var b = ramp_position(z2)
  var piece = Geo.box(self, (a + b) * 0.5 - Vector3(0, 0.4, 0), Vector3(13, 0.8, a.distance_to(b) + 0.08), Color("284564"))
  piece.rotation.x = atan2(b.y - a.y, a.z - b.z)
  for side in [-1, 1]:
   Geo.beam(self, a + Vector3(side * 6.6, 0.5, 0), b + Vector3(side * 6.6, 0.5, 0), 0.16, Color("ffc857"))
  if i % 5 == 0:
   Geo.box(self, a + Vector3(0, 0.06, 0), Vector3(0.25, 0.08, 1.1), Color("fff1cf"))
   for side in [-1, 1]:
    Geo.beam(self, Vector3(side * 5, 0, a.z), a + Vector3(side * 5, -0.5, 0), 0.4, Color("5a8291"))
 Geo.box(self, Vector3(0, 22.1, 0), Vector3(13.5, 0.25, 1.2), Color("ffc857"))
 Geo.text(self, "MONSTERBREKER", Vector3(0, 88, 200), 90)
 for z in [150, 100, 50]:
  var sign_position = ramp_position(z) + Vector3(10, 3, 0)
  Geo.text(self, "%d m" % z, sign_position, 70)
 # Distant rocks and buoys make the water scale and landing zone readable.
 for i in 15:
  var side = -1 if i % 2 == 0 else 1
  Geo.ball(self, Vector3(side * (78 + i * 4), 1, -30 - i * 18), Vector3(22, 17, 25), Color("437c86"))
 for i in 12:
  for side in [-1, 1]:
   Geo.ball(self, Vector3(side * 32, 0.2, 15 - i * 19), Vector3(1.4, 1.8, 1.4), Color("ffcd66"))
 if model != null:
  structure = model
 else:
  structure.build_dragon()
 structure.add_tower()
 hit_bounds = structure.bounds()
 rebuild_standing()

static func ramp_position(z: float) -> Vector3:
 if z >= 60:
  var u = clampf((COURSE_START - z) / 130.0, 0, 1)
  return Vector3(0, 82 - 79 * u * u * (3 - 2 * u), z)
 return Vector3(0, 3 + 19 * pow(clampf((60 - z) / 60, 0, 1), 2), z)

static func ramp_slope(z: float) -> float:
 if z >= 60:
  var u = clampf((COURSE_START - z) / 130.0, 0, 1)
  return 79.0 * 6 * u * (1 - u) / 130.0
 return -38.0 * clampf((60 - z) / 60, 0, 1) / 60.0

func block_batch(blocks: Dictionary, center: Vector3) -> Node3D:
 var group = Node3D.new()
 for is_stud in [false, true]:
  var instance = MultiMeshInstance3D.new()
  var batch = MultiMesh.new()
  batch.transform_format = MultiMesh.TRANSFORM_3D
  batch.use_colors = true
  batch.mesh = stud_mesh if is_stud else brick_mesh
  batch.instance_count = blocks.size()
  var index = 0
  for cell in blocks:
   var at: Vector3 = structure.position_of(cell) - center
   if is_stud:
    at.y += 0.67 * Structure.SIZE_MULTIPLIER
   batch.set_instance_transform(index, Transform3D(Basis.IDENTITY, at))
   batch.set_instance_color(index, blocks[cell])
   index += 1
  instance.multimesh = batch
  instance.material_override = brick_material
  group.add_child(instance)
 return group

func rebuild_standing() -> void:
 if is_instance_valid(standing):
  remove_child(standing)
  standing.queue_free()
 standing = block_batch(structure.cells, Vector3.ZERO)
 add_child(standing)

func impact(from: Vector3, to: Vector3, radius: float, owner_index: int) -> int:
 var bounds = hit_bounds.grow(radius)
 if not bounds.has_point(from) and not bounds.has_point(to) and bounds.intersects_segment(from, to) == null:
  return 0
 var released: Array = structure.strike(from, to, radius)
 var count = 0
 for blocks in released:
  var center = Vector3.ZERO
  for cell in blocks:
   center += structure.position_of(cell)
  center /= blocks.size()
  var node = block_batch(blocks, center)
  add_child(node)
  node.position = center
  var lowest = 0.0
  var highest = 0.0
  var target_count = 0
  for cell in blocks:
   lowest = minf(lowest, structure.position_of(cell).y - center.y)
   highest = maxf(highest, structure.position_of(cell).y - center.y)
   if structure.target_cells.has(cell):
    target_count += 1
  var sign_x = -1.0 if center.x < to.x else 1.0
  chunks.append({"node":node, "velocity":Vector3(sign_x * 3, 2, -5), "count":blocks.size(), "target_count":target_count, "owner":owner_index, "lowest":lowest, "highest":highest, "wet":false})
  count += blocks.size()
 if count:
  rebuild_standing()
 return count

func advance(delta: float) -> Array:
 var landed: Array = []
 for i in range(chunks.size() - 1, -1, -1):
  var chunk: Dictionary = chunks[i]
  chunk.velocity.y -= 15 * delta
  chunk.node.position += chunk.velocity * delta
  # Score when the entire chunk has crossed the surface, not just when detached.
  if not chunk.wet and chunk.node.position.y + chunk.lowest < 0:
   splash(chunk.node.position, minf(8, 1 + sqrt(chunk.count) * 0.45))
   chunk.wet = true
  if chunk.node.position.y + chunk.highest < -0.8 * Structure.SIZE_MULTIPLIER:
   submerged += chunk.target_count
   landed.append({"owner":chunk.owner, "count":chunk.target_count})
   chunk.node.queue_free()
   chunks.remove_at(i)
 for i in range(splashes.size() - 1, -1, -1):
  var ring: Dictionary = splashes[i]
  ring.age += delta
  ring.node.scale = Vector3(1, 0.2, 1) * (1 + ring.age * 3)
  ring.node.transparency = clampf(ring.age / 1.2, 0, 1)
  if ring.age >= 1.2:
   ring.node.queue_free()
   splashes.remove_at(i)
 return landed

func splash(at: Vector3, radius: float = 2.0) -> void:
 var torus = TorusMesh.new()
 torus.inner_radius = radius * 0.8
 torus.outer_radius = radius
 torus.rings = 20
 torus.ring_segments = 6
 var node = Geo.mesh(self, torus, Vector3(at.x, 0.1, at.z), Color("a6f3ef"))
 node.scale.y = 0.2
 splashes.append({"node":node, "age":0.0})

func clear_camera_space(eye: Vector3) -> void:
 # Avoid looking at the inside of a freshly released brick from the cockpit.
 # This affects tiny debris visibility only, never collision, points or large chunks.
 for chunk in chunks:
  chunk.node.visible = chunk.count > 8 or chunk.node.position.distance_squared_to(eye) > 12.25
