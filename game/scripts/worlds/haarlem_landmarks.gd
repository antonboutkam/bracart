extends RefCounted
## One section/model/envelope entry controls both placement and sign replacement.
## Stylised 1888 landmarks, no road collision and no imported image assets.
const Geo = preload("res://scripts/geometry.gd")
const Art = preload("res://scripts/worlds/world_art.gd")
const Architecture = preload("res://scripts/worlds/architecture.gd")
const ENTRIES = [
 {"id":"amsterdamse-poort", "section":1, "side":-1, "radius":14.0, "bounds":AABB(Vector3(-11,-0.6,-8),Vector3(22,32,16)), "label":"Amsterdamse Poort"},
 {"id":"teylers-museum", "section":5, "side":-1, "radius":17.0, "bounds":AABB(Vector3(-13,-0.6,-10),Vector3(26,25,20)), "label":"Teylers Museum"}
]

static func section_fraction(entry: Dictionary, section_count: int) -> float:
 return float(entry.section) / section_count + 0.035

static func valid_entry(entry: Dictionary, section_count: int) -> bool:
 return entry.get("id","") in ["amsterdamse-poort","teylers-museum"] and typeof(entry.get("section")) == TYPE_INT and entry.section >= 0 and entry.section < section_count and entry.get("side",0) in [-1,1] and entry.get("radius",0) > 0 and entry.get("bounds") is AABB

static func build_model(parent: Node3D, entry: Dictionary) -> bool:
 if not valid_entry(entry,6): return false
 parent.name = "Landmark_" + str(entry.id).replace("-","_")
 parent.set_meta("haarlem_landmark",entry.id)
 parent.set_meta("section",entry.section)
 parent.set_meta("bounds",entry.bounds)
 match entry.id:
  "amsterdamse-poort": _poort(parent)
  "teylers-museum": _teylers(parent)
 return true

static func _stone(parent: Node3D, p: Vector3, size: Vector3) -> void:
 Art.box(parent,p,size,"stone",Color("e5d3b2"),0.45)

static func _brick(parent: Node3D, p: Vector3, size: Vector3) -> void:
 Art.box(parent,p,size,"brick",Color("b7775b"),0.5)

static func _roof(parent: Node3D, p: Vector3, size: Vector3) -> void:
 var roof = Geo.mesh(parent,Architecture.cap_mesh(),p,Color("605e59"))
 roof.scale = Vector3(size.x/9.8,size.y/3.8,size.z/12.1)
 Art.apply(roof,"roof",Color("655e58"),0.4)

static func _arch(parent: Node3D, x: float, bottom: float, z: float, radius: float, thickness: float, depth: float, color: Color) -> void:
 # Twelve CLOSED stone voussoirs: radial wedge prisms with outward normals.
 var st = SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in 12:
  var a = PI*float(i)/12
  var b = PI*float(i+1)/12
  var points: Array[Vector3] = []
  for side in [-1,1]:
   for r in [radius,radius+thickness]:
    for angle in [a,b]: points.append(Vector3(x+cos(angle)*r,bottom+sin(angle)*r,z+side*depth/2))
  for face in [[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]]:
   var c: Vector3 = (points[face[0]]+points[face[1]]+points[face[2]]+points[face[3]])/4
   var center = Vector3.ZERO
   for point in points: center += point/8
   Architecture._quad(st,points[face[0]],points[face[1]],points[face[2]],points[face[3]],(c-center).normalized())
 Geo.mesh(parent,st.commit(),Vector3.ZERO,color)

static func _poort(parent: Node3D) -> void:
 # Empty archway, tall square gatehouse, two lower round towers and slate caps.
 _stone(parent,Vector3(0,-0.3,0),Vector3(22,0.6,16))
 for side in [-1,1]:
  _brick(parent,Vector3(side*4,5.5,0),Vector3(3.5,11,9))
  _stone(parent,Vector3(side*4,0.6,0),Vector3(3.8,1.2,9.3))
 _brick(parent,Vector3(0,15.8,0),Vector3(11.5,10.4,9))
 _arch(parent,0,5,-4.6,2.3,0.65,0.5,Color("e1cead"))
 _arch(parent,0,5,4.6,2.3,0.65,0.5,Color("e1cead"))
 # Fill above the curved opening with closed masonry strips; no black fake hole.
 for i in 16:
  var x = -2.3+(i+0.5)*4.6/16
  var y = 5+sqrt(maxf(2.3*2.3-x*x,0))
  _brick(parent,Vector3(x,(y+10.6)/2,0),Vector3(4.6/16,10.6-y,9))
 for y in [10.8,17.5,21.2]: _stone(parent,Vector3(0,y,0),Vector3(11.9,0.4,9.4))
 _roof(parent,Vector3(0,21.3,0),Vector3(12.4,9,10))
 for side in [-1,1]:
  var x = side*7.6
  Art.apply(Geo.cylinder(parent,Vector3(x,5.7,-3.5),3.0,11.4,Color.WHITE),"brick",Color("c08a69"),0.45)
  Geo.cylinder(parent,Vector3(x,11.4,-3.5),3.2,0.5,Color("e5d3b2"))
  Geo.cylinder(parent,Vector3(x,14.4,-3.5),3.4,5.5,Color("575958"),0)
  for y in [3.6,8.4]:
   Geo.box(parent,Vector3(x,y,-6.52),Vector3(0.65,1.8,0.12),Color("303d40"))
  for z in [-2.8,2.8]:
   Geo.box(parent,Vector3(side*5.77,14,z),Vector3(0.12,2.3,0.6),Color("303d40"))
 for x in [-2.5,2.5]:
  Geo.box(parent,Vector3(x,14.2,-4.53),Vector3(1.2,2.2,0.15),Color("394448"))
  _stone(parent,Vector3(x,15.5,-4.65),Vector3(1.5,0.3,0.35))
 Geo.text(parent,"AMSTERDAMSE POORT",Vector3(0,18.8,-4.75),34).rotation.y = PI

static func _teylers(parent: Node3D) -> void:
 # Ulrich's monumental Spaarne facade: pale stone, central loggia, paired
 # columns, pediment and a simplified allegorical sculpture group.
 _stone(parent,Vector3(0,-0.3,0),Vector3(26,0.6,20))
 _stone(parent,Vector3(0,7,1),Vector3(24,14,15))
 for y in [0.4,6.2,13.6]: _stone(parent,Vector3(0,y,0.4),Vector3(25,0.5,16.8))
 _roof(parent,Vector3(0,14,1.5),Vector3(24.5,3.6,15))
 # A recessed entrance sits behind the projecting paired columns.
 for x in [-7.7,0,7.7]:
  for y in [3.2,9.1]:
   Geo.box(parent,Vector3(x,y,-6.57),Vector3(3.3,4.5,0.16),Color("354a4f"))
   _arch(parent,x,y+1.2,-6.75,1.65,0.38,0.4,Color("eddec1"))
   _stone(parent,Vector3(x,y-2.25,-6.9),Vector3(4,0.25,0.65))
  for offset in [-2.35,2.35]:
   _stone(parent,Vector3(x+offset,9,-6.9),Vector3(0.5,5.3,0.65))
 Geo.box(parent,Vector3(0,2.5,-6.8),Vector3(3.2,5,0.18),Color("574c3d"))
 for x in [-4.5,-3.4,3.4,4.5]:
  Geo.cylinder(parent,Vector3(x,9.1,-8),0.32,6,Color("e9d8b6"))
  for y in [6.3,11.9]: _stone(parent,Vector3(x,y,-8),Vector3(0.9,0.4,0.9))
 _stone(parent,Vector3(0,12.4,-7.6),Vector3(11,0.7,2.4))
 # Closed triangular pediment rather than a one-sided cutout.
 var pediment = Geo.mesh(parent,Architecture.cap_mesh(),Vector3(0,14,-7),Color("ddcbaa"))
 pediment.scale = Vector3(11.6/9.8,2.4/3.8,2.8/12.1)
 for x in [-3,0,3]:
  Geo.cylinder(parent,Vector3(x,17.4,-6.7),0.65,2.5,Color("e2d1b0"),0.48)
  Geo.ball(parent,Vector3(x,19,-6.7),Vector3.ONE*0.95,Color("eddec0"))
  Geo.beam(parent,Vector3(x,18,-6.7),Vector3(x+0.9,17.1,-6.6),0.18,Color("e2d1b0"))
 # The glazed vestibule dome rises behind the stone frontage.
 Geo.cylinder(parent,Vector3(0,16,3),3.5,3,Color("718782"))
 Geo.ball(parent,Vector3(0,17.3,3),Vector3(7.1,4.2,7.1),Color("aac2bf"))
 Geo.text(parent,"TEYLERS MUSEUM",Vector3(0,5.5,-7.1),32).rotation.y = PI

 # The narrow, tall facade proportions distinguish the museum from townhouses.
 for child in parent.get_children():
  if child is Node3D:
   child.position *= Vector3(0.75,1.2,1)
   child.scale *= Vector3(0.75,1.2,1)
