extends SceneTree
const Main=preload("res://scripts/main.gd")
const Catalog=preload("res://scripts/catalog.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String):
 checks+=1
 if not ok: failures+=1;push_error(label)
func buttons(node:Node, result:Array):
 if node is Button: result.append(node)
 for child in node.get_children(): buttons(child,result)
func labels(node:Node, result:Array):
 if node is Label: result.append(node.text)
 for child in node.get_children(): labels(child,result)
func _initialize(): call_deferred("run")
func run():
 var game=Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.muted=true
 game.audio.music.stop()
 for version in [1,2]:
  game.ui.world_variant=version
  game.ui.show_worlds()
  var choices=[]
  buttons(game.ui.screen,choices)
  var starts=choices.filter(func(button):return button.text=="Start de race  →")
  check(starts.size()==6,"Each version exposes six keyboard/touch buttons in the existing grid")
  for world in 6:
   game.ui.world_variant=version
   game.ui.show_worlds()
   choices=[]
   buttons(game.ui.screen,choices)
   starts=choices.filter(func(button):return button.text=="Start de race  →")
   starts[world].pressed.emit()
   var index=world+(6 if version==2 else 0)
   check(game.track_index==index and game.world_index==world and game.track.track_index==index and game.track.world_index==world,"Actual selection callback starts the right track with base landscape")
   var texts=[]
   labels(game.ui.hud,texts)
   check(Catalog.track_name(index) in texts,"HUD includes exact world name and V2 version")
   game.race.countdown=0
   game.race.paused=true
   var progress=game.race.player.progress
   game.race.step(.2,1,0,0,false)
   check(game.race.player.progress==progress,"Paused race preserves position")
   game.ui.show_pause()
   choices=[]
   buttons(game.ui.overlay,choices)
   var restart=choices.filter(func(button):return button.text=="Opnieuw starten")
   check(restart.size()==1,"Pause offers actual restart action")
   restart[0].pressed.emit()
   check(game.track_index==index and game.track.track_index==index and game.race.player.progress==-14,"Restart retains exact V1/V2 selection")
   game.go_home()
   check(game.track.track_index==index and game.world_index==world,"Home preview retains track context without converting landscape to V2 index")
   await process_frame
 game.queue_free()
 await process_frame
 print("BORACER TRACKS V2 UI: %d checks, %d failures"%[checks,failures])
 quit(0 if failures==0 else 1)
