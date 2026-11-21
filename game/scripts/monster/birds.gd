extends Node3D
## Small comic obstacles; a bumped bird tumbles briefly, then flies away unharmed.
const Geo = preload("res://scripts/geometry.gd")
var birds: Array = []
var elapsed: float = 0
var hits: int = 0

func reset(turn: int) -> void:
 for child in get_children():
  remove_child(child)
  child.queue_free()
 birds.clear()
 elapsed = 0
 hits = 0
 for i in 4:
  var node = Node3D.new()
  add_child(node)
  Geo.ball(node, Vector3.ZERO, Vector3(1.1, 0.65, 1.8), Color("fff2d4"))
  Geo.ball(node, Vector3(0, 0.25, -0.8), Vector3.ONE * 0.7, Color("fff8e7"))
  Geo.box(node, Vector3(0, 0.2, -1.35), Vector3(0.25, 0.18, 0.6), Color("ffc34f"))
  var wings: Array = []
  for side in [-1, 1]:
   Geo.ball(node, Vector3(side * 0.26, 0.38, -1.03), Vector3.ONE * 0.13, Color("132c45"))
   var pivot = Node3D.new()
   node.add_child(pivot)
   Geo.box(pivot, Vector3(side * 1.2, 0, 0), Vector3(2.4, 0.12, 0.65), Color("dce7ed"))
   wings.append(pivot)
  var z = -45.0 - i * 26
  var time = -z / 59.1
  var y = 23 + 37.4 * time - 6 * time * time
  var phase = i * 1.7 + turn * 2.1
  var origin = Vector3(0 if i == turn % 4 else (-13 if i % 2 else 13), y + (i % 2) * 3, z)
  node.position = origin + Vector3(sin(phase) * 9, 0, 0)
  birds.append({"node":node, "wings":wings, "origin":origin, "phase":phase, "hit":false, "since_hit":0.0, "previous":node.position})

func advance(delta: float) -> void:
 elapsed += delta
 for bird in birds:
  bird.previous = bird.node.position
  if bird.hit:
   bird.since_hit += delta
   bird.node.position += Vector3(12, 3, -7) * delta
   bird.node.rotation.z += delta * 5 if bird.since_hit < 1.2 else 0
   if bird.since_hit > 1.2:
    bird.node.rotation.z = lerp_angle(bird.node.rotation.z, 0, minf(1, delta * 5))
  else:
   bird.node.position = bird.origin + Vector3(sin(elapsed * 0.8 + bird.phase) * 9, sin(elapsed * 1.4 + bird.phase) * 1.5, 0)
  bird.wings[0].rotation.z = sin(elapsed * 10 + bird.phase) * 0.45
  bird.wings[1].rotation.z = -bird.wings[0].rotation.z

func collide(from: Vector3, to: Vector3) -> int:
 var count = 0
 for bird in birds:
  if bird.hit:
   continue
  var bounds = AABB(Vector3.ONE * -1.8, Vector3.ONE * 3.6)
  var relative_from: Vector3 = from - bird.previous
  var relative_to: Vector3 = to - bird.node.position
  if bounds.has_point(relative_from) or bounds.has_point(relative_to) or bounds.intersects_segment(relative_from, relative_to) != null:
   bird.hit = true
   count += 1
   hits += 1
   for i in 4:
    var star = Geo.ball(bird.node, Vector3(cos(i * PI / 2) * 1.2, 1, sin(i * PI / 2) * 1.2), Vector3.ONE * 0.22, Color("ffdd63"))
    star.name = "DizzyStar%d" % i
 return count
