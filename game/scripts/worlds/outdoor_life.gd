extends RefCounted
## Decorative street life on real supported promenades. Never owns race collision.
const Geo = preload("res://scripts/geometry.gd")
const Walkers = preload("res://scripts/worlds/street_walkers.gd")
const NatureAccents = preload("res://scripts/worlds/nature_accents.gd")
const RADIUS = 14.5
var track: Node3D
var root: Node3D
var world: int
var batches: Dictionary = {}
var clusters: Array[Dictionary] = []
var walkers: Array[Dictionary] = []
var frame: Transform3D
var samples: Array[Vector3] = []
var houses: Array = []
var sites: Array = []
var obstacles: Array[AABB] = []
var current_bounds = AABB()
var has_bounds = false

static func build(target: Node3D) -> Node3D:
 if target.world_index == 5: return null
 var builder = new()
 return builder._build(target)

func _build(target: Node3D) -> Node3D:
 track = target
 world = track.world_index
 root = Node3D.new()
 root.name = "OutdoorLife"
 track.add_child(root)
 for i in int(ceil(track.length/0.8)): samples.append(track.position_at(i*0.8))
 if track.has_node("StreetDistricts"): houses = track.get_node("StreetDistricts").get_meta("buildings",[])
 sites = track.get_meta("scenic_sites",[]).duplicate()
 # Existing direct skyline and roadside primitives also have physical bounds.
 for child in track.get_children():
  if not child is MeshInstance3D or child.mesh is ArrayMesh: continue
  var bounds: AABB = child.transform*child.get_aabb()
  if bounds.size.x>150 or bounds.size.z>150: continue
  obstacles.append(bounds)
 for index in 36:
  if clusters.size()>=24: break
  var candidate = _site(index)
  if not candidate.is_finite(): continue
  var d = track.length*(index+0.33)/36.0
  var tangent: Vector3 = -track.frame(d).basis.z
  tangent.y = 0
  tangent = tangent.normalized()
  frame = Transform3D(Basis(tangent,Vector3.UP,tangent.cross(Vector3.UP)),candidate)
  current_bounds = AABB()
  has_bounds = false
  _platform()
  _tree(index)
  _vehicle(index)
  _furniture(index)
  var spec = {"id":"street_%02d" % index,"label":_label(),"center":candidate,"radius":RADIUS,"transform":frame,"static_aabb":current_bounds,"floor_y":candidate.y,"height":9.5,"vehicle":"steam_carriage" if world==3 else "parked_car","supported":true,"progress":d,"support_kind":"cloud_island" if world==2 else "ground_pedestal","walkspec":{}}
  var add_walkers = clusters.size()%6==0
  clusters.append(spec)
  sites.append({"position":candidate,"radius":RADIUS,"outdoor_life":true})
  if walkers.size()<4 and add_walkers:
   var promenade = frame*Transform3D(Basis.IDENTITY,Vector3(0,0,-1.2))
   var walk_spec = {"id":spec.id,"transform":promenade,"half_length":7.0,"width":1.8,"ground_y":0.0,"world":world,"dynamic_aabb":promenade*AABB(Vector3(-9,0,-1.5),Vector3(18,3,3))}
   walkers.append(walk_spec)
   spec.walkspec = walk_spec
 for key in batches:
  var batch: Dictionary = batches[key]
  var mm = MultiMesh.new()
  mm.transform_format = MultiMesh.TRANSFORM_3D
  mm.mesh = batch.mesh
  mm.instance_count = batch.transforms.size()
  for i in batch.transforms.size(): mm.set_instance_transform(i,batch.transforms[i])
  var node = MultiMeshInstance3D.new()
  node.name = "StreetDetails_"+str(batches.keys().find(key))
  node.multimesh = mm
  # RenderingServerDummy does not retain retrievable instance buffers headlessly.
  # Retain exactly the submitted matrices for deterministic structural QA.
  node.set_meta("instance_transforms",batch.transforms)
  root.add_child(node)
 root.set_meta("clusters",clusters)
 root.set_meta("walker_specs",walkers)
 root.set_meta("world",world)
 track.set_meta("outdoor_life_count",clusters.size())
 var registered: Array = track.get_meta("scenic_sites",[])
 for cluster in clusters: registered.append({"position":cluster.center,"radius":cluster.radius,"outdoor_life":true})
 track.set_meta("scenic_sites",registered)
 Walkers.build(track,walkers)
 NatureAccents.build(track,clusters)
 return root

func _label() -> String:
 return ["Zonsondergangpark","Neon-stadsplein","Gedragen wolkenpromenade","Haarlemse parkstrook 1888","Uithoornse buurtstraat"][world]

func _site(index: int) -> Vector3:
 var d = track.length*(index+0.33)/36.0
 if track.v2_course != null and not track.v2_course.scenery_safe(d,24): return Vector3.INF
 var side = -1.0 if index%2 else 1.0
 var normal: Vector3 = track.frame(d).basis.x
 normal.y = 0
 normal = normal.normalized()
 var origin: Vector3 = track.position_at(d)
 # Compare both sides at each distance before accepting a farther placement.
 for step in 16:
  for flip in 2:
   var sign_value = side if flip==0 else -side
   var p = origin+normal*sign_value*(track.width+RADIUS+8+step*7)
   p.y = -20.85 if world==4 else origin.y-1.0
   if _safe(p): return p
 return Vector3.INF

func _safe(p: Vector3) -> bool:
 # Arc-length guard covers the gaps between samples as well as the sampled points.
 for q in samples:
  if Vector2(p.x-q.x,p.z-q.z).length()<track.width+RADIUS+4.5: return false
 # Water has fixed x bounds in these worlds; outdoor objects stay on dry land.
 if world in [0,3,4] and absf(p.x)<24.5+RADIUS+1: return false
 for site in sites:
  var q: Vector3 = site.position
  if Vector2(p.x-q.x,p.z-q.z).length()<RADIUS+float(site.radius)+2: return false
 for obstacle in obstacles:
  var dx = maxf(maxf(obstacle.position.x-p.x,p.x-obstacle.end.x),0)
  var dz = maxf(maxf(obstacle.position.z-p.z,p.z-obstacle.end.z),0)
  if Vector2(dx,dz).length()<RADIUS+1.0: return false
 for house in houses:
  var local: Vector3 = house.frame.affine_inverse()*p
  # Includes front gardens, stoops, roof projection and the complete group radius.
  if absf(local.x)<house.width/2+RADIUS+1.5 and local.z>-house.depth/2-10-RADIUS and local.z<house.depth/2+RADIUS+1.5:
   return false
 if world==4:
  for i in 192:
   var a = TAU*i/192.0
   var q = Vector3(83+49*cos(a),-21.68,100*sin(a))
   if Vector2(p.x-q.x,p.z-q.z).length()<RADIUS+6.0: return false
 return true

func _instance(shape: String, color: Color, p: Vector3, scale_value: Vector3, rotation: Vector3 = Vector3.ZERO, metallic: bool = false, glow: bool = false) -> void:
 var key = shape+str(color)+str(metallic)+str(glow)
 if not batches.has(key):
  var mesh: PrimitiveMesh
  if shape=="box":
   mesh = BoxMesh.new()
   mesh.size = Vector3.ONE
  elif shape=="sphere":
   mesh = SphereMesh.new()
   mesh.radius = 0.5
   mesh.height = 1
   mesh.radial_segments = 12
   mesh.rings = 6
  else:
   mesh = CylinderMesh.new()
   mesh.top_radius = 0.5
   mesh.bottom_radius = 0.5
   mesh.height = 1
   mesh.radial_segments = 12
  var mat = Geo.material(color,0.3 if glow else 0.0)
  mat.roughness = 0.35 if metallic else 0.8
  mat.metallic = 0.6 if metallic else 0.0
  mesh.material = mat
  batches[key] = {"mesh":mesh,"transforms":[]}
 var local = Transform3D(Basis.from_euler(rotation)*Basis.from_scale(scale_value),p)
 var transform = frame*local
 batches[key].transforms.append(transform)
 var bounds: AABB = transform*batches[key].mesh.get_aabb()
 current_bounds = current_bounds.merge(bounds) if has_bounds else bounds
 has_bounds = true

func _box(p: Vector3, size: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO, metallic: bool = false, glow: bool = false) -> void:
 _instance("box",color,p,size,rotation,metallic,glow)

func _ball(p: Vector3, size: Vector3, color: Color) -> void:
 _instance("sphere",color,p,size)

func _cylinder(p: Vector3, size: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO, metallic: bool = false) -> void:
 _instance("cylinder",color,p,size,rotation,metallic)

func _platform() -> void:
 var floor = [Color("d6b58a"),Color("415468"),Color("e7d9f0"),Color("bdac91"),Color("a7a59a")][world]
 _box(Vector3(0,-0.3,0),Vector3(22,0.6,12),floor)
 if world==2:
  # This is a carried island, not pedestrians/cars hanging in empty sky.
  for x in [-6,0,6]: _ball(Vector3(x,-4.0,0),Vector3(13,7.5,13),Color("e7e4f0"))
 else:
  var bottom = -22.0
  var height = frame.origin.y-bottom
  if height>0.4: _box(Vector3(0,-height/2-0.3,0),Vector3(21.5,height,11.5),floor.darkened(0.17))
 if world in [1,2]:
  for z in [-5.9,5.9]: _box(Vector3(0,0.08,z),Vector3(22,0.15,0.13),Color("4ed5dd") if world==1 else Color("ead19e"),Vector3.ZERO,false,true)

func _tree(index: int) -> void:
 var trunk = Color("95734e")
 var leaf = [Color("527d55"),Color("408e77"),Color("94c887"),Color("788f5e"),Color("59855b")][world]
 _cylinder(Vector3(-7,3,2),Vector3(0.65,6,0.65),trunk)
 if world==0:
  for i in 5:
   var a = TAU*i/5
   _instance("sphere",leaf,Vector3(-7+cos(a)*1.2,6.2,2+sin(a)*1.2),Vector3(5,0.7,1.7),Vector3(0,-a,0.12))
 else:
  _ball(Vector3(-7,6,2),Vector3(4.8,4,4.6),leaf)
  _ball(Vector3(-8.1,5.5,2),Vector3(2.6,3,3),leaf.lightened(0.08))
  if world==2: _ball(Vector3(-6,7,2),Vector3(2.6,2.8,2.6),[Color("eeb3cb"),Color("b6b4e5")][index%2])
 _box(Vector3(-7,0.15,2),Vector3(2.1,0.3,2.1),Color("7b8072"))

func _vehicle(index: int) -> void:
 var color = [Color("e3b76f"),Color("557ea0"),Color("b8d4cb"),Color("826345"),Color("8d9da2")][world]
 if world!=3: color = color.lightened(0.08*(index%3))
 var wheel_radius = 0.7 if world==3 else 0.43
 for x in [2.6,5.4]:
  for z in [0.85,3.15]:
   _cylinder(Vector3(x,wheel_radius,z),Vector3(wheel_radius*2,0.25,wheel_radius*2),Color("293136"),Vector3(PI/2,0,0))
   _cylinder(Vector3(x,wheel_radius,z+(-0.14 if z<2 else 0.14)),Vector3(0.36,0.05,0.36),Color("acb0a6"),Vector3(PI/2,0,0),true)
 _box(Vector3(4,1.0,2),Vector3(4.8,0.75,2.25),color)
 _box(Vector3(3.8,1.85,2),Vector3(2.7,1.0,1.95),color)
 for z in [0.99,3.01]: _box(Vector3(3.75,1.95,z),Vector3(2.2,0.55,0.035),Color("3c5963"))
 for x in [1.58,6.42]:
  _box(Vector3(x,0.97,2),Vector3(0.12,0.16,1.95),Color("bfbdab"),Vector3.ZERO,true)
 if world==3:
  _cylinder(Vector3(5.5,2,2),Vector3(0.55,2.3,0.55),Color("b08b48"),Vector3.ZERO,true)
  _box(Vector3(3.8,2.48,2),Vector3(2.9,0.18,2.2),Color("4b473d"))
 elif world==1:
  _box(Vector3(4,0.55,0.84),Vector3(3.8,0.1,0.08),Color("63e1df"),Vector3.ZERO,false,true)
 else:
  for z in [1.3,2.7]: _box(Vector3(6.43,1.15,z),Vector3(0.08,0.2,0.45),Color("e5d9ac"))

func _furniture(index: int) -> void:
 var wood = Color("a17d58") if world!=1 else Color("668692")
 _box(Vector3(-3.5,0.9,-4.0),Vector3(4.3,0.22,1.15),wood)
 _box(Vector3(-3.5,1.6,-4.55),Vector3(4.3,0.8,0.18),wood)
 for x in [-5,-2]: _box(Vector3(x,0.45,-4),Vector3(0.22,0.9,0.85),Color("424e4b"))
 _cylinder(Vector3(0.2,0.65,-4.1),Vector3(0.9,1.3,0.9),Color("496564"))
 _cylinder(Vector3(0.2,1.34,-4.1),Vector3(1,0.12,1),Color("303f40"))
 _box(Vector3(8,0.35,-3.8),Vector3(2,0.7,1.2),Color("b6a493"))
 _ball(Vector3(8,0.85,-3.8),Vector3(1.9,0.7,1.15),Color("6d945e"))
 for x in [7.4,8,8.6]: _ball(Vector3(x,1.2,-3.8),Vector3(0.4,0.4,0.4),Color("d7a18e") if world!=2 else Color("b8a0dc"))
 _cylinder(Vector3(9.8,2.8,-4.5),Vector3(0.14,5.6,0.14),Color("535d5a"))
 _box(Vector3(9.8,5.65,-4.5),Vector3(0.7,0.7,0.7),Color("f3d9a3") if world!=1 else Color("67d6e1"),Vector3.ZERO,false,world==1)
 if index%3==0:
  # Low bicycle parking rail at the rear edge, away from the walking strip.
  for x in [-1,0,1]:
   for side in [-1,1]: _cylinder(Vector3(x+side*0.3,0.6,4.6),Vector3(0.08,1.2,0.08),Color("757e7b"))
   _box(Vector3(x,1.2,4.6),Vector3(0.65,0.08,0.08),Color("757e7b"),Vector3.ZERO,true)
