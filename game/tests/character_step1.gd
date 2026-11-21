extends SceneTree
# Read the review candidate directly. Never synchronizes it into game/assets.
var candidate_path := ProjectSettings.globalize_path("res://../persons/boaz/boaz.glb")
var checks := 0
var failures: Array[String] = []
var skeleton: Skeleton3D
var player: AnimationPlayer
var bounds := AABB()
var has_bounds := false
var textured_surfaces := 0

func check(condition: bool, label: String) -> void:
 checks += 1
 if not condition:
  failures.append(label)
  push_error(label)

func _initialize() -> void:
 call_deferred("run")

func inspect_node(node: Node) -> void:
 if node is Skeleton3D:
  skeleton = node
 if node is AnimationPlayer:
  player = node
 if node is MeshInstance3D and node.mesh:
  var box: AABB = node.global_transform * node.mesh.get_aabb()
  check(box.position.is_finite() and box.size.is_finite(), "finite mesh bounds")
  bounds = bounds.merge(box) if has_bounds else box
  has_bounds = true
  for index in node.mesh.get_surface_count():
   var material = node.mesh.surface_get_material(index)
   check(material != null, "surface material present")
   if material:
    check(material.get("albedo_texture") != null, "loaded albedo texture")
    check(material.get("roughness_texture") != null, "loaded roughness texture")
    check(material.get("metallic_texture") != null, "loaded metallic texture")
    textured_surfaces += 1
 for child in node.get_children():
  inspect_node(child)

func run() -> void:
 var document := GLTFDocument.new()
 var state := GLTFState.new()
 var error := document.append_from_file(candidate_path, state)
 check(error == OK, "candidate GLTFDocument import")
 if error != OK:
  quit(1)
  return
 var candidate := document.generate_scene(state)
 check(candidate != null, "candidate runtime scene generated")
 if candidate == null:
  quit(1)
  return
 root.add_child(candidate)
 await process_frame
 inspect_node(candidate)
 check(skeleton != null, "skeleton imported")
 if skeleton:
  check(skeleton.get_bone_count() == 51, "51-bone skeleton preserved")
 check(has_bounds and absf(bounds.size.y - 1.15) < 0.002, "candidate height 1.15 m")
 check(absf(bounds.position.y) < 0.001, "feet on Y=0")
 check(textured_surfaces > 0, "textured character surface present")
 check(state.get_images().size() == 2, "both embedded textures decoded")
 check(player != null, "animation player imported")
 var clips: Array[String] = []
 if player:
  for clip in player.get_animation_list():
   if clip != "RESET": clips.append(clip)
  check(clips.size() == 6, "six animation clips preserved")
  for expected in ["Idle", "Run", "Jump", "Cheer", "Kart_Sit", "Kart_Steer"]:
   check(clips.any(func(clip): return str(clip).get_file() == expected), "clip " + expected)
  var sit := ""
  for clip in clips:
   if clip.get_file() == "Kart_Sit": sit = clip
  if not sit.is_empty() and skeleton:
   var thigh := skeleton.find_bone("thigh.L")
   check(thigh >= 0, "left thigh bone imported")
   var before := skeleton.get_bone_pose_rotation(thigh) if thigh >= 0 else Quaternion.IDENTITY
   player.play(sit)
   player.advance(0.5)
   await process_frame
   check(player.current_animation == sit, "Kart_Sit playback active")
   if thigh >= 0:
    check(not skeleton.get_bone_pose_rotation(thigh).is_equal_approx(before), "Kart_Sit deforms leg pose")
   for index in skeleton.get_bone_count():
    check(skeleton.get_bone_global_pose(index).origin.is_finite(), "finite animated bone pose")
 var report := {"candidate": candidate_path, "Godot_version": Engine.get_version_info().string,
  "runtime_import": "passed" if failures.is_empty() else "failed", "checks": checks,
  "failures": failures, "bounds": str(bounds), "clips": clips,
  "rendering": "headless; no native image or visual gameplay approval"}
 var output := FileAccess.open("/tmp/boracer-character-step1-godot.json", FileAccess.WRITE)
 output.store_string(JSON.stringify(report, "  ") + "\n")
 print("CHARACTER STEP 1 CHECKS: %d; failures: %d" % [checks, failures.size()])
 candidate.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
