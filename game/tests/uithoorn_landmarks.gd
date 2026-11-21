extends SceneTree
const Track = preload("res://scripts/track.gd")
const Models = preload("res://scripts/worlds/uithoorn_landmarks.gd")
var checks = 0
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures.append(label)
  push_error(label)
func _initialize() -> void: call_deferred("run")
func geometry(node: Node, transform: Transform3D, meshes: Array) -> void:
 if node is Node3D: transform = transform*node.transform
 if node is MeshInstance3D and node.mesh != null: meshes.append({"mesh":node,"bounds":transform*node.mesh.get_aabb()})
 for child in node.get_children(): geometry(child,transform,meshes)
func run() -> void:
 for index in [4,10]:
  var track = Track.new()
  root.add_child(track)
  track.build(index)
  var found: Array = []
  for child in track.get_children():
   if child.has_meta("uithoorn_landmark"): found.append(child)
  check(found.size()==6,"six imported landmarks in Uithoorn track "+str(index))
  var samples: Array[Vector3] = []
  for i in int(ceil(track.length/0.5)): samples.append(track.position_at(i*0.5))
  var houses: Array = track.get_node("StreetDistricts").get_meta("buildings",[])
  for entry in Models.ENTRIES:
   var model = track.get_node_or_null("Landmark_"+str(entry.id).replace("-","_")) as Node3D
   check(model != null,"registered model exists "+entry.id)
   if model == null: continue
   if index==4:
    check(model.position.is_equal_approx(track.ground_course.SITES[entry.id]),"authored street-corner landmark site "+entry.id)
   var bounds: AABB = model.get_meta("bounds")
   var envelope = Models.radius(entry)
   var meshes: Array = []
   # Imported mesh bounds relative to holder, excluding separate ground support.
   for child in model.get_children():
    if child.name != "GroundSupport": geometry(child,Transform3D.IDENTITY,meshes)
   check(not meshes.is_empty(),"real imported mesh geometry "+entry.id)
   var texture_count = 0
   for item in meshes:
    for corner in 8:
     check(bounds.grow(0.08).has_point(item.bounds.get_endpoint(corner)),"registry contains complete imported geometry "+entry.id)
    var mesh: MeshInstance3D = item.mesh
    for surface in mesh.mesh.get_surface_count():
     var material = mesh.get_active_material(surface)
     check(material != null,"imported material exists")
     if material is BaseMaterial3D:
      check(material.cull_mode == BaseMaterial3D.CULL_BACK,"normal backface culling")
      if material.albedo_texture != null: texture_count += 1
   check(texture_count>0,"embedded textured PBR material "+entry.id)
   for q in samples:
    check(Vector2(q.x-model.position.x,q.z-model.position.z).length()>=envelope+track.width+6-0.01,"complete driving/camera corridor clear "+entry.id)
   for i in 360:
    var a = TAU*i/360.0
    check(Vector2(model.position.x-83-49*cos(a),model.position.z-100*sin(a)).length()>=envelope+7-0.01,"tram clearance "+entry.id)
   var matching = 0
   for site in track.get_meta("scenic_sites",[]):
    if site.get("uithoorn_landmark","")==entry.id:
     matching += 1
     check(site.radius>=envelope,"OutdoorLife reserves full landmark envelope")
   check(matching==1,"one reserved site per landmark")
   for house in houses:
    var p: Vector3 = house.frame.origin
    # Spoorhuis is covered separately by its own conservative reserved envelope.
    var house_radius = Vector2(house.width,house.depth+14).length()/2
    check(Vector2(p.x-model.position.x,p.z-model.position.z).length()>envelope+house_radius,"district house and front garden do not intersect "+entry.id)
   for other in found:
    if other==model: continue
    var ob: AABB = other.get_meta("bounds")
    var r = Vector2(ob.size.x,ob.size.z).length()/2
    check(Vector2(other.position.x-model.position.x,other.position.z-model.position.z).length()>envelope+r+8,"landmark envelopes do not overlap")
   if entry.id=="irenebrug":
    check(is_zero_approx(model.position.x),"Irenebrug spans Amstel water")
   else:
    check(model.has_node("GroundSupport"),"building datum supported down to ground")
  print("UITHOORN_PLACEMENTS variant=",index," ",found.map(func(n): return {"id":n.get_meta("uithoorn_landmark"),"position":n.position}))
  track.queue_free()
  await process_frame
 # The generic church is gone; unrelated world regressions use existing suites.
 var source = FileAccess.get_file_as_string("res://scripts/worlds/scenery.gd")
 check(not source.contains('_church(church,"THAMERKERK"'),"generic duplicate Thamerkerk removed")
 print("UITHOORN_LANDMARKS checks=",checks," failures=",failures.size())
 quit(0 if failures.is_empty() else 1)
