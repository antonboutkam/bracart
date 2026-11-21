extends SceneTree
const Podium = preload("res://scripts/ui/victory_podium.gd")
const Interface = preload("res://scripts/interface.gd")
const Race = preload("res://scripts/race.gd")
const Profile = preload("res://scripts/profile.gd")
const Catalog = preload("res://scripts/catalog.gd")
class SilentAudio extends RefCounted:
 func cue(_kind): pass
class Host extends Node:
 var audio = SilentAudio.new()
 var race
 var profile
 var track_index := 11
 var last_save_error := ""
 func start_race(_index): pass
 func go_home(): pass
var checks := 0
var failures: Array[String] = []
func check(value: bool, description: String):
 checks += 1
 if not value: failures.append(description)
func _initialize(): call_deferred("run")
func run():
 var race := Race.new()
 root.add_child(race)
 race.set_process(false)
 race.rank = 1
 race.done = true
 race.reward = 54
 race.elapsed = 87.25
 race.collected = 4
 race.lap_times.assign([28.0,30.0,29.25])
 race.player = {"driver":"boaz","vehicle_index":0,"finish_time":87.25,"racer_name":"Boaz","progress":100.0}
 race.racers = [race.player,{"driver":"ravi","vehicle_index":2,"finish_time":-1.0,"racer_name":"Ravi","progress":90.0},{"driver":"boaz","vehicle_index":3,"finish_time":-1.0,"racer_name":"Racer","progress":80.0}]
 var host := Host.new()
 root.add_child(host)
 host.race = race
 host.profile = Profile.new("user://podium-profile.json")
 var ui := Interface.new()
 host.add_child(ui)
 ui.game = host
 ui.hud = Control.new()
 ui.add_child(ui.hud)
 ui.overlay = Control.new()
 ui.add_child(ui.overlay)
 for character in ["boaz","ravi"]:
  race.player.driver = character
  for vehicle in 6:
   race.player.vehicle_index = vehicle
   var podium := Podium.new()
   ui.overlay.add_child(podium)
   podium.setup(race)
   podium.set_process(false)
   check(podium.animation.current_animation == "Cheer" and not podium.animation.has_animation("racing/finish"),"Original standing Cheer without seated animation library")
   check(podium.vehicles[0].vehicle_index == vehicle and podium.vehicles.size() >= 2,"Actual selected vehicle and multiple actual race vehicles")
   check(podium.mouse_filter == Control.MOUSE_FILTER_IGNORE and podium.viewport.own_world_3d,"Isolated noninteractive viewport")
   check(not podium.sole_vertices.is_empty(),"Skinned sole samples exist")
   var arm: int = podium.skeleton.find_bone("upper_arm.L")
   var before: Transform3D = podium.skeleton.get_bone_global_pose(arm)
   for frame in 17:
    podium.advance(0.05)
    check(absf(podium.winner.position.y+podium.sole_height-Podium.PODIUM_TOP) < 0.0001,"Skinned shoes contact platform throughout clip")
    for side in ["L","R"]:
     var hip: Vector3 = podium.skeleton.get_bone_global_pose(podium.skeleton.find_bone("thigh."+side)).origin
     var foot: Vector3 = podium.skeleton.get_bone_global_pose(podium.skeleton.find_bone("foot."+side)).origin
     check(hip.y-foot.y > 0.28,"Legs remain standing rather than folded on kart")
   check(not before.is_equal_approx(podium.skeleton.get_bone_global_pose(arm)),"Actual arm bone pose changes over time")
   podium.hide()
   var age: float = podium.age
   podium.advance(1)
   check(podium.age == age and podium.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED,"Hidden animation and rendering suspend")
   podium.show()
   podium.setup(race)
   check(podium.get_child_count()==1,"Repeated setup cannot leak viewport")
   var old: WeakRef = weakref(podium.viewport)
   ui.clear(ui.overlay)
   await process_frame
   check(old.get_ref()==null,"Overlay removal releases world and models")
 race.rank = 2
 var negative := Podium.new()
 ui.overlay.add_child(negative)
 negative.setup(race)
 check(negative.viewport==null,"Nonwinner setup rejects scene")
 ui.show_results()
 check(ui.overlay.find_child("VictoryPodium",true,false)==null,"Rank2 actual results has no celebration")
 race.rank = 1
 race.player.driver = "ravi"
 host.profile.storage_path = "user://missing-podium-folder/profile.json"
 var before_coins: int = host.profile.coins
 check(not race.claim_reward(host.profile,11),"Failed save leaves payout pending")
 ui.show_results()
 var pending = ui.overlay.find_child("VictoryPodium",true,false)
 var old_view: WeakRef = weakref(pending.viewport)
 var retry: Button
 for node in ui.overlay.find_children("*","Button",true,false):
  if node.text=="Opnieuw opslaan": retry=node
 check(retry!=null,"Failed-save results retain retry action")
 host.profile.storage_path = "user://podium-profile.json"
 retry.pressed.emit()
 await process_frame
 check(old_view.get_ref()==null,"Retry rebuild destroys previous celebration")
 check(race.payout_claimed and host.profile.coins==before_coins+race.reward,"Retry commits reward exactly once")
 var saved: int = host.profile.coins
 ui.show_results()
 check(host.profile.coins==saved and not race.claim_reward(host.profile,11) and host.profile.coins==saved,"Rebuild and repeated claim cannot duplicate reward")
 check(ui.overlay.find_children("VictoryPodium","",true,false).size()==1,"Exactly one current podium after retries")
 var focus: Control = root.gui_get_focus_owner()
 check(focus is Button and focus.text=="Nog een race","Navigation receives focus immediately")
 var current = ui.overlay.find_child("VictoryPodium",true,false)
 var final_view: WeakRef = weakref(current.viewport)
 ui.clear(ui.overlay)
 await process_frame
 check(final_view.get_ref()==null,"Menu/restart overlay clear releases celebration")
 host.free()
 race.free()
 print("VICTORY_PODIUM: %d checks; %d failures" % [checks,failures.size()])
 for failure in failures: push_error(failure)
 quit(0 if failures.is_empty() else 1)
