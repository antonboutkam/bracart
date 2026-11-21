extends Node3D
const Geo = preload("res://scripts/geometry.gd")
const Catalog = preload("res://scripts/catalog.gd")
const Routes = preload("res://scripts/worlds/routes.gd")
const Scenery = preload("res://scripts/worlds/scenery.gd")
const KitchenCourse = preload("res://scripts/worlds/kitchen_course.gd")
const KitchenRainbow = preload("res://scripts/effects/kitchen_rainbow.gd")
const StuntCourseV2 = preload("res://scripts/worlds/stunt_course_v2.gd")
const UithoornGroundCourse = preload("res://scripts/worlds/uithoorn_ground_course.gd")
var ground_course
var v2_course
var track_index: int = 0
var table_half := Vector2(117.5,102.5)
var kitchen_course
var kitchen_rainbow
var curve: Curve3D
var length: float
var width: float = 8.0
var world_index: int = 0
var rotating: Array[Node3D] = []
var ambient_motions: Array[Dictionary] = []
var ambient_time: float = 0
var road_material: StandardMaterial3D
var accent: Color

func build(index: int) -> void:
 for child in get_children():
  remove_child(child)
  child.queue_free()
 rotating.clear()
 ambient_motions.clear()
 ambient_time = 0
 set_meta("scenic_sites", [])
 track_index = clampi(index,0,Catalog.TRACKS.size()-1)
 world_index = Catalog.TRACKS[track_index].world
 index = world_index
 var world: Dictionary = Catalog.WORLDS[index]
 accent = Color(world.accent)
 width = 7.0 if index == 5 else 8.0
 curve = Curve3D.new()
 curve.bake_interval = 0.8
 # Closed Catmull-Rom converted to cubic Beziers with a shared finish tangent.
 var points: Array[Vector3] = Routes.points(index)
 var count = points.size()
 for i in count + 1:
  var j = i % count
  var tangent = (points[(j + 1) % count] - points[posmod(j - 1, count)]) / 6.0
  curve.add_point(points[j], -tangent, tangent)
 length = curve.get_baked_length()
 v2_course = null
 ground_course = null
 if track_index == 4:
  ground_course = UithoornGroundCourse.new()
  ground_course.setup()
  curve = ground_course.curve
  length = ground_course.length
 table_half = Vector2(117.5,102.5)
 kitchen_course = null
 kitchen_rainbow = null
 if index == 5:
  kitchen_course = KitchenCourse.new()
  kitchen_course.setup(curve)
  curve = kitchen_course.curve
  length = kitchen_course.length
 if track_index >= 6:
  v2_course = StuntCourseV2.new()
  v2_course.setup(length,index)
  curve = v2_course.curve
  length = v2_course.length
  table_half = v2_course.table_half
  # Legacy kitchen props consume only the original kitchen feature contract.
  kitchen_course = null
 if index != 5 or v2_course != null:
  _build_road(world)
 else:
  # Exactly one wood surface, with cable boundaries and no separate road ribbon.
  Geo.box(self, Vector3(0, -0.55, 0), Vector3(235, 1.3, 205), Color(world.road))
  for i in 28:
   Geo.box(self, Vector3(-114 + i * 8.4, 0.105, 0), Vector3(0.07, 0.01, 203), Color("9a6c46"))
 if index == 5 and v2_course != null:
  var table = Geo.box(self,Vector3(0,-0.55,0),Vector3(table_half.x*2,1.3,table_half.y*2),Color(world.road))
  table.set_meta("v2_table",true)
 if index == 5 and kitchen_course != null: kitchen_course.build_loop(self)
 if ground_course != null: ground_course.build_hill(self)
 _build_edges()
 _finish_gate()
 Scenery.build(self, world)
 if index == 5 and kitchen_course != null:
  set_meta("kitchen_features",kitchen_course.features)
  kitchen_rainbow = KitchenRainbow.new()
  add_child(kitchen_rainbow)
  kitchen_rainbow.setup(self,kitchen_course.features[3])

func kitchen_features() -> Array:
 return kitchen_course.features if world_index == 5 and kitchen_course != null else []

func frame(distance: float) -> Transform3D:
 if v2_course != null: return v2_course.frame(distance)
 if world_index == 5 and kitchen_course != null: return kitchen_course.frame(distance)
 var d = fposmod(distance, length)
 var p = curve.sample_baked(d, true)
 var forward = (curve.sample_baked(fposmod(d + 0.6, length), true) - curve.sample_baked(fposmod(d - 0.6, length), true)).normalized()
 var right = forward.cross(Vector3.UP).normalized()
 var up = right.cross(forward).normalized()
 var bank = 0.0 if world_index == 5 or ground_course != null else sin(d / length * TAU * 3) * 0.16
 var basis_value = Basis(right, up, -forward).rotated(forward, bank)
 return Transform3D(basis_value, p)

func bowl(lateral: float) -> float:
 return 0.0 if world_index == 5 or v2_course != null or ground_course != null else 1.9 * pow(clampf(absf(lateral) / width, 0, 1), 4)

func position_at(distance: float, lateral: float = 0, lift: float = 0) -> Vector3:
 var f = frame(distance)
 return f.origin + f.basis.x * lateral + f.basis.y * (bowl(lateral) + lift)

func _build_road(world: Dictionary) -> void:
 var st = SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 road_material = Geo.material(Color(world.road))
 road_material.cull_mode = BaseMaterial3D.CULL_DISABLED
 road_material.roughness = 0.78
 road_material.metallic_specular = 0.22
 st.set_material(road_material)
 var segments = int(ceil(length/0.65)) if v2_course != null or ground_course != null else 420
 var across = 2 if ground_course != null else 16
 for i in segments:
  if v2_course != null and v2_course.is_gap(length*(i+0.5)/segments): continue
  for j in across:
   var a = position_at(length * i / segments, lerpf(-width, width, float(j) / across))
   var b = position_at(length * (i + 1) / segments, lerpf(-width, width, float(j) / across))
   var c = position_at(length * (i + 1) / segments, lerpf(-width, width, float(j + 1) / across))
   var d = position_at(length * i / segments, lerpf(-width, width, float(j + 1) / across))
   for vertex in [a, c, b, a, d, c]:
    st.add_vertex(vertex)
 st.generate_normals()
 var road = MeshInstance3D.new()
 road.mesh = st.commit()
 add_child(road)

func _build_edges() -> void:
 # Continuous integrated edge ribbons, or household cables on the kitchen table.
 for side in [-1, 1]:
  if world_index == 5 and v2_course == null:
   _kitchen_cable(side)
   continue
  var st = SurfaceTool.new()
  st.begin(Mesh.PRIMITIVE_TRIANGLES)
  var edge_material = Geo.material(accent, 0.3)
  edge_material.cull_mode = BaseMaterial3D.CULL_DISABLED
  st.set_material(edge_material)
  var segments = int(ceil(length/0.65)) if v2_course != null or ground_course != null else 360
  for i in segments:
   if v2_course != null and v2_course.is_gap(length*(i+0.5)/segments): continue
   var p = position_at(length * i / segments, side * width, 0.08)
   var q = position_at(length * (i + 1) / segments, side * width, 0.08)
   var dx = frame(length * i / segments).basis.x * 0.18
   for v in [p - dx, q + dx, q - dx, p - dx, p + dx, q + dx]:
    st.add_vertex(v)
  st.generate_normals()
  var edge = MeshInstance3D.new()
  edge.mesh = st.commit()
  add_child(edge)
 if world_index != 5 and world_index != 2 and v2_course == null and ground_course == null:
  for i in 32:
   var p = position_at(length * i / 32)
   Geo.cylinder(self, Vector3(p.x, (p.y - 24) / 2, p.z), 0.6, p.y + 20, Color("435366"))

func _kitchen_cable(side: int) -> void:
 var st = SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var mat = Geo.material(Color("d95c46") if side < 0 else Color("303b42"))
 mat.cull_mode = BaseMaterial3D.CULL_DISABLED
 st.set_material(mat)
 for i in 360:
  var a = length * i / 360
  var b = length * (i + 1) / 360
  if kitchen_course != null and (frame(a).origin.y > 0.14 or frame(b).origin.y > 0.14): continue
  for j in 6:
   var vertices: Array[Vector3] = []
   for pair in [[a,j],[b,j],[b,j + 1],[a,j + 1]]:
    var f = frame(pair[0])
    var angle = TAU * pair[1] / 6
    vertices.append(position_at(pair[0],side * width,0.4) + (f.basis.x * cos(angle) + f.basis.y * sin(angle)) * 0.35)
   for k in [0,2,1,0,3,2]: st.add_vertex(vertices[k])
 st.generate_normals()
 var cable = MeshInstance3D.new()
 cable.mesh = st.commit()
 add_child(cable)

func _finish_gate() -> void:
 var root = Node3D.new()
 add_child(root)
 root.transform = frame(0)
 for x in [-width, width]:
  Geo.cylinder(root, Vector3(x, 4, 0), 0.25, 8, accent)
 Geo.box(root, Vector3(0, 8, 0), Vector3(width * 2 + 1, 1.2, 0.7), Color("172641"))
 var label = Geo.text(root, "BoRacer  /  START", Vector3(0, 8, 0.42), 76)
 label.rotation.y = 0
 # A single gold finish band; generic road has no stripes or center line.
 Geo.box(root, Vector3(0, 0.035, 0), Vector3(width * 2 - 1, 0.02, 0.35), accent)

func active_course():
 return v2_course if v2_course != null else kitchen_course

func section_name(distance: float) -> String:
 if ground_course != null: return ground_course.section_name(distance)
 if v2_course != null:
  var feature: Dictionary = v2_course.feature_at(distance)
  if not feature.is_empty(): return feature.name
 return Routes.section_name(world_index, distance / length)

func add_ambient_motion(node: Node3D, axis: Vector3, amount: float, speed: float, phase: float = 0) -> void:
 ambient_motions.append({"node":node,"base":node.position,"axis":axis,"amount":amount,"speed":speed,"phase":phase})

func _process(delta: float) -> void:
 ambient_time += delta
 for node in rotating:
  node.rotate_z(delta * 0.15)
 for motion in ambient_motions:
  motion.node.position = motion.base + motion.axis * sin(ambient_time * motion.speed + motion.phase) * motion.amount
