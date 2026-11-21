extends SceneTree
const Track = preload("res://scripts/track.gd")
const Accents = preload("res://scripts/worlds/nature_accents.gd")
var checks = 0
var failures = 0

func check(value: bool, label: String) -> void:
 checks+=1
 if not value:
  failures+=1
  if failures<20: push_error(label)

func _initialize() -> void: call_deferred("run")

func run() -> void:
 for world in 6:
  var track = Track.new()
  root.add_child(track)
  track.build(world)
  if world not in [3,4]:
   check(not track.has_node("NatureAccents"),"Other worlds preserve existing nature")
  else:
   check(track.has_node("NatureAccents"),"World gets actual imported accents")
   if not track.has_node("NatureAccents"):
    track.free()
    continue
   var accents = track.get_node("NatureAccents")
   var records: Array = accents.get_meta("instances")
   check(records.size()==12,"Exactly twelve selected imported instances")
   check(accents.get_child_count()==4,"Four batches only")
   check(Accents.build(track,track.get_node("OutdoorLife").get_meta("clusters"))==accents,"Repeated install is idempotent")
   check(accents.find_children("*","CollisionObject3D",true,false).is_empty(),"Decorative imports do not change collision")
   var counter = 0
   for batch in accents.get_children():
    check(batch is MultiMeshInstance3D,"Nature instances are batched")
    check(batch.visibility_range_end==350,"Finite culling distance")
    var matrices: Array = batch.get_meta("instance_transforms")
    check(matrices.size()==batch.multimesh.instance_count,"Submitted transforms match instances")
    for matrix in matrices:
     var actual: AABB = matrix*batch.multimesh.mesh.get_aabb()
     var record: Dictionary = records[counter]
     counter+=1
     check(actual.is_equal_approx(record.bounds),"Recorded bounds equal actual imported mesh")
     check(absf(actual.position.y-record.support_y)<0.001,"Imported model rests on existing deck")
     check(absf(actual.size.y-record.height)<0.001,"Source meters normalized to intended height")
     var local: AABB = record.cluster_transform.affine_inverse()*actual
     # World AABB rotated back can be looser; exact corners below are decisive.
     check(local.size.is_finite(),"Local coordinates remain finite")
     for corner in 8:
      var point: Vector3 = record.cluster_transform.affine_inverse()*(matrix*batch.multimesh.mesh.get_aabb().get_endpoint(corner))
      check(absf(point.x)<10.91 and absf(point.z)<5.91 and point.y>=-0.001,"Actual mesh bounds stay on supported deck footprint")
     for step in int(ceil(track.length/2.0)):
      var road: Vector3 = track.position_at(step*2.0)
      var dx = maxf(maxf(actual.position.x-road.x,road.x-actual.end.x),0)
      var dz = maxf(maxf(actual.position.z-road.z,road.z-actual.end.z),0)
      check(Vector2(dx,dz).length()>track.width+4.0,"Complete imported bounds clear road and race camera")
    for surface in batch.multimesh.mesh.get_surface_count():
     var material = batch.multimesh.mesh.surface_get_material(surface)
     check(material is BaseMaterial3D and material.cull_mode==BaseMaterial3D.CULL_BACK,"Imported materials have outward culling")
  track.free()
  await process_frame
 print("Nature accents: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
