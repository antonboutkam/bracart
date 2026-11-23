extends SceneTree
const Main = preload("res://scripts/main.gd")
const Catalog = preload("res://scripts/catalog.gd")
var out := "/home/anton/Documents/sites/boracart/persons/integration-materials-2026-11-21"
var game
var shots: Array[String] = []
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
 for frame in 6:await process_frame
 await RenderingServer.frame_post_draw
 var image := root.get_texture().get_image()
 if image==null or image.is_empty():
  push_error("Empty native capture")
  quit(1)
  return
 var err := image.save_png(out.path_join(name+".png"))
 if err!=OK:
  push_error("Capture save failed")
  quit(1)
  return
 shots.append(name+".png")
 print("GAME CAPTURE ",name)
func run() -> void:
 if DisplayServer.get_name()=="headless":
  push_error("Actual rendering required")
  quit(2)
  return
 root.size=Vector2i(1280,800)
 game=Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.muted=true
 game.audio.music.stop()
 game.profile.selected=Catalog.DEFAULT_VEHICLE
 for id in ["boaz","ravi"]:
  game.profile.character=id
  game.refresh_preview()
  game.ui.show_garage()
  await shot(id+"-garage")
  game.start_race(0)
  game.race.set_process(false)
  game.race.countdown=0
  var kart=game.race.player
  kart.progress=game.track.length*0.035
  kart.speed=20
  kart.update_visual(game.track,0)
  kart.update_effects(.2)
  game._camera(0,true)
  game.ui.update_hud(0)
  await shot(id+"-race")
  game.ui.visible=false
  game.camera.fov=38
  game.camera.global_position=kart.global_transform*Vector3(.9,1.15,-1.8)
  game.camera.look_at(kart.global_transform*Vector3(0,.95,0))
  await shot(id+"-race-close")
  game.ui.visible=true
  game.go_home()
 var file := FileAccess.open(out+"/capture-results.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"images":shots,"display":DisplayServer.get_name(),"Godot":Engine.get_version_info().string,"scope":"Actual garage and race instances using imported game assets; isolated temporary profile."},"  ")+"\n")
 game.queue_free()
 await process_frame
 quit(0 if shots.size()==6 else 1)
