extends SceneTree
const Main=preload("res://scripts/main.gd")
const Catalog=preload("res://scripts/catalog.gd")
var output:String
var subjects:Array[Dictionary]=[]
var game
var failures:=0
func _initialize(): call_deferred("run")
func capture(filename:String,label:String,category:String,extra:Dictionary={}):
 for frame in 3: await process_frame
 await RenderingServer.frame_post_draw
 if root.get_texture().get_image().save_png(output.path_join(filename+".png"))!=OK: failures+=1
 var item={"filename":filename+".png","label":label,"category":category}
 item.merge(extra)
 subjects.append(item)
 print("V2 CAPTURE ",filename)
func run():
 output=OS.get_environment("BORACER_CAPTURE_DIR")
 if output.is_empty() or DisplayServer.get_name()=="headless":
  quit(2)
  return
 root.size=Vector2i(1280,800)
 root.gui_disable_input=true
 game=Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_process_unhandled_input(false)
 game.ui.set_process_input(false)
 game.set_physics_process(false)
 game.audio.muted=true
 game.audio.music.stop()
 game.ui.world_variant=1
 game.ui.show_worlds()
 await capture("selectie-versie-1","Zes oorspronkelijke circuits · Versie 1","ui")
 game.ui.world_variant=2
 game.ui.show_worlds()
 await capture("selectie-versie-2","Zes extra circuits · Versie 2 · aparte records","ui")
 for index in range(6,12):
  game.start_race(index)
  game.race.countdown=0
  game.race.auto_drive=true
  game.race.set_process(false)
  game.camera.far=3000
  var track=game.track
  var id=Catalog.track_id(index)
  game.ui.visible=false
  game.camera.projection=Camera3D.PROJECTION_ORTHOGONAL
  game.camera.size=maxf(track.table_half.y*2.2,track.table_half.x*1.55)
  game.camera.position=Vector3(0,690,310)
  game.camera.look_at(Vector3(0,12,0))
  var fog=game.environment.environment.fog_density
  game.environment.environment.fog_density=fog*0.25
  if index==11:
   game.camera.position=Vector3(0,210,0)
   game.camera.look_at(Vector3.ZERO,Vector3.FORWARD)
  await capture(id+"-overzicht",Catalog.track_name(index)+" · volledig circuit (technische overzichtscamera)","overview",{"track":id,"length":track.length,"posed_camera":true,"overview_fog_factor":0.25,"overview_camera_inside_room":index==11})
  game.environment.environment.fog_density=fog
  game.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
  game.ui.visible=true
  var targets:Array[Dictionary]=[]
  for feature in track.v2_course.features:
   var progress:float=lerpf(feature.lip,feature.end,0.45) if feature.has("lip") else feature.center
   targets.append({"progress":progress,"id":feature.id,"name":feature.name})
   if feature.id=="mega_jump": targets.append({"progress":feature.landing+1.0,"id":"mega_landing","name":"Megaschans · contact op de landingsbaan"})
  targets.sort_custom(func(a,b):return a.progress<b.progress)
  var target_index=0
  var ticks=0
  while target_index<targets.size() and ticks<4000:
   game.race.step(1.0/30,1,0,0,false)
   game.follow_camera.update(track,game.race.player,1.0/30,true,false)
   var target:Dictionary=targets[target_index]
   if game.race.player.progress>=target.progress:
    game.ui.update_hud(0)
    var kart=game.race.player
    await capture(id+"-"+target.id,Catalog.track_name(index)+" · "+target.name+" · echte auto-drive/racecamera","gameplay",{"track":id,"feature":target.id,"progress":kart.progress,"jump_height":kart.jump_height,"up_y":track.frame(kart.progress).basis.y.y,"source":"continuous Race.step from starting grid"})
    target_index+=1
   ticks+=1
  if target_index!=targets.size(): failures+=1
  print("V2 DRIVE ",id," ticks=",ticks," captured=",target_index," progress=",game.race.player.progress," paused=",game.race.paused," done=",game.race.done)
 var file=FileAccess.open(output.path_join("subjects.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(subjects,"  "))
 print("V2 CAPTURES=",subjects.size()," failures=",failures)
 game.queue_free()
 await process_frame
 quit(0 if failures==0 and subjects.size()==56 else 1)
