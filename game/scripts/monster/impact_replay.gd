extends Node3D
## Visual recording only: playback never runs collisions, scoring or game audio.
const BEFORE = 0.8
const AFTER = 2.4
const SAMPLE_INTERVAL = 1.0 / 30
const PLAYBACK_SPEED = 0.6
var frames: Array = []
var copies: Dictionary = {}
var references: Dictionary = {}
var hidden_roots: Array = []
var elapsed: float = 0
var sample_time: float = 0
var hit_time: float = -1
var hit_position = Vector3.ZERO
var played: bool = false
var playing: bool = false
var playback_time: float = 0
var frame_index: int = 0

func reset() -> void:
 finish()
 for copy in copies.values():
  copy.queue_free()
 copies.clear()
 references.clear()
 frames.clear()
 elapsed = 0
 sample_time = 0
 hit_time = -1
 played = false
 hide()

func mark_hit(at: Vector3) -> void:
 if hit_time < 0:
  hit_time = elapsed
  hit_position = at
  sample_time = SAMPLE_INTERVAL

func pending() -> bool:
 return hit_time >= 0 and not played

func complete() -> bool:
 return pending() and elapsed >= hit_time + AFTER and frames.size() > 1

func visual_roots(mode) -> Array:
 var roots: Array = [mode.rocket, mode.birds, mode.arena.standing]
 if "piece_root" in mode.arena:
  roots.append(mode.arena.piece_root)
 for chunk in mode.arena.chunks:
  roots.append(chunk.node)
 for splash in mode.arena.splashes:
  roots.append(splash.node)
 return roots

func record(delta: float, mode) -> void:
 if played or complete():
  return
 elapsed += delta
 sample_time += delta
 if sample_time < SAMPLE_INTERVAL and not frames.is_empty():
  return
 sample_time = 0
 var poses: Dictionary = {}
 for source in visual_roots(mode):
  if is_instance_valid(source):
   # Cockpit-only debris hiding must not hide debris in the external replay.
   var show_root: bool = source.visible or source.get_parent() == mode.arena
   _capture(source, show_root, poses)
 frames.append({"time":elapsed, "poses":poses})
 while hit_time < 0 and frames.size() > 1 and frames[1].time < elapsed - BEFORE:
  var old: Dictionary = frames.pop_front()
  for id in old.poses:
   references[id] -= 1
   if references[id] == 0:
    copies[id].queue_free()
    copies.erase(id)
    references.erase(id)

func _capture(source: Node, shown: bool, poses: Dictionary) -> void:
 if not shown:
  return
 if source is MeshInstance3D or source is MultiMeshInstance3D:
  var id = source.get_instance_id()
  if not copies.has(id):
   # Share immutable meshes/materials; retain them when live debris is freed.
   var copy = source.duplicate(0)
   for child in copy.get_children():
    child.free()
   copy.set_script(null)
   add_child(copy)
   copy.hide()
   copies[id] = copy
   references[id] = 0
  poses[id] = {"transform":source.global_transform, "transparency":source.transparency}
  references[id] += 1
 for child in source.get_children():
  _capture(child, child.visible if child is Node3D else true, poses)

func begin(mode) -> void:
 played = true
 playing = true
 playback_time = frames[0].time
 frame_index = 0
 for source in visual_roots(mode):
  if is_instance_valid(source):
   hidden_roots.append({"node":source, "visible":source.visible})
   source.hide()
 show()
 _show_frame()

func advance(delta: float) -> bool:
 playback_time = minf(playback_time + delta * PLAYBACK_SPEED, frames.back().time)
 _show_frame()
 return playback_time >= frames.back().time

func _show_frame() -> void:
 while frame_index + 1 < frames.size() and frames[frame_index + 1].time <= playback_time:
  frame_index += 1
 var frame: Dictionary = frames[frame_index]
 var next: Dictionary = frames[mini(frame_index + 1, frames.size() - 1)]
 var weight = clampf((playback_time - frame.time) / maxf(0.0001, next.time - frame.time), 0, 1)
 for id in copies:
  var copy: GeometryInstance3D = copies[id]
  copy.visible = frame.poses.has(id)
  if not copy.visible:
   continue
  var pose: Dictionary = frame.poses[id]
  var after: Dictionary = next.poses.get(id, pose)
  copy.global_transform = pose.transform.interpolate_with(after.transform, weight)
  copy.transparency = lerpf(pose.transparency, after.transparency, weight)

func finish() -> void:
 for entry in hidden_roots:
  if is_instance_valid(entry.node):
   entry.node.visible = entry.visible
 hidden_roots.clear()
 playing = false
 hide()
