extends SceneTree
const Catalog = preload("res://scripts/catalog.gd")
const Profile = preload("res://scripts/profile.gd")
const Kart = preload("res://scripts/kart.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var idx = Catalog.vehicle_index("ufo")
 check(idx >= 0 and idx in Catalog.available_indices(), "UFO is available")
 var save_path = "user://ufo-integration-test.json"
 for ext in ["", ".bak", ".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + ext))
 var profile = Profile.new(save_path)
 check("ufo" in profile.owned, "Free UFO is granted")
 check(profile.buy_or_select(idx), "UFO can be selected")
 check(Profile.new(save_path).selected == idx, "UFO selection survives reload")
 for character in ["boaz", "ravi"]:
  var kart = Kart.new()
  root.add_child(kart)
  kart.setup(idx, character, false)
  check(kart.driver_model != null and kart.wheel_nodes.size() == 4, character + " driver and four wheels")
  kart.speed = 20
  kart.update_effects(.25)
  check(not kart.wheel_nodes[0].basis.is_equal_approx(kart.wheel_rest[0]), character + " wheel rotates")
  kart.queue_free()
  await process_frame
 for ext in ["", ".bak", ".tmp"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + ext))
 print("UFO INTEGRATION failures: ", failures)
 quit(0 if failures == 0 else 1)
