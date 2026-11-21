extends Button
## A native, accessible Button with original concept art and a small vector emblem.
## Decorative children never intercept pointer, touch or keyboard interactions.
var artwork: TextureRect
var emblem: TileEmblem
var active_tween: Tween
const CYAN = Color("32d5ff")
const GOLD = Color("ffce63")

class TileEmblem:
 extends Control
 var kind: String = "race"
 var accent: Color = Color("ffce63")
 func _draw() -> void:
  var center = Vector2(30, 30)
  draw_circle(center, 25, Color(0.02, 0.05, 0.13, 0.93))
  draw_arc(center, 25, 0, TAU, 48, accent, 2, true)
  match kind:
   "race":
    draw_line(Vector2(18, 46), Vector2(22, 14), Color.WHITE, 3, true)
    for x in 4:
     for y in 3:
      draw_rect(Rect2(22 + x * 6, 14 + y * 6, 6, 6), Color.WHITE if (x + y) % 2 == 0 else Color("123256"))
   "garage":
    # Crossed workshop spanners over a character illustration.
    for direction in [-1, 1]:
     var a = center + Vector2(11 * direction, -11)
     var b = center + Vector2(-10 * direction, 10)
     draw_line(a, b, accent, 5, true)
     draw_arc(a, 6, deg_to_rad(-10), deg_to_rad(250), 14, accent, 3, true)
     draw_circle(b, 4, accent)
     draw_circle(b, 1.5, Color("071a34"))
   "settings":
    for i in 8:
     var angle = i * TAU / 8.0
     draw_line(center + Vector2.from_angle(angle) * 12, center + Vector2.from_angle(angle) * 19, accent, 6, true)
    draw_circle(center, 14, accent)
    draw_circle(center, 6, Color("071a34"))
   "exit":
    draw_polyline(PackedVector2Array([Vector2(29, 15), Vector2(17, 15), Vector2(17, 45), Vector2(29, 45)]), accent, 3, true)
    draw_line(Vector2(27, 30), Vector2(44, 30), Color.WHITE, 3, true)
    draw_polyline(PackedVector2Array([Vector2(37, 22), Vector2(45, 30), Vector2(37, 38)]), Color.WHITE, 3, true)

func setup(image: Texture2D, kind: String, typeface: Font, primary: bool = false) -> void:
 custom_minimum_size = Vector2(278, 158)
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 clip_contents = true
 add_theme_font_override("font", typeface)
 add_theme_font_size_override("font_size", 20)
 for state in ["normal", "hover", "pressed", "focus", "disabled"]:
  var style = StyleBoxFlat.new()
  style.bg_color = GOLD if primary else Color("0b2546")
  style.set_corner_radius_all(13)
  style.set_border_width_all(2)
  style.border_color = GOLD if primary else Color("278ac0")
  style.content_margin_top = 112
  style.content_margin_bottom = 10
  style.content_margin_left = 10
  style.content_margin_right = 10
  if state in ["hover", "focus"]:
   style.bg_color = Color("ffe6a4") if primary else Color("16446a")
   style.set_border_width_all(4)
   style.border_color = Color("fff4c1") if primary else CYAN
  elif state == "pressed":
   style.bg_color = Color("dfa542") if primary else Color("08203b")
   style.border_color = GOLD
  elif state == "disabled":
   style.bg_color = Color("263044")
   style.border_color = Color("425168")
  add_theme_stylebox_override(state, style)
 for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
  add_theme_color_override(state, Color("071a34") if primary else Color("f6f1e5"))
 add_theme_color_override("font_disabled_color", Color("889bad"))
 add_theme_color_override("font_outline_color", Color("020c20"))
 add_theme_constant_override("outline_size", 0 if primary else 2)
 artwork = TextureRect.new()
 artwork.name = "TileArtwork"
 artwork.texture = image
 artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
 artwork.position = Vector2(5, 5)
 artwork.size = Vector2(268, 101)
 add_child(artwork)
 # Shade only the art; leave the native Button caption and focus border unobscured.
 var gradient = Gradient.new()
 gradient.set_color(0, Color(0.01, 0.04, 0.11, 0))
 gradient.set_color(1, Color(0.01, 0.04, 0.11, 0.38))
 var shade_texture = GradientTexture2D.new()
 shade_texture.gradient = gradient
 shade_texture.fill_from = Vector2(0, 0)
 shade_texture.fill_to = Vector2(0, 1)
 var shade = TextureRect.new()
 shade.name = "ArtworkShade"
 shade.texture = shade_texture
 shade.position = artwork.position
 shade.size = artwork.size
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(shade)
 emblem = TileEmblem.new()
 emblem.name = "TileEmblem"
 emblem.kind = kind
 emblem.accent = GOLD if primary or kind == "exit" else CYAN
 emblem.position = Vector2(105, 10) if kind == "garage" else Vector2(10, 10)
 emblem.pivot_offset = Vector2(30, 30)
 emblem.size = Vector2(60, 60)
 emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(emblem)
 mouse_entered.connect(_refresh_emphasis)
 mouse_exited.connect(_refresh_emphasis)
 focus_entered.connect(_refresh_emphasis)
 focus_exited.connect(_refresh_emphasis)

func _refresh_emphasis() -> void:
 var emphasized = is_hovered() or has_focus()
 if is_instance_valid(active_tween):
  active_tween.kill()
 active_tween = create_tween()
 active_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 active_tween.tween_property(artwork, "modulate", Color(1.12, 1.12, 1.12) if emphasized else Color.WHITE, 0.16)
 active_tween.parallel().tween_property(emblem, "rotation", -0.10 if emphasized else 0.0, 0.16)
