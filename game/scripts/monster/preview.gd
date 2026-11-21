extends TextureRect
const Arena = preload("res://scripts/monster/arena.gd")
const Models = preload("res://scripts/monster/models.gd")
var viewport: SubViewport

func setup(id: String, resolution: Vector2i = Vector2i(520, 440)) -> bool:
 if is_instance_valid(viewport):
  remove_child(viewport)
  viewport.queue_free()
 expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 viewport = SubViewport.new()
 viewport.size = resolution
 viewport.own_world_3d = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
 add_child(viewport)
 texture = viewport.get_texture()
 var structure = Models.create(id)
 if not structure.load_monster(id):
  return false
 var model = Models.arena_for(structure)
 model.structure = structure
 viewport.add_child(model)
 model.prepare_blocks()
 model.rebuild_standing()
 var world = WorldEnvironment.new()
 var env = Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("123149")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("d3e6ef")
 env.ambient_light_energy = 0.4
 env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 env.tonemap_white = 2.5
 world.environment = env
 model.add_child(world)
 var sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-35, -25, 0)
 sun.light_energy = 0.7
 model.add_child(sun)
 var bounds: AABB = model.structure.bounds()
 var low = bounds.position
 var high = bounds.end
 var center = (low + high) * 0.5
 var camera = Camera3D.new()
 model.add_child(camera)
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.size = maxf(high.y - low.y + 3, (high.x - low.x + 8) / (float(resolution.x) / resolution.y)) * 1.1
 camera.position = center + Vector3(35, 18, 70)
 camera.look_at(center)
 camera.current = true
 return true
