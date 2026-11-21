extends SceneTree
const Track=preload("res://scripts/track.gd")
const Race=preload("res://scripts/race.gd")
const CameraRig=preload("res://scripts/follow_camera.gd")
const Catalog=preload("res://scripts/catalog.gd")
const Profile=preload("res://scripts/profile.gd")
var checks:=0
var failures:=0
var results={}
func check(ok:bool,label:String):
 checks+=1
 if not ok:
  failures+=1
  if failures<30: push_error(label)
func _initialize(): call_deferred("run")
func run():
 var baseline=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/tracks_v1_baseline.json"))
 check(Catalog.WORLDS.size()==6 and Catalog.TRACKS.size()==12,"Six landscapes, twelve separate selections")
 var camera=Camera3D.new()
 root.add_child(camera)
 var rig=CameraRig.new(camera)
 for i in 12:
  var track=Track.new()
  root.add_child(track)
  track.build(i)
  check(track.world_index==i%6 and track.track_index==i,"Track and landscape identities are independent")
  # Classic Uithoorn deliberately changed; uithoorn_ground tests its new contract.
  # Keep the historical fixture: V2 still uses its original length reference.
  if i<6 and i!=4:
   var old:Dictionary=baseline[str(i)]
   check(absf(track.length-old.length)<.001,"Original length unchanged")
   for j in 120:
    var f=track.frame(track.length*j/120.0)
    var sample:Array=old.samples[j]
    check(f.origin.distance_to(Vector3(sample[0],sample[1],sample[2]))<.001 and absf(f.basis.x.x-sample[3])<.00001 and absf(f.basis.y.y-sample[4])<.00001 and absf(f.basis.z.z-sample[5])<.00001,"Original route/frame snapshot remains unchanged")
  elif i>=6:
   var course=track.v2_course
   check(track.length/baseline[str(i%6)].length>2.8 and track.length/baseline[str(i%6)].length<3.2,"V2 measured length is three original courses")
   check(course.features.size()==7,"One loop, corkscrew, descent, S bends, two small jumps and one mega")
   var previous=track.frame(0)
   var min_edge=INF
   for j in 6000:
    var f=track.frame(track.length*j/6000.0)
    check(f.origin.is_finite() and absf(f.basis.determinant()-1)<.001,"Finite right-handed frame")
    check(previous.basis.y.dot(f.basis.y)>.998,"Continuous up-axis through inversions")
    if i==11:
     for side in [-7,7]:
      var edge=f.origin+f.basis.x*side
      min_edge=minf(min_edge,edge.y)
      check(absf(edge.x)<track.table_half.x and absf(edge.z)<track.table_half.y,"Kitchen road stays inside enlarged tabletop")
    previous=f
   if i==11: check(min_edge>=0.105,"Entire kitchen ribbon stays above real tabletop")
   check(track.frame(0).origin.distance_to(track.frame(track.length-.001).origin)<.002 and track.frame(0).basis.y.dot(track.frame(track.length-.001).basis.y)>.99999,"Closed position and up seam")
   for feature in course.features:
    if feature.id in ["loop","corkscrew"]:
     var inverted=0
     var max_height=-INF
     for j in 100:
      var f=track.frame(lerpf(feature.start,feature.end,j/99.0))
      if f.basis.y.y<-.8: inverted+=1
      max_height=maxf(max_height,f.origin.y)
     check(inverted>=6,"Each 3D stunt carries actual track frame upside down")
     check(max_height-course.base_height>20,"Actual centerline has three dimensional rise")
    elif feature.has("lip"):
     check(course.is_gap((feature.lip+feature.end)/2),"Unsupported space after each physical ramp lip")
    elif feature.id=="downhill":
     check(track.frame(feature.start).origin.y-track.frame(feature.end).origin.y>37 and feature.end-feature.start>150,"Long descent loses 38m over a straight section")
   var race=Race.new()
   root.add_child(race)
   race.setup(track,i%6,"boaz",1)
   race.countdown=0
   race.auto_drive=true
   var visited={}
   var airborne={}
   var landed={}
   for k in race.racers:
    visited[k.racer_name]=[]
    airborne[k.racer_name]=[]
    landed[k.racer_name]=[]
   var ticks=0
   # One whole lap by every real AI and the auto-driving player, followed by
   # complete race finish. Slow AI must reach every feature before player finish.
   while not race.done and ticks<6000:
    race.step(0.1,1,0,0,false)
    if ticks%3==0:
     rig.update(track,race.player,0.1,true,false)
     check(camera.position.is_finite() and absf(camera.basis.determinant()-1)<.001,"Follow camera survives real continuous driving")
    for k in race.racers:
     var feature:Dictionary=course.feature_at(k.progress)
     if not feature.is_empty() and not feature.id in visited[k.racer_name]: visited[k.racer_name].append(feature.id)
     if course.is_gap(k.progress) and k.jump_height>0 and not feature.id in airborne[k.racer_name]: airborne[k.racer_name].append(feature.id)
     for jump in course.features:
      if jump.has("landing") and k.progress>jump.landing and k.jump_height==0 and not jump.id in landed[k.racer_name]: landed[k.racer_name].append(jump.id)
    ticks+=1
   check(race.done,"Actual autonomous race reaches finish")
   for k in race.racers:
    check(visited[k.racer_name].size()==7,"Player and every AI drive every feature")
    check(airborne[k.racer_name].size()==3 and landed[k.racer_name].size()==3,"Player and all AI launch and land on all three jumps")
   results[Catalog.track_id(i)]={"length":track.length,"ratio":track.length/baseline[str(i%6)].length,"ticks":ticks,"visited":visited,"airborne":airborne,"landed":landed,"min_table_edge_y":min_edge if i==11 else null}
   race.queue_free()
  track.queue_free()
  await process_frame
 var path="user://v2-profile-test.json"
 for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 var legacy=FileAccess.open(path,FileAccess.WRITE)
 legacy.store_string(JSON.stringify({"version":3,"coins":1234,"owned":["toxic-turbo"],"selected_vehicle":"toxic-turbo","character":"ravi","records":{"0":211,"haarlem-1888":212},"settings":{"difficulty":2,"auto_accelerate":true,"music":0.21}}))
 legacy.close()
 var profile=Profile.new(path)
 check(profile.selected==3 and profile.coins==1234 and profile.character=="ravi" and profile.record_for(0)==211 and profile.record_for(3)==212 and profile.settings.difficulty==2 and profile.settings.auto_accelerate,"V3 legacy numeric/string records and all existing player choices survive loading")
 profile.coins=1234
 profile.owned.append("toxic-turbo")
 profile.selected=3
 for i in 12: check(profile.record_race(i,200+i,0),"Persist separate record through real save")
 var reload=Profile.new(path)
 check(reload.selected==3 and reload.coins==1234 and reload.character=="ravi" and reload.settings.music==0.21 and reload.settings.difficulty==2,"Vehicle selection and coins survive V2 save without migration reset")
 for i in 12: check(reload.record_for(i)==200+i,"All twelve records survive reload")
 var file=FileAccess.open("res://validation/tracks-v2-results.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(results,"  "))
 print("BORACER TRACKS V2: %d checks, %d failures"%[checks,failures])
 quit(0 if failures==0 else 1)
