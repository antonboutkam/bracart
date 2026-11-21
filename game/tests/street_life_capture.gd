extends SceneTree
## Native views of the actual five outdoor tracks; validation creates no images.
const Main = preload("res://scripts/main.gd")
const Catalog = preload("res://scripts/catalog.gd")
var output: String
var validate_only := false
var failures := 0
var scenarios := 0

func _initialize() -> void:
 call_deferred("run")

func shot(filename: String) -> void:
 scenarios += 1
 if validate_only:
  await process_frame
  var camera := root.get_camera_3d()
  if camera == null or not camera.global_transform.is_finite(): failures += 1
  print("STREET LIFE SETUP ",filename," (no image)")
  return
 for frame in 10: await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 if picture.is_empty() or picture.save_png(output.path_join(filename+".png")) != OK:
  failures += 1
 print("STREET LIFE CAPTURE ",filename)

func stage_race_view(game, clusters: Array) -> Dictionary:
 # Choose a real road pose from which a populated cluster lies ahead in frame.
 var chosen: Dictionary = clusters[0]
 var progress: float = float(chosen.progress)
 var best_distance := INF
 for candidate in clusters:
  if candidate.walkspec.is_empty(): continue
  for offset in [35.0,55.0,80.0,110.0,145.0,180.0]:
   game.race.player.progress = fposmod(float(candidate.progress)-offset,game.track.length)
   game.race.player.update_visual(game.track,0)
   game._camera(0,true)
   var target: Vector3 = candidate.center+Vector3.UP*3
   if not game.camera.is_position_in_frustum(target): continue
   var screen: Vector2 = game.camera.unproject_position(target)
   var distance: float = game.camera.global_position.distance_to(target)
   if screen.x > 100 and screen.x < 1180 and screen.y > 100 and screen.y < 620 and distance < best_distance:
    best_distance = distance
    chosen = candidate
    progress = game.race.player.progress
 if not is_finite(best_distance): failures += 1
 game.race.player.progress = progress
 game.race.player.update_visual(game.track,0)
 game._camera(0,true)
 print("STREET LIFE race view distance=",best_distance," progress=",progress)
 return chosen

func run() -> void:
 validate_only = "--validate-only" in OS.get_cmdline_user_args()
 output = OS.get_environment("BORACER_CAPTURE_DIR")
 if not validate_only and (output.is_empty() or DisplayServer.get_name() == "headless"):
  push_error("Set BORACER_CAPTURE_DIR and use native Godot rendering")
  quit(2)
  return
 root.size = Vector2i(1280,720)
 var game := Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.muted = true
 game.audio.music.stop()
 game.audio.music.stream = null
 for world in 5:
  game.start_race(world)
  game.race.set_process(false)
  game.race.set_physics_process(false)
  game.race.countdown = 0
  var outdoor = game.track.get_node_or_null("OutdoorLife")
  var walkers = game.track.get_node_or_null("StreetWalkers")
  var clusters: Array = outdoor.get_meta("clusters",[]) if outdoor != null else []
  if clusters.is_empty() or walkers == null:
   failures += 1
   continue
  walkers.set_process(false)
  var cluster: Dictionary = stage_race_view(game,clusters)
  var frame: Transform3D = cluster.transform
  var prefix: String = str(Catalog.WORLDS[world].id)
  game.race.player.speed = 18
  game.race.player.update_visual(game.track,0)
  game.ui.visible = true
  game._camera(0,true)
  game.ui.update_hud(0)
  await shot(prefix+"-racecamera")
  game.ui.visible = false
  game.camera.fov = 58
  game.camera.position = frame * Vector3(19,19,26)
  game.camera.look_at(frame * Vector3(0,2,0))
  await shot(prefix+"-straatinterieur")
  var route: Transform3D = cluster.walkspec.transform
  var walker_center: Vector3 = route.origin
  for actor in walkers.actors:
   if str(actor.node.get_meta("route_id")) == str(cluster.id):
    walker_center = (actor.person.global_position+actor.dog.global_position)*0.5
    break
  game.camera.fov = 44
  game.camera.position = walker_center + route.basis * Vector3(4,3.5,-10)
  game.camera.look_at(walker_center+Vector3.UP*0.9)
  await shot(prefix+"-wandelaar-hond")
  # Same camera at a later deterministic pose demonstrates actual movement.
  for tick in 180: walkers.advance(1.0/60)
  await shot(prefix+"-wandelaar-hond-later")
 game.queue_free()
 await process_frame
 print("STREET LIFE ","SETUP VALIDATION; no images" if validate_only else "CAPTURE COMPLETE","; scenarios=",scenarios,"; failures=",failures)
 quit(0 if failures == 0 and scenarios == 20 else 1)
