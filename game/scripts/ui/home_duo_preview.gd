extends TextureRect
## Home-only transparent turntables: two real, single-seat Raketfietsen.
const Kart = preload("res://scripts/kart.gd")
const Catalog = preload("res://scripts/catalog.gd")
const GarageStudio = preload("res://scripts/ui/garage_studio.gd")
const BUFFER_SIZE = Vector2i(960,600)
const ROTATION_SPEED = 0.17
var viewport: SubViewport
var studio: Node3D
var camera: Camera3D
var karts: Array[Node3D] = []
var model_bounds: Array[AABB] = []
var angle: float = 0
var horizontal_radius: float = 0
var center_spacing: float = 0

func setup() -> void:
 if is_instance_valid(viewport):
  return
 name = "HomeDuoPreview"
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 viewport = SubViewport.new()
 viewport.name = "DuoViewport"
 viewport.size = BUFFER_SIZE
 viewport.own_world_3d = true
 viewport.transparent_bg = true
 viewport.msaa_3d = Viewport.MSAA_2X
 add_child(viewport)
 texture = viewport.get_texture()
 studio = Node3D.new()
 studio.name = "DuoStudio"
 viewport.add_child(studio)
 var world := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color(0,0,0,0)
 env.sky = GarageStudio._sky()
 env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
 env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
 env.ambient_light_energy = 0.65
 env.ambient_light_sky_contribution = 1
 world.environment = env
 studio.add_child(world)
 _light(Vector3(-42,-28,0),Color("fff0d0"),1.1,true)
 _light(Vector3(-20,125,0),Color("bfdcff"),0.6)
 _light(Vector3(-35,-165,0),Color("ffe9bb"),0.85)
 var highest: float = 0
 var lowest: float = 0
 for character in ["boaz","ravi"]:
  var kart := Kart.new()
  kart.name = character.capitalize() + "Raketfiets"
  studio.add_child(kart)
  kart.setup(Catalog.DEFAULT_VEHICLE,character,false)
  if kart.animation:
   kart.animation.advance(0)
   kart.animation.pause()
  kart.flame.visible = false
  # Mesh bounds include the authored rider. Conservative rest bounds also cover
  # the seated skin deformation; hidden power-effect meshes are excluded.
  var bounds: AABB = _bounds(kart,Transform3D.IDENTITY)
  model_bounds.append(bounds)
  for corner in 8:
   var point: Vector3 = bounds.get_endpoint(corner)
   horizontal_radius = maxf(horizontal_radius,Vector2(point.x,point.z).length())
   highest = maxf(highest,point.y)
   lowest = minf(lowest,point.y)
  _contact_shadow(kart)
  karts.append(kart)
 center_spacing = horizontal_radius + 0.3
 karts[0].position.x = center_spacing
 karts[1].position.x = -center_spacing
 camera = Camera3D.new()
 camera.name = "DuoCamera"
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.keep_aspect = Camera3D.KEEP_HEIGHT
 studio.add_child(camera)
 var target := Vector3(0,(highest+lowest)*0.5,0)
 camera.position = target + Vector3(0,3.0,-9.0)
 camera.look_at(target)
 camera.current = true
 # Fit a rotation-invariant envelope, including contact patches, with margin.
 var total_width: float = 2 * (center_spacing + horizontal_radius)
 var vertical_extent: float = (highest-lowest) + horizontal_radius * 0.8
 camera.size = maxf(total_width/(float(BUFFER_SIZE.x)/BUFFER_SIZE.y),vertical_extent) * 1.12
 camera.near = 0.05
 camera.far = 40
 _pose()
 visibility_changed.connect(_sync_visibility)
 _sync_visibility()

func _light(orientation: Vector3, color: Color, energy: float, shadows: bool = false) -> void:
 var light := DirectionalLight3D.new()
 light.rotation_degrees = orientation
 light.light_color = color
 light.light_energy = energy
 light.shadow_enabled = shadows
 light.shadow_blur = 2.5
 light.directional_shadow_max_distance = 15
 studio.add_child(light)

func _contact_shadow(kart: Node3D) -> void:
 var shadow := MeshInstance3D.new()
 shadow.name = "SoftContactShadow"
 var plane := PlaneMesh.new()
 plane.size = Vector2(1.65,2.6)
 shadow.mesh = plane
 var material := StandardMaterial3D.new()
 material.albedo_texture = GarageStudio._contact_texture()
 material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 shadow.material_override = material
 shadow.position.y = -0.018
 shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 kart.add_child(shadow)

func _bounds(node: Node3D, parent_transform: Transform3D) -> AABB:
 if not node.visible:
  return AABB()
 var transform_value: Transform3D = parent_transform * node.transform
 var bounds := AABB()
 if node is MeshInstance3D and node.mesh != null:
  bounds = transform_value * node.get_aabb()
 for child in node.get_children():
  if child is Node3D:
   var child_bounds: AABB = _bounds(child,transform_value)
   if child_bounds.size != Vector3.ZERO:
    bounds = child_bounds if bounds.size == Vector3.ZERO else bounds.merge(child_bounds)
 return bounds

func _pose() -> void:
 if karts.size() == 2:
  # Independent centers keep the pair side by side at every turntable angle.
  karts[0].rotation.y = angle + 0.25
  karts[1].rotation.y = angle - 0.25

func advance(delta: float) -> void:
 if not is_visible_in_tree() or delta <= 0 or not is_finite(delta):
  return
 angle = fposmod(angle + minf(delta,0.1) * ROTATION_SPEED,TAU)
 _pose()

func _process(delta: float) -> void:
 advance(delta)

func _sync_visibility() -> void:
 var active: bool = is_visible_in_tree()
 set_process(active)
 if is_instance_valid(viewport):
  viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
