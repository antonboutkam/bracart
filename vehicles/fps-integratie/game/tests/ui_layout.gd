extends SceneTree
const Main = preload("res://scripts/main.gd")
const Profile = preload("res://scripts/profile.gd")
const Catalog = preload("res://scripts/catalog.gd")
const Preview = preload("res://scripts/ui/vehicle_preview.gd")
const TouchAction = preload("res://scripts/ui/touch_action.gd")
var checks = 0
var failures: Array[String] = []

func check(value: bool, title: String) -> void:
 checks += 1
 if not value:
  failures.append(title)
  push_error(title)

func descendants(node: Node, type: String) -> Array:
 var found: Array = []
 for child in node.get_children():
  if child.is_class(type):
   found.append(child)
  found.append_array(descendants(child, type))
 return found

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var main = Main.new()
 root.add_child(main)
 await process_frame
 main.set_process(false)
 main.set_physics_process(false)
 main.audio.muted = true
 main.audio.music.stop()
 main.profile = Profile.new("user://ui-layout-isolated.json")
 var ui = main.ui
 ui.show_garage()
 await process_frame
 await process_frame
 var previews: Array = []
 for candidate in descendants(ui.screen, "TextureRect"):
  if candidate is Preview:
   previews.append(candidate)
 check(previews.size() == Catalog.VEHICLES.size() + 1, "Garage shows all vehicle cards and the current vehicle")
 for preview in previews:
  check(preview.viewport.own_world_3d and preview.viewport.msaa_3d == Viewport.MSAA_4X, "Preview isolates lighting and provides antialiasing")
 var choose_buttons = 0
 for candidate in descendants(ui.screen, "Button"):
  if candidate.text in ["Selecteren", "Geselecteerd", "Kopen"]:
   choose_buttons += 1
 check(choose_buttons == Catalog.VEHICLES.size() - 1, "Only vehicles that are not selected have a selection or purchase action")
 var garage_panels = descendants(ui.screen, "PanelContainer")
 for card in garage_panels:
  check(card.position.y + card.size.y < 752, "Garage content remains above footer")
 ui.show_settings()
 await process_frame
 await process_frame
 var toggles = descendants(ui.screen, "CheckButton")
 check(toggles.size() == 7, "Settings expose graphics, replay, FPS and input preferences")
 for toggle in toggles:
  var bounds: Rect2 = toggle.get_global_rect()
  check(bounds.end.y <= ui.layout_root.get_global_rect().end.y, "Setting controls remain within logical page")
 var cancel = InputEventAction.new()
 cancel.action = "ui_cancel"
 cancel.pressed = true
 ui._input(cancel)
 check(ui.active_page == "home", "Cancel returns settings to home")
 ui.show_garage()
 await process_frame
 ui.show_vehicle(0)
 ui._input(cancel)
 check(ui.active_page == "garage", "Cancel returns model inspection to garage")
 await process_frame
 var focus = root.gui_get_focus_owner()
 ui.show_message("Een langere melding die leesbaar in het venster moet passen.")
 await process_frame
 ui._input(cancel)
 check(ui.overlay.get_child_count() == 0 and (focus == null or root.gui_get_focus_owner() == focus), "Dismiss message restores previous menu focus")
 main.profile.settings.touch_controls = true
 main.start_race(0)
 await process_frame
 var touch_count = 0
 for child in ui.hud.get_children():
  if child is TouchAction:
   touch_count += 1
 check(touch_count == 8, "Touch setting exposes eight independent action targets")
 ui.update_hud(0)
 check("Ronde" in ui.current_lap_label.text and "Beste race" in ui.record_label.text, "HUD exposes lap timer and world record")
 check(not ui.section_label.text.is_empty(), "HUD describes current track section")
 ui.show_pause()
 ui._input(cancel)
 check(not main.race.paused and ui.overlay.get_child_count() == 0, "Cancel resumes paused race")
 main.race.done = true
 main.race.reward = 30
 main.race.elapsed = 42
 main.race.payout_claimed = false
 main.last_save_error = "Test storage failure"
 ui.show_results()
 var retry: Button
 for candidate in descendants(ui.overlay, "Button"):
  if candidate.text == "Opnieuw opslaan":
   retry = candidate
 check(is_instance_valid(retry), "Unsaved race result offers an explicit retry")
 if is_instance_valid(retry):
  retry.pressed.emit()
 check(main.race.payout_claimed and main.last_save_error == "", "Result retry saves reward and clears error status")
 # Test layout math against actual viewport geometry at common aspect ratios.
 for dimensions in [Vector2i(1280, 800), Vector2i(1280, 720), Vector2i(800, 600), Vector2i(600, 900)]:
  root.content_scale_size = Vector2i.ZERO
  root.size = dimensions
  ui._resize_layout()
  var rect: Rect2 = ui.layout_root.get_global_rect()
  check(rect.position.x >= -0.1 and rect.position.y >= -0.1 and rect.end.x <= dimensions.x + 0.1 and rect.end.y <= dimensions.y + 0.1, "Logical layout fits %dx%d viewport" % [dimensions.x, dimensions.y])
 for suffix in ["", ".bak", ".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(main.profile.storage_path + suffix))
 main.queue_free()
 await process_frame
 print("BORACER UI LAYOUT: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
