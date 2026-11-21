extends Node3D
## Bounded outdoor weather. Main explicitly advances it so race pause is respected.
signal changed(event: String)
const Geo = preload("res://scripts/geometry.gd")
const EVENTS = ["sun", "rain", "rainbow", "night"]
const RAIN_COUNT = 160
var current_event: String = "sun"
var rng = RandomNumberGenerator.new()
var time_left: float = 40.0
var elapsed: float = 0.0
var rain_amount: float = 0.0
var night_amount: float = 0.0
var rainbow_amount: float = 0.0
var world_index: int = 0
var env: Environment
var sun: DirectionalLight3D
var camera: Camera3D
var track: Node3D
var drops: MultiMeshInstance3D
var rainbow: MeshInstance3D
var fill: OmniLight3D
var baseline: Dictionary = {}
var road: StandardMaterial3D
var road_roughness: float = 0.8
var road_specular: float = 0.5
var sky_material: ProceduralSkyMaterial

func setup(race_track: Node3D, environment: Environment, light: DirectionalLight3D, view: Camera3D, random_seed: int = -1) -> void:
 name = "Weather"
 track = race_track
 world_index = track.world_index
 env = environment
 sun = light
 camera = view
 if random_seed >= 0: rng.seed = random_seed
 else: rng.randomize()
 time_left = rng.randf_range(32.0, 55.0)
 baseline = {"sun_energy":sun.light_energy, "sun_color":sun.light_color,
  "ambient_energy":env.ambient_light_energy, "ambient_color":env.ambient_light_color,
  "fog_density":env.fog_density, "fog_color":env.fog_light_color}
 if env.sky != null and env.sky.sky_material is ProceduralSkyMaterial:
  # Duplicate resources: changing this world must never recolor other worlds.
  sky_material = env.sky.sky_material.duplicate()
  env.sky.sky_material = sky_material
  baseline["sky_top"] = sky_material.sky_top_color
  baseline["sky_horizon"] = sky_material.sky_horizon_color
  baseline["ground_horizon"] = sky_material.ground_horizon_color
 if track.road_material != null:
  road = track.road_material
  road_roughness = road.roughness
  road_specular = road.metallic_specular
 _build_rain()
 _build_rainbow()
 fill = OmniLight3D.new()
 fill.name = "NightVisibilityFill"
 fill.light_color = Color("b6d8ff")
 fill.omni_range = 25.0
 fill.light_energy = 0.0
 fill.shadow_enabled = false
 add_child(fill)
 _apply_lighting()

func force_event(event: String, immediate: bool = false) -> bool:
 if event not in EVENTS: return false
 if world_index == 5 and event != "sun": return false
 current_event = event
 time_left = rng.randf_range(18.0, 32.0) if event != "sun" else rng.randf_range(32.0, 55.0)
 if immediate:
  rain_amount = 1.0 if event == "rain" else 0.0
  night_amount = 1.0 if event == "night" else 0.0
  rainbow_amount = 1.0 if event == "rainbow" else 0.0
  _apply_lighting()
 changed.emit(event)
 return true

func advance(delta: float, focus: Vector3, paused: bool = false) -> void:
 if paused or delta <= 0.0: return
 elapsed += delta
 time_left -= delta
 if time_left <= 0.0:
  if world_index == 5:
   time_left = 60.0
  elif current_event == "rain":
   # Rainbow deliberately follows a clearing shower, with sun restored.
   force_event("rainbow")
  elif current_event != "sun":
   force_event("sun")
  else:
   # No precipitation in the cloudscape; other outdoor worlds permit showers.
   force_event("night" if world_index == 2 or rng.randf() < 0.35 else "rain")
 var blend = 1.0 - exp(-delta * 0.9)
 rain_amount = lerpf(rain_amount, 1.0 if current_event == "rain" else 0.0, blend)
 night_amount = lerpf(night_amount, 1.0 if current_event == "night" else 0.0, blend)
 rainbow_amount = lerpf(rainbow_amount, 1.0 if current_event == "rainbow" else 0.0, blend)
 drops.global_position = focus
 drops.visible = rain_amount > 0.02
 if drops.visible:
  for i in RAIN_COUNT:
   var x = sin(i * 127.1) * 15.0
   var z = cos(i * 269.5) * 15.0
   var y = fposmod(i * 1.71 - elapsed * 18.0, 17.0) - 1.0
   var transform = Transform3D(Basis.IDENTITY, Vector3(x, y, z))
   transform.basis = transform.basis.scaled(Vector3(1, 0.4 + rain_amount * 0.6, 1))
   drops.multimesh.set_instance_transform(i, transform)
 fill.global_position = focus + Vector3.UP * 5.0
 rainbow.visible = rainbow_amount > 0.02
 if is_instance_valid(camera):
  # A distant arc outside the route, facing the current view with no road blockers.
  var forward = -camera.global_basis.z
  forward.y = 0
  forward = forward.normalized()
  rainbow.global_position = focus + forward * 140.0 + Vector3.UP * 2.0
  rainbow.rotation.y = atan2(forward.x, forward.z)
 var rainbow_mat = rainbow.material_override as StandardMaterial3D
 rainbow_mat.albedo_color.a = rainbow_amount * 0.53
 _apply_lighting()

func _apply_lighting() -> void:
 if baseline.is_empty(): return
 if is_instance_valid(drops): drops.visible = rain_amount > 0.02
 if is_instance_valid(rainbow):
  rainbow.visible = rainbow_amount > 0.02
  rainbow.material_override.albedo_color.a = rainbow_amount * 0.53
 var cloud = rain_amount
 sun.light_energy = lerpf(float(baseline.sun_energy), 0.24, night_amount) * (1.0 - cloud * 0.4)
 sun.light_color = Color(baseline.sun_color).lerp(Color("8eafff"), night_amount)
 env.ambient_light_energy = lerpf(float(baseline.ambient_energy), 0.58, night_amount)
 env.ambient_light_color = Color(baseline.ambient_color).lerp(Color("718bae"), night_amount)
 env.fog_density = float(baseline.fog_density) + cloud * 0.0015
 env.fog_light_color = Color(baseline.fog_color).lerp(Color("a6b7c8"), cloud * 0.65).lerp(Color("1c2b49"), night_amount)
 if sky_material != null:
  sky_material.sky_top_color = Color(baseline.sky_top).lerp(Color("617789"), cloud * 0.6).lerp(Color("050d24"), night_amount)
  sky_material.sky_horizon_color = Color(baseline.sky_horizon).lerp(Color("b3bfca"), cloud * 0.55).lerp(Color("263b61"), night_amount)
  sky_material.ground_horizon_color = Color(baseline.ground_horizon).lerp(Color("263b61"), night_amount)
 if is_instance_valid(fill): fill.light_energy = night_amount * 0.6
 if road != null:
  road.roughness = lerpf(road_roughness, maxf(0.22, road_roughness * 0.45), rain_amount)
  road.metallic_specular = lerpf(road_specular, 0.8, rain_amount)

func _build_rain() -> void:
 drops = MultiMeshInstance3D.new()
 drops.name = "RainStreaks"
 var batch = MultiMesh.new()
 batch.transform_format = MultiMesh.TRANSFORM_3D
 var streak = BoxMesh.new()
 streak.size = Vector3(0.018, 0.5, 0.018)
 batch.mesh = streak
 batch.instance_count = RAIN_COUNT
 drops.multimesh = batch
 drops.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var mat = Geo.material(Color(0.70, 0.84, 0.94, 0.55))
 mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 drops.material_override = mat
 drops.custom_aabb = AABB(Vector3(-17, -2, -17), Vector3(34, 21, 34))
 drops.visible = false
 add_child(drops)

func _build_rainbow() -> void:
 rainbow = MeshInstance3D.new()
 rainbow.name = "RainbowArc"
 var arc = ImmediateMesh.new()
 arc.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
 var colors = [Color("ef707d"), Color("f6b06f"), Color("f3db82"), Color("91d59d"), Color("80bfe6"), Color("a89bdb"), Color("ca9ed5")]
 for band in colors.size():
  var outer = 61.0 - band * 1.15
  var inner = outer - 1.1
  arc.surface_set_color(colors[band])
  for i in 64:
   var a = PI * i / 64.0
   var b = PI * (i + 1) / 64.0
   var p = Vector3(cos(a) * inner, sin(a) * inner, 0)
   var q = Vector3(cos(a) * outer, sin(a) * outer, 0)
   var r = Vector3(cos(b) * outer, sin(b) * outer, 0)
   var s = Vector3(cos(b) * inner, sin(b) * inner, 0)
   for point in [p, q, r, p, r, s]: arc.surface_add_vertex(point)
 arc.surface_end()
 rainbow.mesh = arc
 var mat = StandardMaterial3D.new()
 mat.vertex_color_use_as_albedo = true
 mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 mat.cull_mode = BaseMaterial3D.CULL_DISABLED
 mat.albedo_color = Color(1, 1, 1, 0)
 rainbow.material_override = mat
 rainbow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 rainbow.visible = false
 add_child(rainbow)

func _exit_tree() -> void:
 if road != null:
  road.roughness = road_roughness
  road.metallic_specular = road_specular
