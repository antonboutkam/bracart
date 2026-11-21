extends Node3D
## Visible PBR highlights and geometry also work in the Compatibility renderer.
const Geo = preload("res://scripts/geometry.gd")
var age: float = 0.0
var lifetime: float = 0.55
var rays: Array[Node3D] = []
var ring: MeshInstance3D

static func metal(color: Color, roughness: float = 0.22) -> StandardMaterial3D:
 var mat = Geo.material(color)
 mat.metallic = 0.78
 mat.roughness = roughness
 return mat

static func torus(parent: Node3D, radius: float, thickness: float, color: Color) -> MeshInstance3D:
 var shape = TorusMesh.new()
 shape.inner_radius = radius - thickness
 shape.outer_radius = radius + thickness
 shape.rings = 24
 shape.ring_segments = 8
 var mesh = Geo.mesh(parent, shape, Vector3.ZERO, color)
 mesh.material_override = metal(color)
 return mesh

static func create_pickup(parent: Node3D, kind: String, at: Vector3) -> Node3D:
 var item = Node3D.new()
 item.name = "GoldenCoin" if kind == "coin" else "CrystalPowerbox"
 parent.add_child(item)
 item.position = at
 if kind == "coin":
  var face = Geo.cylinder(item, Vector3.ZERO, 0.42, 0.13, Color("edaa22"))
  face.rotation.x = PI / 2
  face.material_override = metal(Color("efb638"), 0.25)
  var rim = torus(item, 0.423, 0.043, Color("ffdf7b"))
  rim.rotation.x = PI / 2
  for side in [-1.0, 1.0]:
   var inset = torus(item, 0.32, 0.014, Color("bd7416"))
   inset.rotation.x = PI / 2
   inset.position.z = side * 0.076
   # Raised B stamp and fine rim facets catch the real sun as the coin rotates.
   var stamp = Geo.text(item, "B", Vector3(0, -0.02, side * 0.085), 45)
   stamp.pixel_size = 0.012
   stamp.outline_size = 2
   stamp.modulate = Color("fff1b4")
   stamp.rotation.y = PI if side < 0 else 0.0
 else:
  var core = Geo.box(item, Vector3.ZERO, Vector3.ONE * 0.91, Color("218cb4"))
  var crystal = Geo.material(Color(0.21, 0.78, 0.93, 0.6), 0.22)
  crystal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  crystal.metallic = 0.3
  crystal.roughness = 0.18
  core.material_override = crystal
  # Explicit golden edges keep the box readable without relying on bloom.
  for a in [-0.5, 0.5]:
   for b in [-0.5, 0.5]:
    for axis in 3:
     var pos = Vector3(a, b, 0) if axis == 2 else (Vector3(a, 0, b) if axis == 1 else Vector3(0, a, b))
     var size = Vector3(0.055, 0.055, 0.055)
     size[axis] = 1.07
     Geo.box(item, pos, size, Color("ffe2a0")).material_override = metal(Color("ffe2a0"))
  var label = Geo.text(item, "?", Vector3(0, -0.07, 0), 78)
  label.pixel_size = 0.014
  label.outline_size = 9
  label.modulate = Color("fff5d8")
  label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 item.set_meta("reward_visual_version", 1)
 return item

static func burst(parent: Node3D, at: Vector3, kind: String) -> Node3D:
 var effect = load("res://scripts/effects/reward_visuals.gd").new()
 parent.add_child(effect)
 effect.position = at
 effect.name = "PickupFlash"
 var color = Color("ffe08a") if kind == "coin" else Color("9aeeff")
 effect.ring = torus(effect, 0.4, 0.025, color)
 effect.ring.material_override = Geo.material(color, 0.45)
 for i in 6:
  var spark = Geo.ball(effect, Vector3.ZERO, Vector3(0.08, 0.08, 0.08), color)
  spark.material_override = Geo.material(color, 0.65)
  effect.rays.append(spark)
 return effect

func _process(delta: float) -> void:
 # Parent is the race; the simulation's pause must also freeze visual lifetimes.
 if get_parent() != null and get_parent().get("paused") == true:
  return
 age += delta
 if age >= lifetime:
  queue_free()
  return
 var t = age / lifetime
 ring.scale = Vector3.ONE * (0.5 + t * 2.8)
 for i in rays.size():
  var angle = TAU * i / rays.size()
  rays[i].position = Vector3(cos(angle), 0.5 + sin(t * PI), sin(angle)) * t * 1.5
  rays[i].scale = Vector3.ONE * (1.0 - t)
 ring.scale.y = maxf(0.05, 1.0 - t)
