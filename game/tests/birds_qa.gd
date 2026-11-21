extends SceneTree
## Independent geometry, temporal passage, actual Main lifecycle and projection QA.
const Main = preload("res://scripts/main.gd")
const Birds = preload("res://scripts/worlds/birds.gd")
var checks = 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:
  failures.append(label)
  if failures.size()<=15: push_error(label)
func descendants(node: Node) -> Array[Node]:
 var result: Array[Node]=[]
 for child in node.get_children():
  result.append(child)
  result.append_array(descendants(child))
 return result
func run() -> void:
 root.size=Vector2i(1280,800)
 var main=Main.new()
 root.add_child(main)
 main.set_process(false)
 main.set_physics_process(false)
 main.audio.muted=true
 main.audio.music.stop()
 main.audio.music.stream=null
 var previous=null
 for world in 6:
  main.start_race(world)
  await process_frame # World replacement uses queue_free; assert after its actual flush.
  if previous!=null: check(previous.get_ref()==null,"World switch releases previous bird")
  var bird=main.track.get_node_or_null("Birds")
  if world==5:
   check(bird==null,"Kitchen has no outdoor birds")
   continue
  check(bird is Birds and Birds.install(main.track)==bird,"Every outdoor world installs exactly one idempotent bird")
  previous=weakref(bird)
  bird.set_process(false)
  var nodes=descendants(bird).size()
  check(nodes<25,"Single light bird has bounded node count")
  var geometry={}
  for child in descendants(bird):
   check(not child is CollisionObject3D and not child is AudioStreamPlayer3D,"Bird has no gameplay collision or spatial audio")
   if child is MeshInstance3D:
    check(child.mesh!=null and child.mesh.get_faces().size()>=6,"Bird uses real nonempty mesh geometry")
    geometry[str(bird.get_path_to(child))]=child.mesh.get_instance_id()
  for name in ["Body","Head","Beak","Tail","LeftWing/WingSurface","RightWing/WingSurface"]:
   check(bird.flight.get_node_or_null(name) is MeshInstance3D,"Actual recognizable bird component exists: "+name)
  if world==0:
   var first=0.0
   check(not bird.flight.visible,"Bird starts absent rather than permanently in view")
   while bird.phase=="waiting" and first<17:
    bird.advance(0.2)
    first+=0.2
   check(first>=7.8 and first<=16.2,"First natural bird arrives after declared occasional delay")
  bird.force_passage()
  var direction: Vector3=(bird.path_end-bird.path_start).normalized()
  var body: MeshInstance3D=bird.flight.get_node("Body")
  var beak: MeshInstance3D=bird.flight.get_node("Beak")
  check((beak.global_position-body.global_position).dot(direction)>0,"Actual beak points ahead along flight direction")
  var left=bird.flight.get_node("LeftWing")
  var right=bird.flight.get_node("RightWing")
  var span_left: MeshInstance3D=left.get_node("WingSurface")
  var span_right: MeshInstance3D=right.get_node("WingSurface")
  check(span_left.mesh.get_aabb().size.x>1 and span_right.mesh.get_aabb().size.x>1 and body.get_aabb().size.x*body.scale.x<1,"Actual two broad wing meshes extend beyond the compact bird body")
  var moving_wings=0
  var glides=0
  var minimum_up=INF
  var previous_left: Basis=left.basis
  var previous_position: Vector3=bird.flight.position
  var seen=0
  var max_pixels=0.0
  for tick in 120:
   bird.advance(bird.duration/121.0)
   check(bird.flight.position.is_finite() and bird.flight.basis.is_finite(),"Bird flight remains finite")
   check(bird.flight.position.distance_to(previous_position)>0.01,"Bird keeps travelling during wingbeats and glides")
   if not left.basis.is_equal_approx(previous_left): moving_wings+=1
   if bird.gliding:
    glides+=1
    check(absf(bird.wing_angle)<0.15,"Gliding holds wings nearly extended")
   previous_left=left.basis
   previous_position=bird.flight.position
   for child in descendants(bird.flight):
    if not child is MeshInstance3D: continue
    check(child.mesh.get_instance_id()==geometry[str(bird.get_path_to(child))],"Animation reuses original mesh resources")
    for corner in 8:
     var p: Vector3=child.global_transform*child.get_aabb().get_endpoint(corner)
     check(p.is_finite(),"All posed bird mesh bounds remain finite")
     minimum_up=minf(minimum_up,p.y)
   if tick%12==0:
    for sample in 24:
     main.race.player.progress=main.track.length*sample/24.0
     main._camera(0,true)
     var p: Vector3=bird.flight.global_position
     check(p.distance_to(main.camera.global_position)<main.camera.far-10,"Bird is inside actual camera far distance")
     if main.camera.is_position_in_frustum(p):
      seen+=1
      var screen=Rect2(main.camera.unproject_position(p),Vector2.ZERO)
      for child in descendants(bird.flight):
       if child is MeshInstance3D:
        for corner in 8: screen=screen.expand(main.camera.unproject_position(child.global_transform*child.get_aabb().get_endpoint(corner)))
      max_pixels=maxf(max_pixels,screen.size.x)
  var max_road=-INF
  for sample in 360: max_road=maxf(max_road,main.track.frame(main.track.length*sample/360.0).origin.y)
  check(minimum_up>max_road+15,"Complete flapping bird stays well above the highest road, including elevated worlds")
  check(moving_wings>15 and glides>0,"Passage includes actual hinge motion and extended-wing gliding")
  check(seen>0 and max_pixels>=3,"Normal race views can project a recognizable bird-sized silhouette")
  check(descendants(bird).size()==nodes,"One whole passage does not allocate additional nodes")
  print("BIRDS QA world=",world," normal_views=",seen," max_width_pixels=",max_pixels," nodes=",nodes)
  if world==0:
   bird.force_passage()
   var passed=0
   var previous_phase: String=bird.phase
   var last_end: float=bird.elapsed
   var waits: Array[float]=[]
   var active=0
   for tick in 3600:
    bird.advance(0.2)
    if bird.phase=="passing": active+=1
    if bird.phase!=previous_phase:
     if bird.phase=="passing":
      passed+=1
      waits.append(bird.elapsed-last_end)
     else: last_end=bird.elapsed
     previous_phase=bird.phase
   check(passed>=8 and active<1800,"Natural schedule contains repeated occasional passages with substantial quiet time")
   for gap in waits: check(gap>=34.7 and gap<=65.3,"Natural inter-passage delays stay within declared bounds")
   check(waits.size()>2 and not is_equal_approx(waits[0],waits[1]),"Natural cooldown varies instead of fixed continuous traffic")
   check(descendants(bird).size()==nodes,"Twelve simulated minutes retain bounded node allocation")
  bird.force_passage()
  main.weather.force_event("rain",true)
  bird.advance(0.1)
  check(bird.flight.visible and bird.flight.position.is_finite(),"Actual rain preserves valid visible bird")
  main.weather.force_event("night",true)
  bird.advance(0.1)
  check(bird.flight.visible and bird.flight.position.is_finite(),"Actual night preserves valid visible bird")
  if world==4:
   bird.set_process(true)
   main.set_process(true)
   main.ui.show_pause()
   for frame in 3: await process_frame
   var elapsed: float=bird.elapsed
   var position: Transform3D=bird.flight.transform
   var wing: Basis=left.basis
   await create_timer(0.1).timeout
   check(bird.elapsed==elapsed and bird.flight.transform==position and left.basis==wing,"Actual Main pause freezes passage and posed wings")
   main.ui.resume()
   await create_timer(0.1).timeout
   check(bird.elapsed>elapsed and bird.flight.transform!=position,"Actual Main resume advances bird again")
   main.set_process(false)
 # Remove Main with a live outdoor bird, as well as testing world replacement above.
 main.start_race(0)
 await process_frame
 previous=weakref(main.track.get_node("Birds"))
 main.queue_free()
 for frame in 8: await process_frame
 check(previous.get_ref()==null,"Main cleanup frees last outdoor bird")
 print("BORACER BIRDS INDEPENDENT QA: %d checks, %d failures" % [checks,failures.size()])
 quit(1 if failures.size() else 0)
