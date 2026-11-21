extends Control
## Original illustrated torsos, layered without changing the saved driver on hover.
signal selected(character_id: String)
const ART = preload("res://assets/ui/garage.png")
var selected_id: String = "boaz"
var front_id: String = "boaz"
var portraits: Dictionary = {}
var hover_latched: bool = false
var hover_candidate: String = ""
var pointer_viewport_position: Vector2
var has_pointer_position: bool = false
var last_input_was_pointer: bool = false

class Portrait extends Button:
 var artwork: AtlasTexture
 var winner: bool = false
 func _draw() -> void:
  var rect := Rect2(Vector2.ONE*3,size-Vector2.ONE*6)
  var style := StyleBoxFlat.new()
  style.bg_color = Color("10345a")
  style.border_color = Color("ffce63") if winner else Color("4b8fb1")
  style.set_border_width_all(3 if winner else 1)
  style.set_corner_radius_all(11)
  draw_style_box(style,rect)
  var image_height: float = size.y-8
  var image_width: float = image_height*artwork.get_width()/artwork.get_height()
  draw_texture_rect(artwork,Rect2((size.x-image_width)/2,4,image_width,image_height),false)
  if winner:
   # A modest golden winner crown, without obscuring the original face.
   var crown := PackedVector2Array([Vector2(8,25),Vector2(5,11),Vector2(14,16),Vector2(20,6),Vector2(26,16),Vector2(35,11),Vector2(32,25)])
   draw_colored_polygon(crown,Color("ffce63"))
   draw_line(Vector2(9,28),Vector2(31,28),Color("fff0ad"),2,true)
  if has_focus():
   draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color("ffffff"),false,2)

func setup(character_id: String) -> void:
 name = "GarageDrivers"
 size = Vector2(276,125)
 mouse_filter = Control.MOUSE_FILTER_PASS
 selected_id = character_id
 for id in ["boaz","ravi"]:
  var portrait := Portrait.new()
  portrait.name = id.capitalize()+"Portrait"
  portrait.text = id.capitalize()
  portrait.tooltip_text = id.capitalize()+" kiezen"
  portrait.accessibility_name = id.capitalize()
  portrait.artwork = AtlasTexture.new()
  portrait.artwork.atlas = ART
  portrait.artwork.region = Rect2(260,694,129,105) if id == "boaz" else Rect2(407,694,128,105)
  for state in ["normal","hover","pressed","focus"]:
   portrait.add_theme_stylebox_override(state,StyleBoxEmpty.new())
  portrait.add_theme_color_override("font_color",Color.TRANSPARENT)
  portrait.add_theme_color_override("font_hover_color",Color.TRANSPARENT)
  portrait.add_theme_color_override("font_pressed_color",Color.TRANSPARENT)
  portrait.add_theme_color_override("font_focus_color",Color.TRANSPARENT)
  add_child(portrait)
  portraits[id] = portrait
  portrait.mouse_entered.connect(_hover.bind(id))
  portrait.focus_entered.connect(_focus.bind(id))
  portrait.pressed.connect(_activate.bind(id))
  portrait.mouse_exited.connect(_reset_if_outside)
 portraits.boaz.focus_neighbor_left = portraits.boaz.get_path_to(portraits.ravi)
 portraits.boaz.focus_neighbor_right = portraits.boaz.get_path_to(portraits.ravi)
 portraits.ravi.focus_neighbor_left = portraits.ravi.get_path_to(portraits.boaz)
 portraits.ravi.focus_neighbor_right = portraits.ravi.get_path_to(portraits.boaz)
 present(selected_id)

func _hover(character_id: String) -> void:
 if not hover_latched and character_id != front_id:
  hover_latched = true
  hover_candidate = character_id
  present(character_id)

func present(character_id: String) -> void:
 if not portraits.has(character_id): return
 front_id = character_id
 for id in portraits:
  var portrait: Portrait = portraits[id]
  var front: bool = id == front_id
  portrait.position = Vector2.ZERO if front else Vector2(123,9)
  portrait.size = Vector2(160,122) if front else Vector2(133,108)
  portrait.z_index = 2 if front else 1
  portrait.winner = id == selected_id
  portrait.set_meta("selected_driver",portrait.winner)
  portrait.set_meta("front",front)
  portrait.queue_redraw()

func reset_presentation() -> void:
 hover_latched = false
 hover_candidate = ""
 present(selected_id)

func _pointer_inside() -> bool:
 if not has_pointer_position: return true
 var local: Vector2 = get_global_transform_with_canvas().affine_inverse()*pointer_viewport_position
 return Rect2(Vector2.ZERO,size).has_point(local)

func _focus(character_id: String) -> void:
 # Mouse focus can land on the newly exposed rear button after the visual swap.
 # Keep the hovered candidate stable until pointer activation has completed.
 if not hover_latched:
  present(character_id)

func _activate(character_id: String) -> void:
 var choice: String = hover_candidate if last_input_was_pointer and hover_latched and _pointer_inside() else character_id
 selected.emit(choice)

func _reset_if_outside() -> void:
 if not _pointer_inside():
  reset_presentation()

func _input(event: InputEvent) -> void:
 if event is InputEventMouseMotion or event is InputEventMouseButton:
  # Use the actual viewport event, including injected/remote pointer events.
  # OS mouse polling may lag and is unavailable on the headless test backend.
  pointer_viewport_position = event.position
  has_pointer_position = true
  last_input_was_pointer = true
  if hover_latched:
   _reset_if_outside()
 elif ((event is InputEventKey or event is InputEventJoypadButton or event is InputEventAction) and event.is_pressed()) or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.4):
  last_input_was_pointer = false
  hover_latched = false
  hover_candidate = ""
  var focused: Control = get_viewport().gui_get_focus_owner()
  for id in portraits:
   if portraits[id] == focused:
    present(id)
