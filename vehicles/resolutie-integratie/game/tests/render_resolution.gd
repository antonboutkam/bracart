extends SceneTree
const Main = preload("res://scripts/main.gd")
const Profile = preload("res://scripts/profile.gd")
var checks = 0
var failures: Array[String] = []

func check(condition: bool, title: String) -> void:
 checks += 1
 if not condition:
  failures.append(title)
  push_error(title)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 if "--visual" in OS.get_cmdline_user_args():
  await capture_settings()
  return
 var profile = Profile.new()
 check(profile.settings.render_height == 0, "Missing setting preserves native resolution")
 profile.settings.render_height = 1080
 check(profile.save_profile(), "Resolution preference saves")
 root.size = Vector2i(3840, 2160)
 var main = Main.new()
 root.add_child(main)
 await process_frame
 main.set_process(false)
 main.set_physics_process(false)
 main.audio.music.stop()
 main.audio.muted = true
 check(is_equal_approx(root.scaling_3d_scale, 0.5), "Saved 1080p preference applies at startup on a 4K window")
 check(root.scaling_3d_mode == Viewport.SCALING_3D_MODE_BILINEAR, "Uses the Compatibility renderer's supported scaling mode")
 main.ui.show_settings()
 await process_frame
 var choice = main.ui.screen.find_child("RenderResolution", true, false)
 check(choice is OptionButton and choice.get_selected_id() == 1080, "Settings show the saved resolution")
 var ui_scale: Vector2 = main.ui.layout_root.scale
 var stretch_size: Vector2i = root.content_scale_size
 for entry in [[0, 1.0], [1800, 1800.0 / 2160], [1440, 2.0 / 3], [1200, 1200.0 / 2160], [1080, 0.5], [900, 900.0 / 2160], [720, 1.0 / 3], [540, 0.25]]:
  var index: int = choice.get_item_index(entry[0])
  choice.select(index)
  choice.item_selected.emit(index)
  check(is_equal_approx(root.scaling_3d_scale, entry[1]), "Dropdown immediately applies %dp" % entry[0])
  check(Profile.new().settings.render_height == entry[0], "Dropdown persists %dp" % entry[0])
 check(root.size == Vector2i(3840, 2160) and root.content_scale_size == stretch_size and main.ui.layout_root.scale == ui_scale, "Resolution choice preserves window size and sharp UI layout")
 root.size = Vector2i(1920, 1080)
 await process_frame
 check(is_equal_approx(root.scaling_3d_scale, 0.5), "540p scales a 16:9 window without changing its aspect")
 check(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_EXPAND, "Widescreen expands the world instead of cropping it")
 check(root.get_visible_rect().size.x > 1400, "16:9 displays a wider world than the 16:10 base")
 var widescreen_rect: Rect2 = main.ui.layout_root.get_global_rect()
 check(root.get_visible_rect().encloses(widescreen_rect), "Complete UI remains visible on widescreen")
 main.profile.settings.render_height = 720
 main.apply_render_resolution()
 root.size = Vector2i(1280, 720)
 await process_frame
 check(is_equal_approx(root.scaling_3d_scale, 1.0), "Smaller windows are never upscaled internally")
 root.size = Vector2i(2560, 1440)
 await process_frame
 check(is_equal_approx(root.scaling_3d_scale, 0.5), "Resize recalculates the saved 720p cap")
 main.start_monster()
 check(is_equal_approx(root.scaling_3d_scale, 0.5), "Monsterbreker keeps the chosen rendering resolution")
 main.go_home()
 main.start_race(0)
 check(is_equal_approx(root.scaling_3d_scale, 0.5), "Normal races keep the chosen rendering resolution")
 main.go_home()
 root.size = Vector2i(1280, 800)
 main.ui.show_settings()
 await process_frame
 await process_frame
 var scroll: ScrollContainer = main.ui.screen.find_children("*", "ScrollContainer", true, false)[0]
 check(scroll.follow_focus and scroll.get_global_rect().end.y <= main.ui.layout_root.get_global_rect().end.y, "Settings scroll inside the page and follow keyboard focus")
 main.queue_free()
 await process_frame
 for invalid in [-1, 9999, "720", true, [], 720.5]:
  var file = FileAccess.open("user://invalid-resolution.json", FileAccess.WRITE)
  file.store_string(JSON.stringify({"version":3, "settings":{"render_height":invalid}}))
  file.close()
  check(Profile.new("user://invalid-resolution.json").settings.render_height == 0, "Invalid resolution safely falls back: " + str(invalid))
 for path in ["user://profile.json", "user://invalid-resolution.json"]:
  for suffix in ["", ".bak", ".tmp"]:
   DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
 print("RENDER RESOLUTION: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)

func capture_settings() -> void:
 # The 4K resize assertions run headless; this native capture checks only the UI.
 root.size = Vector2i(1280, 800)
 root.disable_3d = true
 var main = Main.new()
 root.add_child(main)
 main.set_process(false)
 main.set_physics_process(false)
 main.audio.music.stop()
 main.audio.muted = true
 main.profile.settings.render_height = 720
 main.apply_render_resolution()
 main.ui.show_settings()
 for i in 4:
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/boracart-resolution-settings.png")
 print("CAPTURED resolution settings")
 main.queue_free()
 await process_frame
 quit()
