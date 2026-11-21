extends SceneTree
const Track=preload("res://scripts/track.gd")
const Race=preload("res://scripts/race.gd")
var checks:=0
var failures:=0
var landings:=0
func check(ok:bool,label:String):
 checks+=1
 if not ok: failures+=1;push_error(label)
func _initialize(): call_deferred("run")
func run():
 var track=Track.new()
 root.add_child(track)
 track.build(11)
 var race=Race.new()
 root.add_child(race)
 race.setup(track,3,"boaz",0)
 race.countdown=0
 race.feedback.connect(func(kind,_at,_intensity,_surface):
  if kind=="landing": landings+=1)
 var kart=race.player
 var course=track.v2_course
 for feature in course.features:
  if not feature.has("lip"): continue
  var span:float=feature.landing-feature.lip
  check(course.flight_state(feature.lip).is_empty() and course.flight_state(feature.landing).is_empty(),"Takeoff and contact have zero additional height")
  var start:Dictionary=course.flight_state(feature.lip+.001)
  var end:Dictionary=course.flight_state(feature.landing-.001)
  check(start.height<.000001 and end.height<.000001 and absf(start.slope)<.0001 and absf(end.slope)<.0001,"C1 lift and zero slope at both physical gap ends")
  for speed in [5.0,12.0,40.0,46.0,66.0]:
   kart.progress=feature.lip-.03
   kart.speed=speed
   kart.jump_height=0
   kart.jump_velocity=0
   kart.lateral=0
   kart.stun_time=0
   kart.boost_time=100 if speed>46 else 0
   var throttle:float=speed/(46*1.45 if speed>46 else 46)
   var landing_before=landings
   var max_height=0.0
   var max_contact_drop=0.0
   var ticks=0
   while kart.progress<feature.landing+.05 and ticks<4000:
    var before:float=kart.progress
    var before_height:float=kart.jump_height
    race.elapsed+=1.0/120
    race._step_kart(kart,0,1.0/120,throttle,0,0,false)
    if course.is_gap(kart.progress):
     check(kart.jump_height>0,"Actual racer stays airborne throughout unsupported gap at low, normal and boost speed")
     check(landings==landing_before,"No landing feedback in unsupported space")
     max_height=maxf(max_height,kart.jump_height)
    if before<feature.landing and kart.progress>=feature.landing: max_contact_drop=before_height
    ticks+=1
   check(ticks<4000 and kart.jump_height==0 and absf(kart.jump_velocity)<.0001,"Every speed contacts physical landing")
   check(landings==landing_before+1,"One landing event only on supported contact")
   check(max_height>(1.99 if feature.id=="mega_jump" else .59),"Real air arc retains the same peak across all vehicle speeds")
   check(max_contact_drop<.005,"Landing height approaches zero continuously without a visual snap")
 print("BORACER TRACKS V2 FLIGHT: %d checks, %d failures"%[checks,failures])
 race.queue_free()
 track.queue_free()
 await process_frame
 quit(0 if failures==0 else 1)
