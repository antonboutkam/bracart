extends SceneTree
const Track = preload("res://scripts/track.gd")
const Models = preload("res://scripts/worlds/haarlem_landmarks.gd")
const Scenery = preload("res://scripts/worlds/scenery.gd")
class RefusedTrack extends "res://scripts/track.gd":
 func position_at(_d: float, _lateral: float = 0, _lift: float = 0) -> Vector3: return Vector3.ZERO

var checks := 0
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures.append(label)
  push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 for world in 6:
  var track = Track.new()
  root.add_child(track)
  track.build(world)
  var models: Array = []
  for child in track.get_children():
   if child.has_meta("haarlem_landmark"): models.append(child)
  check(models.size()==(2 if world==3 else 0),"exactly two physical landmarks only in Haarlem")
  var replaced: Array = track.get_meta("haarlem_landmark_sections",[])
  var count: int = load("res://scripts/worlds/routes.gd").SECTIONS[world].size()
  for section in count:
   check(track.has_node("RouteSign_%d" % section)==(section not in replaced),"signs match actual successful model placements")
  for model in models:
   var bounds: AABB = model.get_meta("bounds")
   var site: Dictionary = {}
   for reserved in track.get_meta("scenic_sites",[]):
    if reserved.position.is_equal_approx(model.position): site = reserved
   check(not site.is_empty(),"physical model reserves scenery site before districts/life")
   var stamps: Array = track.get_node("StreetDistricts").get_meta("buildings",[])
   for house in stamps:
    var local: Vector3 = house.frame.affine_inverse()*model.position
    var dx = maxf(absf(local.x)-house.width/2,0)
    var dz = maxf(absf(local.z)-house.depth/2-1.7,0)
    check(Vector2(dx,dz).length() > Vector2(bounds.size.x,bounds.size.z).length()/2,"neighbouring house footprints leave landmark and frontage open")
   var mesh_count := 0
   for child in model.get_children():
    if child is MeshInstance3D:
     mesh_count += 1
     var actual: AABB = child.transform*child.mesh.get_aabb()
     # Foundation below local zero is measured separately, all horizontal corners count.
     for edge in 8:
      var corner: Vector3 = actual.get_endpoint(edge)
      check(Vector2(corner.x,corner.z).length()<=float(site.get("radius",0))+0.1,"every mesh corner fits reserved radius")
      if corner.y >= -0.6:
       check(bounds.grow(0.05).has_point(corner),"complete model geometry fits registry envelope")
     check(child.material_override.cull_mode==BaseMaterial3D.CULL_BACK,"normal backface culling")
   check(mesh_count>40,"landmark contains real detailed volumes")
   for i in int(ceil(track.length/0.5)):
    var q: Vector3 = track.position_at(i*0.5)
    check(Vector2(q.x-model.position.x,q.z-model.position.z).length()>track.width+float(site.get("radius",0))+3,"full corridor including curves free at half metre spacing")
  track.queue_free()
  await process_frame
 # Exercise placement failure without touching the road or replacing a sign.
 var refused = RefusedTrack.new()
 root.add_child(refused)
 refused.world_index=3
 refused.curve = Curve3D.new()
 refused.curve.add_point(Vector3.ZERO)
 refused.curve.add_point(Vector3(0,0,100))
 refused.length=100
 refused.width=10
 var samples: Array[Vector3] = [Vector3.ZERO]
 Scenery._haarlem_landmarks(refused,samples)
 Scenery._signs(refused)
 check(refused.get_meta("haarlem_landmark_sections",[]).is_empty(),"failed safe site has no replacement entry")
 check(refused.has_node("RouteSign_1") and refused.has_node("RouteSign_5"),"failed site preserves both original signs")
 check(not Models.valid_entry({"id":"missing-model","section":1},6),"unknown model is rejected before reservation or sign replacement")
 refused.queue_free()
 var duplicate = Track.new()
 root.add_child(duplicate)
 duplicate.world_index=3
 duplicate.curve=Curve3D.new()
 duplicate.curve.add_point(Vector3.ZERO)
 duplicate.curve.add_point(Vector3(0,0,100))
 duplicate.length=100
 var same_section: Dictionary = Models.ENTRIES[1].duplicate()
 same_section.section=Models.ENTRIES[0].section
 var empty_samples: Array[Vector3] = []
 Scenery._haarlem_landmarks(duplicate,empty_samples,[Models.ENTRIES[0],Models.ENTRIES[0],same_section])
 check(duplicate.get_child_count()==1,"duplicate id/section creates one actual model")
 check(duplicate.get_meta("scenic_sites",[]).size()==1,"duplicate id/section reserves one site")
 check(duplicate.get_meta("haarlem_landmark_sections",[]).size()==1,"duplicate id/section replaces one sign")
 duplicate.queue_free()
 print("HAARLEM_LANDMARKS checks=",checks," failures=",failures.size())
 quit(0 if failures.is_empty() else 1)
