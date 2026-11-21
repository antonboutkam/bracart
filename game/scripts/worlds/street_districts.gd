extends RefCounted
## Photo-informed silhouettes; supplied photos are reference only, never textures.
const Geo = preload("res://scripts/geometry.gd")
const Art = preload("res://scripts/worlds/world_art.gd")
const Architecture = preload("res://scripts/worlds/architecture.gd")
var batches: Dictionary = {}
var stamps: Array[Dictionary] = []
var cap: ArrayMesh
var world: int
var frame = Transform3D.IDENTITY

static func build(track: Node3D) -> Node3D:
 var builder = new()
 return builder._build(track)

func _build(track: Node3D) -> Node3D:
 world = track.world_index
 var root = Node3D.new()
 root.name = "StreetDistricts"
 track.add_child(root)
 cap = Architecture.cap_mesh()
 if world == 3: _haarlem(track)
 elif world == 4: _uithoorn(track)
 for key in batches:
  var batch: Dictionary = batches[key]
  var mm = MultiMesh.new()
  mm.transform_format = MultiMesh.TRANSFORM_3D
  mm.mesh = batch.mesh
  mm.instance_count = batch.transforms.size()
  for i in batch.transforms.size(): mm.set_instance_transform(i,batch.transforms[i])
  var node = MultiMeshInstance3D.new()
  node.name = "District_"+str(key)
  node.multimesh = mm
  node.set_meta("district_material",batch.kind)
  root.add_child(node)
 if world == 4:
  var nameplate = Geo.text(root,"HET SPOORHUIS",Vector3(-41,-17.2,37.05),28)
  nameplate.rotation.y = PI
 root.set_meta("buildings",stamps)
 root.set_meta("reference_source","assets/straatbeeld/haarlem and uithoorn, direct photos only")
 track.set_meta("district_house_count",stamps.size())
 return root

func _add(kind: String, color: Color, p: Vector3, size: Vector3, roof: bool = false, rotation_y: float = 0.0) -> void:
 var key = kind+str(color)+str(roof)
 if not batches.has(key):
  var mesh: Mesh = cap.duplicate() if roof else BoxMesh.new()
  if not roof: mesh.size = Vector3.ONE
  var mat = Art.material(kind,color,0.48)
  if roof: mesh.surface_set_material(0,mat)
  else: mesh.material = mat
  batches[key] = {"kind":kind,"mesh":mesh,"transforms":[]}
 var transform = Transform3D(Basis(Vector3.UP,rotation_y)*Basis.from_scale(size),p)
 batches[key].transforms.append(frame*transform)

func _box(kind: String, color: Color, p: Vector3, size: Vector3) -> void:
 _add(kind,color,p,size)

func _roof(kind: String, color: Color, p: Vector3, width: float, rise: float, depth: float, turned: bool = false) -> void:
 _add(kind,color,p,Vector3(width/9.8,rise/3.8,depth/12.1),true,PI/2 if turned else 0.0)

# Ground volume + complete cap stay closed. Details use global shared batches.
func _house(width: float, depth: float, h: float, variant: int, future: bool) -> void:
 var brick = "haarlem_brick" # Shared photographic red-brick set; world alias is historical.
 var tint = [Color("a66e52"),Color("c08a65"),Color("855849"),Color("bd9b7e")][variant%4] if future else [Color("ead1b7"),Color("d6b59a"),Color("f1dcc5"),Color("bfa58e")][variant%4]
 var rise = 2.7 if future else 3.2
 _box(brick,tint,Vector3(0,h/2,0),Vector3(width,h,depth))
 _roof("roof",Color("8f7668") if future else Color("a58b7a"),Vector3(0,h-0.12,0),depth+0.35 if future else width+0.35,rise,width+0.2 if future else depth+0.35,future)
 if not future:
  # Masonry front is itself a closed triangular prism; steps and lists have thickness.
  _roof(brick,tint,Vector3(0,h-0.13,-depth/2-0.1),width,rise,0.22)
  if variant%3 == 0:
   for step in 4:
    var sw = width*(1.0-step*0.22)
    _box(brick,tint,Vector3(0,h+step*0.78+0.28,-depth/2-0.12),Vector3(sw,0.8,0.4))
    _box("stone",Color("e9dfca"),Vector3(0,h+step*0.78+0.72,-depth/2-0.14),Vector3(sw+0.12,0.12,0.47))
  elif variant%3 == 1:
   _box(brick,tint,Vector3(0,h+1.52,-depth/2-0.12),Vector3(width,3.3,0.35))
   _box("wood",Color("f0e8db"),Vector3(0,h+3.2,-depth/2-0.18),Vector3(width+0.2,0.3,0.6))
  else:
   _box("wood",Color("f0e8db"),Vector3(0,h-0.1,-depth/2-0.17),Vector3(width+0.15,0.25,0.4))
 _box("stone",Color("a99783"),Vector3(0,0.3,0),Vector3(width+0.06,0.6,depth+0.06))
 for y in [2.3,5.8,9.2]:
  if y>h-0.8: continue
  for x in [-width*0.26,width*0.26]:
   var ww = width*0.28
   _box("glass",Color("738a90"),Vector3(x,y,-depth/2-0.07),Vector3(ww,2.1,0.12))
   for dx in [-ww/2,ww/2]: _box("wood",Color("f2ece0"),Vector3(x+dx,y,-depth/2-0.18),Vector3(0.12,2.3,0.2))
   for dy in [-1.1,0.1,1.1]: _box("wood",Color("f2ece0"),Vector3(x,y+dy,-depth/2-0.19),Vector3(ww+0.16,0.12,0.22))
 _box("wood",Color("405b50"),Vector3(0,1.3,-depth/2-0.13),Vector3(width*0.2,2.6,0.2))
 if future:
  # Typical roof dormer, boxed closed with flat top, white cheeks and dark inset glass.
  _box("wood",Color("eae9dc"),Vector3(0,h+0.9,-depth*0.365),Vector3(width*0.65,1.8,2.0))
  _box("roof",Color("555a59"),Vector3(0,h+1.85,-depth*0.365),Vector3(width*0.7,0.2,2.18))
  _box("glass",Color("617984"),Vector3(0,h+0.9,-depth*0.365-1.08),Vector3(width*0.52,1.25,0.12))
  _box("grass",Color("728d5e"),Vector3(0,0.03,-depth/2-2.4),Vector3(width-0.2,0.12,4))
  for x in [-width/2,width/2]: _box("grass",Color("5b794e"),Vector3(x,0.5,-depth/2-2.4),Vector3(0.3,1,4))
  _box("stone",Color("bcb5a7"),Vector3(0,0.07,-depth/2-2.3),Vector3(0.85,0.15,4.2))
 else:
  _box("stone",Color("c7b9a4"),Vector3(0,-0.16,-depth/2-0.8),Vector3(width,0.3,1.6))
  if variant%4 == 0:
   _box("wood",Color("546953"),Vector3(0,2.9,-depth/2-0.27),Vector3(width-0.1,0.55,0.4))
   _box("glass",Color("546d70"),Vector3(0,1.5,-depth/2-0.17),Vector3(width-0.5,2.2,0.2))
  if variant%5 == 0:
   _box("stone",Color("a99b88"),Vector3(width*0.35,0.2,-depth/2-1),Vector3(0.8,0.45,0.65))
   _box("grass",Color("607c50"),Vector3(width*0.35,0.8,-depth/2-1),Vector3(0.9,0.8,0.7))
 stamps.append({"frame":frame,"width":width,"depth":depth,"height":h+rise+0.4,"future":future,"variant":variant%3})

func _haarlem(track: Node3D) -> void:
 var samples: Array[Vector3] = []
 for i in int(ceil(track.length)):
  samples.append(track.position_at(i))
 var count = int(track.length/5.65)
 for side in [-1,1]:
  for i in count:
   var d: float = (i+0.25)*track.length/count
   if track.v2_course != null and not track.v2_course.scenery_safe(d,24): continue
   var direction: Vector3 = track.frame(d).basis.x
   direction.y = 0
   direction = direction.normalized()*side
   var z = direction
   var basis = Basis(Vector3.UP.cross(z),Vector3.UP,z)
   var width = 5.4
   var depth = 7.8
   var origin: Vector3 = track.position_at(d)+direction*(track.width+5.0+depth/2)
   origin.y = track.position_at(d).y-1.1
   frame = Transform3D(basis,origin)
   var clear = true
   for q in samples:
    var local = basis.inverse()*(q-origin)
    if absf(local.x)<width/2+track.width+3.1 and absf(local.z)<depth/2+track.width+3.1:
     clear = false
     break
   # Leave both the landmark envelope and its roadside view open. Existing
   # scenery stays unchanged; only the newly registered Haarlem pair participates.
   for landmark in track.get_children():
    if not landmark.has_meta("haarlem_landmark"): continue
    var bounds: AABB = landmark.get_meta("bounds")
    var radius = Vector2(bounds.size.x,bounds.size.z).length()/2
    var house_radius = Vector2(width,depth+3.4).length()/2
    if Vector2(origin.x-landmark.position.x,origin.z-landmark.position.z).length() < radius+house_radius+8:
     clear = false
     break
   if not clear: continue
   # Extend the street foundation down to existing city ground.
   _box("haarlem_stone",Color("b8a893"),Vector3(0,(-22-origin.y)/2,0),Vector3(width,origin.y+22,depth))
   _house(width,depth,7.8+(i%3)*1.7,i,false)

func _tram_clear(p: Vector3, radius: float) -> bool:
 # Conservative exact sampled centreline distance, matching Sem's ellipse contract.
 for i in 192:
  var a = TAU*i/192.0
  var rail = Vector3(83+49*cos(a),-21.85,100*sin(a))
  if Vector2(p.x-rail.x,p.z-rail.z).length()<radius+5.5: return false
 return true

func _uithoorn(track: Node3D) -> void:
 # Ground neighbourhoods; the classic street route reserves its full corridor.
 var number = 0
 var corridor: Array[Vector3] = []
 if track.ground_course != null:
  for i in int(ceil(track.length/2)): corridor.append(track.position_at(i*2.0))
 for side in [-1,1]:
  for row in 5:
   var z = -130.0+row*59
   for column in 13:
    var x = side*(39.0+column*5.9)
    var p = Vector3(x,-21.8,z)
    if not _tram_clear(p,15.0): continue
    var road_clear = true
    for q in corridor:
     if Vector2(p.x-q.x,p.z-q.z).length()<track.width+20:
      road_clear = false
      break
    if not road_clear: continue
    # Keep the photographed landmark's high gable and lower wing unobstructed.
    if Vector2(p.x+38,p.z-44).length()<25: continue
    var landmark_clear = true
    for site in track.get_meta("scenic_sites",[]):
     if not site.has("uithoorn_landmark"): continue
     # Whole house, garden/pavement and an eight metre view corridor.
     if Vector2(p.x-site.position.x,p.z-site.position.z).length()<float(site.radius)+19:
      landmark_clear = false
      break
    if not landmark_clear: continue
    frame = Transform3D(Basis.IDENTITY,p)
    _house(5.8,8.4,5.7,number,true)
    _box("haarlem_paving",Color("9f9990"),Vector3(0,0.01,-11.5),Vector3(5.9,0.12,5))
    number+=1
 _spoorhuis()

func _spoorhuis() -> void:
 # Interpreted landmark: cream stepped main gable and low red-roofed brick wing.
 frame = Transform3D(Basis.IDENTITY,Vector3(-41,-21.8,44))
 _house(9,13,8.5,2,true)
 _box("stone",Color("eee5ce"),Vector3(0,5,-6.65),Vector3(9.2,10,0.3))
 _roof("stone",Color("eee5ce"),Vector3(0,9.7,-6.65),9.2,3.2,0.35)
 for x in [-2.5,0,2.5]:
  _box("glass",Color("405456"),Vector3(x,6.8,-6.88),Vector3(1.2,2.6,0.12))
  _box("wood",Color("f3ead6"),Vector3(x,6.8,-6.95),Vector3(1.42,0.13,0.2))
 frame.origin += Vector3(8,-0.0,1.8)
 _house(7,9,4,0,true)
