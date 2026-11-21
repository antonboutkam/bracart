extends Node
## Keep the forward rig running, swapping only the viewport's active camera.
var forward: Camera3D
var rear: Camera3D
var inset_camera: Camera3D
var viewport: SubViewport
var layer: CanvasLayer
var panel: PanelContainer
var active: bool = false
var blocked_until_release: bool = false

func setup(camera: Camera3D) -> void:
 forward = camera
 rear = Camera3D.new()
 rear.name = "RearLookCamera"
 add_child(rear)
 viewport = SubViewport.new()
 viewport.name = "ForwardInsetViewport"
 viewport.size = Vector2i(400,225)
 viewport.world_3d = forward.get_world_3d()
 viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
 add_child(viewport)
 inset_camera = Camera3D.new()
 inset_camera.current = true
 viewport.add_child(inset_camera)
 layer = CanvasLayer.new()
 layer.layer = 3
 add_child(layer)
 var screen = Control.new()
 screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
 layer.add_child(screen)
 panel = PanelContainer.new()
 panel.name = "ForwardViewInset"
 panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
 panel.offset_left = -142
 panel.offset_right = 142
 panel.offset_top = -236
 panel.offset_bottom = -52
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 screen.add_child(panel)
 var style = StyleBoxFlat.new()
 style.bg_color = Color("102638")
 style.border_color = Color("56d9e9")
 style.set_border_width_all(2)
 style.content_margin_left = 5
 style.content_margin_right = 5
 style.content_margin_top = 3
 style.content_margin_bottom = 5
 panel.add_theme_stylebox_override("panel",style)
 var column = VBoxContainer.new()
 column.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.add_child(column)
 var caption = Label.new()
 caption.text = "VOORUIT  ·  C / LB loslaten"
 caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 caption.add_theme_font_size_override("font_size",13)
 column.add_child(caption)
 var image = TextureRect.new()
 image.texture = viewport.get_texture()
 image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.custom_minimum_size = Vector2(270,152)
 image.mouse_filter = Control.MOUSE_FILTER_IGNORE
 column.add_child(image)
 panel.hide()

func reset() -> void:
 blocked_until_release = Input.is_action_pressed("rear_look")
 _set_active(false)

func update(track, kart, enabled: bool) -> void:
 var pressed = Input.is_action_pressed("rear_look")
 if not pressed: blocked_until_release = false
 if not enabled:
  reset()
  return
 _set_active(pressed and not blocked_until_release)
 if not active: return
 var frame: Transform3D = track.frame(kart.progress)
 # Eye behind the vehicle clears the rider/body; loops retain their local up.
 var eye: Vector3 = track.position_at(kart.progress,kart.lateral,kart.jump_height+1.15)+frame.basis.z*1.6
 rear.global_position = eye
 rear.look_at(eye+frame.basis.z*10,frame.basis.y)
 rear.fov = 78
 rear.far = forward.far
 inset_camera.global_transform = forward.global_transform
 inset_camera.fov = forward.fov
 inset_camera.near = forward.near
 inset_camera.far = forward.far

func _set_active(value: bool) -> void:
 active = value
 panel.visible = value
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if value else SubViewport.UPDATE_DISABLED
 if value:
  rear.make_current()
 else:
  forward.make_current()
