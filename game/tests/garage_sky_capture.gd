extends SceneTree
## Real garage and outdoor vistas; headless mode validates setup without pictures.
const Main = preload("res://scripts/main.gd")
const Catalog = preload("res://scripts/catalog.gd")
const VehiclePreview = preload("res://scripts/ui/vehicle_preview.gd")
var output: String
var validate_only := false
var failures := 0
var scenarios := 0

func _initialize() -> void: call_deferred("run")

func shot(filename: String) -> void:
 scenarios += 1
 if validate_only:
  await process_frame
  if root.get_camera_3d()==null: failures += 1
  print("GARAGE SKY SETUP ",filename," (no image)")
  return
 for frame in 10: await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 if picture.is_empty() or picture.save_png(output.path_join(filename+".png")) != OK: failures += 1
 print("GARAGE SKY CAPTURE ",filename)

func previews(node: Node) -> Array:
 var result: Array = []
 if node is VehiclePreview: result.append(node)
 for child in node.get_children(): result.append_array(previews(child))
 return result

func run() -> void:
 validate_only = "--validate-only" in OS.get_cmdline_user_args()
 output = OS.get_environment("BORACER_CAPTURE_DIR")
 if not validate_only and (output.is_empty() or DisplayServer.get_name()=="headless"):
  push_error("Set BORACER_CAPTURE_DIR and use native Godot rendering")
  quit(2)
  return
 root.size = Vector2i(1280,800)
 var game := Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.muted = true
 game.audio.music.stop()
 game.audio.music.stream = null
 game.profile.character = "boaz"
 game.profile.coins = 0
 game.ui.show_garage()
 await shot("garage-boaz-vooraan")
 var drivers = game.ui.screen.get_node_or_null("GarageDrivers")
 if drivers==null: failures += 1
 else: drivers.present("ravi")
 await shot("garage-ravi-hover")
 game.profile.character = "ravi"
 game.refresh_preview()
 game.ui.show_garage()
 await shot("garage-ravi-geselecteerd")
 game.profile.coins = 300
 game.ui.show_garage()
 await shot("garage-voldoende-muntjes")
 var cards := previews(game.ui.screen)
 if cards.size()!=6: failures += 1
 for tick in 240:
  for card in cards: card.advance(1.0/60)
 await shot("garage-voertuigen-gedraaid")
 game.profile.coins = 0
 game.ui.show_garage()
 await shot("garage-onvoldoende-muntjes")
 for world in 5:
  game.start_race(world)
  game.race.set_process(false)
  game.ui.visible = false
  var p: Vector3 = game.track.position_at(game.track.length*0.12)
  game.camera.fov = 68
  game.camera.position = p+Vector3.UP*12
  game.camera.look_at(game.camera.position+Vector3(0,40,-110))
  var sky = game.track.get_node_or_null("DutchSky")
  if sky==null: failures += 1
  else: sky.sync_weather()
  await shot(str(Catalog.WORLDS[world].id)+"-hemel")
  if world in [3,4]:
   var horizon = game.track.find_child("DutchHorizons",true,false)
   var views: Array = horizon.get_meta("review_views",[]) if horizon!=null else []
   if views.is_empty():
    failures += 1
    continue
   game.camera.fov = 58
   game.camera.position = views[0].eye
   game.camera.look_at(views[0].target)
   await shot(str(views[0].id))
   if world==3:
    for event in ["rain","night"]:
     game.weather.force_event(event,true)
     if sky!=null: sky.sync_weather()
     await shot("haarlem-hemel-"+event)
    game.weather.force_event("sun",true)
 game.queue_free()
 await process_frame
 print("GARAGE SKY ","SETUP VALIDATION; no images" if validate_only else "CAPTURE COMPLETE","; scenarios=",scenarios,"; failures=",failures)
 quit(0 if failures==0 and scenarios==15 else 1)
