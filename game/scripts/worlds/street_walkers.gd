extends Node3D
## Light, original primitive pedestrians and leashed dogs. No character GLBs/audio.
## Track owns this node: inherited process mode freezes the whole route and gait.
static var meshes: Dictionary = {}
static var materials: Dictionary = {}
var actors: Array[Dictionary] = []
var elapsed: float = 0

static func build(track: Node3D, specs: Array) -> Node3D:
 var walkers = new()
 walkers.name = "StreetWalkers"
 track.add_child(walkers)
 if track.world_index == 5:
  walkers.set_process(false)
  return walkers
 for spec in specs:
  walkers._actor(spec)
 walkers._pose()
 return walkers

static func route_frame(phase: float, half_length: float, width: float, ground_y: float = 0) -> Transform3D:
 var radius_x: float = maxf(0.5,half_length-1.7)
 var radius_z: float = minf(0.3,width*0.17)
 var p := Vector3(cos(phase)*radius_x,ground_y,sin(phase)*radius_z)
 var forward := Vector3(-sin(phase)*radius_x,0,cos(phase)*radius_z).normalized()
 return Transform3D(Basis(forward.cross(Vector3.UP).normalized(),Vector3.UP,-forward),p)

func _material(color: Color) -> StandardMaterial3D:
 var key: String = color.to_html()
 if not materials.has(key):
  var material := StandardMaterial3D.new()
  material.albedo_color = color
  material.roughness = 0.85
  materials[key] = material
 return materials[key]

func _shape(parent: Node3D, type: String, dimensions: Vector3, color: Color, position: Vector3) -> MeshInstance3D:
 var key: String = type + str(dimensions)
 if not meshes.has(key):
  var shape: PrimitiveMesh
  if type == "capsule":
   var capsule := CapsuleMesh.new()
   capsule.radius = dimensions.x
   capsule.height = dimensions.y
   capsule.radial_segments = 8
   capsule.rings = 2
   shape = capsule
  elif type == "ball":
   var sphere := SphereMesh.new()
   sphere.radius = dimensions.x
   sphere.height = dimensions.x*2
   sphere.radial_segments = 8
   sphere.rings = 4
   shape = sphere
  elif type == "line":
   var cylinder := CylinderMesh.new()
   cylinder.top_radius = dimensions.x
   cylinder.bottom_radius = dimensions.x
   cylinder.height = 1
   cylinder.radial_segments = 6
   shape = cylinder
  else:
   var box := BoxMesh.new()
   box.size = dimensions
   shape = box
  meshes[key] = shape
 var instance := MeshInstance3D.new()
 instance.mesh = meshes[key]
 instance.material_override = _material(color)
 parent.add_child(instance)
 instance.position = position
 return instance

func _pivot(parent: Node3D, position: Vector3, title: String) -> Node3D:
 var pivot := Node3D.new()
 pivot.name = title
 parent.add_child(pivot)
 pivot.position = position
 return pivot

func _actor(spec: Dictionary) -> void:
 var group := Node3D.new()
 group.name = "Walk_" + str(spec.id)
 add_child(group)
 group.transform = spec.transform
 var half_length: float = float(spec.get("half_length",7.0))
 var width: float = float(spec.get("width",1.8))
 var ground_y: float = float(spec.get("ground_y",0.0))
 var envelope := AABB(Vector3(-half_length-2,ground_y,-1.5),Vector3(2*(half_length+2),3,3))
 group.set_meta("route_id",str(spec.id))
 group.set_meta("world",int(spec.world))
 group.set_meta("route_kind","closed-ellipse-no-teleport")
 group.set_meta("aabb_space","track-local")
 group.set_meta("local_aabb",envelope)
 group.set_meta("dynamic_aabb",group.transform*envelope)
 group.set_meta("support_origin",group.position)
 var rig := _pivot(group,Vector3.ZERO,"WalkingPair")
 var person := _pivot(rig,Vector3.ZERO,"Pedestrian")
 var skin := Color("cf9977") if actors.size()%2 else Color("edbc91")
 var shirt: Color = [Color("dba24e"),Color("438b9b"),Color("b66569"),Color("688a52")][actors.size()%4]
 _shape(person,"capsule",Vector3(0.19,0.59,0),shirt,Vector3(0,1.15,0))
 _shape(person,"ball",Vector3(0.17,0,0),skin,Vector3(0,1.65,0))
 _shape(person,"ball",Vector3(0.175,0,0),Color("53433a"),Vector3(0,1.72,0.02)).scale = Vector3(1,0.55,1)
 _shape(person,"ball",Vector3(0.045,0,0),skin,Vector3(0,1.64,-0.16))
 for x in [-0.055,0.055]:
  _shape(person,"ball",Vector3(0.018,0,0),Color("26333b"),Vector3(x,1.68,-0.15))
 var legs: Array[Node3D] = []
 var knees: Array[Node3D] = []
 var arms: Array[Node3D] = []
 var hand: Node3D
 for side in [-1,1]:
  var leg := _pivot(person,Vector3(side*0.105,0.8,0),"Hip")
  _shape(leg,"capsule",Vector3(0.075,0.42,0),Color("354653"),Vector3(0,-0.2,0))
  var knee := _pivot(leg,Vector3(0,-0.4,0),"Knee")
  _shape(knee,"capsule",Vector3(0.06,0.36,0),Color("354653"),Vector3(0,-0.17,0))
  _shape(knee,"box",Vector3(0.15,0.08,0.27),Color("26323a"),Vector3(0,-0.35,-0.05))
  legs.append(leg)
  knees.append(knee)
  var arm := _pivot(person,Vector3(side*0.255,1.4,0),"Shoulder")
  _shape(arm,"capsule",Vector3(0.055,0.33,0),shirt,Vector3(0,-0.15,0))
  var elbow := _pivot(arm,Vector3(0,-0.3,0),"Elbow")
  elbow.rotation.x = -0.22
  _shape(elbow,"capsule",Vector3(0.047,0.3,0),skin,Vector3(0,-0.14,0))
  var palm := _pivot(elbow,Vector3(0,-0.29,0),"LeashHand" if side == 1 else "Hand")
  _shape(palm,"ball",Vector3(0.055,0,0),skin,Vector3.ZERO)
  arms.append(arm)
  if side == 1: hand = palm
 var dog := _pivot(rig,Vector3(0.42,0.01,-0.28),"LeashedDog")
 var fur := Color("b37e4f") if actors.size()%2 else Color("e6d3ac")
 _shape(dog,"capsule",Vector3(0.14,0.54,0),fur,Vector3(0,0.4,0)).rotation.x = PI/2
 _shape(dog,"ball",Vector3(0.14,0,0),fur,Vector3(0,0.49,-0.32))
 _shape(dog,"box",Vector3(0.16,0.12,0.16),fur.darkened(0.08),Vector3(0,0.455,-0.43))
 _shape(dog,"ball",Vector3(0.045,0,0),Color("293239"),Vector3(0,0.47,-0.51))
 for x in [-0.105,0.105]:
  _shape(dog,"capsule",Vector3(0.045,0.2,0),fur.darkened(0.3),Vector3(x,0.5,-0.27)).rotation.z = x*4
  _shape(dog,"ball",Vector3(0.018,0,0),Color("26333b"),Vector3(x*0.72,0.53,-0.43))
 var paws: Array[Node3D] = []
 for x in [-0.1,0.1]:
  for z in [-0.18,0.18]:
   var paw := _pivot(dog,Vector3(x,0.32,z),"DogLeg")
   _shape(paw,"capsule",Vector3(0.035,0.3,0),fur,Vector3(0,-0.13,0))
   _shape(paw,"ball",Vector3(0.045,0,0),fur.darkened(0.15),Vector3(0,-0.275,-0.025))
   paws.append(paw)
 var tail := _pivot(dog,Vector3(0,0.43,0.23),"WaggingTail")
 _shape(tail,"capsule",Vector3(0.03,0.29,0),fur,Vector3(0,0.06,0.11)).rotation.x = 0.9
 var collar := _pivot(dog,Vector3(0,0.43,-0.25),"LeashCollar")
 _shape(collar,"box",Vector3(0.25,0.055,0.045),Color("a94948"),Vector3.ZERO)
 var leash: MeshInstance3D = _shape(rig,"line",Vector3(0.011,1,0),Color("e5b85d"),Vector3.ZERO)
 leash.name = "VisibleLeash"
 actors.append({"node":group,"rig":rig,"person":person,"dog":dog,"legs":legs,"knees":knees,"arms":arms,"paws":paws,"tail":tail,"hand":hand,"collar":collar,"leash":leash,"half_length":half_length,"width":width,"ground_y":ground_y,"offset":actors.size()*1.4,"rate":0.21+actors.size()*0.008})

func _process(delta: float) -> void:
 advance(delta)

func advance(delta: float) -> void:
 if delta <= 0 or not is_finite(delta):
  return
 elapsed += delta
 _pose()

func _pose() -> void:
 for actor in actors:
  var phase: float = fposmod(elapsed*actor.rate+actor.offset,TAU)
  actor.rig.transform = route_frame(phase,actor.half_length,actor.width,actor.ground_y)
  var gait: float = phase*10 # Integer cycles make limb poses continuous at the route seam.
  var swing: float = sin(gait)
  actor.person.position.y = 0.03 + absf(swing)*0.012
  for index in 2:
   var stride: float = swing if index == 0 else -swing
   actor.legs[index].rotation.x = stride*0.32
   actor.knees[index].rotation.x = maxf(0,-stride)*0.3
   actor.arms[index].rotation.x = -stride*0.23
  for index in 4:
   actor.paws[index].rotation.x = sin(gait*1.2 + (PI if (index == 1 or index == 2) else 0))*0.35
  actor.tail.rotation.z = sin(gait*1.8)*0.35
  var a: Vector3 = actor.rig.to_local(actor.hand.global_position)
  var b: Vector3 = actor.rig.to_local(actor.collar.global_position)
  var up: Vector3 = (b-a).normalized()
  var right: Vector3 = up.cross(Vector3.FORWARD).normalized()
  if right.length_squared() < 0.001: right = Vector3.RIGHT
  actor.leash.position = (a+b)*0.5
  actor.leash.basis = Basis(right,up*(b-a).length(),right.cross(up))
  actor.node.set_meta("leash_start",actor.hand.global_position)
  actor.node.set_meta("leash_end",actor.collar.global_position)
