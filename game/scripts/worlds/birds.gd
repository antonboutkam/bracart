extends Node3D
## One small, quiet gull on occasional route-relative horizon crossings.
const Geo = preload("res://scripts/geometry.gd")
var flight: Node3D
var left_wing: Node3D
var right_wing: Node3D
var rng := RandomNumberGenerator.new()
var phase: String = "waiting"
var elapsed: float = 0
var pass_elapsed: float = 0
var passage_progress: float = 0
var wait_remaining: float = 12
var duration: float = 15
var altitude: float = 0
var maximum_track_y: float = 0
var wing_angle: float = 0
var gliding: bool = false
var path_start: Vector3
var path_end: Vector3
var review_eye: Vector3
var review_target: Vector3
var anchor: Transform3D
var forward: Vector3
var right: Vector3

static func install(track: Node3D) -> Node3D:
 if track.world_index < 0 or track.world_index > 4: return null
 var existing: Node3D = track.get_node_or_null("Birds")
 if existing != null: return existing
 var bird = new()
 bird.name = "Birds"
 track.add_child(bird)
 bird.setup(track)
 return bird

func setup(track: Node3D) -> void:
 rng.seed = 82613+int(track.world_index)*317
 maximum_track_y = -INF
 for index in 480:
  maximum_track_y = maxf(maximum_track_y,track.position_at(track.length*index/480.0).y)
 anchor = track.frame(0)
 forward = -anchor.basis.z
 forward.y = 0
 forward = forward.normalized()
 right = forward.cross(Vector3.UP).normalized()
 flight = Node3D.new()
 flight.name = "Flight"
 add_child(flight)
 var body: MeshInstance3D = Geo.ball(flight,Vector3.ZERO,Vector3(0.5,0.52,1.25),Color("d4d9db"))
 body.name = "Body"
 var head: MeshInstance3D = Geo.ball(flight,Vector3(0,0.2,-0.6),Vector3.ONE*0.4,Color("eee9db"))
 head.name = "Head"
 var beak := CylinderMesh.new()
 beak.top_radius = 0
 beak.bottom_radius = 0.085
 beak.height = 0.34
 beak.radial_segments = 6
 var beak_node: MeshInstance3D = Geo.mesh(flight,beak,Vector3(0,0.18,-0.9),Color("d8ae55"))
 beak_node.name = "Beak"
 beak_node.rotation.x = -PI/2
 var tail: MeshInstance3D = Geo.ball(flight,Vector3(0,0,0.75),Vector3(0.65,0.08,0.55),Color("59616b"))
 tail.name = "Tail"
 var feather: StandardMaterial3D = Geo.material(Color("a3adb7"))
 feather.cull_mode = BaseMaterial3D.CULL_DISABLED
 # Modest unshaded feather contrast preserves the silhouette during existing night weather.
 feather.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 for side in [-1,1]:
  var wing := Node3D.new()
  wing.name = "LeftWing" if side < 0 else "RightWing"
  wing.position = Vector3(side*0.18,0.1,0)
  flight.add_child(wing)
  var surface := SurfaceTool.new()
  surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  var points: Array[Vector3] = [Vector3(0,0,-0.35),Vector3(side*1.6,0,0.3),Vector3(side*1.25,0,0.65),Vector3(0,0,0.4)]
  for index in [0,1,2,0,2,3]: surface.add_vertex(points[index])
  surface.generate_normals()
  var mesh := MeshInstance3D.new()
  mesh.name = "WingSurface"
  mesh.mesh = surface.commit()
  mesh.material_override = feather
  mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  wing.add_child(mesh)
  if side < 0: left_wing = wing
  else: right_wing = wing
 flight.visible = false
 wait_remaining = rng.randf_range(8,16)
 set_meta("maximum_track_y",maximum_track_y)
 set_meta("maximum_birds",1)
 set_meta("wingspan",3.56)
 set_meta("phase",phase)

func force_passage() -> void:
 pass_elapsed = 0
 passage_progress = 0
 duration = rng.randf_range(12,18)
 altitude = maximum_track_y+rng.randf_range(26,34)
 var center: Vector3 = anchor.origin+forward*rng.randf_range(90,130)+right*rng.randf_range(-12,12)
 center.y = altitude
 var direction: float = -1 if rng.randf() < 0.5 else 1
 path_start = center-right*80*direction
 path_end = center+right*80*direction
 review_target = center
 review_eye = center-forward*100-Vector3.UP*18
 phase = "passing"
 flight.visible = true
 set_meta("phase",phase)
 set_meta("altitude",altitude)
 _pose()

func begin_passage() -> void:
 force_passage()

func _pose() -> void:
 flight.position = path_start.lerp(path_end,passage_progress)+Vector3.UP*sin(passage_progress*TAU)*0.6
 var direction: Vector3 = (path_end-path_start).normalized()
 flight.basis = Basis(direction.cross(Vector3.UP),Vector3.UP,-direction)
 var cycle: float = fmod(pass_elapsed,5.5)
 gliding = cycle >= 3.2
 var envelope: float = smoothstep(0,0.35,cycle)*(1-smoothstep(2.8,3.2,cycle))
 wing_angle = sin(pass_elapsed*TAU*1.8)*0.46*envelope
 left_wing.rotation.z = -wing_angle
 right_wing.rotation.z = wing_angle

func _process(delta: float) -> void:
 advance(delta)

func advance(delta: float) -> void:
 if delta <= 0 or not is_finite(delta): return
 elapsed += delta
 var remaining: float = delta
 while remaining > 0:
  if phase == "waiting":
   var waiting: float = minf(remaining,wait_remaining)
   wait_remaining -= waiting
   remaining -= waiting
   if wait_remaining <= 0: force_passage()
  else:
   var flying: float = minf(remaining,duration-pass_elapsed)
   pass_elapsed += flying
   remaining -= flying
   passage_progress = clampf(pass_elapsed/duration,0,1)
   _pose()
   if pass_elapsed >= duration:
    phase = "waiting"
    flight.visible = false
    wait_remaining = rng.randf_range(35,65)
    set_meta("phase",phase)
