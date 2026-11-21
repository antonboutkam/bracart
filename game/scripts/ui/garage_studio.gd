extends Node3D
## Small independent photo studio. Uses the actual race kart and authored PBR materials.
## Reflection lighting works in GL Compatibility; no screen-space effects required.
const Kart = preload("res://scripts/kart.gd")
const Geo = preload("res://scripts/geometry.gd")
const WorldArt = preload("res://scripts/worlds/world_art.gd")
var kart: Node3D
var camera: Camera3D
var frame_bounds: AABB
var rotation_radius: float = 0
static var studio_sky: Sky
static var contact_texture: ImageTexture

func setup(index: int, character_id: String, hero: bool = false) -> void:
 var world = WorldEnvironment.new()
 var env = Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("182536")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
 env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
 env.ambient_light_energy = 0.55
 env.ambient_light_sky_contribution = 1.0
 env.sky = _sky()
 world.environment = env
 add_child(world)
 _light(Vector3(-48, -28, 0), Color("fff1d8"), 1.15, true)
 _light(Vector3(-20, 125, 0), Color("bedbff"), 0.55)
 _light(Vector3(-38, -155, 0), Color("ffffff"), 0.95)
 _track_diorama()
 # A soft contact patch supplements the directional shadow on low-end GL drivers.
 var shadow = MeshInstance3D.new()
 var patch = PlaneMesh.new()
 patch.size = Vector2(1.6, 2.55)
 shadow.mesh = patch
 var ink = StandardMaterial3D.new()
 ink.albedo_texture = _contact_texture()
 ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 shadow.material_override = ink
 shadow.position.y = -0.018
 shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(shadow)
 kart = Kart.new()
 add_child(kart)
 kart.setup(index, character_id, false)
 if kart.animation:
  kart.animation.advance(0)
  kart.animation.pause()
 kart.flame.visible = false
 camera = Camera3D.new()
 add_child(camera)
 frame_bounds = _model_bounds(kart,Transform3D.IDENTITY)
 for corner in 8:
  var point: Vector3 = frame_bounds.get_endpoint(corner)
  rotation_radius = maxf(rotation_radius,Vector2(point.x,point.z).length())
 var target := Vector3(0,frame_bounds.get_center().y,0)
 camera.position = target + Vector3(3.25,2.05,-4.6).normalized()*8
 camera.look_at(target)
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.keep_aspect = Camera3D.KEEP_HEIGHT
 var aspect: float = 960.0/700.0 if hero else 676.0/184.0
 var up: Vector3 = camera.basis.y
 var projected_height: float = frame_bounds.size.y*absf(up.y) + 2*rotation_radius*Vector2(up.x,up.z).length()
 camera.size = maxf(projected_height,2*rotation_radius/aspect)*1.12
 camera.near = 0.05
 camera.far = 60
 camera.current = true

func _track_diorama() -> void:
 var track := Node3D.new()
 track.name = "TrackDiorama"
 add_child(track)
 # Actual road and grass materials used by the outdoor circuits, on supported
 # miniature geometry. The road continues beyond the frame like a real circuit.
 var grass := Geo.box(track,Vector3(0,-0.12,0),Vector3(7,0.2,9),Color("73a35c"))
 grass.name = "GrassVerge"
 grass.material_override = WorldArt.material("grass",Color("a6b975"),0.5)
 var asphalt := Geo.box(track,Vector3(0,-0.045,0),Vector3(4.1,0.07,9),Color("5d6871"))
 asphalt.name = "RaceAsphalt"
 asphalt.material_override = WorldArt.material("uithoorn_asphalt",Color("d1d0c9"),0.4)
 for side in [-1,1]:
  for index in 18:
   Geo.box(track,Vector3(side*2.11,0,index*0.5-4.25),Vector3(0.22,0.08,0.5),Color("e9e5d9") if index%2 else Color("c24f48"))
  Geo.box(track,Vector3(side*1.9,0.001,0),Vector3(0.04,0.008,9),Color("eae5ce"))
 var tree := Node3D.new()
 tree.name = "TracksideTree"
 track.add_child(tree)
 tree.position = Vector3(2.8,0,1.7)
 Geo.cylinder(tree,Vector3(0,0.55,0),0.1,1.1,Color("826249"))
 Geo.ball(tree,Vector3(0,1.4,0),Vector3(0.75,1.15,0.75),Color("5e9151"))
 Geo.ball(tree,Vector3(-0.25,1.2,0.08),Vector3(0.6,0.75,0.6),Color("80aa60"))

func _model_bounds(node: Node3D, parent_transform: Transform3D) -> AABB:
 if not node.visible: return AABB()
 var value: Transform3D = parent_transform*node.transform
 var bounds := AABB()
 if node is MeshInstance3D and node.mesh != null:
  bounds = value*node.get_aabb()
 for child in node.get_children():
  if child is Node3D:
   var part: AABB = _model_bounds(child,value)
   if part.size != Vector3.ZERO:
    bounds = part if bounds.size == Vector3.ZERO else bounds.merge(part)
 return bounds

func _light(rotation_value: Vector3, color: Color, energy: float, shadows: bool = false) -> void:
 var light = DirectionalLight3D.new()
 light.rotation_degrees = rotation_value
 light.light_color = color
 light.light_energy = energy
 light.shadow_enabled = shadows
 light.shadow_blur = 2.5
 light.directional_shadow_max_distance = 15
 light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
 add_child(light)

static func _sky() -> Sky:
 if studio_sky:
  return studio_sky
 # Equirectangular studio: broad luminous panels give chrome and metallic paint
 # reflections, unlike a flat ambient color. Kept entirely inside this preview.
 var photo = Image.create(512, 256, false, Image.FORMAT_RGBF)
 for y in 256:
  var elevation = (0.5 - float(y) / 256) * PI
  for x in 512:
   var azimuth = float(x) / 512 * TAU
   var direction = Vector3(sin(azimuth) * cos(elevation), sin(elevation), cos(azimuth) * cos(elevation))
   var base = Color("172536").srgb_to_linear().lerp(Color("718599").srgb_to_linear(), clampf(direction.y * 0.6 + 0.5, 0, 1))
   var panels = pow(maxf(0, direction.dot(Vector3(0.5, 0.75, -0.65).normalized())), 24) * 3.5
   panels += pow(maxf(0, direction.dot(Vector3(-0.8, 0.38, 0.4).normalized())), 40) * 2.2
   panels += pow(maxf(0, direction.dot(Vector3(0.25, 0.55, 0.8).normalized())), 28) * 3.0
   photo.set_pixel(x, y, base + Color(panels, panels, panels, 0))
 var sky_material = PanoramaSkyMaterial.new()
 sky_material.panorama = ImageTexture.create_from_image(photo)
 studio_sky = Sky.new()
 studio_sky.sky_material = sky_material
 studio_sky.radiance_size = Sky.RADIANCE_SIZE_128
 return studio_sky

static func _contact_texture() -> ImageTexture:
 if contact_texture:
  return contact_texture
 var ink = Image.create(128, 128, false, Image.FORMAT_RGBA8)
 for y in 128:
  for x in 128:
   var radius = Vector2((x - 63.5) / 63.5, (y - 63.5) / 63.5).length()
   var alpha = pow(clampf(1.0 - radius, 0, 1), 1.5) * 0.6
   ink.set_pixel(x, y, Color(0.01, 0.02, 0.035, alpha))
 contact_texture = ImageTexture.create_from_image(ink)
 return contact_texture
