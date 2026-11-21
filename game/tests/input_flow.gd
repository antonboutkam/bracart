extends SceneTree
const Main = preload("res://scripts/main.gd")
var failures: Array[String] = []
var checks: int = 0
var game

func check(condition: bool, title: String) -> void:
 checks += 1
 if not condition:
  failures.append(title)
  push_error(title)

func _initialize() -> void:
 call_deferred("run")

func find_button(node: Node, title: String) -> Button:
 if node is Button and node.text == title:
  return node
 for child in node.get_children():
  var found = find_button(child, title)
  if found:
   return found
 return null

func click(title: String) -> void:
 await process_frame
 var target = find_button(game.ui, title)
 check(target != null, "button exists: " + title)
 if not target:
  return
 var pos = target.get_global_rect().get_center()
 for down in [true, false]:
  var event = InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_LEFT
  event.position = pos
  event.pressed = down
  root.push_input(event, true)
  await process_frame

func key(code: Key, down: bool) -> void:
 var event = InputEventKey.new()
 event.physical_keycode = code
 event.pressed = down
 Input.parse_input_event(event)
 Input.flush_buffered_events()

func run() -> void:
 game = Main.new()
 root.add_child(game)
 await process_frame
 game.audio.music.stop()
 game.audio.muted = true
 game.set_physics_process(false)
 check(game.ui.active_page == "splash", "startup opens branded splash")
 await click("Speel  →")
 check(game.ui.active_page == "home", "splash opens dashboard")
 await click("Racen  →")
 check(find_button(game.ui, "Start de race  →") != null, "mouse opens world selection")
 await click("Start de race  →")
 check(game.mode == "race", "mouse starts race")
 if game.mode == "race":
  game.race.countdown = -1
  key(KEY_W, true)
  for i in 90:
   game._physics_process(1.0 / 60)
  key(KEY_W, false)
  check(game.race.player.speed > 15, "physical W input accelerates")
  key(KEY_D, true)
  for i in 30:
   game._physics_process(1.0 / 60)
  key(KEY_D, false)
  check(game.race.player.lateral > -1.5, "physical D input steers")
  game.race.player.power = "Schild"
  game.race.use_power()
  check(game.race.player.shield_time > 0, "player has an active shield")
  await click("Ⅱ")
  check(game.race.paused, "mouse pause freezes race")
  await click("Verder racen")
  check(not game.race.paused, "mouse resumes race")
  await click("Ⅱ")
  await click("Naar het hoofdmenu")
  check(game.mode == "menu" and game.race == null, "mouse can abandon race safely")
 game.queue_free()
 await process_frame
 print("BORACER INPUT FLOW: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
