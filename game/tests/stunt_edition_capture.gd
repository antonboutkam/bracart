extends SceneTree
const Main=preload("res://scripts/main.gd")
var output:String
var subjects:Array[Dictionary]=[]
var game
var failures:=0
func _initialize(): call_deferred("run")
func capture(filename:String,label:String):
 for frame in 3: await process_frame
 await RenderingServer.frame_post_draw
 if root.get_texture().get_image().save_png(output.path_join(filename+".png"))!=OK: failures+=1
 subjects.append({"filename":filename+".png","label":label,"category":"ui"})
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
 for variant in [1,2]:
  game.ui.world_variant=variant
  game.ui.show_worlds()
  await capture("selectie-"+str(variant),"Baanselectie · "+("Versie 1" if variant==1 else "Stunt Edition"))
  game.start_race(5 if variant==1 else 11)
  game.race.set_process(false)
  game.race.countdown=0
  game.ui.update_hud(0)
  await capture("cockpit-"+str(variant),"Cockpit · De Keukentafel · "+("Versie 1" if variant==1 else "Stunt Edition"))
  game.go_home()
  await capture("home-"+str(variant),"Dashboard Racen-tegel · "+("Versie 1" if variant==1 else "Stunt Edition"))
 var file=FileAccess.open(output.path_join("subjects.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(subjects,"  "))
 print("STUNT EDITION CAPTURES=",subjects.size()," failures=",failures)
 game.queue_free()
 await process_frame
 quit(0 if failures==0 and subjects.size()==6 else 1)
