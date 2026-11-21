extends SceneTree
## Native review of exported candidates; reads source GLBs without changing game assets.
var canvas: SubViewport
var stage: Node3D
var camera: Camera3D
var failures := 0

func _initialize() -> void:
 call_deferred("run")

func shot(filename: String) -> void:
 for frame in 8:
  await process_frame
 await RenderingServer.frame_post_draw
 var error := canvas.get_texture().get_image().save_png("/tmp/boracer-character-review/" + filename + ".png")
 if error != OK:
  failures += 1
 print("CHARACTER CAPTURE ", filename)

func run() -> void:
 if DisplayServer.get_name() == "headless":
  push_error("Native rendering required for visual review")
  quit(2)
  return
 DirAccess.make_dir_recursive_absolute("/tmp/boracer-character-review")
 canvas = SubViewport.new()
 canvas.size = Vector2i(800, 900)
 canvas.own_world_3d = true
 canvas.msaa_3d = Viewport.MSAA_4X
 canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(canvas)
 stage = Node3D.new()
 canvas.add_child(stage)
 var world := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("263448")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("d5e2ed")
 env.ambient_light_energy = 0.45
 world.environment = env
 stage.add_child(world)
 for spec in [[Vector3(-35,-30,0),1.0,Color("fff0d6")],[Vector3(-20,120,0),0.55,Color("c3dbff")]]:
  var light := DirectionalLight3D.new()
  light.rotation_degrees = spec[0]
  light.light_energy = spec[1]
  light.light_color = spec[2]
  stage.add_child(light)
 camera = Camera3D.new()
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.current = true
 stage.add_child(camera)
 var characters: Array = Array(OS.get_cmdline_user_args())
 if characters.is_empty():
  characters = ["boaz", "ravi"]
 for character in characters:
  if character not in ["boaz", "ravi"]:
   failures += 1
   continue
  var document := GLTFDocument.new()
  var state := GLTFState.new()
  var error := document.append_from_file(ProjectSettings.globalize_path("res://../persons/%s/%s.glb" % [character,character]),state)
  if error != OK:
   failures += 1
   continue
  var model := document.generate_scene(state)
  stage.add_child(model)
  await process_frame
  for view in [["front",Vector3(0,1.05,-3),0.94,0.52],["quarter",Vector3(1.7,1.1,-3),0.94,0.52],["back",Vector3(0,1.05,3),0.94,0.52],["full",Vector3(1.6,1.2,-3),0.57,1.4]]:
   camera.position = view[1]
   camera.look_at(Vector3(0,view[2],0))
   camera.size = view[3]
   await shot(character + "-" + view[0])
  var player := model.find_child("AnimationPlayer",true,false) as AnimationPlayer
  if player:
   for clip in player.get_animation_list():
    if str(clip).get_file() == "Kart_Sit":
     player.play(clip)
     player.advance(0.2)
  camera.position = Vector3(1.6,1.2,-3)
  camera.look_at(Vector3(0,0.57,0))
  camera.size = 1.4
  await shot(character + "-sit")
  model.queue_free()
  await process_frame
 stage.queue_free()
 await process_frame
 canvas.queue_free()
 await process_frame
 quit(0 if failures == 0 else 1)
