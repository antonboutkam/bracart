extends SceneTree
const Track = preload("res://scripts/track.gd")
const Race = preload("res://scripts/race.gd")
const Kart = preload("res://scripts/kart.gd")
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 for character in ["boaz", "ravi"]:
  var kart = Kart.new()
  root.add_child(kart)
  kart.setup(5, character, false)
  kart.update_effects(0)
  var rig: Skeleton3D = kart.reactions.skeleton
  var hip := rig.find_bone("hips")
  var hip_start := rig.get_bone_global_pose(hip)
  var hand := rig.find_bone("hand.L")
  var hand_start := rig.get_bone_global_pose(hand)
  check(rig.get_bone_count() == 51, character+" rig")
  check(kart.reactions.wink_index >= 0, character+" wink")
  kart.react_to_shot()
  for frame in 27: kart.update_effects(1.0/60)
  check(kart.reactions.turn_weight > 0.99, character+" turn peak")
  check(kart.reactions.wink_weight > 0.99, character+" wink peak")
  check(rig.get_bone_global_pose(hip).is_equal_approx(hip_start), character+" fixed hips")
  check(rig.get_bone_global_pose(hand).origin.distance_to(hand_start.origin)<0.005, character+" fixed hand")
  var wink_pose := rig.get_bone_global_pose(rig.find_bone("head"))
  for frame in 10: await process_frame
  check(rig.get_bone_global_pose(rig.find_bone("head")).is_equal_approx(wink_pose), character+" paused manual animation")
  kart.boost_time = 2
  for frame in 90:
   if frame % 18 == 0: kart.react_to_shot()
   kart.update_effects(1.0/60)
   check(rig.get_bone_global_pose(hip).is_equal_approx(hip_start), character+" repeated overlap hips")
   check(rig.get_bone_global_pose(hand).origin.distance_to(hand_start.origin)<0.005, character+" repeated overlap hands")
  check(kart.reactions.boost_weight > 0.99, character+" boost peak")
  kart.boost_time = 0
  for frame in 150: kart.update_effects(1.0/60)
  check(kart.reactions.turn_weight == 0 and kart.reactions.wink_weight == 0 and kart.reactions.boost_weight == 0, character+" returned")
  kart.react_to_shot()
  kart.finish_time = 2
  kart.update_effects(0.1)
  check(kart.reactions.turn_weight == 0 and kart.reactions.wink_weight == 0, character+" finish priority")
  kart.queue_free()
  await process_frame
 var track = Track.new()
 root.add_child(track)
 track.build(0)
 var race = Race.new()
 root.add_child(race)
 race.setup(track,5,"boaz",0)
 race.countdown = -1
 for kart in [race.player, race.racers[1]]:
  kart.cannon_time=7
  race.use_power(kart)
  check(kart.reactions.shot_age==0,"real player/AI fire hook")
  kart.update_effects(0.2)
  var age: float = kart.reactions.shot_age
  var count: int = race.projectiles.size()
  race.use_power(kart)
  check(race.projectiles.size()==count and kart.reactions.shot_age==age,"cooldown rejects without restart")
 race.paused=true
 var age: float = race.player.reactions.shot_age
 var pose: Transform3D = race.player.reactions.skeleton.get_bone_global_pose(5)
 race.step(0.5,1,0,0,true)
 for frame in 4: await process_frame
 check(race.player.reactions.shot_age==age and race.player.reactions.skeleton.get_bone_global_pose(5).is_equal_approx(pose),"real race pause freezes pose")
 race.paused=false
 race.player.cannon_time=0
 race.player.power="Boost"
 race.use_power()
 race.step(0.25,1,0,0,false)
 check(race.player.reactions.boost_weight>0.99,"real Boost power reaction")
 race.player.boost_time=0
 race.step(0.25,1,0,0,true)
 check(race.player.reactions.boost_weight>0.99,"real held turbo reaction")
 var weak = weakref(race.player)
 race.queue_free()
 track.queue_free()
 await process_frame
 check(weak.get_ref()==null,"race cleanup frees reaction owner")
 print("DRIVER REACTION CHECKS=",checks," failures=",failures)
 quit(0 if failures==0 else 1)
