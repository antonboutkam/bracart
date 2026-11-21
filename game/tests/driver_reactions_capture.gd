extends SceneTree
const Main = preload("res://scripts/main.gd")
var output: String
var subjects: Array[Dictionary] = []
var failures := 0
var game
func _initialize() -> void: call_deferred("run")
func advance(kart, seconds: float) -> void:
 for frame in roundi(seconds*60): kart.update_effects(1.0/60)
func capture(kart, label: String) -> void:
 for close in ([0,1,2] if label in ["00-neutraal","05-turbo"] else [0,1]):
  game.ui.show_hud()
  game.ui.update_hud(0)
  game.ui.visible = close == 0
  if close:
   game.camera.fov = 32
   game.camera.global_position = kart.global_transform * Vector3(0.65,1.12,1.75)
   game.camera.look_at(kart.global_transform * Vector3(0,0.98,0))
   if close == 2:
    game.camera.global_position = kart.global_transform * Vector3(1.7,0.98,-0.5)
    game.camera.look_at(kart.global_transform * Vector3(0,0.65,0))
  else:
   game._camera(0,true)
  var name: String = kart.driver+"-"+label+("-side" if close == 2 else ("-close" if close else "-race"))
  for frame in 3: await process_frame
  await RenderingServer.frame_post_draw
  if root.get_texture().get_image().save_png(output.path_join(name+".png")) != OK: failures += 1
  subjects.append({"filename":name+".png","label":kart.driver.capitalize()+" • "+label+(" • gezicht/romp" if close else " • gewone racecamera"),"category":"driver-reactions","turn":kart.reactions.turn_weight,"wink":kart.reactions.wink_weight,"boost":kart.reactions.boost_weight})
  print("REACTION CAPTURE ",name)
func run() -> void:
 output = OS.get_environment("BORACER_CAPTURE_DIR")
 if output.is_empty() or DisplayServer.get_name()=="headless":
  quit(2)
  return
 root.size = Vector2i(1280,800)
 game = Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.muted=true
 game.audio.music.stop()
 for character in ["boaz","ravi"]:
  game.profile.character = character
  game.start_race(3)
  game.race.set_process(false)
  game.race.countdown=-2
  var kart = game.race.player
  # The actual player instance, action handler and follow camera remain in use.
  kart.progress=game.track.length*0.035
  kart.speed=20
  kart.update_visual(game.track,0)
  kart.update_effects(0.2)
  game.ui.update_hud(0)
  await capture(kart,"00-neutraal")
  game.race.fire(kart,"rocket")
  advance(kart,0.14)
  await capture(kart,"01-aanloop")
  advance(kart,0.31)
  await capture(kart,"02-knipoog")
  advance(kart,0.43)
  await capture(kart,"03-terugkeer")
  advance(kart,0.62)
  await capture(kart,"04-hersteld")
  kart.boost_time=2
  advance(kart,0.3)
  await capture(kart,"05-turbo")
  game.race.fire(kart,"rocket")
  advance(kart,0.45)
  await capture(kart,"06-turbo-knipoog")
  kart.boost_time=0
  advance(kart,1.6)
  await capture(kart,"07-losgelaten")
 var file = FileAccess.open(output.path_join("subjects.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(subjects,"  "))
 print("REACTION CAPTURES=",subjects.size()," failures=",failures)
 game.queue_free()
 await process_frame
 quit(0 if failures==0 and subjects.size()==36 else 1)
