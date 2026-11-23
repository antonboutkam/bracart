extends SceneTree
const Main = preload("res://scripts/main.gd")
const Catalog = preload("res://scripts/catalog.gd")
const Profile = preload("res://scripts/profile.gd")
const Preview = preload("res://scripts/ui/vehicle_preview.gd")
var checks := 0
var failures := 0
func check(value: bool, title: String) -> void:
 checks += 1
 if not value:
  failures += 1
  if failures < 12: push_error(title)
func _initialize() -> void:
 call_deferred("run")
func previews(node: Node) -> Array:
 var found: Array = []
 for child in node.get_children():
  if child is Preview: found.append(child)
  found.append_array(previews(child))
 return found
func run() -> void:
 var main := Main.new()
 root.add_child(main)
 await process_frame
 main.set_process(false)
 main.set_physics_process(false)
 main.audio.music.stop()
 main.audio.music.stream = null
 main.audio.muted = true
 var path := "user://garage-features-isolated.json"
 for suffix in ["",".bak",".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 main.profile = Profile.new(path)
 main.profile.save_profile()
 main.ui.show_garage()
 await process_frame
 var drivers: Control = main.ui.screen.get_node("GarageDrivers")
 check(drivers.selected_id == "boaz" and drivers.front_id == "boaz","Saved driver starts at the front with winner state")
 check(drivers.portraits.boaz.winner and not drivers.portraits.ravi.winner,"Only saved driver receives crown")
 check(drivers.portraits.boaz.artwork is AtlasTexture and drivers.portraits.ravi.artwork.atlas == drivers.ART,"Original shared illustrated torso art reused")
 var wallet_snapshot: String = FileAccess.get_file_as_string(path)
 drivers.portraits.ravi.mouse_entered.emit()
 check(drivers.front_id == "ravi" and main.profile.character == "boaz" and FileAccess.get_file_as_string(path) == wallet_snapshot,"Rear portrait hover only swaps display order, never persists")
 drivers.portraits.boaz.mouse_entered.emit()
 check(drivers.front_id == "ravi","Hover latch prevents stacking from oscillating beneath a stationary pointer")
 drivers.reset_presentation()
 drivers.portraits.ravi.grab_focus()
 check(drivers.front_id == "ravi" and main.profile.character == "boaz","Keyboard/controller focus previews the same portrait swap without selecting")
 check(drivers.portraits.ravi.tooltip_text.contains("Ravi") and drivers.portraits.ravi.accessibility_name == "Ravi","Portrait has accessible and tooltip character names")
 drivers.portraits.ravi.pressed.emit()
 await process_frame
 check(main.profile.character == "ravi" and Profile.new(path).character == "ravi","Portrait activation persists actual driver choice")
 drivers = main.ui.screen.get_node("GarageDrivers")
 check(drivers.front_id == "ravi" and drivers.portraits.ravi.winner,"Chosen portrait becomes the front winner")
 for funds in [79,80,81]:
  main.profile.coins = funds
  main.ui.show_garage()
  await process_frame
  var choose: Button = main.ui.screen.find_child("GarageChoose_purple-passion",true,false)
  check(choose.text == "Kopen" and choose.disabled == (funds<80),"Buy availability obeys exact price boundary")
  var style: StyleBoxFlat = choose.get_theme_stylebox("normal")
  if funds >= 80:
   check(style.bg_color.g > style.bg_color.r and style.bg_color.g > style.bg_color.b,"Affordable purchase is visibly green")
  else:
   check(choose.tooltip_text.contains("80") and choose.tooltip_text.contains("79"),"Unaffordable action explains required and available coins")
 var action: Button = main.ui.screen.find_child("GarageChoose_purple-passion",true,false)
 action.pressed.emit()
 await process_frame
 check("purple-passion" in main.profile.owned and main.profile.coins == 1 and main.profile.selected == 1,"Green buy uses actual single-charge profile transaction")
 action = main.ui.screen.find_child("GarageChoose_purple-passion",true,false)
 check(action == null,"Selected vehicle has no redundant selection button")
 check(main.ui.screen.get_node("GarageSelectedVehicle").studio.kart.vehicle_index == 1,"Chosen vehicle is displayed beside the drivers")
 var cards: Array = previews(main.ui.screen)
 check(cards.size() == Catalog.VEHICLES.size() + 1,"Every vehicle and the selected vehicle have studios")
 for preview in cards:
  preview.set_process(false)
  check(preview.studio.has_node("TrackDiorama/RaceAsphalt") and preview.studio.has_node("TrackDiorama/TracksideTree"),"Actual road/grass/kerbs/tree diorama supports each preview")
  var before: float = preview.studio.kart.rotation.y
  preview.advance(0.1)
  check(preview.studio.kart.rotation.y != before,"Visible vehicle actually rotates slowly")
  for index in 13:
   preview.studio.kart.rotation.y = float(index)/12*TAU
   for corner in 8:
    var point: Vector3 = preview.studio.kart.global_transform*preview.studio.frame_bounds.get_endpoint(corner)
    var pixel: Vector2 = preview.studio.camera.unproject_position(point)
    check(pixel.x>=1 and pixel.x<675 and pixel.y>=1 and pixel.y<183,"Every vehicle and rider stay inside the rotating-card camera frame")
  preview.hide()
  var stopped: float = preview.studio.kart.rotation.y
  preview.advance(1)
  check(stopped == preview.studio.kart.rotation.y and preview.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED,"Hidden card suspends both rotation and rendering")
  preview.show()
  check(preview.viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS,"Visible card resumes rendering")
 var old: WeakRef = weakref(cards[0].viewport)
 cards.clear()
 main.ui.show_home()
 await process_frame
 check(old.get_ref() == null,"Leaving garage frees preview subviewports")
 main.queue_free()
 await process_frame
 for suffix in ["",".bak",".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 print("BORACER GARAGE FEATURES: %d checks, %d failures" % [checks,failures])
 quit(0 if failures == 0 else 1)
