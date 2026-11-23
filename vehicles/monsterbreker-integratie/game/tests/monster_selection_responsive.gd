extends SceneTree
const Main = preload("res://scripts/main.gd")
const Catalog = preload("res://scripts/catalog.gd")
const Monsters = preload("res://scripts/monster/catalog.gd")
var failures := 0
func check(ok: bool, msg: String):
 if not ok:
  failures += 1
  push_error(msg)
func _initialize():
 call_deferred("run")
func run():
 var game = Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.music.stop()
 game.audio.muted = true
 await process_frame
 var entries = Monsters.entries()
 check(entries.size() == 8 and entries.all(func(e): return e.get("format") == "fractured"), "Only refined monsters listed")
 game.choose_monster(1)
 await process_frame
 check(game.ui.screen.find_child("Choose_02-schouderreus-turkoois", true, false) == null, "Old monster excluded")
 game.start_monster(Monsters.DEFAULT_ID, 1)
 var mode = game.monster_mode
 mode.set_process(false)
 mode.set_physics_process(false)
 await process_frame
 await process_frame
 var scroll = mode.vehicle_picker.find_child("VehicleScroll", true, false)
 check(scroll != null, "Vehicle choice can scroll")
 check(mode.vehicle_buttons.size() == Catalog.available_indices().size(), "Every playable vehicle has a choice")
 for i in mode.vehicle_buttons.size():
  var button: Button = mode.vehicle_buttons[i]
  check(button.icon != null, "Thumbnail for " + button.name)
  scroll.ensure_control_visible(button)
  await process_frame
  var b = button.get_global_rect()
  var v = scroll.get_global_rect()
  check(v.intersection(b).size.x >= b.size.x - 1, "Visible after scrolling: " + button.name)
  button.pressed.emit()
  check(mode.vehicle_index == mode.vehicles[i] and mode.rocket.vehicle_index == mode.vehicles[i], "Selectable: " + button.name)
 check(game.environment.environment.background_color == Color("526c82") and game.sun.light_energy < .75, "Darkened world")
 game.queue_free()
 await process_frame
 print("MONSTER SELECTION: ", failures, " failures")
 quit(0 if failures == 0 else 1)
