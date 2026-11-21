extends RefCounted
## Small reusable primitives; scenery stays separate from the drivable surface.
static func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
 var mat = StandardMaterial3D.new()
 mat.albedo_color = color
 mat.roughness = 0.46
 if glow > 0:
  mat.emission_enabled = true
  mat.emission = color
  mat.emission_energy_multiplier = glow
 return mat

static func mesh(parent: Node3D, shape: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
 var instance = MeshInstance3D.new()
 instance.mesh = shape
 instance.material_override = material(color)
 parent.add_child(instance)
 instance.position = pos
 return instance

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
 var shape = BoxMesh.new()
 shape.size = size
 return mesh(parent, shape, pos, color)

static func ball(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
 var shape = SphereMesh.new()
 shape.radial_segments = 12
 shape.rings = 6
 var instance = mesh(parent, shape, pos, color)
 instance.scale = size
 return instance

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, top: float = -1) -> MeshInstance3D:
 var shape = CylinderMesh.new()
 shape.top_radius = radius if top < 0 else top
 shape.bottom_radius = radius
 shape.height = height
 shape.radial_segments = 12
 return mesh(parent, shape, pos, color)

static func beam(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> MeshInstance3D:
 var instance = cylinder(parent, (a + b) / 2, radius, a.distance_to(b), color)
 var up = (b - a).normalized()
 var right = up.cross(Vector3.FORWARD).normalized()
 if right.length() < 0.1:
  right = Vector3.RIGHT
 instance.basis = Basis(right, up, right.cross(up)).orthonormalized()
 return instance

static func text(parent: Node3D, title: String, pos: Vector3, size: int = 64) -> Label3D:
 var label = Label3D.new()
 label.text = title
 label.font_size = size
 label.pixel_size = 0.014
 label.outline_size = 8
 label.modulate = Color("fff4d9")
 parent.add_child(label)
 label.position = pos
 return label
