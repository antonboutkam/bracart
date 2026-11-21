extends SceneTree
const Kart = preload("res://scripts/kart.gd")
const Catalog = preload("res://scripts/catalog.gd")
var checks: int = 0
var failures: Array[String] = []

func check(condition: bool, title: String) -> void:
 checks += 1
 if not condition:
  failures.append(title)
  push_error(title)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 for index in Catalog.VEHICLES.size():
  for character in ["boaz", "ravi"]:
   var kart = Kart.new()
   root.add_child(kart)
   kart.setup(index, character, false)
   var label = Catalog.VEHICLES[index].id + "/" + character
   check(kart.wheel_nodes.size() >= 3, label + ": independent wheel pivots")
   check(kart.wheel_radii.all(func(radius): return radius > 0.05 and radius < 0.4), label + ": physical wheel radii")
   var body_bounds = kart._bounds(kart.visual.get_child(0), Transform3D.IDENTITY)
   check(absf(body_bounds.position.y) < 0.001 and absf(body_bounds.size.z - 1.95) < 0.001 and body_bounds.size.x < 1.1, label + ": tight bounds keep wheels grounded at common scale")
   check(kart.driver_seat.y > 0.2 and kart.driver_seat.y < 0.55, label + ": seat within cockpit")
   var skeleton = kart._find_skeleton(kart.driver_model)
   check(skeleton != null, label + ": driver has a skeleton")
   if skeleton:
    var hip = skeleton.find_bone("hips")
    check(hip >= 0, label + ": driver has a hip joint")
    if hip >= 0:
     var seat_hip = kart.driver_mount.to_local(skeleton.to_global(skeleton.get_bone_global_rest(hip).origin))
     check(absf(seat_hip.y) < 0.0001, label + ": actual exported hip joint anchored on cushion")
   check(kart.animation != null, label + ": character animation loaded")
   for state in ["sit", "steer", "jump", "finish"]:
    check(kart.animation.has_animation("racing/" + state), label + ": seated " + state + " clip")
   # Standing Jump/Cheer must preserve the actual seated leg pose throughout.
   var seated = kart.animation.get_animation("racing/sit")
   for state in ["jump", "finish"]:
    var clip = kart.animation.get_animation("racing/" + state)
    for track in clip.get_track_count():
     if not "thigh" in str(clip.track_get_path(track)):
      continue
     var source = seated.find_track(clip.track_get_path(track), clip.track_get_type(track))
     check(source >= 0, label + ": leg has matching seated track")
     if source >= 0:
      var expected = seated.track_get_key_value(source, 0)
      for key in clip.track_get_key_count(track):
       check(clip.track_get_key_value(track, key) == expected, label + ": legs stay seated during " + state)
   kart.speed = 20
   kart.steering = 1
   kart.update_effects(0.25)
   check(kart.driver_state == "steer", label + ": steering follows input")
   check(not kart.wheel_nodes[0].basis.is_equal_approx(kart.wheel_rest[0]), label + ": wheels turn at speed")
   check(kart.flame.visible and not kart.shield_mesh.visible and not kart.magnet_ring.visible, label + ": default active effects")
   kart.jump_height = 0.5
   kart.update_effects(0.1)
   check(kart.driver_state == "jump", label + ": jump reaction")
   kart.jump_height = 0
   kart.steering = 0
   kart.shield_time = 2
   kart.magnet_time = 2
   kart.cannon_time = 2
   kart.update_effects(0.25)
   check(kart.shield_mesh.visible and kart.magnet_ring.visible and kart.cannons[0].visible, label + ": equipment effects visible")
   var speed_before = kart.speed
   check(not kart.take_hit() and kart.shield_time == 0 and kart.speed == speed_before, label + ": shield absorbs impact")
   kart.update_effects(0)
   check(kart.shield_mesh.visible, label + ": absorbed impact flashes shield")
   kart.hit_cooldown = 0
   check(kart.take_hit() and kart.hit_reaction > 0 and kart.speed < speed_before, label + ": impact reaction and slowdown")
   kart.finish_time = 30
   kart.update_effects(0.1)
   check(kart.driver_state == "finish" and not kart.flame.visible, label + ": seated finish celebration")
   check(not kart.take_hit(), label + ": finished racer immune")
   kart.queue_free()
   await process_frame
 print("KART VISUAL CHECKS: %d; failures: %d" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
