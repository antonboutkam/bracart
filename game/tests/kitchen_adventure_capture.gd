extends SceneTree
## The actual kitchen course and furniture, including real race jump/trigger state.
const Main = preload("res://scripts/main.gd")
var output: String
var validate_only := false
var failures := 0
var scenarios := 0
var game
var props: Dictionary = {}
var course: Dictionary = {}

func _initialize() -> void: call_deferred("run")

func shot(filename: String) -> void:
 scenarios += 1
 if validate_only:
  await process_frame
  if not game.camera.global_transform.is_finite(): failures += 1
  print("KITCHEN ADVENTURE SETUP ",filename," (no image)")
  return
 for frame in 10: await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 if picture.is_empty() or picture.save_png(output.path_join(filename+".png"))!=OK: failures += 1
 print("KITCHEN ADVENTURE CAPTURE ",filename)

func stage_player(progress: float, hud: bool = true) -> void:
 game.race.player.progress = progress
 game.race.player.speed = 22
 game.race.player.lateral = 0
 game.race.player.jump_height = 0
 game.race.player.jump_velocity = 0
 game.race.player.update_visual(game.track,0)
 game._process(1.0/60)
 game._camera(0,true)
 game.ui.visible = hud

func context(id: String, filename: String) -> void:
 game.ui.visible = false
 var feature: Dictionary = props[id]
 var center: Vector3 = feature.center+Vector3.UP*float(feature.height)*0.35
 var radius: float = maxf(float(feature.get("radius",10)),float(feature.height)*0.6)
 game.camera.fov = 55
 game.camera.position = center+Vector3(1,0.85,1.5).normalized()*maxf(radius*3,18)
 game.camera.look_at(center)
 await shot(filename)

func jumping(id: String, filename: String) -> void:
 var feature: Dictionary = course[id]
 stage_player(float(feature.lip)-2)
 var launched := false
 for tick in 90:
  game.race.step(1.0/60,1,0,0,false)
  if game.race.player.progress > float(feature.lip)+1:
   launched = true
   break
 if not launched or game.race.player.jump_height<=0: failures += 1
 game._process(1.0/60)
 game._camera(0,true)
 game.ui.visible = true
 await shot(filename)

func run() -> void:
 validate_only = "--validate-only" in OS.get_cmdline_user_args()
 output = OS.get_environment("BORACER_CAPTURE_DIR")
 if not validate_only and (output.is_empty() or DisplayServer.get_name()=="headless"):
  push_error("Set BORACER_CAPTURE_DIR and use native Godot rendering")
  quit(2)
  return
 root.size = Vector2i(1280,800)
 game = Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.muted = true
 game.audio.music.stop()
 game.audio.music.stream = null
 game.start_race(5)
 game.race.countdown = 0
 game.race.set_process(false)
 var additions = game.track.get_node_or_null("KitchenAdventureProps")
 if additions==null or not game.track.has_method("kitchen_features"):
  push_error("Missing kitchen feature contract")
  quit(1)
  return
 for item in additions.get_meta("features",[]): props[str(item.id)] = item
 for item in game.track.kitchen_features(): course[str(item.id)] = item
 for id in ["toilet_rolls","loose_cables","pvc_rainbow","comic_ramp","card_ramp","game_controller"]:
  if not props.has(id): failures += 1
 if failures>0:
  quit(1)
  return
 game.ui.visible = false
 game.camera.fov = 65
 game.camera.position = Vector3(0,220,150)
 game.camera.look_at(Vector3.ZERO)
 await shot("keukentafel-avontuur-overzicht")
 stage_player(0)
 await shot("keukentafel-race-start")
 await context("toilet_rolls","toiletrollen-overzicht")
 stage_player(float(course.toilet_rolls.center))
 await shot("toiletrollen-racecamera")
 await context("loose_cables","losse-kabels-overzicht")
 stage_player(float(course.loose_cables.center))
 await shot("losse-kabels-racecamera")
 stage_player(0,false)
 await context("pvc_rainbow","pvc-grijs-zonder-effect")
 stage_player(float(course.pvc_rainbow.center))
 await shot("pvc-regenboog-binnen")
 for tick in 90: game._process(1.0/60)
 await shot("pvc-regenboog-gedraaid")
 var loop_data: Dictionary = course.orange_loop
 var loop_frame: Transform3D = game.track.frame(float(loop_data.start))
 var apex: Transform3D = loop_data.frame
 var center: Vector3 = apex.origin-Vector3.UP*float(loop_data.radius)
 game.ui.visible = false
 game.camera.fov = 55
 game.camera.position = center+loop_frame.basis.x*52+Vector3.UP*12
 game.camera.look_at(center)
 await shot("oranje-looping-voor")
 game.camera.position = center+loop_frame.basis.x*42+loop_frame.basis.z*28+Vector3.UP*18
 game.camera.look_at(center)
 await shot("oranje-looping-zij")
 game.camera.position = Vector3(center.x,3,center.z)+loop_frame.basis.z*8
 game.camera.look_at(apex.origin)
 await shot("oranje-looping-onderzijde")
 stage_player(float(loop_data.center))
 await shot("oranje-looping-ondersteboven")
 await context("comic_ramp","stripalbum-schans")
 await jumping("comic_ramp","stripalbum-sprong")
 await context("card_ramp","speelkaart-schans")
 await jumping("card_ramp","speelkaart-sprong")
 await context("game_controller","zwarte-controller")
 game.ui.visible = false
 var room = game.track.find_child("AdventureRoomFurniture",true,false)
 var views: Array = room.get_meta("review_views",[]) if room!=null else []
 if views.size()!=2: failures += 1
 for view in views:
  game.camera.fov = 58
  game.camera.position = view.eye
  game.camera.look_at(view.target)
  await shot(str(view.id))
 game.queue_free()
 await process_frame
 print("KITCHEN ADVENTURE ","SETUP VALIDATION; no images" if validate_only else "CAPTURE COMPLETE","; scenarios=",scenarios,"; failures=",failures)
 quit(0 if failures==0 and scenarios==20 else 1)
