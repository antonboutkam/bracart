extends SceneTree
const Track = preload("res://scripts/track.gd")
var failures: Array[String] = []
var checks = 0
func check(ok: bool, title: String) -> void:
 checks += 1
 if not ok:
  failures.append(title)
  push_error(title)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var route_signatures: Array[String] = []
 for world in 6:
  var track = Track.new()
  root.add_child(track)
  track.build(world)
  check(track.length > 450, "world %d substantial circuit" % world)
  check(track.width >= 7, "world %d racers have room" % world)
  check(track.position_at(0).distance_to(track.position_at(track.length)) < 0.001,"world %d closed position" % world)
  check(track.frame(0).basis.z.dot(track.frame(track.length - 0.01).basis.z) > 0.999,"world %d smooth seam" % world)
  var count = 220
  var min_clearance = INF
  var max_gradient = 0.0
  var min_radius = INF
  var min_lane_forward = INF
  var signature = ""
  for i in count:
   var d: float = track.length * i / count
   var f: Transform3D = track.frame(d)
   check(f.basis.determinant() > 0.99 and f.basis.is_finite(), "world %d finite orthonormal frame %d" % [world,i])
   var f_next: Transform3D = track.frame(d + 1)
   var angle: float = acos(clampf(f.basis.z.dot(f_next.basis.z),-1,1))
   if angle > 0.00001: min_radius = minf(min_radius, 1.0 / angle)
   max_gradient = maxf(max_gradient,absf(f.basis.z.y))
   if i % 44 == 0: signature += str(f.origin.snapped(Vector3.ONE))
   if world == 5:
    check(f.origin.y >= 0.1 and f.origin.y <= 25,"kitchen supported feature height %d" % i)
    for side in [-1,1]:
     var lane: float = side*(track.width-0.65)
     var tangent: Vector3 = (track.position_at(d+0.1,lane)-track.position_at(d,lane))/0.1
     min_lane_forward = minf(min_lane_forward,tangent.dot(-f.basis.z))
    check(absf(f.origin.x) + track.width < 116 and absf(f.origin.z) + track.width < 101,"table margins %d" % i)
   for j in range(i + 1,count):
    var arc: float = track.length * mini(j - i, count - (j - i)) / count
    if arc < 60: continue
    var other: Vector3 = track.position_at(track.length * j / count)
    var horizontal = Vector2(f.origin.x - other.x,f.origin.z - other.z).length()
    min_clearance = minf(min_clearance,f.origin.distance_to(other) if world == 5 else horizontal)
  check(min_clearance > track.width * 2 + 3,"world %d no overlapping road ribbons (%.1f)" % [world,min_clearance])
  check(max_gradient > 0.9 if world == 5 else max_gradient < 0.6,"world %d appropriate climb/inversion (%.2f)" % [world,max_gradient])
  check(min_lane_forward > 0.05 if world == 5 else min_radius > track.width * 1.25,"world %d drivable inner lanes do not fold" % world)
  check(signature not in route_signatures,"world %d unique route" % world)
  route_signatures.append(signature)
  check(not track.section_name(0).is_empty(),"world %d named sectors" % world)
  if world == 5:
   # Photo-informed props cluster related items into eleven safe placements.
   var props = track.get_node_or_null("KitchenProps")
   var ids: Array = []
   if props != null:
    for item in props.get_meta("objects",[]): ids.append(item.id)
   for id in ["monitor","megaphone","can","remote","power","esp","scissors","paper","adapter","cloth","globe"]:
    check(ids.count(id) == 1,"kitchen retains photo-reference group " + id)
   for component in ["monitor/Photo_monitor_screen","monitor/Photo_keyboard_top","monitor/Mouse","paper/BlisterPack","power/RoundCable"]:
    check(props != null and props.has_node(component),"kitchen grouped placement retains " + component)
  for site in track.get_meta("scenic_sites",[]):
   var p: Vector3 = site.position
   for i in count:
    var q: Vector3 = track.position_at(track.length * i / count)
    check(Vector2(p.x-q.x,p.z-q.z).length() > track.width + site.radius + 2.5,"world %d scenery keeps corridor clear" % world)
  var before_nodes: int = track.get_child_count()
  for i in 120: track._process(1.0 / 60)
  check(track.get_child_count() == before_nodes,"world %d ambient motion reuses nodes" % world)
  for motion in track.ambient_motions:
   check(motion.node.position.is_finite() and motion.node.position.distance_to(motion.base) <= motion.amount + 0.01,"world %d ambient motion stays bounded" % world)
  print("WORLD %d length=%.1f min_clearance=%.1f max_gradient=%.2f min_bend_radius=%.1f" % [world,track.length,min_clearance,max_gradient,min_radius])
  track.queue_free()
  await process_frame
 print("WORLD GEOMETRY: %d checks, %d failures" % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
