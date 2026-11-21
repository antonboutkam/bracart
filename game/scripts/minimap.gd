extends Control
var race
var points: PackedVector2Array
var minimum: Vector2
var span: Vector2

func configure(active_race) -> void:
 race = active_race
 points = PackedVector2Array()
 minimum = Vector2(INF, INF)
 var maximum = Vector2(-INF, -INF)
 for i in 160:
  var p: Vector3 = race.track.position_at(race.track.length * i / 159.0)
  var v = Vector2(p.x, p.z)
  points.append(v)
  minimum = minimum.min(v)
  maximum = maximum.max(v)
 span = (maximum - minimum).max(Vector2.ONE)

func mapped(p: Vector2) -> Vector2:
 var scale_value = minf((size.x - 24) / span.x, maxf(size.y - 24, 1) / span.y)
 return Vector2(12, 12) + (p - minimum) * scale_value + (size - Vector2(24, 24) - span * scale_value) / 2

func _draw() -> void:
 if not is_instance_valid(race) or points.is_empty():
  return
 var path = PackedVector2Array()
 for p in points:
  path.append(mapped(p))
 draw_polyline(path, Color("334766"), 8, true)
 draw_polyline(path, Color("b0c7dd"), 2, true)
 for kart in race.racers:
  var pos: Vector3 = race.track.position_at(kart.progress, kart.lateral)
  var point = mapped(Vector2(pos.x, pos.z))
  draw_circle(point, 5 if kart == race.player else 3, Color("ffd05b") if kart == race.player else Color("7de0ed"))
 draw_circle(mapped(points[0]), 3, Color.WHITE)
