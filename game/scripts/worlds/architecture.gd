extends RefCounted
## Closed roadside volumes. Decorative only: no collision or route ownership.
const Geo = preload("res://scripts/geometry.gd")
const Art = preload("res://scripts/worlds/world_art.gd")
const HALF_SPAN = 4.9
const RISE = 3.8
const HALF_DEPTH = 6.05

# Faces are separately shaded, but their geometric edges coincide exactly.
# Godot uses clockwise front faces; normals are explicitly outward.
static func cap_mesh() -> ArrayMesh:
 var st = SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var a = Vector3(-HALF_SPAN,0,-HALF_DEPTH)
 var b = Vector3(HALF_SPAN,0,-HALF_DEPTH)
 var c = Vector3(0,RISE,-HALF_DEPTH)
 var d = Vector3(-HALF_SPAN,0,HALF_DEPTH)
 var e = Vector3(HALF_SPAN,0,HALF_DEPTH)
 var f = Vector3(0,RISE,HALF_DEPTH)
 _triangle(st,a,b,c,Vector3.FORWARD)
 _triangle(st,d,f,e,Vector3.BACK)
 _quad(st,a,d,e,b,Vector3.DOWN)
 _quad(st,a,c,f,d,Vector3(-RISE,HALF_SPAN,0).normalized())
 _quad(st,b,e,f,c,Vector3(RISE,HALF_SPAN,0).normalized())
 return st.commit()

static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
 var vertices = [a,b,c] if (c-a).cross(b-a).dot(normal) > 0 else [a,c,b]
 for vertex in vertices:
  st.set_normal(normal)
  st.set_uv(Vector2(vertex.x,vertex.z))
  st.add_vertex(vertex)

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
 _triangle(st,a,b,c,normal)
 _triangle(st,a,c,d,normal)

static var shared_cap: ArrayMesh

static func house(parent: Node3D, p: Vector3, index: int, solar: bool) -> Node3D:
 var root = Node3D.new()
 root.name = "ClosedHouse_%02d" % index
 root.set_meta("architecture_house",true)
 root.set_meta("solar",solar)
 parent.add_child(root)
 root.position = p
 var height: float = 10 + (index % 4) * 3
 root.set_meta("eaves_height",height)
 var facade = ([Color("f4e6cb"),Color("d3e4d3"),Color("eac1a7")] if solar else [Color("bd8c68"),Color("d0ab7a"),Color("a76d56")])[index % 3]
 var masonry = "stone" if solar else "brick"
 if p.y > -21:
  Art.box(root,Vector3(0,(-22-p.y)/2,0),Vector3(9,p.y+22,11),masonry,facade.darkened(0.08))
 Art.box(root,Vector3.UP*height/2,Vector3(9,height,11),masonry,facade.lightened(0.25),0.35)
 # Full triangular prism: ridge, both gables, roof planes and soffit are closed.
 # A 15 cm overlap with the wall eliminates any seam at the eaves.
 if shared_cap == null: shared_cap = cap_mesh()
 var roof = Geo.mesh(root,shared_cap,Vector3(0,height-0.15,0),Color.WHITE)
 roof.name = "ClosedRoof"
 Art.apply(roof,"grass" if solar else "roof",Color("bfdb9a") if solar else Color("e3bca6"),0.4)
 # Thin masonry gables sit just in front of the cap ends; the cap stays watertight.
 for side in [-1,1]:
  var st = SurfaceTool.new()
  st.begin(Mesh.PRIMITIVE_TRIANGLES)
  _triangle(st,Vector3(-HALF_SPAN,0,side*(HALF_DEPTH+0.005)),Vector3(HALF_SPAN,0,side*(HALF_DEPTH+0.005)),Vector3(0,RISE,side*(HALF_DEPTH+0.005)),Vector3(0,0,side))
  var gable = Geo.mesh(root,st.commit(),Vector3(0,height-0.15,0),facade)
  Art.apply(gable,masonry,facade.lightened(0.25),0.35)
  for edge in [-1,1]:
   Geo.beam(root,Vector3(edge*HALF_SPAN,height-0.15,side*(HALF_DEPTH+0.01)),Vector3(0,height+RISE-0.15,side*(HALF_DEPTH+0.01)),0.1,Color("e5d6bc"))
 Art.box(root,Vector3(0,height+RISE-0.08,0),Vector3(0.32,0.3,12.4),"roof",Color("6a5650"))
 for side in [-1,1]:
  Art.box(root,Vector3(side*4.72,height-0.05,0),Vector3(0.34,0.38,12.4),"metal" if solar else "wood",Color("776a5b"))
 # Stone plinth / cornice wrap all sides; no one-sided facade cards.
 Art.box(root,Vector3(0,0.45,0),Vector3(9.15,0.9,11.15),"stone",Color("bcad98"))
 Art.box(root,Vector3(0,height-0.45,0),Vector3(9.2,0.25,11.2),"stone",Color("e5d6bc"))
 _facades(root,height,solar)
 if solar:
  var angle = atan2(RISE,HALF_SPAN)
  var panel = Art.box(root,Vector3(2.45,height-0.15+RISE*0.5,0)+Vector3(sin(angle),cos(angle),0)*0.16,Vector3(4.1,0.16,4.3),"solar",Color.WHITE,0.65)
  panel.name = "RoofMountedSolar"
  panel.rotation.z = -angle
 else:
  Art.box(root,Vector3(2.5,height+2.3,3),Vector3(1.1,3.6,1.1),"brick",Color("d4ad87"),0.5)
  Art.box(root,Vector3(2.5,height+4.15,3),Vector3(1.4,0.3,1.4),"stone",Color("b5a68f"))
  Geo.cylinder(root,Vector3(5,7,2),0.65,17,Color("bf874b"))
  Geo.ball(root,Vector3(5,18,2),Vector3(3,3.4,3),Color("e9decd"))
 return root

# Batch repeated details per house. Panes remain behind raised jambs/heads,
# with dark reveals and projecting sills, on front, back and both side walls.
static func _facades(root: Node3D, height: float, solar: bool) -> void:
 var batches: Dictionary = {}
 for face in 4:
  var side_face = face >= 2
  var normal = [Vector3.FORWARD,Vector3.BACK,Vector3.LEFT,Vector3.RIGHT][face]
  var tangent = Vector3.RIGHT if not side_face else Vector3.BACK
  var depth = 4.5 if side_face else 5.5
  for column in [-1,1]:
   var x: float = column * (3.0 if side_face else 2.5)
   for row in range(int((height-2)/4.5)):
    var y = 4.0 + row*4.5
    var center: Vector3 = tangent*x+Vector3.UP*y
    _detail(batches,"reveal",center+normal*(depth+0.035),Vector3(2.36,2.85,0.06),side_face)
    _detail(batches,"glass",center+normal*(depth+0.09),Vector3(1.94,2.4,0.08),side_face)
    for dx in [-1.08,1.08]:
     _detail(batches,"wood",center+tangent*dx+normal*(depth+0.21),Vector3(0.18,2.8,0.28),side_face)
    for dy in [-1.3,0.0,1.3]:
     _detail(batches,"wood",center+Vector3.UP*dy+normal*(depth+0.21),Vector3(2.3,0.16,0.28),side_face)
    _detail(batches,"stone",center+Vector3.DOWN*1.46+normal*(depth+0.3),Vector3(2.58,0.2,0.6),side_face)
 # Entrance in front has casing, dark reveal, deep door and lintel.
 _detail(batches,"reveal",Vector3(0,2.45,-5.54),Vector3(2.2,4,0.08),false)
 _detail(batches,"door",Vector3(0,2.4,-5.62),Vector3(1.7,3.8,0.18),false)
 for x in [-1.02,1.02]: _detail(batches,"wood",Vector3(x,2.45,-5.76),Vector3(0.2,4.1,0.3),false)
 _detail(batches,"stone",Vector3(0,4.55,-5.76),Vector3(2.5,0.25,0.4),false)
 _detail(batches,"stone",Vector3(0,0.45,-5.88),Vector3(2.6,0.25,0.75),false)
 var colors = {"reveal":Color("333b3c"),"glass":Color("68adbb") if solar else Color("c5c2ae"),"wood":Color("e9decd"),"stone":Color("d6c8af"),"door":Color("416662")}
 for key in batches:
  var spec: Dictionary = batches[key]
  var mm = MultiMesh.new()
  mm.transform_format = MultiMesh.TRANSFORM_3D
  var box = BoxMesh.new()
  box.size = spec.size
  box.material = Art.material("wood" if spec.kind == "door" else spec.kind,colors[spec.kind],0.4) if spec.kind != "reveal" else Geo.material(colors.reveal)
  if spec.kind == "glass": box.material.roughness = 0.2
  mm.mesh = box
  mm.instance_count = spec.positions.size()
  for i in spec.positions.size(): mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,spec.positions[i]))
  var node = MultiMeshInstance3D.new()
  node.multimesh = mm
  node.set_meta("architecture_detail",spec.kind)
  root.add_child(node)

static func _detail(batches: Dictionary, kind: String, p: Vector3, size: Vector3, side_face: bool) -> void:
 if side_face: size = Vector3(size.z,size.y,size.x)
 var key = kind+str(size)
 if not batches.has(key): batches[key] = {"kind":kind,"size":size,"positions":[]}
 batches[key].positions.append(p)
