extends TextureRect
## Results-owned diorama. No gameplay, rewards, input or shared rig mutation.
const Kart = preload("res://scripts/kart.gd")
const Geo = preload("res://scripts/geometry.gd")
const Studio = preload("res://scripts/ui/garage_studio.gd")
const PODIUM_TOP = 0.46
const DURATION = 3.2
var viewport: SubViewport
var studio: Node3D
var camera: Camera3D
var winner: Node3D
var skeleton: Skeleton3D
var animation: AnimationPlayer
var cheer: String
var vehicles: Array[Node3D] = []
var age: float = 0
var sole_vertices: Array[Dictionary] = []
var sole_height: float = 0

func setup(race) -> void:
 if is_instance_valid(viewport) or race.rank != 1: return
 name = "VictoryPodium"
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 custom_minimum_size = Vector2(518,480)
 viewport = SubViewport.new()
 viewport.size = Vector2i(900,850)
 viewport.own_world_3d = true
 viewport.msaa_3d = Viewport.MSAA_2X
 add_child(viewport)
 texture = viewport.get_texture()
 studio = Node3D.new()
 viewport.add_child(studio)
 var world := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("112a43")
 env.sky = Studio._sky()
 env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
 env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
 env.ambient_light_energy = 0.7
 world.environment = env
 studio.add_child(world)
 for values in [[Vector3(-38,-25,0),Color("fff0d0"),1.2],[Vector3(-20,135,0),Color("afdfff"),0.7]]:
  var light := DirectionalLight3D.new()
  light.rotation_degrees = values[0]
  light.light_color = values[1]
  light.light_energy = values[2]
  light.shadow_enabled = true
  light.directional_shadow_max_distance = 15
  studio.add_child(light)
 Geo.box(studio,Vector3(0,-0.08,1),Vector3(9,0.16,9),Color("24435b"))
 var platform = Geo.cylinder(studio,Vector3(0,PODIUM_TOP/2,-0.45),0.78,PODIUM_TOP,Color("e5ad39"))
 platform.name = "WinnerPodium"
 Geo.cylinder(studio,Vector3(0,0.035,-0.45),0.84,0.07,Color("fff0ac"))
 var number := Label3D.new()
 number.text = "1"
 number.font_size = 110
 number.pixel_size = 0.003
 number.position = Vector3(0,0.24,-1.235)
 number.rotation.y = PI
 number.modulate = Color("fff6d6")
 number.no_depth_test = false
 studio.add_child(number)
 winner = load("res://assets/models/%s.glb" % race.player.driver).instantiate()
 winner.name = race.player.driver.capitalize()+"Winner"
 studio.add_child(winner)
 winner.scale = Vector3.ONE*1.8
 winner.position.z = -0.45
 skeleton = winner.find_children("*","Skeleton3D",true,false)[0]
 animation = winner.find_children("*","AnimationPlayer",true,false)[0]
 animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 for clip in animation.get_animation_list():
  if clip == "Cheer" or clip.ends_with("/Cheer"): cheer = clip
 animation.play(cheer)
 animation.advance(0)
 _cache_soles(winner)
 # Copy actual race vehicle identities; selected player always appears prominently.
 var indices: Array[int] = [race.player.vehicle_index]
 for racer in race.racers:
  if racer.vehicle_index not in indices and indices.size() < 3: indices.append(racer.vehicle_index)
 for i in indices.size():
  var kart := Kart.new()
  studio.add_child(kart)
  kart.setup(indices[i],race.player.driver,false)
  kart.driver_mount.free()
  kart.driver_mount = null
  kart.animation = null
  kart.driver_model = null
  kart.position = [Vector3(-1.45,0,1.25),Vector3(1.5,0,1.5),Vector3(0.1,0,3.2)][i]
  kart.rotation.y = [-0.3,0.35,0.18][i]
  vehicles.append(kart)
 camera = Camera3D.new()
 studio.add_child(camera)
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.size = 5.15
 camera.near = 0.05
 camera.far = 30
 camera.current = true
 _pose()
 visibility_changed.connect(_sync_visibility)
 _sync_visibility()

func _cache_soles(node: Node) -> void:
 if node is MeshInstance3D and node.skin:
  for surface in node.mesh.get_surface_count():
   var arrays: Array = node.mesh.surface_get_arrays(surface)
   var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
   var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
   var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
   var stride: int = bones.size()/vertices.size()
   for i in vertices.size():
    if vertices[i].y > 0.16: continue
    var binds: Array[int] = []
    var poses: Array[Transform3D] = []
    var influences: Array[float] = []
    for j in stride:
     var weight: float = weights[i*stride+j]
     if weight <= 0: continue
     var bind: int = bones[i*stride+j]
     binds.append(skeleton.find_bone(node.skin.get_bind_name(bind)))
     poses.append(node.skin.get_bind_pose(bind))
     influences.append(weight)
    sole_vertices.append({"vertex":vertices[i],"bones":binds,"poses":poses,"weights":influences})
 for child in node.get_children(): _cache_soles(child)

func _pose() -> void:
 animation.seek(minf(age,animation.get_animation(cheer).length),true)
 skeleton.force_update_all_bone_transforms()
 # Original Cheer contains hip sway; align the lowest actually skinned shoe
 # vertex to the top rather than guessing a seated rig offset or rest AABB.
 var lowest: float = INF
 for sample in sole_vertices:
  var point := Vector3.ZERO
  for i in sample.bones.size():
   point += (skeleton.get_bone_global_pose(sample.bones[i])*sample.poses[i]*sample.vertex)*sample.weights[i]
  lowest = minf(lowest,(winner.global_transform.affine_inverse()*skeleton.global_transform*point).y)
 sole_height = lowest*winner.scale.y
 winner.position.y = PODIUM_TOP-sole_height
 camera.position = Vector3(1.3+0.22*sin(age*0.45),3.0,-7)
 camera.look_at(Vector3(0,0.95,0.9))

func _process(delta: float) -> void: advance(delta)
func advance(delta: float) -> void:
 if not is_visible_in_tree() or not is_finite(delta) or delta <= 0 or age >= DURATION: return
 age = minf(DURATION,age+minf(delta,0.1))
 _pose()
 if age >= DURATION: set_process(false)
func _sync_visibility() -> void:
 var active: bool = is_visible_in_tree()
 set_process(active and age < DURATION)
 if is_instance_valid(viewport): viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
