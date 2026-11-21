extends SceneTree
## Independent additive-route snapshots, full inversion and actual six-vehicle races.
const Track = preload("res://scripts/track.gd")
const Routes = preload("res://scripts/worlds/routes.gd")
const Race = preload("res://scripts/race.gd")
const Catalog = preload("res://scripts/catalog.gd")
var checks = 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
 checks += 1
 if not value:
  failures.append(label)
  if failures.size() <= 15: push_error(label)
func vector(v: Vector3) -> Array: return [v.x,v.y,v.z]
func signature(track,world: int) -> String:
 var data = {"length":track.length,"points":[],"frames":[],"road_edges":[]}
 for point in Routes.points(world): data.points.append(vector(point))
 for sample in 241:
  var d: float = track.length*sample/240.0
  var frame: Transform3D = track.frame(d)
  data.frames.append([vector(frame.origin),vector(frame.basis.x),vector(frame.basis.y),vector(frame.basis.z)])
  data.road_edges.append([vector(track.position_at(d,-track.width)),vector(track.position_at(d,track.width))])
 return JSON.stringify(data).sha256_text()
func run() -> void:
 var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://validation/kitchen-adventure-outdoor-baseline.json"))
 for world in 5:
  var outside = Track.new()
  root.add_child(outside)
  outside.build(world)
  check(signature(outside,world) == baseline[str(world)].sha256,"Outside route%d points,241frames and both road edges retain their exact pre-delta hash" % world)
  outside.queue_free()
  await process_frame
 var track = Track.new()
 root.add_child(track)
 track.build(5)
 var features: Array = track.kitchen_features()
 var ids: Array = []
 var by_id = {}
 for feature in features:
  ids.append(feature.id)
  by_id[feature.id] = feature
 for id in ["toilet_rolls","loose_cables","orange_loop","pvc_rainbow","comic_ramp","card_ramp"]:
  check(ids.count(id) == 1,"Actual course contains exactly one feature "+id)
 var inverted = 0
 var steep = 0
 for sample in ceili(track.length/0.2)+1:
  var d: float = sample*0.2
  var frame: Transform3D = track.frame(d)
  var next: Transform3D = track.frame(d+0.05)
  check(frame.is_finite() and absf(frame.basis.determinant()-1)<0.0001,"Every sampled course frame is finite and right-handed")
  for axis in [frame.basis.x,frame.basis.y,frame.basis.z]: check(absf(axis.length()-1)<0.0001,"Frame axes remain unit length through vertical and inverted sections")
  check(absf(frame.basis.x.dot(frame.basis.y))<0.0001 and absf(frame.basis.x.dot(frame.basis.z))<0.0001 and absf(frame.basis.y.dot(frame.basis.z))<0.0001,"All frame axes stay mutually perpendicular")
  check(frame.basis.x.dot(next.basis.x)>0.98 and frame.basis.y.dot(next.basis.y)>0.98 and frame.basis.z.dot(next.basis.z)>0.98,"No sudden roll/heading flip over a five-centimetre course step")
  var tangent: Vector3 = (track.position_at(d+0.01)-track.position_at(d-0.01)).normalized()
  check(tangent.dot(-frame.basis.z)>0.997,"Frame forward follows actual positional derivative, including inversion")
  check(frame.origin.distance_to(next.origin)<0.055,"Arc-length route has no positional teleport or collapsed seam")
  if frame.basis.y.y < -0.8: inverted += 1
  if absf(frame.basis.z.y)>0.75: steep += 1
 check(inverted>20 and steep>20,"The route actually turns upside-down and reaches steep vertical-loop approaches")
 var loop: Dictionary = by_id.orange_loop
 var reference: Vector3 = -track.frame(loop.start).basis.z
 var last = 0.0
 var turn = 0.0
 for sample in 501:
  var up: Vector3 = track.frame(lerpf(loop.start,loop.end,sample/500.0)).basis.y
  var angle = atan2(up.dot(reference),up.dot(Vector3.UP))
  if sample>0: turn += wrapf(angle-last,-PI,PI)
  last = angle
 check(absf(absf(turn)-TAU)<0.15,"Actual frame-up completes a full continuous360-degree loop rather than a decorative arch")
 for id in ["comic_ramp","card_ramp"]:
  var feature: Dictionary = by_id[id]
  check(track.frame(feature.lip).origin.y-track.frame(feature.start).origin.y>1.5,"Ramp has a real traversable elevation gain")
  check(absf(track.frame(feature.landing).origin.y-0.12)<0.05,"Ramp guide rejoins tabletop at its actual landing")
  for point in [feature.start,feature.lip,feature.landing]:
   check(track.frame(point-0.01).origin.distance_to(track.frame(point+0.01).origin)<0.03,"Ramp entry/lip/landing position stays continuous")
 for vehicle in Catalog.available_indices():
  var race = Race.new()
  root.add_child(race)
  race.setup(track,vehicle,"boaz" if vehicle%2==0 else "ravi",2)
  race.set_process(false)
  race.countdown = -1
  race.auto_drive = true
  for pickup in race.pickups:
   var height = 1.1 if pickup.kind=="coin" else 1.2
   check(pickup.node.position.is_equal_approx(track.position_at(pickup.distance,pickup.lane,height)),"Actual pickup starts at the banked/inverted course offset")
  var saw_inverted = [false,false,false,false,false]
  var previous: Array[float] = []
  for kart in race.racers: previous.append(kart.progress)
  for tick in 5400:
   race.step(1.0/30,1,0,0,true)
   for index in race.racers.size():
    var kart = race.racers[index]
    check(kart.transform.is_finite() and absf(kart.basis.determinant()-1)<0.001,"Actual player/AI kart keeps a finite orthonormal pose")
    check(kart.progress>=previous[index] and is_finite(kart.speed) and kart.speed>=0,"Actual player/AI keeps progressing without invalid velocity")
    check(kart.position.distance_to(track.position_at(kart.progress,kart.lateral,kart.jump_height+0.04))<0.001,"Actual player/AI stays attached to the complete guided course")
    if kart.basis.y.y < -0.7: saw_inverted[index] = true
    previous[index] = kart.progress
   if race.done: break
  check(race.done and race.player.finish_time>0,"Vehicle%d completes an actual three-lap race" % vehicle)
  check(race.collected>0,"Vehicle%d still collects actual pickups on the new course" % vehicle)
  for index in race.racers.size():
   check(race.racers[index].progress>=track.length and saw_inverted[index],"Vehicle%d racer%d traverses a full lap and actually inverts" % [vehicle,index])
  print("KITCHEN COURSE QA vehicle=",vehicle," finish=",race.player.finish_time," collected=",race.collected," inverted=",saw_inverted)
  race.queue_free()
  await process_frame
 track.queue_free()
 await process_frame
 print("BORACER KITCHEN COURSE INDEPENDENT QA: %d checks, %d failures" % [checks,failures.size()])
 quit(1 if failures.size() else 0)
