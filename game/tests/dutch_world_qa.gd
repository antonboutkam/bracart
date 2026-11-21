extends SceneTree
## Independent final landscape-vs-existing-object/route and real-weather checks.
## CPU-submitted MultiMesh shapes are verified; no GPU readback or native-image claim.
const Main = preload("res://scripts/main.gd")
const DutchSky = preload("res://scripts/worlds/dutch_sky.gd")
var checks = 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
 checks += 1
 if not value:
  failures.append(label)
  if failures.size() <= 15: push_error(label)
func top_at(shape: Dictionary, point: Vector3) -> float:
 var p: Vector3 = shape.transform.affine_inverse()*point
 var mesh: Mesh = shape.mesh
 if mesh is BoxMesh:
  var bounds: AABB = mesh.get_aabb()
  if p.x < bounds.position.x or p.x > bounds.end.x or p.z < bounds.position.z or p.z > bounds.end.z: return -INF
  return (shape.transform*Vector3(p.x,bounds.end.y,p.z)).y
 if mesh is SphereMesh:
  var inside: float = 1.0-pow(p.x/mesh.radius,2)-pow(p.z/mesh.radius,2)
  if inside < 0: return -INF
  return (shape.transform*Vector3(p.x,mesh.height*0.5*sqrt(inside),p.z)).y
 if mesh is ArrayMesh:
  var bounds: AABB = shape.transform*mesh.get_aabb()
  if point.x >= bounds.position.x and point.x <= bounds.end.x and point.z >= bounds.position.z and point.z <= bounds.end.z: return bounds.end.y
 return -INF
func run() -> void:
 var orphan_baseline = Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
 var empty_env = Environment.new()
 check(DutchSky.install(empty_env,0) == null,"Environment helper accepts the existing no-sky caller without a controller")
 check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == orphan_baseline,"No-sky helper call never leaves an orphan controller")
 var isolated_env = Environment.new()
 isolated_env.sky = Sky.new()
 isolated_env.sky.sky_material = ProceduralSkyMaterial.new()
 check(DutchSky.install(isolated_env,0) == null and isolated_env.sky.sky_material.sky_cover != null,"Optional trackless call still configures its real sky without returning an unattached node")
 check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == orphan_baseline,"Configured trackless sky leaves no orphan Node")
 var main = Main.new()
 root.add_child(main)
 await process_frame
 main.audio.muted = true
 main.audio.music.stop()
 main.audio.music.stream = null
 main.set_physics_process(false)
 var old_sky = null
 var old_controller = null
 for world in 6:
  main.start_race(world)
  await process_frame
  if old_controller != null: check(old_controller.get_ref() == null,"World replacement releases previous sky controller")
  var env: Environment = main.environment.environment
  var sky: ProceduralSkyMaterial = env.sky.sky_material
  if old_sky != null: check(old_sky != sky,"Weather does not share a mutable sky resource between worlds")
  old_sky = sky
  if world == 5:
   check(not main.track.has_node("DutchSky") and not main.track.has_node("DutchHorizons"),"Kitchen receives no outdoor sky or far landscape")
   check(sky.sky_cover == null and sky.sun_angle_max == 15,"Kitchen sky cover and procedural sun stay unchanged")
   check(sky.sky_top_color.is_equal_approx(Color("cdbb9f").darkened(0.25)) and sky.sky_horizon_color.is_equal_approx(Color("cdbb9f").lightened(0.18)),"Kitchen previous palette is preserved exactly")
   check(is_equal_approx(env.fog_density,0.00035) and is_equal_approx(main.sun.light_energy,0.65),"Kitchen previous fog and sun energy remain intact")
   check(main.track.get_node("KitchenProps").get_meta("objects").size() == 11,"Kitchen retains its eleven original photo-informed groups")
   continue
  var controller = main.track.get_node("DutchSky")
  old_controller = weakref(controller)
  check(sky.sky_cover is ImageTexture and sky.sky_cover.get_width() == 1024 and sky.sky_cover.get_height() == 512,"Outdoor sky uses bounded actual cloud image")
  var baseline_cover = sky.sky_cover
  var baseline_tint: Color = sky.sky_cover_modulate
  var baseline_top: Color = sky.sky_top_color
  main.weather.force_event("rain",true)
  for frame in 2: await process_frame
  check((sky.sky_cover_modulate != baseline_tint or world == 1) and main.weather.drops.visible and sky.get_meta("weather_rain") == 1.0,"Actual controller updates cloud tint alongside visible rain")
  main.weather.force_event("night",true)
  for frame in 2: await process_frame
  check(sky.sky_cover.get_meta("night") and sky.sun_angle_max == 0,"Actual scene update changes moonlit cover and hides sun at night")
  check(sky.sky_top_color.get_luminance() < baseline_top.get_luminance() or world == 1,"Night darkens the procedural atmosphere")
  main.ui.show_pause()
  var elapsed: float = main.weather.elapsed
  var tint: Color = sky.sky_cover_modulate
  await create_timer(0.07).timeout
  check(main.weather.elapsed == elapsed and sky.sky_cover_modulate == tint,"Real Main pause freezes weather and resulting cloud appearance")
  main.ui.resume()
  await create_timer(0.07).timeout
  check(main.weather.elapsed > elapsed,"Real Main resume advances weather again")
  main.weather.force_event("sun",true)
  for frame in 2: await process_frame
  check(sky.sky_cover == baseline_cover and sky.sky_cover_modulate.is_equal_approx(baseline_tint) and sky.sky_top_color.is_equal_approx(baseline_top),"Sun restores complete original sky state")
  if world not in [3,4]: continue
  var horizon = main.track.get_node("DutchHorizons")
  var shapes: Array = []
  for node in horizon.get_children():
   if node is MultiMeshInstance3D:
    var submitted: Array = node.get_meta("instance_transforms")
    check(submitted.size() == node.multimesh.instance_count,"Every landscape instance exposes its exact submitted CPU transform")
    for transform in submitted:
     shapes.append({"transform":node.global_transform*transform,"mesh":node.multimesh.mesh})
   elif node is MeshInstance3D and node.mesh != null:
    shapes.append({"transform":node.global_transform,"mesh":node.mesh})
  check(shapes.size() > 40,"Landscape includes substantial submitted geometry")
  var clusters: Array = main.track.get_node("OutdoorLife").get_meta("clusters")
  for cluster in clusters:
   var whole_cluster = AABB(cluster.center-Vector3(cluster.radius,0,cluster.radius),Vector3(cluster.radius*2,0.1,cluster.radius*2))
   for shape in shapes:
    var bounds: AABB = shape.transform*shape.mesh.get_aabb()
    var overlap_x = bounds.position.x <= whole_cluster.end.x and bounds.end.x >= whole_cluster.position.x
    var overlap_z = bounds.position.z <= whole_cluster.end.z and bounds.end.z >= whole_cluster.position.z
    check(not (overlap_x and overlap_z) or bounds.end.y < cluster.center.y-0.035,"Conservative complete cluster envelope stays above or outside every new landscape shape")
   for dx in [-11.0,0.0,11.0]:
    for dz in [-6.0,0.0,6.0]:
     var point: Vector3 = cluster.transform*Vector3(dx,0,dz)
     for shape in shapes:
      check(top_at(shape,point) < point.y-0.035,"Final new landscape never buries an existing street platform or walking floor")
  for index in 301:
   var progress: float = main.track.length*index/300.0
   var point: Vector3 = main.track.position_at(progress)
   for shape in shapes:
    var bounds: AABB = shape.transform*shape.mesh.get_aabb()
    var dx = maxf(maxf(bounds.position.x-point.x,point.x-bounds.end.x),0)
    var dz = maxf(maxf(bounds.position.z-point.z,point.z-bounds.end.z),0)
    check(Vector2(dx,dz).length() > main.track.width+4.0 or bounds.end.y < point.y-8,"Far landscape leaves the full existing road corridor clear")
 for nighttime in [false,true]:
  var image: Image = DutchSky.panorama(nighttime).get_image()
  var opaque = 0
  var clear = 0
  for y in range(0,512,4):
   var left = image.get_pixel(0,y)
   var right = image.get_pixel(1023,y)
   check(absf(left.a-right.a) <= 1.0/255.0 and absf(left.r-right.r) <= 1.0/255.0,"Cloud panorama joins continuously across equirectangular seam")
   for x in range(0,1024,8):
    var pixel = image.get_pixel(x,y)
    if pixel.a > 0.15: opaque += 1
    if pixel.a < 0.01: clear += 1
    if y >= 256: check(pixel.a == 0,"Cloud cover never paints the lower ground hemisphere")
  check(opaque > 100 and clear > 100,"Generated panorama includes both real cloud pixels and clear sky")
 main.go_home()
 main.queue_free()
 for frame in 8: await process_frame
 print("BORACER DUTCH WORLD INDEPENDENT QA: %d checks, %d failures" % [checks,failures.size()])
 quit(1 if failures.size() else 0)
