extends RefCounted
## Photo-informed tabletop objects; decorative only, no gameplay collision.
const Geo = preload("res://scripts/geometry.gd")
const Photos = preload("res://scripts/worlds/kitchen_photo_materials.gd")
const BLACK = Color("171a1d")
const WHITE = Color("e8e8df")
const SILVER = Color("b9bdbd")
var track: Node3D
var root: Node3D
var objects: Array[Dictionary] = []

static func build(target: Node3D) -> Node3D:
 var builder = new()
 return builder._build(target)

func _build(target: Node3D) -> Node3D:
 track = target
 root = Node3D.new()
 root.name = "KitchenProps"
 track.add_child(root)
 var node = _place("monitor","Code-monitor, toetsenbord en muis",Vector3(-22,0.12,-24),24)
 if node: _monitor(node)
 node = _place("megaphone","Rechtopstaande witte megafoon met rode bovenkant",Vector3(21,0.12,-24),7)
 if node: _megaphone(node)
 node = _place("can","Slank cyaan energiedrankblik",Vector3(39,0.12,8),5)
 if node: _can(node)
 node = _place("remote","Zwarte afstandsbediening",Vector3(-35,0.12,25),10)
 if node: _remote(node)
 node = _place("power","Zwart stekkerblok en kabelbundel",Vector3(2,0.12,25),13)
 if node: _power(node)
 node = _place("esp","Kleine blauwe printplaatjes",Vector3(30,0.12,33),11)
 if node: _esp(node)
 node = _place("scissors","Schaar met metalen bladen",Vector3(-3,0.12,0),9)
 if node: _scissors(node)
 node = _place("paper","Papier en doordrukstrip",Vector3(-15,0.12,43),10)
 if node: _paper(node)
 node = _place("adapter","Witte USB-voeding",Vector3(17,0.12,5),6)
 if node: _adapter(node)
 node = _place("cloth","Groene stof met witte binnenkant",Vector3(-43,0.12,-2),10)
 if node: _cloth(node)
 node = _place("globe","Glazen bol op zwart-zilveren voet en doosje",Vector3(-50,0.12,-25),7)
 if node: _globe(node)
 root.set_meta("objects",objects)
 root.set_meta("photo_source","assets/straatbeeld/keukentafel, 18 direct jpg references")
 return root

func _place(id: String, label: String, p: Vector3, radius: float) -> Node3D:
 if track.v2_course != null:
  var ids = ["monitor","megaphone","can","remote","power","esp","scissors","paper","adapter","cloth","globe"]
  var d: float = track.v2_course.scenery_distance(track.length*(ids.find(id)+0.35)/ids.size())
  p = track.position_at(d,track.width+radius+7)
  p.y = 0.12
 # Conservative circular footprint, dense enough for continuous route margin.
 if absf(p.x)+radius>track.table_half.x-3.5 or absf(p.z)+radius>track.table_half.y-3.5: return null
 for i in int(ceil(track.length/0.5)):
  var q: Vector3 = track.position_at(i*0.5)
  if Vector2(p.x-q.x,p.z-q.z).length()<track.width+radius+4.0: return null
 var object = Node3D.new()
 object.name = id
 root.add_child(object)
 object.position = p
 object.set_meta("kitchen_object",id)
 object.set_meta("footprint_radius",radius)
 var heights = {"monitor":25.0,"megaphone":14.1,"can":12.2,"remote":1.5,"power":4.0,"esp":1.5,"scissors":1.1,"paper":1.5,"adapter":3.1,"cloth":2.6,"globe":10.4}
 objects.append({"id":id,"label":label,"center":p,"radius":radius,"height":heights[id],"node":id,"front":Vector3.BACK})
 var sites: Array = track.get_meta("scenic_sites",[])
 sites.append({"position":p,"radius":radius,"object":id})
 track.set_meta("scenic_sites",sites)
 return object

func _box(parent: Node3D, p: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
 var node = Geo.box(parent,p,size,color)
 node.set_meta("world_material","kitchen_plastic")
 node.material_override.roughness = 0.72
 return node

func _metal(node: MeshInstance3D) -> MeshInstance3D:
 node.material_override.metallic = 0.75
 node.material_override.roughness = 0.27
 node.set_meta("world_material","kitchen_metal")
 return node

func _photo(parent: Node3D, id: String, p: Vector3, size: Vector2, front: bool = false) -> MeshInstance3D:
 var face = Photos.patch(parent,id,size)
 face.name = "Photo_"+id
 face.set_meta("photo_surface",id)
 face.position = p
 if not front: face.rotation.x = -PI/2
 return face

func _monitor(parent: Node3D) -> void:
 _box(parent,Vector3(0,0.5,0),Vector3(13,1,7),BLACK)
 _box(parent,Vector3(0,4.5,0),Vector3(2.2,8,2),BLACK)
 _box(parent,Vector3(0,15,0),Vector3(34,20,1.7),BLACK)
 _photo(parent,"monitor_screen",Vector3(0,15,0.86),Vector2(31.8,17.8),true)
 _box(parent,Vector3(0,0.65,10),Vector3(24,1.2,8),BLACK)
 _photo(parent,"keyboard_top",Vector3(0,1.26,10),Vector2(23,7))
 var mouse = Geo.ball(parent,Vector3(16,1.1,10),Vector3(4,2.2,6),BLACK)
 mouse.name = "Mouse"
 mouse.set_meta("world_material","kitchen_plastic")
 _box(parent,Vector3(16,2.19,9.1),Vector3(0.18,0.15,1.3),Color("636566"))
 _cable(parent,[Vector3(16,0.2,7),Vector3(18,0.2,4),Vector3(15,0.2,1),Vector3(10,0.2,0)],0.11)

# Thick annular frustum; open at mouth and neck, with inner wall + rim faces.
# The red electronics cap closes only the narrow top, never the mouth opening.
static func horn_mesh() -> ArrayMesh:
 var st = SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var n = 48
 for i in n:
  var a = TAU*i/n
  var b = TAU*(i+1)/n
  var outer_a = Vector3(cos(a)*4.0,0.3,sin(a)*4.0)
  var outer_b = Vector3(cos(b)*4.0,0.3,sin(b)*4.0)
  var neck_a = Vector3(cos(a)*1.35,8.0,sin(a)*1.35)
  var neck_b = Vector3(cos(b)*1.35,8.0,sin(b)*1.35)
  var inner_a = Vector3(cos(a)*3.77,0.3,sin(a)*3.77)
  var inner_b = Vector3(cos(b)*3.77,0.3,sin(b)*3.77)
  var throat_a = Vector3(cos(a)*1.12,8.0,sin(a)*1.12)
  var throat_b = Vector3(cos(b)*1.12,8.0,sin(b)*1.12)
  var normal = Vector3(cos((a+b)/2),2.65/7.7,sin((a+b)/2)).normalized()
  _quad(st,outer_a,outer_b,neck_b,neck_a,normal)
  _quad(st,inner_a,throat_a,throat_b,inner_b,-normal)
  _quad(st,inner_a,inner_b,outer_b,outer_a,Vector3.DOWN)
  _quad(st,neck_a,neck_b,throat_b,throat_a,Vector3.UP)
 return st.commit()

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
 for triangle in [[a,b,c],[a,c,d]]:
  if (triangle[2]-triangle[0]).cross(triangle[1]-triangle[0]).dot(normal)<0:
   triangle = [triangle[0],triangle[2],triangle[1]]
  for vertex in triangle:
   st.set_normal(normal)
   st.add_vertex(vertex)

func _megaphone(parent: Node3D) -> void:
 var horn = Geo.mesh(parent,horn_mesh(),Vector3.ZERO,WHITE)
 horn.name = "OpenWhiteHorn"
 horn.set_meta("world_material","kitchen_plastic")
 Geo.cylinder(parent,Vector3(0,9.6,0),1.35,3.2,WHITE)
 var cap = Geo.cylinder(parent,Vector3(0,12.6,0),1.7,2.8,Color("c53637"))
 cap.name = "RedTop"
 cap.set_meta("world_material","kitchen_red_plastic")
 for i in 16:
  var angle = TAU*i/16
  _box(parent,Vector3(cos(angle)*1.66,12.5,sin(angle)*1.66),Vector3(0.13,1.6,0.13),Color("a3282b"))
 _photo(parent,"megaphone_cap",Vector3(0,14.02,0),Vector2(2.1,1.6))
 _box(parent,Vector3(2.6,8.5,0),Vector3(0.7,4.8,1.2),WHITE)
 for y in [6.5,10.5]: _box(parent,Vector3(1.8,y,0),Vector3(2,0.7,1.2),WHITE)
 _box(parent,Vector3(2.8,9.7,0),Vector3(0.3,1,0.8),BLACK)

func _can(parent: Node3D) -> void:
 var body = Geo.cylinder(parent,Vector3(0,6,0),2.15,11.6,Color("7eb9d6"))
 body.name = "CyanCan"
 _metal(body)
 # Photo sector follows the real curved body; caps stay metallic silver.
 var label = Photos.wrap_can(parent,2.158,11.3)
 label.position.y = 6
 label.set_meta("photo_surface","can_label")
 for y in [0.25,11.85]: _metal(Geo.cylinder(parent,Vector3(0,y,0),2.2,0.35,SILVER))
 var tab = _metal(_box(parent,Vector3(0,12.08,0.4),Vector3(0.8,0.12,1.4),SILVER))
 tab.rotation.y = 0.2
 _box(parent,Vector3(0,12.06,-0.7),Vector3(0.9,0.04,0.7),BLACK)

func _remote(parent: Node3D) -> void:
 _box(parent,Vector3(0,0.6,0),Vector3(3.9,1.2,16),BLACK)
 _photo(parent,"remote_top",Vector3(0,1.21,0),Vector2(3.7,15.5))
 # Physical relief remains visible alongside the rectified photo face.
 var nav = Geo.cylinder(parent,Vector3(0,1.37,-3),1.1,0.22,Color("34383c"))
 nav.name = "NavigationRing"
 for z in [0.0,2.4,4.4]:
  for x in [-0.85,0.85]: Geo.cylinder(parent,Vector3(x,1.35,z),0.34,0.18,Color("3a3d3e"))

func _cable(parent: Node3D, points: Array, thickness: float = 0.13) -> void:
 var cable = Node3D.new()
 cable.name = "RoundCable"
 parent.add_child(cable)
 for i in points.size()-1:
  var segment = Geo.beam(cable,points[i],points[i+1],thickness,BLACK)
  segment.set_meta("world_material","kitchen_rubber")
 for point in points.slice(1,points.size()-1):
  var joint = Geo.ball(cable,point,Vector3.ONE*thickness*2,BLACK)
  joint.set_meta("world_material","kitchen_rubber")

func _power(parent: Node3D) -> void:
 _box(parent,Vector3(0,0.9,0),Vector3(5.2,1.8,15),BLACK)
 for z in [-4.5,0,4.5]:
  var socket = Geo.cylinder(parent,Vector3(0,1.83,z),1.75,0.1,Color("35383a"))
  socket.name = "Socket"
  for x in [-0.55,0.55]: Geo.cylinder(parent,Vector3(x,1.9,z),0.2,0.06,BLACK)
 _box(parent,Vector3(0,2.8,0),Vector3(2.7,2,3),BLACK)
 _box(parent,Vector3(0,1.9,6.5),Vector3(1.2,0.2,1),Color("922e28"))
 for index in 4:
  var points: Array = []
  for i in 11:
   var a = TAU*i/10+index*0.6
   points.append(Vector3(cos(a)*(5.6+index*0.6),0.25+index*0.15,sin(a)*(4.0+index*0.5)))
  points.append(Vector3(2+index,0.4,8.5))
  _cable(parent,points,0.12)

func _esp(parent: Node3D) -> void:
 for side in [-1,1]:
  var board = Node3D.new()
  parent.add_child(board)
  board.position.x = side*4.4
  _box(board,Vector3(0,0.3,0),Vector3(5.5,0.5,8),Color("286ea6"))
  _box(board,Vector3(0,0.61,2.7),Vector3(2.3,0.1,1.6),BLACK)
  _metal(_box(board,Vector3(0,0.95,0),Vector3(2.8,0.7,3.2),SILVER))
  _metal(_box(board,Vector3(0,0.75,-3.9),Vector3(2,0.8,1),SILVER))
  for z in [-2.5,-1.5,-0.5,0.5,1.5,2.5]:
   for x in [-2.7,2.7]: _metal(_box(board,Vector3(x,0.7,z),Vector3(0.45,0.45,0.3),Color("bfaf73")))
 _cable(parent,[Vector3(-4.4,0.2,-4),Vector3(-6,0.2,-6),Vector3(0,0.2,-8),Vector3(4.4,0.2,-4)],0.1)

func _ring(parent: Node3D, p: Vector3, radius: float, thickness: float, color: Color) -> void:
 var shape = TorusMesh.new()
 shape.inner_radius = radius-thickness
 shape.outer_radius = radius+thickness
 shape.rings = 24
 shape.ring_segments = 8
 Geo.mesh(parent,shape,p,color)

func _scissors(parent: Node3D) -> void:
 for side in [-1,1]:
  _ring(parent,Vector3(side*1.8,0.5,3.3),1.5,0.35,Color("343b3c"))
  var blade = _metal(_box(parent,Vector3(-side*0.8,0.6,-2),Vector3(0.7,0.25,7),SILVER))
  blade.rotation.y = side*0.27
 _metal(Geo.cylinder(parent,Vector3(0,0.8,0.5),0.5,0.35,SILVER))

func _paper(parent: Node3D) -> void:
 _box(parent,Vector3(-1,0.14,0),Vector3(12,0.2,14),Color("e9e7de"))
 for i in 5:
  _box(parent,Vector3(-2,0.26,-4+i*1.1),Vector3(7,0.015,0.09),Color("999d97"))
 var blister = Node3D.new()
 blister.name = "BlisterPack"
 parent.add_child(blister)
 blister.position = Vector3(1,0.3,1)
 blister.rotation.y = -0.35
 _metal(_box(blister,Vector3(0,0.15,0),Vector3(5,0.2,8),SILVER))

 for z in [-2.5,0,2.5]:
  for x in [-1.1,1.1]:
   var tablet = Geo.ball(blister,Vector3(x,0.5,z),Vector3(1.2,0.65,1.8),Color("e3e3dc"))
   tablet.material_override.roughness = 0.27

func _adapter(parent: Node3D) -> void:
 _box(parent,Vector3(0,1.5,0),Vector3(5.3,3,6.4),WHITE)
 for i in 3: _box(parent,Vector3(0,3.01,-1+i*0.6),Vector3(2.3,0.02,0.08),Color("a4a8a2"))
 for x in [-1,1]: _metal(Geo.cylinder(parent,Vector3(x,1.3,-4.1),0.2,2,SILVER)).rotation.x = PI/2
 _box(parent,Vector3(0,1.3,3.23),Vector3(1.8,0.7,0.08),BLACK)

func _cloth(parent: Node3D) -> void:
 var base = Geo.ball(parent,Vector3(0,1,0),Vector3(15,1.8,12),Color("187f4b"))
 base.set_meta("world_material","kitchen_fabric")
 for i in 4:
  var fold = Geo.ball(parent,Vector3(-4+i*2.5,1.5,1.5*sin(i)),Vector3(4,2,8),Color("279457") if i%2 else Color("e4e7de"))
  fold.rotation.y = i*0.35
  fold.set_meta("world_material","kitchen_fabric")

func _globe(parent: Node3D) -> void:
 _box(parent,Vector3(0,1.5,0),Vector3(8,3,8),Color("d5d3c6"))
 _box(parent,Vector3(0,3.35,0),Vector3(5,0.7,5),BLACK)
 _metal(Geo.cylinder(parent,Vector3(0,3.8,0),2.0,0.4,SILVER))
 var glass = Geo.ball(parent,Vector3(0,7.2,0),Vector3.ONE*6.4,Color(0.72,0.83,0.84,0.42))
 glass.name = "CrystalSphere"
 glass.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 glass.material_override.roughness = 0.09
 glass.material_override.metallic_specular = 0.8
 glass.set_meta("world_material","kitchen_glass")
