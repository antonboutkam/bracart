extends SceneTree
const Main = preload("res://scripts/main.gd")
const Collection = preload("res://scripts/monster/catalog.gd")
var checks = 0
var failures: Array[String] = []
var game
var visual: bool = false

func _initialize() -> void:
 call_deferred("run")

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures.append(message)
  push_error(message)

func controlled(id: String):
 game.start_monster(id, 2)
 var mode = game.monster_mode
 mode.set_process(false)
 mode.set_physics_process(false)
 return mode

func capture(label: String, mode) -> void:
 if not visual:
  return
 mode._camera(0, true)
 mode.refresh_ui()
 for i in 3:
  if mode.paused: mode.toggle_pause()
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/boracart-impact-" + label + ".png")

func run() -> void:
 visual = "--visual" in OS.get_cmdline_user_args()
 game = Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.music.stop()
 game.audio.muted = true
 await process_frame
 for id in [Collection.DEFAULT_ID, "gifspuwer-breekbaar"]:
  var mode = controlled(id)
  mode.action()
  for i in 1800:
   mode.step(1.0 / 60)
   if mode.phase == "replay": break
  check(mode.phase == "replay" and mode.hit_count > 0, id + ": real hit automatically starts replay after splash")
  if mode.phase != "replay": continue
  var replay = mode.impact_replay
  check(replay.frames.size() <= 101 and replay.frames[0].time < replay.hit_time - 0.7 and replay.frames.back().time > replay.hit_time + 2.3, "Recording is bounded and includes approach and falling debris")
  check(mode.title.text == "IMPACT REPLAY" and not mode.action_button.disabled, "Replay is clearly labelled and can be skipped")
  check(not mode.arena.standing.visible and replay.visible and not mode.rocket.visible and not mode.rings.visible, "Playback hides the live dynamic scene")
  var score_before: Array = mode.scores.duplicate()
  var submerged_before: int = mode.arena.submerged
  var cells_before: Dictionary = mode.arena.structure.cells.duplicate()
  var chunks_before: Array = []
  for chunk in mode.arena.chunks:
   chunks_before.append(chunk.node.transform)
  var rocket_before: Transform3D = mode.rocket.transform
  var birds_before: float = mode.birds.elapsed
  var time_before: float = mode.turn_time
  var sounds_before: Dictionary = mode.sounds.counts.duplicate()
  mode._camera(0, true)
  var camera_before: Transform3D = game.camera.transform
  check(absf(game.camera.position.x) > 55 and game.camera.position.distance_to(replay.hit_position) > 70 and game.camera.is_position_in_frustum(replay.hit_position), "External camera frames the impact from the side and farther away")
  await capture(id + "-approach", mode)
  mode.toggle_pause()
  var play_before: float = replay.playback_time
  mode.step(0.25)
  mode._process(0.25)
  check(replay.playback_time == play_before and game.camera.transform == camera_before, "Pause freezes replay and camera")
  mode.toggle_pause()
  for i in 90: mode.step(1.0 / 60, 1, 0, 1, true)
  check(replay.playback_time > play_before + 0.8 and replay.playback_time < play_before + 1, "Playback runs at 60 percent speed")
  check(mode.scores == score_before and mode.arena.submerged == submerged_before and mode.arena.structure.cells == cells_before, "Replay never changes score or damage")
  check(mode.rocket.transform == rocket_before and mode.birds.elapsed == birds_before and mode.turn_time == time_before and mode.sounds.counts == sounds_before, "Live flight, birds, timer and audio stay frozen")
  var frozen = mode.arena.chunks.size() == chunks_before.size()
  for i in chunks_before.size():
   frozen = frozen and mode.arena.chunks[i].node.transform == chunks_before[i]
  check(frozen, "Live debris does not advance during replay")
  var frame: Dictionary = replay.frames[replay.frame_index]
  var matched = 0
  for key in frame.poses:
   if replay.copies[key].visible: matched += 1
  check(matched == frame.poses.size(), "Visible replay geometry matches the recorded frame")
  await capture(id + "-impact", mode)
  for i in 75: mode.step(1.0 / 60)
  await capture(id + "-debris", mode)
  if id == Collection.DEFAULT_ID:
   mode.action()
   check(mode.phase == "settling" and not replay.playing, "Skip returns immediately to live settlement")
  else:
   for i in 300:
    mode.step(1.0 / 60)
    if mode.phase != "replay": break
   check(mode.phase == "settling" and not replay.playing, "Replay finishes automatically")
  check(not replay.visible and mode.arena.standing.visible and mode.birds.visible and mode.rings.visible and not mode.rocket.visible, "Original scene visibility is restored after playback")
  for i in 1200:
   mode.step(1.0 / 60)
   if mode.phase in ["between", "finished"]: break
  check(mode.phase == "between" and replay.played, "A hit replays only once before handoff")
  mode.action()
  check(mode.player == 1 and mode.phase == "ready" and replay.frames.is_empty() and replay.copies.is_empty(), "Next player starts with a cleared recording")
  mode.action()
  for i in 1800:
   mode.step(1.0 / 60, 1, 0, 1, true)
   if mode.phase in ["between", "finished", "replay"]: break
  check(mode.phase == "between" and mode.hit_count == 0 and not replay.played, "A miss does not trigger an impact replay")
  await process_frame
 game.queue_free()
 await process_frame
 await process_frame
 print("IMPACT REPLAY: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
