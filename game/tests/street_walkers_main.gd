extends SceneTree
## Actual Main pause/resume and world switch, independently of primitive-only test.
const Main = preload("res://scripts/main.gd")
var checks := 0
var failures := 0
func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(label)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var main := Main.new()
 root.add_child(main)
 await process_frame
 main.audio.muted = true
 main.audio.music.stop()
 main.audio.music.stream = null
 main.set_physics_process(false)
 main.start_race(0)
 await create_timer(0.08).timeout
 var walkers: Node = main.track.get_node_or_null("StreetWalkers")
 check(walkers != null and walkers.actors.size() >= 2,"Actual Main outside world contains at least two supported walking groups")
 if walkers == null:
  main.queue_free()
  await process_frame
  print("BORACER STREET WALKERS MAIN: %d checks, %d failures" % [checks,failures])
  quit(1)
  return
 var elapsed: float = walkers.elapsed
 await create_timer(0.08).timeout
 check(walkers.elapsed > elapsed,"Actual race world advances pedestrian routes")
 main.ui.show_pause()
 await process_frame
 var paused: float = walkers.elapsed
 var old_pose: Transform3D = walkers.actors[0].rig.transform
 await create_timer(0.15).timeout
 check(walkers.elapsed == paused and walkers.actors[0].rig.transform == old_pose and not walkers.can_process(),"Main pause freezes actual pedestrian clock and articulated route pose")
 main.ui.resume()
 await create_timer(0.08).timeout
 check(walkers.elapsed > paused and walkers.elapsed-paused < 0.2,"Main resume advances live delta without paused-time catchup")
 var old: WeakRef = weakref(walkers)
 main.start_race(5)
 await process_frame
 check(old.get_ref() == null,"Main world switch destroys prior pedestrian controller")
 check(not main.track.has_node("StreetWalkers") and not main.track.has_node("OutdoorLife"),"Kitchen remains free of all outdoor pedestrian content")
 main.go_home()
 main.queue_free()
 await process_frame
 print("BORACER STREET WALKERS MAIN: %d checks, %d failures" % [checks,failures])
 quit(0 if failures == 0 else 1)
