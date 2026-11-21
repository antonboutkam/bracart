extends SceneTree
## Independent real-input, economy, projected model and lifecycle checks.
const Main = preload("res://scripts/main.gd")
const Profile = preload("res://scripts/profile.gd")
const Catalog = preload("res://scripts/catalog.gd")
const Preview = preload("res://scripts/ui/vehicle_preview.gd")
var checks = 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures.append(label)
  if failures.size() <= 15: push_error(label)
func descendants(node: Node) -> Array[Node]:
 var result: Array[Node] = []
 for child in node.get_children():
  result.append(child)
  result.append_array(descendants(child))
 return result
func previews(node: Node) -> Array:
 return descendants(node).filter(func(n): return n is Preview)
func move(point: Vector2) -> void:
 var event = InputEventMouseMotion.new()
 event.position = point
 Input.parse_input_event(event)
 await process_frame
 await process_frame
func click(button: Button) -> void:
 var point = button.get_global_rect().get_center()
 await move(point)
 await click_at(point)
func click_at(point: Vector2) -> void:
 for state in [true,false]:
  var event = InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_LEFT
  event.position = point
  event.pressed = state
  root.push_input(event,true)
  await process_frame
func framed(preview) -> void:
 var kart = preview.studio.kart
 var camera: Camera3D = preview.studio.camera
 var previous: float = kart.rotation.y
 preview.set_process(false)
 var rect = Rect2(Vector2.ONE,Vector2(preview.viewport.size)-Vector2.ONE*2)
 for angle in 13:
  kart.rotation.y = angle*TAU/12.0
  for node in descendants(kart):
   if node is MeshInstance3D and node.visible and node.is_visible_in_tree():
    for corner in 8:
     var point: Vector3 = node.global_transform*node.get_aabb().get_endpoint(corner)
     check(not camera.is_position_behind(point) and rect.has_point(camera.unproject_position(point)),"Vehicle and seated driver fit actual preview at every sampled rotation")
 kart.rotation.y = previous
 preview.set_process(true)
 var track = preview.studio.get_node("TrackDiorama")
 check(track.get_node("RaceAsphalt").mesh is BoxMesh,"Preview uses supported road geometry with race asphalt")
 check(track.get_node("GrassVerge").position.y < track.get_node("RaceAsphalt").position.y,"Grass stays below the vehicle road surface")
func run() -> void:
 root.size = Vector2i(1280,800)
 var main = Main.new()
 root.add_child(main)
 await process_frame
 main.set_physics_process(false)
 main.audio.muted = true
 main.audio.music.stop()
 main.audio.music.stream = null
 for suffix in ["", ".bak", ".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path("user://independent-garage-qa.json"+suffix))
 main.profile = Profile.new("user://independent-garage-qa.json")
 main.profile.coins = 79
 main.profile.character = "boaz"
 main.profile.records = {"haarlem-1888":73.25}
 main.world_index = 4
 main.ui.show_garage()
 for frame in 4: await process_frame
 var ui = main.ui
 var drivers = ui.screen.get_node("GarageDrivers")
 check(drivers.front_id == "boaz" and drivers.portraits.boaz.winner,"Selected driver starts in front with winner marker")
 var rear: Button = drivers.portraits.ravi
 var hover_point: Vector2 = rear.global_position+Vector2(rear.size.x-10,rear.size.y*0.5)
 await move(hover_point)
 check(root.gui_get_hovered_control() in drivers.portraits.values(),"Injected portrait pointer reaches an actual native portrait Button")
 check(drivers.front_id == "ravi" and main.profile.character == "boaz","Actual rear-portrait hover changes presentation without changing saved driver")
 check(drivers.portraits.ravi.z_index > drivers.portraits.boaz.z_index,"Hovered portrait actually draws above selected portrait")
 check(drivers.portraits.boaz.winner and not drivers.portraits.ravi.winner,"Hover keeps the saved winner crown on Boaz until confirmation")
 await click_at(hover_point)
 check(main.profile.character == "ravi" and Profile.new(main.profile.storage_path).character == "ravi","Stationary click after rear-portrait swap saves intended Ravi rather than displaced Boaz")
 check(main.profile.coins == 79 and main.profile.records == {"haarlem-1888":73.25},"Portrait selection preserves economy and records")
 drivers = ui.screen.get_node("GarageDrivers")
 drivers.portraits.boaz.grab_focus()
 await process_frame
 check(drivers.front_id == "boaz" and main.profile.character == "ravi" and drivers.portraits.ravi.winner,"Keyboard focus previews Boaz while retaining saved Ravi until confirmation")
 for pressed in [true,false]:
  var key = InputEventKey.new()
  key.keycode = KEY_ENTER
  key.physical_keycode = KEY_ENTER
  key.pressed = pressed
  root.push_input(key,true)
  await process_frame
 check(main.profile.character == "boaz","Actual keyboard accept selects driver")
 drivers = ui.screen.get_node("GarageDrivers")
 rear = drivers.portraits.ravi
 await move(rear.global_position+Vector2(rear.size.x-10,rear.size.y*0.5))
 check(drivers.front_id == "ravi" and drivers.hover_latched,"A second actual rear hover still works after keyboard selection")
 var axis = InputEventJoypadMotion.new()
 axis.axis = JOY_AXIS_LEFT_X
 axis.axis_value = 0.8
 root.push_input(axis,true)
 await process_frame
 check(not drivers.hover_latched and drivers.hover_candidate == "","Actual controller stick input clears prior mouse candidate")
 drivers.present("boaz")
 await move(Vector2(1200,780))
 check(drivers.front_id == main.profile.character and not drivers.hover_latched,"Leaving the portrait area restores the saved winner")
 var purchase: Button = ui.screen.find_child("GarageChoose_purple-passion",true,false)
 check(purchase.disabled,"Price-minus-one purchase is disabled")
 await click(purchase)
 check(main.profile.coins == 79 and not "purple-passion" in main.profile.owned,"Disabled purchase cannot spend coins")
 main.profile.coins = 80
 ui.show_garage()
 for frame in 3: await process_frame
 purchase = ui.screen.find_child("GarageChoose_purple-passion",true,false)
 var style: StyleBoxFlat = purchase.get_theme_stylebox("normal")
 check(not purchase.disabled and purchase.text == "Kopen" and style.bg_color.g > style.bg_color.r*1.5 and style.bg_color.g > style.bg_color.b*1.2,"Exactly affordable purchase is enabled with green affordance")
 await click(purchase)
 check(main.profile.coins == 0 and main.profile.selected == 1 and "purple-passion" in main.profile.owned,"Real green button spends exact price and selects vehicle")
 var reloaded = Profile.new(main.profile.storage_path)
 check(reloaded.coins == 0 and reloaded.selected == 1 and "purple-passion" in reloaded.owned,"Purchase survives actual profile reload")
 check(ui.screen.find_child("GarageChoose_purple-passion",true,false) == null,"Current vehicle has no select action")
 await click(ui.screen.find_child("GarageChoose_retro",true,false))
 await click(ui.screen.find_child("GarageChoose_purple-passion",true,false))
 check(main.profile.coins == 0,"Selecting an owned vehicle never charges twice")
 var cards = previews(ui.screen)
 check(cards.size() == 7,"Garage contains six cards and the current vehicle beside the drivers")
 for preview in cards:
  check(preview.studio.kart.driver == main.profile.character,"All cards contain the currently selected seated driver")
  framed(preview)
  var before: float = preview.studio.kart.rotation.y
  await create_timer(0.03).timeout
  check(preview.studio.kart.rotation.y != before and preview.viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS,"Visible preview rotates through real scene frames")
  preview.hide()
  before = preview.studio.kart.rotation.y
  await create_timer(0.03).timeout
  check(preview.studio.kart.rotation.y == before and preview.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED,"Hidden preview stops rotation and rendering")
  preview.show()
 for index in 6:
  ui.show_vehicle(index)
  for frame in 2: await process_frame
  var heroes = previews(ui.screen)
  check(heroes.size() == 1 and heroes[0].studio.kart.vehicle_index == index,"Each detail renders its actual vehicle")
  framed(heroes[0])
 ui.show_garage()
 for frame in 3: await process_frame
 var baseline = descendants(main).size()
 for repeat in 4:
  var old = weakref(previews(ui.screen)[0])
  ui.show_home()
  ui.show_garage()
  for frame in 3: await process_frame
  check(old.get_ref() == null and previews(ui.screen).size() == 7,"Garage reentry frees old studios without stacking viewports")
 check(descendants(main).size() == baseline,"Repeated garage reentry has stable owned node count")
 check(main.world_index == 4 and main.profile.records == {"haarlem-1888":73.25},"Garage browsing never resets chosen world or records")
 main.queue_free()
 for frame in 8: await process_frame
 print("BORACER GARAGE INDEPENDENT QA: %d checks, %d failures" % [checks,failures.size()])
 quit(1 if failures.size() else 0)
