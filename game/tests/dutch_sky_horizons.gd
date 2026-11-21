extends SceneTree
const Main = preload("res://scripts/main.gd")
const DutchSky = preload("res://scripts/worlds/dutch_sky.gd")
var checks = 0
var failures: Array[String] = []
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:
  failures.append(label)
  push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var standalone = Environment.new()
 standalone.sky = Sky.new()
 standalone.sky.sky_material = ProceduralSkyMaterial.new()
 var orphan_count = Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
 check(DutchSky.install(standalone,3)==null,"null-track install configures static sky without a controller")
 check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)==orphan_count,"null-track install adds zero orphan nodes")
 check(standalone.sky.sky_material.sky_cover!=null,"null-track static sky still receives cloud cover")
 var main = Main.new()
 root.add_child(main)
 await process_frame
 main.set_process(false)
 main.set_physics_process(false)
 main.audio.muted = true
 main.audio.music.stop()
 for world in 6:
  main.start_race(world)
  await process_frame
  var env: Environment = main.environment.environment
  var track: Node3D = main.track
  var sky = env.sky.sky_material as ProceduralSkyMaterial
  check(sky!=null,"Weather procedural sky contract retained")
  if world==5:
   check(not track.has_node("DutchSky"),"kitchen sky controller excluded")
   check(sky.sky_cover==null,"kitchen previous sky cover untouched")
   check(track.get_node("LayeredWorldBackground").get_child_count()>30,"kitchen interior unchanged")
   check(not track.has_node("DutchHorizons"),"kitchen horizon excluded")
   continue
  var controller = track.get_node("DutchSky")
  check(sky.sky_cover!=null,"outdoor cumulus panorama installed")
  check(sky.get_meta("dutch_cloud_cover",false),"weather sky duplicate preserves cover metadata")
  check(track.has_node("DutchHorizons")== (world in [3,4]),"only Haarlem Uithoorn get replacement horizon")
  var day_color: Color = sky.sky_top_color
  main.weather.force_event("rain",true)
  controller.sync_weather()
  check(sky.get_meta("weather_rain") == 1.0,"cloud appearance follows actual rain state")
  check(main.weather.drops.visible,"rain still visible")
  check(env.fog_density>main.weather.baseline.fog_density,"rain atmospheric fog preserved")
  main.weather.force_event("night",true)
  controller.sync_weather()
  check(sky.sky_cover.get_meta("night"),"actual night uses moon star and subdued cloud cover")
  check(sky.sun_angle_max==0,"night hides procedural sun disc")
  check(sky.sky_top_color.get_luminance()<day_color.get_luminance() or world==1,"Weather darkens sky at night")
  var before: Color = sky.sky_cover_modulate
  main.weather.advance(2,Vector3.ZERO,true)
  controller.sync_weather()
  check(sky.sky_cover_modulate==before,"paused weather does not animate cloud state")
  main.weather.force_event("rainbow",true)
  controller.sync_weather()
  check(main.weather.rainbow.visible,"existing rainbow geometry preserved")
  main.weather.force_event("sun",true)
  controller.sync_weather()
  check(sky.sky_top_color.is_equal_approx(day_color),"Weather restores baseline sky after night")
  check(sky.sky_cover.get_meta("night")== (world==1),"Neon remains moonlit, other worlds return to sun")
  if world in [3,4]:
   var horizon = track.get_node("DutchHorizons")
   var records: Array = horizon.get_meta("geometry_records")
   check(records.size()>10,"landscape has real geometry")
   check(horizon.get_meta("review_views").size()==1,"reproducible horizon camera provided")
   var dune_count = 0
   var fields = 0
   var rivers: Array = []
   for record in records:
    var bounds: AABB = record.bounds
    var dx = maxf(maxf(bounds.position.x,-bounds.end.x),0)
    var dz = maxf(maxf(bounds.position.z,-bounds.end.z),0)
    check(Vector2(dx,dz).length()>=300,"every final landscape AABB remains outside 300 m exclusion radius")
    if record.kind=="dune":
     dune_count+=1
     var scale_value: Vector3 = record.transform.basis.get_scale()
     check(scale_value.y/minf(scale_value.x,scale_value.z)<0.36,"dunes are low and broad instead of steep mountains")
    if record.kind=="field":
     fields+=1
     check(bounds.size.y<0.1,"polder fields stay flat")
    if record.kind=="amstel": rivers.append(record)
   check(dune_count==12 if world==3 else fields>30,"world-specific dunes or broad pasture parcels")
   if world==4:
    check(rivers.size()==2,"Amstel continues at both ends")
    for river in rivers:
     check(absf(river.points[0].x)<0.001 and absf(absf(river.points[0].z)-440)<0.001,"river starts inside existing straight water join")
     check(absf(river.points[-1].x)>15,"Amstel genuinely bends through polders")
     for record in records:
      if record.kind!="field": continue
      for point in river.points:
       var bounds: AABB = record.bounds
       var dx = maxf(maxf(bounds.position.x-point.x,point.x-bounds.end.x),0)
       var dz = maxf(maxf(bounds.position.z-point.z,point.z-bounds.end.z),0)
       check(Vector2(dx,dz).length()>27,"actual field boxes never cover Amstel surface")
   print("DUTCH_HORIZON world=",world," records=",records.size()," nodes=",horizon.get_child_count())
 for palette in [false,true]:
  check(DutchSky.panorama(palette)==DutchSky.panorama(palette),"panorama cached without per-frame regeneration")
 var image: Image = DutchSky.images.day
 check(image.get_size()==Vector2i(1024,512),"sky cover is full equirectangular panorama")
 var cloud_pixels = 0
 var clear_pixels = 0
 for y in range(0,256,8):
  for x in range(0,1024,8):
   var c = image.get_pixel(x,y)
   if c.a>0.35: cloud_pixels+=1
   if c.a<0.02: clear_pixels+=1
 for y in 256:
  check(absf(image.get_pixel(0,y).a-image.get_pixel(1023,y).a)<0.08,"cloud panorama seamless across longitude")
 check(cloud_pixels>60 and clear_pixels>60,"cumulus has readable clusters and clear sky between")
 print("DUTCH_SKY_HORIZONS checks=",checks," failures=",failures.size()," cloud_pixels=",cloud_pixels," clear_pixels=",clear_pixels)
 main.vehicle_audio.clear()
 main.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
