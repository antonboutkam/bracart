extends RefCounted
## Far scenery only. All geometry stays beyond the 300 m exclusion radius.
const Geo = preload("res://scripts/geometry.gd")
const MIN_RADIUS = 300.0
var batches: Dictionary = {}
var records: Array[Dictionary] = []
var root: Node3D
var world: int

static func build(parent: Node3D, index: int) -> Node3D:
 if index not in [3,4]: return null
 var builder = new()
 return builder._build(parent,index)

func _build(parent: Node3D, index: int) -> Node3D:
 world = index
 root = Node3D.new()
 root.name = "DutchHorizons"
 parent.add_child(root)
 if index==3: _dunes()
 else: _polders()
 for key in batches:
  var batch: Dictionary = batches[key]
  var mm = MultiMesh.new()
  mm.transform_format = MultiMesh.TRANSFORM_3D
  mm.mesh = batch.mesh
  mm.instance_count = batch.transforms.size()
  for i in batch.transforms.size(): mm.set_instance_transform(i,batch.transforms[i])
  var node = MultiMeshInstance3D.new()
  node.multimesh = mm
  node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  node.set_meta("instance_transforms",batch.transforms)
  root.add_child(node)
 root.set_meta("geometry_records",records)
 root.set_meta("minimum_radius",MIN_RADIUS)
 root.set_meta("landscape", "soft_dunes_marram" if world==3 else "low_polder_fields_ditches_amstel")
 root.set_meta("review_views",[
  {"id":"haarlem-duinen" if world==3 else "uithoorn-polder-amstel", "eye":Vector3(-110,32,30) if world==3 else Vector3(40,55,225),"target":Vector3(-440,-9,60) if world==3 else Vector3(55,-20,650)}])
 return root

func _add(kind: String, p: Vector3, size: Vector3, color: Color, yaw: float = 0.0) -> void:
 var key = kind+str(color)
 if not batches.has(key):
  var mesh: PrimitiveMesh
  if kind=="dune":
   mesh = SphereMesh.new()
   mesh.radius = 0.5
   mesh.height = 1
   mesh.radial_segments = 24
   mesh.rings = 10
  else:
   mesh = BoxMesh.new()
   mesh.size = Vector3.ONE
  mesh.material = Geo.material(color)
  mesh.material.roughness = 0.98
  mesh.material.metallic_specular = 0.08
  batches[key] = {"mesh":mesh,"transforms":[]}
 var transform = Transform3D(Basis(Vector3.UP,yaw)*Basis.from_scale(size),p)
 batches[key].transforms.append(transform)
 records.append({"kind":kind,"transform":transform,"bounds":transform*batches[key].mesh.get_aabb()})

func _dunes() -> void:
 for i in 12:
  var angle = 3.25+i*0.235
  var radius = 460.0+(i%3)*45
  var center = Vector3(sin(angle)*radius,-22,cos(angle)*radius)
  var size = Vector3(150+(i%3)*18,26+(i%4)*3,105)
  _add("dune",center,size,[Color("c5b58c"),Color("cebf99"),Color("b5ad8a")][i%3],-angle)
  # Sparse marram silhouettes on the crest, deliberately short and not pine trees.
  for tuft in 9:
   var offset = Vector3(-38+tuft*9,0,sin(tuft*2.3+i)*12).rotated(Vector3.UP,-angle)
   var y = -22+size.y*0.5*sqrt(maxf(0.0,1-pow((tuft*9-38)/(size.x/2),2)-pow(sin(tuft*2.3+i)*12/(size.z/2),2)))
   for blade in 3:
    _add("marram",Vector3(center.x+offset.x,y+0.35,center.z+offset.z),Vector3(0.16,0.8+blade*0.16,0.16),Color("94956c"),blade*0.7)

func _polders() -> void:
 var river_points: Array[Vector3] = []
 for side in [-1,1]:
  for i in 81:
   var t = i/80.0
   river_points.append(Vector3(side*75*sin(t*PI*0.9)*smoothstep(0,0.4,t),-21.735,side*(440+t*400)))
 for ix in range(-5,6):
  for iz in range(-6,7):
   var center = Vector3(ix*140,-21.75,iz*120)
   var dx = maxf(absf(center.x)-69,0)
   var dz = maxf(absf(center.z)-59,0)
   if Vector2(dx,dz).length()<MIN_RADIUS+20: continue
   var river_clear = true
   for point in river_points:
    var rx = maxf(absf(center.x-point.x)-70,0)
    var rz = maxf(absf(center.z-point.z)-60,0)
    if Vector2(rx,rz).length()<29:
     river_clear = false
     break
   if not river_clear: continue
   var color = [Color("83955d"),Color("788c55"),Color("94a36c"),Color("697f50")][posmod(ix*7+iz*3,4)]
   _add("field",center,Vector3(138,0.08,118),color)
   _add("ditch",center+Vector3(69.2,-0.025,0),Vector3(1.3,0.02,118),Color("648681"))
   _add("ditch",center+Vector3(0,-0.025,59.2),Vector3(138,0.02,1.3),Color("648681"))
 for sign_value in [-1,1]: _amstel(sign_value)

func _amstel(sign_value: int) -> void:
 var points: Array[Vector3] = []
 var water = SurfaceTool.new()
 water.begin(Mesh.PRIMITIVE_TRIANGLES)
 var banks = SurfaceTool.new()
 banks.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in 41:
  var t = i/40.0
  # Starts aligned with existing straight water, then bends gradually through fields.
  points.append(Vector3(sign_value*75*sin(t*PI*0.9)*smoothstep(0,0.4,t),-21.735,sign_value*(440+t*400)))
 var rights: Array[Vector3] = []
 for i in points.size():
  rights.append((points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]).normalized().cross(Vector3.UP))
 for i in points.size()-1:
  var a = points[i]
  var b = points[i+1]
  var ra = rights[i]
  var rb = rights[i+1]
  _ribbon_quad(water,a-ra*24.5,b-rb*24.5,b+rb*24.5,a+ra*24.5)
  for side in [-1,1]:
   _ribbon_quad(banks,a+ra*(side*24.5),b+rb*(side*24.5),b+rb*(side*27),a+ra*(side*27))
 var node = Geo.mesh(root,water.commit(),Vector3.ZERO,Color("56867f"))
 node.name = "AmstelNorth" if sign_value>0 else "AmstelSouth"
 node.material_override.roughness = 0.22
 node.material_override.metallic_specular = 0.5
 node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var bank = Geo.mesh(root,banks.commit(),Vector3.DOWN*0.015,Color("a4af81"))
 bank.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 records.append({"kind":"amstel","points":points,"width":49.0,"bounds":node.get_aabb()})
 records.append({"kind":"amstel_bank","bounds":bank.transform*bank.get_aabb()})
 root.set_meta(node.name,points)

func _ribbon_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
 for triangle in [[a,b,c],[a,c,d]]:
  if (triangle[2]-triangle[0]).cross(triangle[1]-triangle[0]).y<0: triangle=[triangle[0],triangle[2],triangle[1]]
  for point in triangle:
   st.set_normal(Vector3.UP)
   st.set_uv(Vector2(point.x,point.z)*0.04)
   st.add_vertex(point)
