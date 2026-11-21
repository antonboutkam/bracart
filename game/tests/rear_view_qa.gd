extends SceneTree
## Independent behavioral QA: real input events, camera direction and lifecycle.
const Main = preload("res://scripts/main.gd")
const Profile = preload("res://scripts/profile.gd")
const Kart = preload("res://scripts/kart.gd")
var main
var checks := 0
var failures: Array[String] = []
func _initialize(): call_deferred("run")
func check(value: bool, description: String):
 checks += 1
 if not value:
  failures.append(description)
  push_error(description)
func key(pressed: bool, code: int = KEY_C):
 var event := InputEventKey.new()
 event.physical_keycode = code
 event.pressed = pressed
 Input.parse_input_event(event)
 Input.flush_buffered_events()
func joy(pressed: bool):
 var event := InputEventJoypadButton.new()
 event.device = 0
 event.button_index = JOY_BUTTON_LEFT_SHOULDER
 event.pressed = pressed
 Input.parse_input_event(event)
 Input.flush_buffered_events()
func rear_active() -> bool:
 return root.get_camera_3d() != main.camera
func refresh(): main._camera(1.0/60)
func run():
 main = Main.new()
 root.add_child(main)
 await process_frame
 main.set_process(false)
 main.set_physics_process(false)
 main.audio.muted = true
 main.audio.music.stop()
 main.profile = Profile.new("user://rear-view-independent-qa.json")
 main.start_race(6)
 await process_frame
 main.race.countdown = 0
 check(not rear_active(), "Starts in forward main camera")
 key(true)
 refresh()
 check(rear_active(), "Actual C key event selects rear main camera")
 check(main.rear_view.viewport.world_3d == main.camera.get_world_3d(), "Inset shares the actual forward race world")
 check(main.rear_view.panel.visible and main.rear_view.viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "Active inset is visible and rendering")
 key(true, KEY_W)
 check(Input.is_action_pressed("accelerate"), "Rear look permits simultaneous gas key")
 key(false, KEY_W)
 var rear_camera: Camera3D = root.get_camera_3d()
 var course = main.track.active_course()
 for feature in course.features:
  if not feature.id in ["loop", "corkscrew"]: continue
  for i in 100:
   main.race.player.progress = lerpf(feature.start,feature.end,i/99.0)
   main._camera(1.0/60,true)
   var frame: Transform3D = main.track.frame(main.race.player.progress)
   check(rear_camera.position.is_finite() and rear_camera.basis.is_finite(), "Rear camera finite on actual inverted course")
   check(absf(rear_camera.basis.determinant()-1)<0.001, "Rear camera remains right handed through stunt")
   check(rear_camera.basis.y.dot(frame.basis.y)>0.5, "Rear camera follows stunt local up")
   check((-rear_camera.basis.z).dot(frame.basis.z)>0.5, "Rear camera looks along actual backward course direction")
   check(main.rear_view.inset_camera.global_transform.is_equal_approx(main.camera.global_transform), "Inset follows current forward camera through stunt")
 key(false)
 refresh()
 check(not rear_active(), "Actual C release immediately returns forward camera")
 check(not main.rear_view.panel.visible and main.rear_view.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "Released inset is hidden and stops rendering")
 joy(true)
 refresh()
 check(rear_active(), "Actual joypad LB event selects rear camera")
 joy(false)
 refresh()
 check(not rear_active(), "Actual joypad LB release restores forward")
 key(true)
 refresh()
 main.ui.show_pause()
 refresh()
 check(not rear_active(), "Pause cancels held rear camera")
 main.ui.resume()
 refresh()
 check(not rear_active(), "Resuming while still held requires release before rear look")
 main.ui.show_pause()
 key(false)
 main.ui.resume()
 refresh()
 check(not rear_active(), "Release during pause remains forward on resume")
 key(true)
 refresh()
 main._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 refresh()
 check(main.race.paused and not rear_active(), "Focus loss pauses and clears held rear look")
 key(false)
 main.ui.resume()
 joy(true)
 refresh()
 Input.joy_connection_changed.emit(0,false)
 refresh()
 check(not rear_active(), "Controller disconnect clears held rear look")
 joy(false)
 key(true)
 refresh()
 main.race.done = true
 main.ui.show_results()
 refresh()
 check(not rear_active(), "Finish/results clears rear camera")
 key(false)
 main.start_race(0)
 key(true)
 refresh()
 main.go_home()
 check(not rear_active(), "Home teardown restores forward main camera")
 key(false)
 main.start_race(0)
 check(not rear_active(), "New race starts without inherited rear state")
 key(true)
 refresh()
 main.start_race(0)
 refresh()
 check(not rear_active(), "Restart while held requires a fresh rear press")
 key(false)
 refresh()
 key(true)
 refresh()
 check(rear_active(), "Fresh rear press works after restart")
 key(false)
 refresh()
 for vehicle in 6:
  var kart = Kart.new()
  main.add_child(kart)
  kart.setup(vehicle,"boaz",false)
  var left = kart.visual.get_node("SideMirrors/LeftMirror/Glass")
  var right = kart.visual.get_node("SideMirrors/RightMirror/Glass")
  check(left is MeshInstance3D and right is MeshInstance3D, "Both physical mirror glass meshes vehicle %d" % vehicle)
  check(left.position.x < -0.5 and right.position.x > 0.5, "Mirror pair physically straddles vehicle %d" % vehicle)
  check(left.visible and right.visible and left.mesh.get_faces().size()>0 and right.mesh.get_faces().size()>0, "Actual visible mirror geometry vehicle %d" % vehicle)
  kart.queue_free()
 var inset_ref = main.rear_view.viewport
 main.queue_free()
 Input.action_release("rear_look")
 await process_frame
 check(not is_instance_valid(inset_ref), "Whole-scene teardown frees extra viewport")
 print("BORACER REAR VIEW INDEPENDENT QA: %d checks, %d failures" % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
