extends SceneTree
const Kart = preload("res://scripts/kart.gd")
const Geo = preload("res://scripts/geometry.gd")
const Catalog = preload("res://scripts/catalog.gd")
var viewport: SubViewport
var stage: Node3D

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 DirAccess.make_dir_recursive_absolute("/tmp/boracer-kart-gallery")
 viewport = SubViewport.new()
 viewport.size = Vector2i(1000, 800)
 viewport.own_world_3d = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 stage = Node3D.new()
 viewport.add_child(stage)
 var environment = WorldEnvironment.new()
 environment.environment = Environment.new()
 environment.environment.background_mode = Environment.BG_COLOR
 environment.environment.background_color = Color("1b283b")
 environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color = Color.WHITE
 environment.environment.ambient_light_energy = 0.75
 stage.add_child(environment)
 var sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-45, -35, 0)
 sun.light_energy = 1.6
 stage.add_child(sun)
 Geo.box(stage, Vector3(0, -0.08, 0), Vector3(8, 0.1, 8), Color("34465c"))
 var camera = Camera3D.new()
 stage.add_child(camera)
 camera.position = Vector3(3.0, 1.8, -3.4)
 camera.look_at(Vector3(0, 0.55, 0))
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.size = 2.9
 camera.current = true
 for index in Catalog.VEHICLES.size():
  var kart = Kart.new()
  stage.add_child(kart)
  kart.setup(index, "boaz" if index % 2 == 0 else "ravi", false)
  print(Catalog.VEHICLES[index].id, " model bounds=", kart._bounds(kart.visual.get_child(0), Transform3D.IDENTITY))
  for frame in 5:
   await process_frame
  await RenderingServer.frame_post_draw
  viewport.get_texture().get_image().save_png("/tmp/boracer-kart-gallery/%s.png" % Catalog.VEHICLES[index].id)
  kart.queue_free()
  await process_frame
 quit()
