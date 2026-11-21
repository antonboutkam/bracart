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
func nodes(node: Node) -> int:
 var result = 1
 for child in node.get_children(): result += nodes(child)
 return result
func run() -> void:
 for world in 6:
  var track = Track.new()
  root.add_child(track)
  track.build(world)
  if world==5:
   check(not track.has_node("OutdoorLife") and not track.has_node("StreetWalkers"),"kitchen receives no outdoor population")
   check(track.get_node("KitchenProps").get_meta("objects").size()==11,"kitchen eleven groups preserved")
  else:
   check(track.has_node("OutdoorLife"),"actual Track builds street life")
   var life = track.get_node("OutdoorLife")
   var clusters: Array = life.get_meta("clusters")
   check(clusters.size()>=18 and clusters.size()<=30,"18-30 detail clusters in world "+str(world))
   var walker_specs: Array = life.get_meta("walker_specs")
   check(walker_specs.size()>=2 and walker_specs.size()<=4,"2-4 walker routes world "+str(world))
   var node_count: int = nodes(life)+nodes(track.get_node("StreetWalkers"))
   check(node_count<600,"street life under 600 nodes world "+str(world))
   var cloud_parts = 0
   var deck_count = 0
   var static_count = 0
   for batch in life.get_children():
    check(batch is MultiMeshInstance3D,"static street details instanced")
    static_count+=batch.multimesh.instance_count
    var mesh: Mesh = batch.multimesh.mesh
    for index in batch.multimesh.instance_count:
     var transform: Transform3D = batch.get_meta("instance_transforms")[index]
     var closest: Dictionary = clusters[0]
     var distance = INF
     for cluster in clusters:
      var current = Vector2(transform.origin.x-cluster.center.x,transform.origin.z-cluster.center.z).length()
      if current<distance:
       closest=cluster
       distance=current
     var local: Transform3D = closest.transform.affine_inverse()*transform
     var bounds = mesh.get_aabb()
     for x in [bounds.position.x,bounds.end.x]:
      for y in [bounds.position.y,bounds.end.y]:
       for z in [bounds.position.z,bounds.end.z]:
        var p: Vector3 = local*Vector3(x,y,z)
        check(Vector2(p.x,p.z).length()<=closest.radius+0.05,"submitted mesh incl tree canopy within conservative footprint")
     var scale_value = transform.basis.get_scale()
     if mesh is BoxMesh and scale_value.is_equal_approx(Vector3(22,0.6,12)):
      deck_count+=1
      check(absf(transform.origin.y+0.3-float(closest.floor_y))<0.001,"actual solid deck top equals walking floor")
     if world==2 and mesh is SphereMesh and scale_value.is_equal_approx(Vector3(13,7.5,13)):
      cloud_parts+=1
      check(transform.origin.y+3.75>float(closest.floor_y)-0.6,"real cloud intersects underside of solid deck")
      check(transform.origin.y+3.75<=float(closest.floor_y),"submitted cloud surface never protrudes through walking floor")
   check(deck_count==clusters.size(),"one physical deck per cluster actual="+str(deck_count))
   if world==2: check(cloud_parts==clusters.size()*3,"three genuine supporting cloud volumes per island")
   var distances: Array[float] = []
   for cluster in clusters:
    var nearest = INF
    var y: float = cluster.center.y
    check(cluster.supported,"explicit physical support metadata")
    check(cluster.static_aabb.size.y>=6,"physical tree/platform vertical extent")
    check(cluster.vehicle=="steam_carriage" if world==3 else cluster.vehicle=="parked_car","period vehicle selection")
    if world in [0,3,4]: check(absf(cluster.center.x)>=24.5+cluster.radius+1,"entire platform avoids water")
    if world==4: check(absf(y+20.85)<0.001,"Uithoorn props stand above visible landscaped bank")
    for i in int(ceil(track.length/0.8)):
     var q: Vector3 = track.position_at(i*0.8)
     nearest = minf(nearest,q.distance_to(cluster.center))
     check(Vector2(q.x-cluster.center.x,q.z-cluster.center.z).length()>=track.width+cluster.radius+4.1,"full cluster and canopy outside race/camera corridor")
    distances.append(nearest)
    if world==4:
     for i in 192:
      var a = TAU*i/192.0
      var p = Vector3(83+49*cos(a),-21.68,100*sin(a))
      check(Vector2(p.x-cluster.center.x,p.z-cluster.center.z).length()>=cluster.radius+6,"tram corridor excludes entire cluster")
   distances.sort()
   print("DISTANCES median=",distances[distances.size()/2]," max=",distances.back())
   print("OUTDOOR_LIFE world=",world," clusters=",clusters.size()," walker_routes=",walker_specs.size()," nodes=",node_count," static_instances=",static_count)
  track.queue_free()
  await process_frame
 print("OUTDOOR_LIFE checks=",checks," failures=",failures.size())
 quit(0 if failures.is_empty() else 1)
