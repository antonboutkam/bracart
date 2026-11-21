extends SceneTree
const Track = preload("res://scripts/track.gd")
var checks = 0
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
 checks+=1
 if not value:
  failures.append(label)
  push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 for world in [3,4]:
  var track = Track.new()
  root.add_child(track)
  track.build(world)
  var district = track.get_node("StreetDistricts")
  var stamps: Array = district.get_meta("buildings")
  check(stamps.size()>95 if world==3 else stamps.size()>45,"world has dense street housing")
  check(district.get_child_count()<65,"global instancing bounds draw nodes")
  var geometry_top = -INF
  var instances = 0
  for node in district.get_children():
   if node is Label3D: continue
   check(node is MultiMeshInstance3D,"district is shared instanced geometry")
   instances += node.multimesh.instance_count
   var bounds: AABB = node.multimesh.get_aabb()
   geometry_top = maxf(geometry_top,bounds.end.y)
   check(node.multimesh.mesh.surface_get_material(0).cull_mode==BaseMaterial3D.CULL_BACK,"normal culling preserved")
  var beneath = 0
  var min_gap = INF
  var min_margin = INF
  var variants = {}
  for stamp in stamps:
   variants[stamp.variant] = true
   var inverse: Transform3D = stamp.frame.affine_inverse()
   var crosses = false
   for i in int(ceil(track.length/0.8)):
    var q: Vector3 = track.position_at(i*0.8)
    var local: Vector3 = inverse*q
    var dx = maxf(absf(local.x)-stamp.width/2-0.1,0)
    # Includes front pavement and stoops, back eaves and side overhang.
    var lo = -stamp.depth/2-(1.7 if world==3 else 10)
    var hi = stamp.depth/2+0.3
    var dz = maxf(maxf(lo-local.z,local.z-hi),0)
    var dist = Vector2(dx,dz).length()
    if world==3 or track.ground_course != null:
     min_margin = minf(min_margin,dist-track.width)
     check(dist>=track.width+3.0,"entire street building/stoop footprint clear incl bends")
    elif dist<track.width:
     crosses = true
     var gap: float = q.y-2.0-(stamp.frame.origin.y+stamp.height)
     min_gap = minf(min_gap,gap)
     check(gap>=8,"full dwelling envelope eight metres under road underside")
   if crosses: beneath+=1
  if world==3:
   check(variants.size()==3,"stepped list and pointed gables all present")
  else:
   check(beneath==0,"ground route does not pass through homes")
   check(min_margin>=3,"ground route keeps houses and gardens clear")
   check(track.has_node("UithoornTram"),"tram hook integrated")
  print("DISTRICT world=",world," houses=",stamps.size()," draw_nodes=",district.get_child_count()," instances=",instances," under_route=",beneath," min_vertical_gap=",min_gap," min_horizontal_margin=",min_margin)
  track.queue_free()
  await process_frame
 print("STREET_DISTRICTS checks=",checks," failures=",failures.size())
 quit(0 if failures.is_empty() else 1)
