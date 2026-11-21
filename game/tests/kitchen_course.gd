extends SceneTree
const Track = preload("res://scripts/track.gd")
const Race = preload("res://scripts/race.gd")
const Kart = preload("res://scripts/kart.gd")
const CameraRig = preload("res://scripts/follow_camera.gd")
var checks := 0
var failures := 0
func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures += 1
  if failures < 15: push_error(label)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var track := Track.new()
 root.add_child(track)
 track.build(5)
 var features: Array = track.kitchen_features()
 check(features.size() == 6,"Kitchen has six actual course features")
 var course = track.kitchen_course
 for tube_index in [0,3]:
  var tube: Dictionary = features[tube_index]
  for sample in 241:
   var progress: float = lerpf(tube.entry_start,tube.entry_end,float(sample)/240)
   for lane in [-7.8,0.0,7.8]:
    for lift in [0.0,0.4,2.5,4.0]:
     var point: Vector3 = tube.frame.affine_inverse()*track.position_at(progress,lane,lift)
     point.y -= tube.axis_height-tube.frame.origin.y
     if absf(point.z) <= tube.length*0.5:
      check(Vector2(point.x,point.y).length() < tube.inner_radius*cos(PI/64)-0.05,"Full approach and exit rider/camera envelope clears the real polygonal tunnel bore: %s d=%.3f lane=%.1f lift=%.1f r=%.3f z=%.3f" % [tube.id,progress,lane,lift,Vector2(point.x,point.y).length(),point.z])
 var previous: Transform3D = track.frame(0)
 var inverted: int = 0
 for index in 2000:
  var f: Transform3D = track.frame(track.length*index/2000.0)
  check(f.origin.is_finite() and f.basis.is_finite() and absf(f.basis.determinant()-1)<0.001,"Finite right-handed route frame")
  check(previous.basis.y.dot(f.basis.y) > 0.99,"Dense sampled up vectors rotate continuously without vertical singularities")
  if f.basis.y.y < -0.8: inverted += 1
  for side in [-7,7]:
   var edge: Vector3 = f.origin+f.basis.x*side
   check(absf(edge.x)<117 and absf(edge.z)<102,"Full road stays inside table bounds")
   check(edge.y >= 0.085,"Physical road ribbon never penetrates tabletop")
  previous = f
 check(inverted > 10,"Loop actually carries racers upside down")
 check(track.frame(0).origin.distance_to(track.frame(track.length).origin)<0.001 and track.frame(0).basis.z.dot(track.frame(track.length-0.01).basis.z)>.999,"New kitchen course retains closed smooth finish seam")
 var loop: Dictionary = features[2]
 check(track.frame(loop.start).origin.distance_to(track.frame(loop.end).origin)>20,"Loop entry and exit are spatially separated by a helix")
 var camera := Camera3D.new()
 root.add_child(camera)
 var rig = CameraRig.new(camera)
 for vehicle in 6:
  var kart := Kart.new()
  root.add_child(kart)
  kart.setup(vehicle,"boaz" if vehicle%2==0 else "ravi",false)
  kart.speed = 40
  for index in 61:
   kart.progress = lerpf(loop.start-4,loop.end+4,float(index)/60)
   kart.update_visual(track,1.0/60)
   rig.update(track,kart,1.0/60,true,true)
   var f: Transform3D = track.frame(kart.progress)
   check(kart.basis.y.dot(f.basis.y)>.999,"Each real vehicle and seated rider follows inverted track orientation")
   check(camera.position.is_finite() and camera.basis.is_finite() and absf(camera.basis.determinant()-1)<0.001,"Loop camera remains finite and orthonormal")
   check(camera.position.distance_to(kart.position)>4 and camera.position.distance_to(kart.position)<9,"Actual inverted race camera keeps useful follow distance")
  kart.queue_free()
  await process_frame
 var race := Race.new()
 root.add_child(race)
 race.setup(track,0,"boaz",0)
 race.countdown = 0
 for ramp_index in [4,5]:
  var ramp: Dictionary = features[ramp_index]
  for kart in race.racers:
   kart.progress = ramp.lip-0.3
   kart.speed = 35
   kart.lateral = 0
   kart.jump_height = 0
   kart.jump_velocity = 0
  race.step(1.0/30,1,0,0,false)
  check(race.racers.all(func(k):return k.jump_height>0 and k.jump_velocity>0),"Player and four AI actually launch at the physical ramp lip")
  for tick in 90: race.step(1.0/60,1,0,0,false)
  check(race.racers.all(func(k):return k.jump_height==0 and k.jump_velocity==0),"Existing gravity brings all ramp jumps back to their guide without reset")
 var rainbow: Node3D = track.kitchen_rainbow
 rainbow.set_process(false)
 var pvc: Dictionary = features[3]
 rainbow.update_player(pvc.start-5)
 rainbow.advance(0.3)
 check(not rainbow.inside and rainbow.opacity==0,"Outside PVC has no rainbow tunnel")
 rainbow.update_player(pvc.center)
 rainbow.advance(0.6)
 check(rainbow.inside and rainbow.opacity==1 and rainbow.visible,"Actual player PVC progress fades rainbow tunnel in")
 var phase: float = rainbow.material.get_shader_parameter("phase")
 rainbow.advance(0.5)
 check(rainbow.material.get_shader_parameter("phase")!=phase and not rainbow.material.shader.code.contains("TIME"),"Rainbow rotates using an explicit pauseable time uniform")
 rainbow.update_player(pvc.end+5)
 rainbow.advance(0.6)
 check(rainbow.opacity==0 and not rainbow.visible,"Leaving PVC fades effect out")
 rainbow.set_process(true)
 track.process_mode = Node.PROCESS_MODE_DISABLED
 var clock: float = rainbow.elapsed
 await create_timer(0.08).timeout
 check(rainbow.elapsed==clock,"Track pause freezes rainbow clock")
 var old: WeakRef = weakref(rainbow)
 race.queue_free()
 camera.queue_free()
 track.queue_free()
 await process_frame
 check(old.get_ref()==null,"World cleanup removes route effect")
 print("BORACER KITCHEN COURSE: %d checks, %d failures" % [checks,failures])
 quit(0 if failures==0 else 1)
