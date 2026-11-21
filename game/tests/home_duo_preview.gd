extends SceneTree
const Duo = preload("res://scripts/ui/home_duo_preview.gd")
const Catalog = preload("res://scripts/catalog.gd")
var checks := 0
var failures := 0
func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures += 1
  if failures < 12:
   push_error(label)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var host := Control.new()
 root.add_child(host)
 var preview := Duo.new()
 host.add_child(preview)
 preview.setup()
 preview.set_process(false)
 check(preview.viewport.size == Vector2i(960,600) and preview.viewport.own_world_3d and preview.viewport.transparent_bg,"Bounded independent transparent viewport")
 check(preview.mouse_filter == Control.MOUSE_FILTER_IGNORE and preview.karts.size() == 2,"Two preview racers cannot intercept menu input")
 for index in 2:
  var kart: Node3D = preview.karts[index]
  check(kart.vehicle_index == Catalog.DEFAULT_VEHICLE and kart.driver == ["boaz","ravi"][index],"Both actual drivers sit on individual Raketfietsen")
  check(kart.driver_model != null and kart.animation != null and kart.driver_state == "sit","Actual runtime sitting animation selected")
 check(preview.find_children("*","AudioStreamPlayer3D",true,false).is_empty(),"Preview has no racing audio")
 for index in 73:
  preview.angle = float(index)/72*TAU
  preview._pose()
  var projected: Array[Vector2] = []
  for k in 2:
   var low: float = INF
   var high: float = -INF
   for corner in 8:
    var point: Vector3 = preview.karts[k].global_transform * preview.model_bounds[k].get_endpoint(corner)
    var pixel: Vector2 = preview.camera.unproject_position(point)
    low = minf(low,pixel.x)
    high = maxf(high,pixel.x)
    check(pixel.x > 1 and pixel.x < 959 and pixel.y > 1 and pixel.y < 599,"Rotating authored model bounds remain fully inside frame")
   projected.append(Vector2(low,high))
  check(projected[0].y < projected[1].x,"Separate turntables stay side by side without silhouette overlap")
 print("DUO bounds radius=",preview.horizontal_radius," spacing=",preview.center_spacing," orthosize=",preview.camera.size)
 var before: float = preview.angle
 preview.advance(0.05)
 check(preview.angle != before,"Visible duo actually rotates")
 preview.advance(NAN)
 check(is_finite(preview.angle),"Invalid delta cannot poison rotation")
 host.hide()
 var stopped: float = preview.angle
 preview.advance(1)
 check(preview.angle == stopped and not preview.is_processing() and preview.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED,"Hidden home suspends rotation and rendering")
 host.show()
 check(preview.is_processing() and preview.viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS,"Returning home resumes bounded preview rendering")
 preview.setup()
 check(preview.get_child_count() == 1,"Repeated setup cannot stack subviewports")
 var old_view: WeakRef = weakref(preview.viewport)
 var old_kart: WeakRef = weakref(preview.karts[0])
 host.queue_free()
 await process_frame
 check(old_view.get_ref() == null and old_kart.get_ref() == null,"Leaving page destroys studio viewport and both actual karts")
 print("BORACER HOME DUO: %d checks, %d failures" % [checks,failures])
 quit(0 if failures == 0 else 1)
