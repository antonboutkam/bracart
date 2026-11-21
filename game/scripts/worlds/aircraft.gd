extends Node3D
## One quiet, occasional sky passage. Contrails retain emitted world positions.
const Geo = preload("res://scripts/geometry.gd")
const MAX_TRAIL_POINTS = 96
const TRAIL_LIFETIME = 12.0
const EMISSION_INTERVAL = 0.2
const EXHAUSTS = [Vector3(-2.5,-0.25,1.35),Vector3(2.5,-0.25,1.35)]
var flight: Node3D
var model: Node3D
var trail: MeshInstance3D
var trail_mesh: ImmediateMesh
var trail_material: StandardMaterial3D
var body_material: StandardMaterial3D
var trail_world: Array[PackedVector3Array] = []
var trail_births: Array[PackedFloat64Array] = []
var trail_head := PackedInt32Array([0,0])
var trail_count := PackedInt32Array([0,0])
var rng := RandomNumberGenerator.new()
var elapsed: float = 0
var pass_elapsed: float = 0
var duration: float = 30
var wait_remaining: float = 15
var phase: String = "waiting"
var passage_progress: float = 0
var altitude: float = 0
var path_start: Vector3
var path_end: Vector3
var review_eye: Vector3
var review_target: Vector3
var emission_time: float = 0
var night_amount: float = 0
var world_index: int = 0

static func install(track: Node3D) -> Node3D:
 if track.world_index == 5: return null
 var existing: Node = track.get_node_or_null("Aircraft")
 if existing != null: return existing
 var aircraft = new()
 aircraft.name = "Aircraft"
 track.add_child(aircraft)
 aircraft.setup(track)
 return aircraft

func setup(track: Node3D) -> void:
 world_index = track.world_index
 rng.seed = 49173 + world_index*701
 var maximum: float = -INF
 for index in 240:
  maximum = maxf(maximum,track.position_at(track.length*index/240.0).y)
 altitude = maximum+210
 var frame: Transform3D = track.frame(0)
 var forward: Vector3 = -frame.basis.z
 forward.y = 0
 forward = forward.normalized()
 var right: Vector3 = forward.cross(Vector3.UP).normalized()
 var center: Vector3 = frame.origin+forward*700
 center.y = altitude
 path_start = center-right*500
 path_end = center+right*500
 review_target = center
 review_eye = center-forward*850-Vector3.UP*160
 for engine in 2:
  var positions := PackedVector3Array()
  positions.resize(MAX_TRAIL_POINTS)
  var births := PackedFloat64Array()
  births.resize(MAX_TRAIL_POINTS)
  trail_world.append(positions)
  trail_births.append(births)
 flight = Node3D.new()
 flight.name = "Flight"
 add_child(flight)
 model = flight
 _airplane()
 flight.visible = false
 trail_mesh = ImmediateMesh.new()
 trail = MeshInstance3D.new()
 trail.name = "WorldspaceContrails"
 trail.mesh = trail_mesh
 trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(trail)
 trail_material = StandardMaterial3D.new()
 trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 trail_material.vertex_color_use_as_albedo = true
 trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
 trail.material_override = trail_material
 wait_remaining = rng.randf_range(10,20)
 set_meta("altitude",altitude)
 set_meta("maximum_track_y",maximum)
 set_meta("trail_capacity",MAX_TRAIL_POINTS*2)
 set_meta("trail_space","world")
 set_meta("phase",phase)
 set_meta("trail_records",0)

func _airplane() -> void:
 body_material = Geo.material(Color("e1e6e9"))
 body_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 var body := CapsuleMesh.new()
 body.radius = 0.62
 body.height = 12
 body.radial_segments = 10
 body.rings = 3
 var fuselage := Geo.mesh(flight,body,Vector3.ZERO,Color.WHITE)
 fuselage.name = "Fuselage"
 fuselage.rotation.x = PI/2
 fuselage.material_override = body_material
 for side in [-1,1]:
  _wing("MainWing",[Vector3(side*0.5,0,-1.5),Vector3(side*9,0.1,2.1),Vector3(side*8.6,0.1,3.0),Vector3(side*0.5,0,1.3)])
  _wing("Tailplane",[Vector3(side*0.4,0.15,3.5),Vector3(side*3,0.2,5),Vector3(side*2.8,0.2,5.6),Vector3(side*0.4,0.15,4.7)])
  var engine: MeshInstance3D = Geo.cylinder(flight,Vector3(side*2.5,-0.25,0.4),0.35,1.8,Color("7f94a3"))
  engine.name = "EngineLeft" if side < 0 else "EngineRight"
  engine.rotation.x = PI/2
  _navigation(Vector3(side*9,0.15,2.1),Color("fa6660") if side < 0 else Color("74e59b"))
 _wing("VerticalTail",[Vector3(0,0.2,3.3),Vector3(0,2.5,4.7),Vector3(0,2.3,5.7),Vector3(0,0.2,5.4)])
 var cockpit: MeshInstance3D = Geo.ball(flight,Vector3(0,0.32,-4.7),Vector3(0.95,0.5,1.25),Color("38516b"))
 cockpit.name = "Cockpit"
 cockpit.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 _navigation(Vector3(0,0.3,5.5),Color("e9efff"))

func _wing(title: String, points: Array) -> void:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for index in [0,1,2,0,2,3]: surface.add_vertex(points[index])
 surface.generate_normals()
 var wing := MeshInstance3D.new()
 wing.name = title
 wing.mesh = surface.commit()
 wing.material_override = body_material
 body_material.cull_mode = BaseMaterial3D.CULL_DISABLED
 flight.add_child(wing)

func _navigation(position_value: Vector3, color: Color) -> void:
 var lamp: MeshInstance3D = Geo.ball(flight,position_value,Vector3.ONE*0.32,color)
 lamp.name = "NavigationLight"
 lamp.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 lamp.material_override.emission_enabled = true
 lamp.material_override.emission = color
 lamp.material_override.emission_energy_multiplier = 0.8

func force_passage() -> void:
 trail_count.fill(0)
 trail_head.fill(0)
 trail_mesh.clear_surfaces()
 trail.visible = false
 pass_elapsed = 0
 passage_progress = 0
 emission_time = 0
 duration = rng.randf_range(25,35)
 phase = "passing"
 flight.visible = true
 _flight_pose()
 _emit()
 set_meta("trail_records",2)
 set_meta("phase",phase)

func begin_passage() -> void:
 force_passage()

func _flight_pose() -> void:
 flight.position = path_start.lerp(path_end,passage_progress)
 var forward: Vector3 = (path_end-path_start).normalized()
 flight.basis = Basis(forward.cross(Vector3.UP).normalized(),Vector3.UP,-forward)

func _emit() -> void:
 for engine in 2:
  var slot: int = trail_head[engine]
  trail_world[engine][slot] = flight.to_global(EXHAUSTS[engine])
  trail_births[engine][slot] = elapsed
  trail_head[engine] = (slot+1)%MAX_TRAIL_POINTS
  trail_count[engine] = mini(trail_count[engine]+1,MAX_TRAIL_POINTS)

func trail_point(engine: int, offset: int) -> Vector3:
 return trail_world[engine][posmod(trail_head[engine]-trail_count[engine]+offset,MAX_TRAIL_POINTS)]

func _process(delta: float) -> void:
 advance(delta)

func advance(delta: float) -> void:
 if delta <= 0 or not is_finite(delta): return
 var remaining: float = delta
 while remaining > 0.000001:
  var tick: float = minf(remaining,0.05)
  remaining -= tick
  elapsed += tick
  if phase == "waiting":
   wait_remaining -= tick
   if wait_remaining <= 0: force_passage()
  else:
   pass_elapsed = minf(duration,pass_elapsed+tick)
   passage_progress = pass_elapsed/duration
   _flight_pose()
   emission_time += tick
   if emission_time >= EMISSION_INTERVAL:
    emission_time -= EMISSION_INTERVAL
    _emit()
   if pass_elapsed >= duration:
    phase = "waiting"
    flight.visible = false
    wait_remaining = rng.randf_range(55,100)
    set_meta("phase",phase)
  for engine in 2:
   while trail_count[engine] > 0:
    var oldest: int = posmod(trail_head[engine]-trail_count[engine],MAX_TRAIL_POINTS)
    if elapsed-trail_births[engine][oldest] <= TRAIL_LIFETIME: break
    trail_count[engine] -= 1
 _weather_tint()
 _trail_geometry()
 set_meta("trail_records",trail_count[0]+trail_count[1])

func _weather_tint() -> void:
 var weather: Node = get_parent().get_node_or_null("Weather")
 night_amount = 1.0 if world_index == 1 else 0.0
 if weather != null: night_amount = maxf(night_amount,float(weather.night_amount))
 body_material.albedo_color = Color("e1e6e9").lerp(Color("71839b"),night_amount)

func _trail_geometry() -> void:
 trail_mesh.clear_surfaces()
 var begun: bool = false
 for engine in 2:
  for offset in range(1,trail_count[engine]):
   var a_index: int = posmod(trail_head[engine]-trail_count[engine]+offset-1,MAX_TRAIL_POINTS)
   var b_index: int = (a_index+1)%MAX_TRAIL_POINTS
   var a_world: Vector3 = trail_world[engine][a_index]
   var b_world: Vector3 = trail_world[engine][b_index]
   var direction: Vector3 = (b_world-a_world).normalized()
   if a_world.distance_squared_to(b_world) < 0.001: continue
   if not begun:
    trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
    begun = true
   var a: Vector3 = to_local(a_world)
   var b: Vector3 = to_local(b_world)
   var age_a: float = clampf((elapsed-trail_births[engine][a_index])/TRAIL_LIFETIME,0,1)
   var age_b: float = clampf((elapsed-trail_births[engine][b_index])/TRAIL_LIFETIME,0,1)
   var width_a: float = lerpf(0.35,1.9,age_a)
   var width_b: float = lerpf(0.35,1.9,age_b)
   var alpha_a: float = (1-age_a)*lerpf(0.7,0.3,night_amount)
   var alpha_b: float = (1-age_b)*lerpf(0.7,0.3,night_amount)
   var horizontal: Vector3 = global_basis.inverse()*(Vector3.UP.cross(direction).normalized())
   var vertical: Vector3 = global_basis.inverse()*Vector3.UP
   for ribbon in [horizontal,vertical]:
    for vertex in [0,1,2,0,2,3]:
     var use_a: bool = vertex == 0 or vertex == 3
     trail_mesh.surface_set_color(Color(0.94,0.97,1.0,alpha_a if use_a else alpha_b))
     var side: float = -1.0 if vertex < 2 else 1.0
     trail_mesh.surface_add_vertex((a if use_a else b)+ribbon*side*(width_a if use_a else width_b))
 if begun: trail_mesh.surface_end()
 trail.visible = begun
