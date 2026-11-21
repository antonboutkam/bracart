extends SceneTree
const Track = preload("res://scripts/track.gd")
const Catalog = preload("res://scripts/catalog.gd")
var viewport: SubViewport
var camera: Camera3D
var scene: Node3D
func _initialize() -> void:
 call_deferred("run")
func capture(name_value: String) -> void:
 for i in 5: await process_frame
 await RenderingServer.frame_post_draw
 viewport.get_texture().get_image().save_png("/tmp/boracer-world-gallery/" + name_value + ".png")
 print("WORLD CAPTURE ",name_value)
func run() -> void:
 DirAccess.make_dir_recursive_absolute("/tmp/boracer-world-gallery")
 viewport = SubViewport.new()
 viewport.size = Vector2i(1200,800)
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 viewport.own_world_3d = true
 root.add_child(viewport)
 scene = Node3D.new()
 viewport.add_child(scene)
 camera = Camera3D.new()
 camera.current = true
 camera.far = 1600
 scene.add_child(camera)
 var sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-32,-35,0)
 sun.light_energy = 1.2
 scene.add_child(sun)
 var environment = WorldEnvironment.new()
 scene.add_child(environment)
 for world in 6:
  var track = Track.new()
  scene.add_child(track)
  track.build(world)
  var env = Environment.new()
  env.background_mode = Environment.BG_COLOR
  env.background_color = Color(Catalog.WORLDS[world].sky)
  env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
  env.ambient_light_color = Color("fff2de")
  env.ambient_light_energy = 0.6
  environment.environment = env
  camera.position = Vector3(180,230,240)
  camera.look_at(Vector3(0,12,0),Vector3.UP)
  camera.fov = 65
  await capture("world-%d-overview" % world)
  for fraction in [0.1,0.4,0.7]:
   var d: float = track.length * fraction
   var f: Transform3D = track.frame(d)
   camera.position = track.position_at(d,0,5) + f.basis.z * 9
   camera.look_at(track.position_at(d + 24,0,2),Vector3.UP)
   camera.fov = 72
   await capture("world-%d-drive-%d" % [world,int(fraction * 100)])
  track.queue_free()
  await process_frame
 quit()
