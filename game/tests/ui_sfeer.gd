extends SceneTree
## Runtime geometry/input checks. These do not replace a native visual review.
const Main = preload("res://scripts/main.gd")
const Profile = preload("res://scripts/profile.gd")
const TouchAction = preload("res://scripts/ui/touch_action.gd")
var checks = 0
var failures: Array[String] = []

func check(value: bool, title: String) -> void:
 checks += 1
 if not value:
  failures.append(title)
  push_error(title)

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
 main.profile = Profile.new("user://ui-sfeer-isolated.json")
 var ui = main.ui
 ui.show_splash()
 await process_frame
 check(ui.active_page == "splash" and ui.screen.visible and not ui.hud.visible, "Splash has its own state and no race HUD")
 var play: Button = ui.screen.get_node("SplashPlay")
 check(root.gui_get_focus_owner() == play, "Splash immediately focuses the Play action")
 var cancel = InputEventAction.new()
 cancel.action = "ui_cancel"
 cancel.pressed = true
 ui._input(cancel)
 check(ui.active_page == "splash", "Cancel cannot accidentally bypass the splash")
 var start = InputEventJoypadButton.new()
 start.pressed = true
 start.button_index = JOY_BUTTON_START
 ui._input(start)
 check(ui.active_page == "home" and main.mode == "menu", "Controller Start enters main menu")
 ui.show_splash()
 var enter = InputEventAction.new()
 enter.action = "ui_accept"
 enter.pressed = true
 ui._input(enter)
 check(ui.active_page == "home", "Keyboard accept enters main menu")
 ui.show_splash()
 play = ui.screen.get_node("SplashPlay")
 play.pressed.emit()
 check(ui.active_page == "home", "Pointer/touch Play action enters main menu")
 main.start_race(0)
 await process_frame
 await process_frame
 main.race.countdown = -1
 main.race.player.speed = 40
 main.race.player.boost = 42
 ui.update_hud(0)
 check(ui.position_label.get_theme_font_size("font_size") >= 60, "Position is the primary large race readout")
 check(ui.speed_label.text == "144", "Speed gauge uses real km/h")
 check(is_equal_approx(ui.race_gauge.speed_ratio, 0.72) and is_equal_approx(ui.race_gauge.boost_ratio, 0.42), "Speed arc and boost battery reflect gameplay state")
 check(ui.rank_rows.size() == main.race.racers.size(), "Every racer has an individual standings row")
 var player_row_count = 0
 for row in ui.rank_rows:
  if "◀" in row.label.text:
   player_row_count += 1
   check(row.panel.get_theme_stylebox("panel").border_color == ui.CYAN, "Player standings row has a cyan border")
 check(player_row_count == 1, "Exactly one standings row marks the player")
 # The straight-ahead drive corridor remains clear of corner instruments.
 var corridor = Rect2(420, 420, 480, 300)
 check(not ui.race_gauge.get_global_rect().intersects(corridor), "Speedometer preserves the driving corridor")
 for row in ui.rank_rows:
  check(not row.panel.get_global_rect().intersects(corridor), "Standings preserve the driving corridor")
 main.profile.settings.touch_controls = true
 ui.show_hud()
 await process_frame
 await process_frame
 ui.update_hud(0)
 for child in ui.hud.get_children():
  if child is TouchAction:
   check(not (child.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, child.BUTTON_SIZE)).intersects(ui.race_gauge.get_global_rect()), "Touch action %s does not overlap speed instrument" % child.action)
 for dimensions in [Vector2i(1280, 800), Vector2i(1280, 720), Vector2i(800, 600), Vector2i(600, 900)]:
  root.content_scale_size = Vector2i.ZERO
  root.size = dimensions
  ui._resize_layout()
  var bounds: Rect2 = ui.layout_root.get_global_rect()
  check(bounds.position.x >= -0.1 and bounds.position.y >= -0.1 and bounds.end.x <= dimensions.x + 0.1 and bounds.end.y <= dimensions.y + 0.1, "Race UI fits %s" % dimensions)
 main.go_home()
 check(ui.active_page == "home", "Returning from a race opens menu rather than replaying splash")
 main.queue_free()
 await process_frame
 print("BORACER UI SFEER: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
