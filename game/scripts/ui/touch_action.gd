extends TouchScreenButton
var caption: String
var font: Font
const BUTTON_SIZE = Vector2(86, 64)

func setup(action_id: String, title: String, typeface: Font) -> void:
 action = action_id
 caption = title
 font = typeface
 var polygon = ConvexPolygonShape2D.new()
 polygon.points = PackedVector2Array([Vector2.ZERO, Vector2(BUTTON_SIZE.x, 0), BUTTON_SIZE, Vector2(0, BUTTON_SIZE.y)])
 shape = polygon
 shape_centered = false
 passby_press = true
 pressed.connect(queue_redraw)
 released.connect(queue_redraw)
 var text = Label.new()
 text.text = title
 text.size = BUTTON_SIZE
 text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 text.add_theme_font_override("font", font)
 text.add_theme_color_override("font_color", Color("fff2c8"))
 text.add_theme_font_size_override("font_size", 17)
 text.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(text)

func set_enabled(enabled: bool) -> void:
 if not enabled and is_pressed():
  Input.action_release(action)
 visible = enabled
 queue_redraw()

func _draw() -> void:
 var style = StyleBoxFlat.new()
 style.bg_color = Color(0.95, 0.65, 0.2, 0.95) if is_pressed() else Color(0.05, 0.12, 0.22, 0.85)
 style.border_color = Color("ffd567")
 style.set_border_width_all(2)
 style.set_corner_radius_all(14)
 draw_style_box(style, Rect2(Vector2.ZERO, BUTTON_SIZE))

func _exit_tree() -> void:
 if is_pressed():
  Input.action_release(action)
