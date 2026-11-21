extends Control
## Vector race instrument, matching the cyan/gold cockpit reference.
## All geometry lives in UI space; no additional textures or font licenses.
var speed_ratio: float = 0.0
var boost_ratio: float = 1.0
const CYAN = Color("28d9ff")
const GOLD = Color("ffce39")

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_readings(speed: float, boost: float) -> void:
 speed_ratio = clampf(speed / 200.0, 0.0, 1.0)
 boost_ratio = clampf(boost / 100.0, 0.0, 1.0)
 queue_redraw()

func _draw() -> void:
 var center = Vector2(140, 150)
 # A dark circular face with a thin luminous bezel and segmented speed arc.
 draw_circle(center, 130, Color(0.015, 0.04, 0.10, 0.91))
 draw_arc(center, 133, deg_to_rad(145), deg_to_rad(395), 80, Color(0.02, 0.28, 0.60, 0.5), 8, true)
 draw_arc(center, 130, deg_to_rad(145), deg_to_rad(395), 80, CYAN, 2, true)
 for i in 22:
  var angle = deg_to_rad(145 + i * 11.0)
  var tint = CYAN if i < 15 else (GOLD if i < 19 else Color("ff6247"))
  var filled = float(i) / 22.0 <= speed_ratio
  draw_arc(center, 111, angle, angle + deg_to_rad(8.5), 6, tint if filled else tint.darkened(0.72), 15, true)
 for i in 6:
  var angle = deg_to_rad(145 + i * 46.0)
  draw_line(center + Vector2.from_angle(angle) * 91, center + Vector2.from_angle(angle) * 99, GOLD, 2, true)
 # Boost battery below the numeric display is readable independently of speed.
 draw_line(Vector2(80, 202), Vector2(200, 202), Color("173553"), 9, true)
 draw_line(Vector2(80, 202), Vector2(80 + 120 * boost_ratio, 202), GOLD, 7, true)
