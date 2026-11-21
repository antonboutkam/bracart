extends Control
# Decorative code-native ribbon: clipped/slanted ends, no input or external asset.
func setup(font: Font) -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 focus_mode = Control.FOCUS_NONE
 var caption = Label.new()
 add_child(caption)
 caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 caption.text = "Stunt Edition"
 caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 caption.add_theme_font_override("font", font)
 caption.add_theme_font_size_override("font_size", 17)
 caption.add_theme_color_override("font_color", Color("071a34"))
 caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
 queue_redraw()

func _draw() -> void:
 var w = size.x
 var h = size.y
 var outline = PackedVector2Array([Vector2(10,0),Vector2(w,0),Vector2(w-10,h),Vector2(0,h),Vector2(10,0)])
 draw_colored_polygon(outline, Color("ffce63"))
 draw_polyline(outline, Color("32d5ff"), 2.0, true)
 draw_line(Vector2(17,h-5),Vector2(w-16,h-5),Color("bf7e35"),1.0,true)
