extends Node3D
## Two optional routes across the same plane, each with its own flight impulse.
const Geo = preload("res://scripts/geometry.gd")
const DEPTH = -86.0
const RADIUS = 7.4
const PULSE_TIME = 0.48
const ROUTES = [
 {"center": Vector3(-11.5, 63, DEPTH), "impulse": Vector3(0, 6, -3), "color": Color("51f3ae"),
  "name": "Liftring", "sign": "LIFT", "feedback": "LIFTRING! Je vliegt hoger."},
 {"center": Vector3(10.5, 48, DEPTH), "impulse": Vector3(0, -2, -11), "color": Color("ff953d"),
  "name": "Snelheidsring", "sign": "SNELHEID", "feedback": "SNELHEIDSRING! Extra vaart."},
]
var meshes: Array[MeshInstance3D] = []
var signs: Array[Label3D] = []
var taken: int = -1
var pulse: float = 0

func _ready() -> void:
 var shape = TorusMesh.new()
 shape.inner_radius = RADIUS
 shape.outer_radius = RADIUS + 0.8
 shape.rings = 48
 shape.ring_segments = 8
 for route in ROUTES:
  var ring = Geo.mesh(self, shape, route.center, route.color)
  ring.rotation.x = PI / 2
  ring.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  meshes.append(ring)
  var sign = Geo.text(self, route.sign, route.center + Vector3.UP * 9.8)
  sign.modulate = route.color
  sign.pixel_size = 0.039
  signs.append(sign)

func reset() -> void:
 taken = -1
 pulse = 0
 for i in meshes.size():
  meshes[i].show()
  meshes[i].scale = Vector3.ONE
  signs[i].show()

static func crossed(from: Vector3, to: Vector3) -> int:
 if from.z <= DEPTH or to.z > DEPTH:
  return -1
 var at = from.lerp(to, (DEPTH - from.z) / (to.z - from.z))
 for i in ROUTES.size():
  if at.distance_squared_to(ROUTES[i].center) <= RADIUS * RADIUS:
   return i
 return -1

func take(index: int) -> void:
 taken = index
 pulse = 0
 signs[index].hide()

func advance(delta: float) -> void:
 if taken < 0 or pulse >= PULSE_TIME:
  return
 pulse = minf(pulse + delta, PULSE_TIME)
 var ratio = pulse / PULSE_TIME
 meshes[taken].scale = Vector3.ONE * (1 + ratio * 0.6)
 meshes[taken].visible = pulse < PULSE_TIME
