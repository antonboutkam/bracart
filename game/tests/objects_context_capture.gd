extends SceneTree
## Existing buildings and tabletop props on their actual tracks, never a studio copy.
const Main = preload("res://scripts/main.gd")
var output: String
var validate_only := false
var failures := 0
var scenarios := 0
var subjects: Array[Dictionary] = []

func _initialize() -> void: call_deferred("run")

func shot(filename: String, label: String, category: String, world: int, target: Vector3) -> void:
 scenarios += 1
 subjects.append({"filename":filename+".png","label":label,"category":category,"world":world,"target":[target.x,target.y,target.z]})
 if validate_only:
  await process_frame
  var camera := root.get_camera_3d()
  if camera == null or not camera.global_transform.is_finite() or not camera.is_position_in_frustum(target): failures += 1
  print("CONTEXT SETUP ",filename," (no image)")
  return
 for frame in 10: await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 if picture.is_empty() or picture.save_png(output.path_join(filename+".png")) != OK: failures += 1
 print("CONTEXT CAPTURE ",filename)

func run() -> void:
 validate_only = "--validate-only" in OS.get_cmdline_user_args()
 output = OS.get_environment("BORACER_CAPTURE_DIR")
 if not validate_only and (output.is_empty() or DisplayServer.get_name() == "headless"):
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
 for world in [3,4]:
  game.start_race(world)
  game.race.set_process(false)
  game.ui.visible = false
  var district = game.track.get_node_or_null("StreetDistricts")
  var buildings: Array = district.get_meta("buildings",[]) if district != null else []
  if buildings.size()<3:
   failures += 1
   continue
  var overview: Transform3D = buildings[0].frame
  game.camera.fov = 60
  game.camera.position = overview*Vector3(25,35,-55)
  var center := overview*Vector3(0,3,0)
  game.camera.look_at(center)
  var prefix := "haarlem" if world==3 else "uithoorn"
  await shot(prefix+"-straat-overzicht", "Haarlemse gevelrij langs de racebaan" if world==3 else "Uithoornse woonwijk onder het parcours","gebouwen",world,center)
  var used: Array[int] = []
  for variant in 3:
   var index: int = variant
   for candidate in buildings.size():
    if candidate not in used and int(buildings[candidate].variant)==variant:
     index = candidate
     break
   used.append(index)
   var house: Dictionary = buildings[index]
   var frame: Transform3D = house.frame
   center = frame*Vector3(0,float(house.height)*0.48,-float(house.depth)*0.2)
   game.camera.fov = 55
   game.camera.position = frame*Vector3(float(house.width)*0.7,float(house.height)*0.85,-float(house.depth)*0.5-18)
   game.camera.look_at(center)
   var title: String = ["Haarlems huis met trapgevel","Haarlems huis met lijstgevel","Haarlems huis met kapgevel"][variant] if world==3 else "Uithoorns woonhuis %d met dakkapel" % (variant+1)
   await shot(prefix+"-gebouw-%d" % (variant+1),title,"gebouwen",world,center)
 game.start_race(5)
 game.race.set_process(false)
 game.ui.visible = false
 game.camera.fov = 65
 game.camera.position = Vector3(0,220,150)
 game.camera.look_at(Vector3.ZERO)
 await shot("keukentafel-objecten-overzicht","Voorwerpen op de echte keukentafel","objecten",5,Vector3.ZERO)
 var props = game.track.get_node_or_null("KitchenProps")
 var objects: Array = props.get_meta("objects",[]) if props != null else []
 if objects.size()!=11: failures += 1
 for item in objects:
  var height: float = float(item.height)
  var center: Vector3 = item.center+Vector3.UP*height*0.45
  var radius: float = maxf(Vector2(float(item.radius),height*0.5).length(),3)
  game.camera.fov = 52
  game.camera.position = center+Vector3(1,0.95,1.6).normalized()*maxf(radius*3.2,12)
  game.camera.look_at(center)
  await shot("tafel-"+str(item.id),str(item.label),"objecten",5,center)
 if not validate_only:
  var manifest := FileAccess.open(output.path_join("subjects.json"),FileAccess.WRITE)
  if manifest == null: failures += 1
  else: manifest.store_string(JSON.stringify(subjects,"  "))
 game.queue_free()
 await process_frame
 print("CONTEXT ","SETUP VALIDATION; no images" if validate_only else "CAPTURE COMPLETE","; scenarios=",scenarios,"; failures=",failures)
 quit(0 if failures==0 and scenarios==20 else 1)
