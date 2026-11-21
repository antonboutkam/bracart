extends SceneTree
const Race = preload("res://scripts/race.gd")
const Main = preload("res://scripts/main.gd")
var game
var subjects: Array[Dictionary] = []
var output: String
var failures := 0
func _initialize(): call_deferred("run")
func run():
 output = OS.get_environment("BORACER_CAPTURE_DIR")
 if output.is_empty() or DisplayServer.get_name()=="headless":
  quit(2)
  return
 root.size = Vector2i(1280,800)
 game = Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.muted = true
 game.audio.music.stop()
 game.start_race(7)
 game.race.set_process(false)
 for index in 6:
  game.profile.character = "boaz" if index%2==0 else "ravi"
  game.profile.selected = index
  game.profile.owned = ["raketfiets","purple-passion","golden-rocket-racer","toxic-turbo","retro","rainbow"]
  game.ui.clear(game.ui.overlay)
  game.race.free()
  game.race = Race.new()
  game.add_child(game.race)
  game.race.setup(game.track,index,game.profile.character,0)
  game.race.set_process(false)
  game.race.rank = 1
  game.race.done = true
  game.race.reward = 50
  game.race.elapsed = 87.25
  game.race.lap_times.assign([28.0,30.0,29.25])
  game.race.player.finish_time = 87.25
  game._finish()
  var podium = game.ui.overlay.find_child("VictoryPodium",true,false)
  podium.set_process(false)
  for moment in [0.0,0.55,1.25]:
   podium.age = moment
   podium._pose()
   for frame in 4: await process_frame
   await RenderingServer.frame_post_draw
   var filename: String = "%s-vehicle-%d-%03d.png" % [game.profile.character,index,roundi(moment*100)]
   failures += int(root.get_texture().get_image().save_png(output.path_join(filename)) != OK)
   subjects.append({"filename":filename,"label":"%s • %s • %.2f s" % [game.profile.character.capitalize(),game.race.player.racer_name+" / "+str(index),moment],"category":"victory-podium","character":game.profile.character,"vehicle_index":index,"animation":podium.cheer,"time":moment,"sole_y":podium.winner.position.y+podium.sole_height,"panel_bottom":game.ui.overlay.get_child(1).get_global_rect().end.y})
 var f = FileAccess.open(output.path_join("subjects.json"),FileAccess.WRITE)
 f.store_string(JSON.stringify(subjects,"  "))
 game.queue_free()
 await process_frame
 print("PODIUM CAPTURE ",subjects.size()," failures ",failures)
 quit(0 if failures==0 else 1)
