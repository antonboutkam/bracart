extends Control
## One short, noninteractive celebration above the results card.
const SPARK = preload("res://assets/third_party/kenney/particles/spark.png")
const DURATION = 1.6
const COUNT = 18
var age: float = 0
var race: Node

func _ready() -> void:
 name = "FinishConfetti"
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func points() -> PackedVector2Array:
 var result := PackedVector2Array()
 for index in COUNT:
  var x: float = (index+0.5)/COUNT
  var horizontal: float = clampf(size.x*x+sin(age*2.5+index)*24,24,maxf(24,size.x-24))
  result.append(Vector2(horizontal,size.y*(0.08+age*(0.2+0.02*(index%4)))))
 return result

func _process(delta: float) -> void:
 if not is_instance_valid(race):
  queue_free()
  return
 if race.paused: return
 age += delta
 if age>=DURATION:
  queue_free()
 else:
  queue_redraw()

func _draw() -> void:
 var positions := points()
 for index in COUNT:
  var color := Color.from_hsv(float(index)/COUNT,0.65,1,0.85*(1-age/DURATION))
  var extent: float = 15+4*(index%3)
  draw_set_transform(positions[index],age*(1 if index%2 else -1)+index,Vector2.ONE)
  draw_texture_rect(SPARK,Rect2(Vector2.ONE*(-extent/2),Vector2.ONE*extent),false,color)
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
