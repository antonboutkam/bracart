# Execute in a temporary Godot project containing the five improved GLBs.
# godot --headless --path /tmp/boracer-vehicle-import --script /absolute/path/to/this.gd -- /absolute/path/to/vehicles
extends SceneTree

var mesh_count := 0
var surface_count := 0
var wheel_count := 0
var names: Array[String] = []

func inspect(node: Node) -> void:
 names.append(str(node.name))
 if str(node.name).begins_with("Wheel_") and not node is MeshInstance3D:
  wheel_count += 1
 if node is MeshInstance3D:
  mesh_count += 1
  assert(node.mesh != null, "Missing mesh")
  for i in node.mesh.get_surface_count():
   assert(node.get_active_material(i) != null, "Missing imported material")
   surface_count += 1
 for child in node.get_children():
  inspect(child)

func _initialize() -> void:
 var args := OS.get_cmdline_user_args()
 assert(args.size() == 1, "Expected output vehicles directory")
 for vehicle in ["golden-rocket-racer", "purple-passion", "rainbow", "raketfiets", "retro"]:
  mesh_count = 0
  surface_count = 0
  wheel_count = 0
  names.clear()
  var scene = load("res://%s-improved.glb" % vehicle)
  assert(scene is PackedScene, "GLB did not import as PackedScene")
  var model = scene.instantiate()
  assert(model != null)
  root.add_child(model)
  inspect(model)
  assert(mesh_count > 0 and wheel_count == 3, "Mesh or wheel hierarchy missing")
  if vehicle == "raketfiets":
   assert("Flag_Cloth" in names and "Flag_Pivot" in names)
  if vehicle == "purple-passion":
   assert("Beacon_Emissive_Orb" in names)
  var report = {"godot_version": Engine.get_version_info().string, "packed_scene_loaded": true, "instantiated": true, "mesh_instances": mesh_count, "material_surfaces_checked": surface_count, "wheel_pivots": wheel_count, "checks_passed": true, "scope": "Headless Godot editor import and scene instantiation; no visual lighting, physics or driving test."}
  var file = FileAccess.open(args[0].path_join(vehicle).path_join("source/godot-import-report.json"), FileAccess.WRITE)
  assert(file != null)
  file.store_string(JSON.stringify(report, "  "))
  file.close()
  print("GODOT_IMPORT_OK ", vehicle, " meshes=", mesh_count, " wheels=", wheel_count)
  model.free()
 quit(0)
