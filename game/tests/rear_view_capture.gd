extends SceneTree
const Main=preload("res://scripts/main.gd")
var output:String
var subjects:Array[Dictionary]=[]
var game
var failures:=0
func _initialize(): call_deferred("run")
func capture(filename:String,label:String):
 for frame in 4: await process_frame
 await RenderingServer.frame_post_draw
 if root.get_texture().get_image().save_png(output.path_join(filename+".png"))!=OK: failures+=1
 subjects.append({"filename":filename+".png","label":label,"category":"rear-view"})
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
 game.set_physics_process(false)
 game.audio.muted=true
 game.audio.music.stop()
 for index in 6:
  game.profile.selected=index
  game.start_race(0)
  game.race.set_process(false)
  game.race.countdown=0
  game.race.player.progress=25
  game.race.player.update_visual(game.track,0)
  game.ui.hud.hide()
  var kart=game.race.player
  var f:Transform3D=game.track.frame(kart.progress)
  game.camera.position=kart.position+f.basis*Vector3(2.7,1.8,3.1)
  game.camera.look_at(kart.position+f.basis.y*0.65,f.basis.y)
  game.camera.fov=37
  await capture("spiegels-"+str(index),"Twee fysieke spiegels · "+str(game.Catalog.VEHICLES[index].name))
 game.ui.hud.show()
 game._camera(0,true)
 await capture("vooruit","Vooruitbeeld · C of LB vasthouden voor achterom")
 Input.action_press("rear_look")
 game._camera(0,true)
 await capture("achterom","Achteruit als hoofdbeeld · actueel vooruitbeeld in venster")
 game.race.player.progress+=20
 game.race.player.update_visual(game.track,0)
 game._camera(0,true)
 await capture("achterom-verder","Beide camera's volgen het voertuig tijdens achterom kijken")
 Input.action_release("rear_look")
 game._camera(0)
 await capture("losgelaten","Losgelaten · direct terug naar vooruitbeeld")
 var file=FileAccess.open(output.path_join("subjects.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(subjects,"  "))
 game.queue_free()
 await process_frame
 print("REAR VIEW CAPTURES=",subjects.size()," failures=",failures)
 quit(0 if failures==0 and subjects.size()==10 else 1)
