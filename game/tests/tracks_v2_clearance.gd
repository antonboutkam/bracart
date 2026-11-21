extends SceneTree
const Track=preload("res://scripts/track.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:
  failures+=1
  if failures<15:push_error(label)
func _initialize(): call_deferred("run")
func collect(node:Node,transform:Transform3D,items:Array):
 var current=transform*node.transform if node is Node3D else transform
 if node is MeshInstance3D and node.mesh is PrimitiveMesh:
  # Huge supporting floor/table/wall planes are outside the rider envelope by Y;
  # broad-phase AABBs deliberately remain conservative for round skyline shapes.
  items.append({"bounds":current*node.mesh.get_aabb(),"path":str(node.get_path())})
 for child in node.get_children():collect(child,current,items)
func run():
 for index in range(6,12):
  var track=Track.new()
  root.add_child(track)
  track.build(index)
  var items=[]
  collect(track,Transform3D.IDENTITY,items)
  # Check complete stunt player/camera corridors, using actual generated primitive
  # bounds. Road ribbon ArrayMeshes are intentionally excluded from scenery.
  for feature in track.v2_course.features:
   for sample in 81:
    var d:float=lerpf(feature.start,feature.end,sample/80.0)
    var f=track.frame(d)
    for lane in [-track.width+1.5,0.0,track.width-1.5]:
     var p=track.position_at(d,lane,.85)
     for item in items:
      var bounds:AABB=item.bounds
      if bounds.has_point(p): check(false,"Stunt rider point inside scenery primitive: %s %s d%.2f p%s"%[index,item.path,d,p])
      else: checks+=1
    var camera=track.position_at(d,0,3.0)+f.basis.z*4.3
    for item in items:
     if item.bounds.has_point(camera): check(false,"Stunt camera point inside scenery primitive: %s %s d%.2f"%[index,item.path,d])
     else: checks+=1
  track.queue_free()
  await process_frame
 print("BORACER TRACKS V2 CLEARANCE: %d checks, %d failures"%[checks,failures])
 quit(0 if failures==0 else 1)
