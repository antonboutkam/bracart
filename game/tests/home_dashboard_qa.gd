extends SceneTree
## Independent Main/input/lifecycle checks. --quit-probe tests the real Exit callback separately.
const Main = preload("res://scripts/main.gd")
const Duo = preload("res://scripts/ui/home_duo_preview.gd")
const Catalog = preload("res://scripts/catalog.gd")
var checks = 0
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures.append(label)
  if failures.size() <= 12: push_error(label)

func _initialize() -> void:
 call_deferred("run")

func controls(node: Node) -> Array[Control]:
 var result: Array[Control] = []
 for child in node.get_children():
  if child is Control: result.append(child)
  result.append_array(controls(child))
 return result

func count_type(node: Node, type_name: String) -> int:
 var count = 1 if node.is_class(type_name) else 0
 for child in node.get_children(): count += count_type(child,type_name)
 return count

func meshes(node: Node3D) -> Array[MeshInstance3D]:
 var result: Array[MeshInstance3D] = []
 if not node.is_visible_in_tree(): return result
 if node is MeshInstance3D: result.append(node)
 for child in node.get_children():
  if child is Node3D: result.append_array(meshes(child))
 return result

func click(button: Button) -> void:
 var center = button.get_global_rect().get_center()
 for pressed in [true,false]:
  var event = InputEventMouseButton.new()
  event.position = center
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = pressed
  root.push_input(event,true)
  await process_frame

func run() -> void:
 var main = Main.new()
 root.add_child(main)
 await process_frame
 main.set_physics_process(false)
 main.audio.muted = true
 main.audio.music.stop()
 main.audio.music.stream = null
 main.profile.selected = 3
 main.profile.character = "ravi"
 main.profile.coins = 923
 main.profile.records = {"keukentafel":78.0}
 main.world_index = 4
 main.go_home()
 await process_frame
 await process_frame
 if "--quit-probe" in OS.get_cmdline_user_args():
  print("HOME EXIT PROBE: real callback requested")
  main.ui.screen.get_node("HomeExitTile").pressed.emit()
  await process_frame
  push_error("Home Exit callback failed to quit")
  quit(17)
  return
 var ui = main.ui
 var track_id: int = main.track.get_instance_id()
 var logo_found = false
 for control in controls(ui.screen):
  if control is TextureRect and control.texture != null and control.texture.resource_path == "res://assets/ui/logo.png": logo_found = true
 check(logo_found,"Dashboard still displays the existing unchanged logo asset")
 check(main.world_index == 4 and main.track.world_index == 4,"Home preserves chosen world instead of resetting it")
 check(not main.preview.visible,"Old single world hero is hidden on Home")
 var names = ["HomeRaceTile","HomeGarageTile","HomeSettingsTile","HomeExitTile"]
 var texts = ["Racen  →","Garage & coureurs","Instellingen","Afsluiten"]
 for index in 4:
  var tile: Button = ui.screen.get_node(names[index])
  check(tile.text == texts[index] and tile.focus_mode == Control.FOCUS_ALL,"Home tile retains action and keyboard focus: "+names[index])
  check(tile.get_node(tile.get_focus_neighbor(SIDE_RIGHT)) == ui.screen.get_node(names[(index+1)%4]),"Right focus navigation wraps through all tiles")
  for child in controls(tile): check(child.mouse_filter == Control.MOUSE_FILTER_IGNORE,"Tile picture/text decoration passes pointer input: "+str(child.name))
 check(root.gui_get_focus_owner() == ui.screen.get_node("HomeRaceTile"),"Racing tile receives initial focus")
 var right = InputEventKey.new()
 right.keycode = KEY_RIGHT
 right.physical_keycode = KEY_RIGHT
 right.pressed = true
 root.push_input(right,true)
 await process_frame
 check(root.gui_get_focus_owner() == ui.screen.get_node("HomeGarageTile"),"Actual keyboard navigation reaches next tile")
 right.pressed = false
 root.push_input(right,true)
 ui.screen.get_node("HomeRaceTile").grab_focus()
 var duo = ui.screen.get_node("HomeDuoPreview")
 check(absf(duo.position.x+duo.size.x*0.5-640.0) <= 1.0,"Duo panel is centered above the full four-tile dashboard")
 check(duo is Duo and duo.karts.size() == 2,"Actual Main mounts one two-racer preview")
 check(duo.viewport.transparent_bg and duo.viewport.own_world_3d,"Duo renders transparently in a separate world")
 var world = duo.studio.find_children("*","WorldEnvironment",false,false)[0]
 check(world.environment.background_mode == Environment.BG_COLOR and world.environment.background_color.a == 0,"Duo has no opaque world background")
 for index in 2:
  var kart = duo.karts[index]
  check(kart.vehicle_index == Catalog.DEFAULT_VEHICLE and kart.driver == ["boaz","ravi"][index] and kart.driver_state == "sit","Each actual character sits alone on a Raketfiets")
 for angle_index in 13:
  duo.angle = TAU*angle_index/12.0
  duo._pose()
  for kart in duo.karts:
   for mesh in meshes(kart):
    if mesh.mesh is PlaneMesh:
     check(mesh.material_override != null and mesh.material_override.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA,"Any support plane has alpha rather than an opaque background")
    for corner in 8:
     var point: Vector3 = mesh.global_transform*mesh.get_aabb().get_endpoint(corner)
     var pixel: Vector2 = duo.camera.unproject_position(point)
     check(not duo.camera.is_position_behind(point) and Rect2(1,1,958,598).has_point(pixel),"All actual visible mesh bounds fit every sampled turntable angle")
 var previous: float = duo.angle
 await create_timer(0.1).timeout
 check(duo.angle != previous,"Home rotation advances through real scene frames")
 check(count_type(duo,"SubViewport") == 1 and count_type(duo,"AudioStreamPlayer3D") == 0,"Duo owns one viewport and no vehicle-audio emitters")
 for dimensions in [Vector2i(1280,800),Vector2i(1280,720),Vector2i(800,600),Vector2i(600,900)]:
  root.content_scale_size = Vector2i.ZERO
  root.size = dimensions
  ui._resize_layout()
  await process_frame
  var page: Rect2 = ui.layout_root.get_global_rect()
  for tile_name in names: check(page.encloses(ui.screen.get_node(tile_name).get_global_rect()),"Tile remains within resized logical page")
  check(page.encloses(duo.get_global_rect()),"Duo remains within resized logical page")
 root.size = Vector2i(1280,800)
 ui._resize_layout()
 var old_duo = weakref(duo)
 await click(ui.screen.get_node("HomeRaceTile"))
 check(ui.active_page == "worlds" and main.mode == "menu","Click through actual race tile image opens world chooser")
 check(old_duo.get_ref() == null,"Leaving Home frees old duo rather than stacking previews")
 await process_frame
 check(main.preview.visible,"World single preview is restored outside Home")
 for item in [["HomeGarageTile","garage"],["HomeSettingsTile","settings"]]:
  ui.show_home()
  await process_frame
  await click(ui.screen.get_node(item[0]))
  check(ui.active_page == item[1],"Actual picture tile reaches "+item[1])
 ui.show_home()
 await process_frame
 var baseline_viewports = count_type(main,"SubViewport")
 var baseline_nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
 for repeat in 6:
  var old = weakref(ui.screen.get_node("HomeDuoPreview"))
  ui.show_settings()
  ui.show_home()
  await process_frame
  await process_frame
  check(old.get_ref() == null and count_type(main,"SubViewport") == baseline_viewports,"Repeated menu reentry keeps viewport count stable")
  check(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) <= baseline_nodes+2,"Repeated Home releases old models and controls")
 check(main.track.get_instance_id() == track_id and main.world_index == 4,"Submenu callbacks never rebuild or reset current world")
 check(main.profile.selected == 3 and main.profile.character == "ravi" and main.profile.coins == 923 and main.profile.records == {"keukentafel":78.0},"Home duo never changes actual player garage choice or earned progress")
 main.queue_free()
 await process_frame
 print("BORACER HOME DASHBOARD QA: %d checks, %d failures" % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
