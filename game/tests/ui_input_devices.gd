extends SceneTree
const Main = preload("res://scripts/main.gd")
const Profile = preload("res://scripts/profile.gd")
const TouchAction = preload("res://scripts/ui/touch_action.gd")
var checks = 0
var failures: Array[String] = []
var main

func check(condition: bool, title: String) -> void:
 checks += 1
 if not condition:
  failures.append(title)
  push_error(title)

func touch(target, index: int, pressed: bool, local_point = Vector2(43, 32)) -> void:
 var event = InputEventScreenTouch.new()
 event.index = index
 event.pressed = pressed
 event.position = target.get_global_transform_with_canvas() * local_point
 root.push_input(event, true)

func find_touch(action: String):
 for child in main.ui.hud.get_children():
  if child is TouchAction and child.action == action:
   return child
 return null

func release_actions() -> void:
 for action in ["accelerate", "brake", "steer_left", "steer_right", "boost", "power", "jump", "pause"]:
  Input.action_release(action)

func joy_axis(axis: int, amount: float) -> void:
 var event = InputEventJoypadMotion.new()
 event.device = 0
 event.axis = axis
 event.axis_value = amount
 Input.parse_input_event(event)
 Input.flush_buffered_events()

func joy_button(which: int, pressed: bool) -> void:
 var event = InputEventJoypadButton.new()
 event.device = 0
 event.button_index = which
 event.pressed = pressed
 Input.parse_input_event(event)
 Input.flush_buffered_events()

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 main = Main.new()
 root.add_child(main)
 await process_frame
 main.set_process(false)
 main.set_physics_process(false)
 main.audio.muted = true
 main.audio.music.stop()
 main.profile = Profile.new("user://input-devices-isolated.json")
 main.profile.settings.touch_controls = true
 main.start_race(0)
 await process_frame
 await process_frame
 var gas = find_touch("accelerate")
 var left = find_touch("steer_left")
 check(is_instance_valid(gas) and is_instance_valid(left), "Touch controls are present")
 if not is_instance_valid(gas) or not is_instance_valid(left):
  main.queue_free()
  quit(1)
  return
 for point in [Vector2(43, 32), Vector2(60, 40), Vector2(8, 8), Vector2(78, 56)]:
  touch(gas, 0, true, point)
  check(Input.is_action_pressed("accelerate"), "Visible gas target responds at %s" % point)
  touch(gas, 0, false, point)
  check(not Input.is_action_pressed("accelerate"), "Touch release clears gas at %s" % point)
 for outside in [Vector2(-8, -8), Vector2(94, 72)]:
  touch(gas, 0, true, outside)
  check(not Input.is_action_pressed("accelerate"), "Touch outside visible target does not press gas")
  touch(gas, 0, false, outside)
 touch(gas, 0, true, Vector2(60, 40))
 touch(left, 1, true, Vector2(60, 40))
 check(Input.is_action_pressed("accelerate") and Input.is_action_pressed("steer_left"), "Two fingers can hold gas and steering together")
 touch(gas, 0, false, Vector2(60, 40))
 check(not Input.is_action_pressed("accelerate") and Input.is_action_pressed("steer_left"), "Releasing gas leaves second finger steering")
 touch(left, 1, false, Vector2(60, 40))
 check(not Input.is_action_pressed("steer_left"), "Releasing second finger clears steering")
 touch(left, 1, true)
 touch(gas, 0, true)
 touch(left, 1, false)
 check(Input.is_action_pressed("accelerate") and not Input.is_action_pressed("steer_left"), "Reverse finger release keeps gas independently active")
 main.ui.show_pause()
 check(not Input.is_action_pressed("accelerate"), "Pausing releases held touch gas")
 var power = find_touch("power")
 touch(power, 2, true)
 check(not Input.is_action_pressed("power"), "Pause overlay prevents hidden touch power actions")
 touch(power, 2, false)
 touch(gas, 0, false)
 main.ui.resume()
 touch(left, 0, true)
 main.ui.show_home()
 await process_frame
 check(not Input.is_action_pressed("steer_left"), "Clearing the HUD releases held touch steering")
 release_actions()
 main.start_race(0)
 await process_frame
 gas = find_touch("accelerate")
 root.content_scale_size = Vector2i.ZERO
 for dimensions in [Vector2i(1280, 720), Vector2i(800, 600), Vector2i(600, 900)]:
  root.size = dimensions
  main.ui._resize_layout()
  await process_frame
  for point in [Vector2(43, 32), Vector2(78, 56)]:
   touch(gas, 0, true, point)
   check(Input.is_action_pressed("accelerate"), "Scaled %s viewport touch coordinates match visible target at %s" % [dimensions, point])
   touch(gas, 0, false, point)
 release_actions()
 joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1)
 check(Input.get_action_strength("accelerate") > 0.9, "Synthetic controller RT maps to throttle")
 joy_axis(JOY_AXIS_LEFT_X, -0.8)
 check(Input.get_axis("steer_left", "steer_right") < -0.5, "Synthetic controller left stick maps to steering")
 joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0)
 joy_axis(JOY_AXIS_LEFT_X, 0)
 check(not Input.is_action_pressed("accelerate") and not Input.is_action_pressed("steer_left"), "Controller neutral axes release actions")
 for binding in [[JOY_BUTTON_A, "jump"], [JOY_BUTTON_X, "power"], [JOY_BUTTON_RIGHT_SHOULDER, "boost"], [JOY_BUTTON_Y, "reset_kart"]]:
  joy_button(binding[0], true)
  check(Input.is_action_pressed(binding[1]), "Synthetic controller button maps to %s" % binding[1])
  joy_button(binding[0], false)
  check(not Input.is_action_pressed(binding[1]), "Controller button releases %s" % binding[1])
 joy_button(JOY_BUTTON_START, true)
 check(main.race.paused, "Synthetic controller Start pauses race")
 joy_button(JOY_BUTTON_START, false)
 joy_button(JOY_BUTTON_START, true)
 check(not main.race.paused, "Synthetic controller Start resumes race")
 joy_button(JOY_BUTTON_START, false)
 main.queue_free()
 release_actions()
 await process_frame
 print("BORACER INPUT DEVICES: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
