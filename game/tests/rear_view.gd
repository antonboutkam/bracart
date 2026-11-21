extends SceneTree
const Main = preload("res://scripts/main.gd")
var failures: int = 0
var checks: int = 0
func check(ok: bool,label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game = Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.muted = true
 for vehicle in 6:
  game.profile.selected = vehicle
  game.start_race(11)
  game.race.set_process(false)
  check(game.race.player.visual.get_node_or_null("SideMirrors/LeftMirror/Glass")!=null,"left mirror vehicle %d"%vehicle)
  check(game.race.player.visual.get_node_or_null("SideMirrors/RightMirror/Glass")!=null,"right mirror vehicle %d"%vehicle)
  Input.action_press("rear_look")
  game._camera(0,true)
  check(game.rear_view.active,"rear activates")
  var eye_local: Vector3 = game.track.frame(game.race.player.progress).affine_inverse()*game.rear_view.rear.global_position
  check(eye_local.z>1.5,"rear eye clears normalized vehicle rear on type %d"%vehicle)
  check(game.get_viewport().get_camera_3d()==game.rear_view.rear,"rear main camera")
  check(game.rear_view.viewport.world_3d==game.camera.get_world_3d(),"inset shares actual world")
  check(game.rear_view.inset_camera.global_transform.is_equal_approx(game.camera.global_transform),"inset is forward rig")
  var before: Transform3D = game.camera.global_transform
  Input.action_release("rear_look")
  game._camera(0)
  check(game.get_viewport().get_camera_3d()==game.camera,"release main forward")
  check(game.camera.global_position.distance_to(before.origin)<0.001,"no forward camera jump")
  check(game.rear_view.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"idle inset does not render")
  for sample in 100:
   game.race.player.progress = game.track.length*sample/100.0
   game.race.player.update_visual(game.track,0)
   Input.action_press("rear_look")
   game._camera(0,true)
   var f: Transform3D = game.track.frame(game.race.player.progress)
   check((-game.rear_view.rear.global_basis.z).dot(f.basis.z)>0.999,"rear follows course tangent")
   check(game.rear_view.rear.global_basis.y.dot(f.basis.y)>0.999,"rear follows stunt up")
  game.rear_view.reset()
  game._camera(0,true)
  check(not game.rear_view.active,"held reset blocks")
  Input.action_release("rear_look")
  game._camera(0,true)
  await process_frame
 game.go_home()
 check(not game.rear_view.active and not game.rear_view.panel.visible,"menu cleanup")
 game.queue_free()
 await process_frame
 print("BORACER REAR VIEW: %d checks, %d failures"%[checks,failures])
 quit(0 if failures==0 else 1)
