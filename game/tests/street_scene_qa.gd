extends SceneTree
## Independent QA of actual built districts, full driving/camera path and Main tram lifecycle.
const Main = preload("res://scripts/main.gd")
const Track = preload("res://scripts/track.gd")
const CameraRig = preload("res://scripts/follow_camera.gd")
var checks = 0
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  if failures.size() < 12: push_error(label)
  failures.append(label)

func _initialize() -> void:
 call_deferred("run")

func contains_building(stamp: Dictionary, point: Vector3, margin: float) -> bool:
 var local: Vector3 = stamp.frame.affine_inverse() * point
 # Includes facade relief, steps and full foundation. Conservative roof box.
 return absf(local.x) < stamp.width / 2 + margin and local.z > -stamp.depth / 2 - 1.6 - margin and local.z < stamp.depth / 2 + margin and local.y > -80 and local.y < stamp.height + margin

func run() -> void:
 var camera = Camera3D.new()
 root.add_child(camera)
 var rig = CameraRig.new(camera)
 for world in [3,4]:
  var track = Track.new()
  root.add_child(track)
  track.build(world)
  var district = track.get_node("StreetDistricts")
  var stamps: Array = district.get_meta("buildings")
  check(stamps.size() > 30, "Actual district has substantial house population world%d" % world)
  var under_route = 0
  var closest_vertical_gap = INF
  for meter in range(0, ceili(track.length)):
   var d = float(meter)
   for lane in [-0.85,0.0,0.85]:
    var kart = {"progress":d,"lateral":track.width*lane,"speed":56.0,"jump_height":0.0,"boost_time":0.0}
    rig.reset()
    rig.update(track,kart,0,true,true)
    var road_point: Vector3 = track.position_at(d,track.width*lane,0.5)
    for stamp in stamps:
     if world == 3:
      check(not contains_building(stamp,road_point,0.8), "Haarlem driving corridor clear meter%d lane%.2f" % [meter,lane])
      check(not contains_building(stamp,camera.global_position,0.5), "Haarlem follow camera clear meter%d lane%.2f" % [meter,lane])
     else:
      var local: Vector3 = stamp.frame.affine_inverse()*road_point
      if absf(local.x) < stamp.width/2 and absf(local.z) < stamp.depth/2:
       under_route += 1
       var gap: float = local.y - stamp.height - 1.5
       closest_vertical_gap = minf(closest_vertical_gap,gap)
       check(gap >= 8.0, "Uithoorn roof stays eight meters below road underside meter%d" % meter)
  if world == 4:
   check(under_route > 0, "Some residential roofs are truly below elevated route")
   print("STREET QA elevated roof samples=",under_route," minimum_gap=",closest_vertical_gap)
  track.queue_free()
  await process_frame
 camera.queue_free()
 await process_frame
 var main = Main.new()
 root.add_child(main)
 await process_frame
 main.set_physics_process(false)
 main.audio.muted = true
 main.audio.music.stop()
 main.start_race(4)
 var tram = main.track.get_node("UithoornTram")
 check(tram.cars.size() == 3 and tram.can_process(), "Main creates a live three-car Uithoorn tram")
 var before: float = tram.distance
 await create_timer(0.08).timeout
 check(tram.distance != before, "Actual Main tram advances via scene processing")
 var pause_event = InputEventAction.new()
 pause_event.action = "pause"
 pause_event.pressed = true
 main._unhandled_input(pause_event)
 await process_frame
 before = tram.distance
 await create_timer(0.08).timeout
 check(tram.distance == before and not tram.can_process(), "Actual Main pause freezes inherited tram processing")
 main._unhandled_input(pause_event)
 await process_frame
 await create_timer(0.08).timeout
 check(tram.distance != before, "Actual Main resume restarts tram")
 var outside = weakref(tram)
 main.start_race(3)
 await process_frame
 check(outside.get_ref() == null, "Switching to Haarlem frees tram and infrastructure")
 check(main.track.find_children("UithoornTram","Node3D",true,false).is_empty(), "Haarlem receives no Uithoorn tram")
 main.go_home()
 main.queue_free()
 await process_frame
 print("BORACER STREET SCENE QA: %d checks, %d failures" % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
