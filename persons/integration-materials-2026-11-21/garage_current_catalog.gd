extends SceneTree
## Captures actual runtime studio previews; headless validates scene ownership only.
const Catalog = preload("res://scripts/catalog.gd")
const Main = preload("res://scripts/main.gd")
const Preview = preload("res://scripts/ui/vehicle_preview.gd")
const Profile = preload("res://scripts/profile.gd")
var failures = 0
var checks = 0
var canvas: SubViewport

func _initialize() -> void:
 call_deferred("run")

func check(value: bool, description: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(description)

func find_previews(node: Node) -> Array:
 var result: Array = []
 for child in node.get_children():
  if child is Preview:
   result.append(child)
  result.append_array(find_previews(child))
 return result

func shot(name_value: String) -> void:
 for frame in 12:
  await process_frame
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  canvas.get_texture().get_image().save_png("/tmp/boracer-garage-studio/" + name_value + ".png")

func run() -> void:
 DirAccess.make_dir_recursive_absolute("/tmp/boracer-garage-studio")
 canvas = SubViewport.new()
 canvas.size = Vector2i(1280, 800)
 canvas.own_world_3d = true
 canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(canvas)
 var game = Main.new()
 canvas.add_child(game)
 await process_frame
 game.set_physics_process(false)
 game.profile = Profile.new("user://garage-studio-validation.json")
 game.audio.muted = true
 game.audio.music.stop()
 game.ui.show_garage()
 await shot("garage")
 var cards = find_previews(game.ui.screen)
 check(cards.size() == Catalog.VEHICLES.size()+1, "All current vehicles plus the selected vehicle have actual 3D studios")
 for preview in cards:
  check(preview.viewport.own_world_3d, "Vehicle studio lighting cannot change race world")
  check(preview.viewport.msaa_3d == Viewport.MSAA_4X, "Vehicle silhouettes use multisampling")
  check(preview.viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "Visible cards continuously render real rotation")
  check(preview.studio.kart.driver_mount != null, "Seated selected driver is present")
  check(preview.viewport.size == Vector2i(676, 184), "Cards use bounded supersampled resolution at display size")
 for index in Catalog.VEHICLES.size():
  game.ui.show_vehicle(index)
  await shot("vehicle-%d" % index)
  var heroes = find_previews(game.ui.screen)
  check(heroes.size() == 1, "Detail uses an isolated actual 3D hero")
  if heroes.size() == 1:
   check(heroes[0].studio.kart.vehicle_index == index, "Hero matches requested vehicle")
   var before: float = heroes[0].studio.kart.rotation.y
   heroes[0].rotate_vehicle(1)
   check(is_equal_approx(heroes[0].studio.kart.rotation.y, before + PI / 6), "Rotate reveals another side of the actual model")
   heroes[0].rotate_vehicle(-1)
   check(is_equal_approx(heroes[0].studio.kart.rotation.y, before), "Reverse rotation restores orientation")
 game.ui.show_garage()
 await process_frame
 check(find_previews(game.ui.screen).size() == Catalog.VEHICLES.size()+1, "Returning from details restores garage cards and the selected vehicle")
 game.queue_free()
 for frame in 8:
  await process_frame
 canvas.queue_free()
 for frame in 4:
  await process_frame
 print("BORACER GARAGE STUDIO: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
