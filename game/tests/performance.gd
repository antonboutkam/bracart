extends SceneTree
## Native rendered sample. Run WITHOUT --headless; results go to /tmp/boracer-performance.
const Main = preload("res://scripts/main.gd")
const Catalog = preload("res://scripts/catalog.gd")
const WARMUP_FRAMES = 45
const SAMPLE_FRAMES = 150
var folder = "/tmp/boracer-performance"
var game
var canvas: SubViewport

func _initialize() -> void:
 call_deferred("run")

func percentile(values: Array[float], fraction: float) -> float:
 var sorted = values.duplicate()
 sorted.sort()
 return sorted[clampi(int((sorted.size() - 1) * fraction), 0, sorted.size() - 1)]

func run() -> void:
 if DisplayServer.get_name() == "headless":
  push_error("Performance samples need a native rendering display; omit --headless.")
  quit(1)
  return
 DirAccess.make_dir_recursive_absolute(folder)
 DisplayServer.window_set_size(Vector2i(1280, 800))
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 Engine.max_fps = 0
 canvas = SubViewport.new()
 canvas.size = Vector2i(1280, 800)
 canvas.own_world_3d = true
 canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(canvas)
 var preview_texture = TextureRect.new()
 preview_texture.texture = canvas.get_texture()
 preview_texture.size = Vector2(1280, 800)
 root.add_child(preview_texture)
 game = Main.new()
 canvas.add_child(game)
 game.audio.muted = true
 game.audio.music.stop()
 var report = {"renderer":RenderingServer.get_current_rendering_method(),
  "adapter":RenderingServer.get_video_adapter_name(), "resolution":"1280x800",
  "vsync":false, "shadows":true, "warmup_frames":WARMUP_FRAMES,
  "sample_frames":SAMPLE_FRAMES, "simulation":"native engine physics ticks",
  "route_sampling":"three route thirds, camera snapped after relocation",
  "worlds":[]}
 for world in Catalog.WORLDS.size():
  game.profile.selected = world
  var build_start = Time.get_ticks_usec()
  game.start_race(world)
  var build_ms = (Time.get_ticks_usec() - build_start) / 1000.0
  game.race.countdown = 0
  game.race.auto_drive = true
  for frame in WARMUP_FRAMES:
   await process_frame
   await RenderingServer.frame_post_draw
  var frame_times: Array[float] = []
  var peak_draws: int = 0
  var peak_objects: int = 0
  var peak_primitives: int = 0
  var simulation_usec: int = 0
  for frame in SAMPLE_FRAMES:
   if frame in [50, 100]:
    # Three local gameplay views instead of drawing only the starting straight.
    var sector = 1 if frame == 50 else 2
    for index in game.race.racers.size():
     var kart = game.race.racers[index]
     kart.progress = game.track.length * sector / 3.0 - index * 3
     kart.update_visual(game.track, 0)
    game._camera(0, true)
    for settling_frame in 4:
     await process_frame
     await RenderingServer.frame_post_draw
   var started = Time.get_ticks_usec()
   await process_frame
   await RenderingServer.frame_post_draw
   simulation_usec += int(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000000)
   frame_times.append((Time.get_ticks_usec() - started) / 1000.0)
   peak_draws = maxi(peak_draws, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
   peak_objects = maxi(peak_objects, int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
   peak_primitives = maxi(peak_primitives, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
  var total_ms: float = 0
  for frame_ms in frame_times:
   total_ms += frame_ms
  var item = {"id":Catalog.world_id(world), "build_ms":build_ms,
   "average_ms":total_ms / SAMPLE_FRAMES, "p50_ms":percentile(frame_times, 0.5),
   "p95_ms":percentile(frame_times, 0.95), "max_ms":frame_times.max(),
   "physics_process_mean_ms":simulation_usec / float(SAMPLE_FRAMES) / 1000.0,
   "draw_calls_peak":peak_draws, "render_objects_peak":peak_objects,
   "primitives_peak":peak_primitives,
   "simulated_seconds":game.race.elapsed, "race_paused":game.race.paused,
   "camera_distance_to_player":game.camera.position.distance_to(game.race.player.position),
   "nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
   "objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),
   "resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
   "static_memory_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),
   "video_memory_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))}
  report.worlds.append(item)
  canvas.get_texture().get_image().save_png(folder.path_join(item.id + ".png"))
  print("PERFORMANCE ", JSON.stringify(item))
  game.go_home()
  for frame in 5:
   await process_frame
 var file = FileAccess.open(folder.path_join("performance.json"), FileAccess.WRITE)
 file.store_string(JSON.stringify(report, "  "))
 file.close()
 preview_texture.texture = null
 preview_texture.queue_free()
 game.queue_free()
 await process_frame
 canvas.queue_free()
 await process_frame
 await process_frame
 print("PERFORMANCE REPORT ", folder.path_join("performance.json"))
 quit()
