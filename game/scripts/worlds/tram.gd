extends Node3D
## Ground-level, closed-loop future interpretation inspired by supplied Uithoorn tram photo.
## Owned by Track: inherited process mode freezes motion while the race is paused.
const Geo = preload("res://scripts/geometry.gd")
const CENTER = Vector3(83, -21.68, 0)
const RADII = Vector2(49, 100)
const SPEED = 8.5
const CAR_SPACING = 6.65
const SAMPLES = 360
var elapsed: float = 0
var distance: float = 0
var loop_length: float = 0
var distances: PackedFloat32Array = PackedFloat32Array()
var cars: Array[Node3D] = []

static func build(track: Node3D) -> Node3D:
 var transit = new()
 transit.name = "UithoornTram"
 transit.set_meta("role", "uithoorn-ground-transit")
 transit.set_meta("interpretation", "2056-fiction-inspired-by-supplied-tram-photo")
 track.add_child(transit)
 transit.setup()
 return transit

static func point(angle: float) -> Vector3:
 return CENTER + Vector3(cos(angle) * RADII.x, 0, sin(angle) * RADII.y)

func setup() -> void:
 distances.append(0)
 for index in range(1, SAMPLES + 1):
  loop_length += point(TAU * index / SAMPLES).distance_to(point(TAU * (index - 1) / SAMPLES))
  distances.append(loop_length)
 _infrastructure()
 for index in 3:
  var car := Node3D.new()
  car.name = "Tramdeel%d" % (index + 1)
  add_child(car)
  cars.append(car)
  _car(car, index)
 _pose()

func angle_at(meters: float) -> float:
 var wrapped := fposmod(meters, loop_length)
 var low := 0
 var high := SAMPLES
 while high - low > 1:
  var middle := (low + high) / 2
  if distances[middle] <= wrapped:
   low = middle
  else:
   high = middle
 return TAU * (low + (wrapped - distances[low]) / maxf(distances[high] - distances[low], 0.0001)) / SAMPLES

func frame_at(meters: float) -> Transform3D:
 var angle := angle_at(meters)
 var forward := Vector3(-sin(angle) * RADII.x, 0, cos(angle) * RADII.y).normalized()
 var right := forward.cross(Vector3.UP).normalized()
 return Transform3D(Basis(right, Vector3.UP, -forward), point(angle))

func _pose() -> void:
 for index in cars.size():
  cars[index].transform = frame_at(distance - index * CAR_SPACING)

func _process(delta: float) -> void:
 advance(delta)

func advance(delta: float) -> void:
 if delta <= 0 or not is_finite(delta):
  return
 elapsed += delta
 distance = fposmod(distance + SPEED * delta, loop_length)
 _pose()

func _infrastructure() -> void:
 var roadbed := StandardMaterial3D.new()
 roadbed.albedo_color = Color("76736a")
 roadbed.roughness = 0.98
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 surface.set_material(roadbed)
 for index in SAMPLES:
  var a := frame_at(loop_length * index / SAMPLES)
  var b := frame_at(loop_length * (index + 1) / SAMPLES)
  for vertex in [a.origin-a.basis.x*2, b.origin+b.basis.x*2, b.origin-b.basis.x*2, a.origin-a.basis.x*2, a.origin+a.basis.x*2, b.origin+b.basis.x*2]:
   surface.add_vertex(vertex - Vector3.UP * 0.04)
 surface.generate_normals()
 var bed := MeshInstance3D.new()
 bed.mesh = surface.commit()
 add_child(bed)
 for index in 180:
  var a := frame_at(loop_length * index / 180)
  var b := frame_at(loop_length * (index + 1) / 180)
  # Twin running rails, real track width; no race colliders are created.
  for side in [-0.72,0.72]:
   var rail := Geo.beam(self, a.origin + a.basis.x * side, b.origin + b.basis.x * side, 0.055, Color("aab9bc"))
   rail.material_override.metallic = 0.8
  if index % 2 == 0:
   var sleeper := Geo.box(self, a.origin - Vector3.UP * 0.06, Vector3(2.3,0.08,0.17), Color("635d55"))
   sleeper.basis = a.basis
 for index in 24:
  var a := frame_at(loop_length * index / 24)
  var b := frame_at(loop_length * (index + 1) / 24)
  var pole := a.origin + a.basis.x * 2.5
  Geo.cylinder(self, pole + Vector3.UP*2.9, 0.065, 5.8, Color("5c797e"))
  Geo.beam(self, pole+Vector3.UP*5.6, a.origin+Vector3.UP*5.6, 0.045, Color("5c797e"))
  Geo.beam(self,a.origin+Vector3.UP*5.6,b.origin+Vector3.UP*5.6,0.025,Color("34444a"))
 var halt := Node3D.new()
 halt.name = "HalteSpoorhuis"
 add_child(halt)
 halt.transform = frame_at(loop_length * 0.72)
 set_meta("halt_position", halt.position)
 set_meta("route_center", CENTER)
 set_meta("route_radii", RADII)
 Geo.box(halt,Vector3(3.3,0.12,0),Vector3(2.5,0.3,17),Color("c6c4b4"))
 Geo.box(halt,Vector3(3.4,2.7,0),Vector3(3.0,0.14,10),Color("d1e6df"))
 for z in [-4,4]:
  Geo.cylinder(halt,Vector3(4.25,1.45,z),0.06,2.7,Color("45626a"))
 Geo.box(halt,Vector3(4.25,1.55,0),Vector3(0.09,1.9,8),Color("83b9c4"))
 var sign := Geo.text(halt,"25  SPOORHUIS • UITHOORN",Vector3(2.8,2.2,-3),27)
 sign.rotation.y = PI/2

func _car(parent: Node3D, index: int) -> void:
 # White/blue articulated low-floor silhouette from the supplied tram reference.
 Geo.box(parent,Vector3(0,1.55,0),Vector3(2.45,2.65,6.0),Color("e6e9e3"))
 Geo.box(parent,Vector3(0,0.55,0),Vector3(2.5,0.55,6.1),Color("2b729d"))
 Geo.box(parent,Vector3(0,2.9,0),Vector3(2.2,0.2,5.7),Color("879a9c"))
 for side in [-1,1]:
  for z in [-1.95,-0.65,0.65,1.95]:
   Geo.box(parent,Vector3(side*1.235,1.95,z),Vector3(0.025,1.08,1.08),Color("213e4b"))
  Geo.box(parent,Vector3(side*1.26,1.35,0.7),Vector3(0.03,2.0,0.06),Color("d1d9ce"))
 for z in [-2.05,2.05]:
  for side in [-1,1]:
   var wheel := Geo.cylinder(parent,Vector3(side*1.0,0.3,z),0.3,0.14,Color("25303a"))
   wheel.rotation.z = PI/2
 if index == 0 or index == 2:
  var front := -3.03 if index == 0 else 3.03
  Geo.box(parent,Vector3(0,1.95,front),Vector3(2.12,1.3,0.06),Color("172f3c"))
  var display := Geo.text(parent,"25 UITHOORN",Vector3(0,2.48,front*1.013),22)
  display.modulate = Color("ffd268")
  display.outline_size = 1
  if index == 0: display.rotation.y = PI
  for x in [-0.84,0.84]:
   var lamp := Geo.box(parent,Vector3(x,0.95,front*1.008),Vector3(0.32,0.18,0.035),Color("fff0bd") if index == 0 else Color("ff5141"))
   lamp.material_override.emission_enabled = true
   lamp.material_override.emission = lamp.material_override.albedo_color
 if index < 2:
  # Visible accordion articulation between the separate, curve-following modules.
  for z in [3.04,3.15,3.26,3.37,3.48,3.59]:
   Geo.box(parent,Vector3(0,1.55,z),Vector3(2.17,2.3,0.08),Color("46535a"))
 if index == 1:
  Geo.box(parent,Vector3(0,3.12,0),Vector3(1.45,0.35,2.5),Color("5b7179"))
  for side in [-0.55,0.55]:
   Geo.beam(parent,Vector3(side,3.3,-0.8),Vector3(side,4.35,0),0.045,Color("39474c"))
   Geo.beam(parent,Vector3(side,4.35,0),Vector3(side,5.45,-0.55),0.045,Color("39474c"))
  Geo.beam(parent,Vector3(-0.85,5.45,-0.55),Vector3(0.85,5.45,-0.55),0.045,Color("39474c"))
