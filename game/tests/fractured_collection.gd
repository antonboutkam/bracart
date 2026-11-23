extends SceneTree
const Models = preload("res://scripts/monster/models.gd")
const Main = preload("res://scripts/main.gd")
const Fractured = preload("res://scripts/monster/fractured_structure.gd")
var failures: Array[String] = []
var checks = 0

func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures.append(message)
  push_error(message)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game = Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.music.stop()
 game.audio.muted = true
 for id in ["slakkenoog-breekbaar", "stippelmonster-breekbaar", "stekelmonster-breekbaar", "pluismonster-breekbaar", "girafnek-breekbaar", "robotmonster-breekbaar", "paars-spook-breekbaar"]:
  var model = Models.create(id)
  if not model.load_monster(id):
   check(false, id + ": loads")
   continue
  var arena = Models.arena_for(model)
  root.add_child(arena)
  arena.build(model)
  check(model.pieces.size() == 72 and arena.piece_nodes.size() == 72, id + ": all pieces visible")
  check(model.unsupported_groups().is_empty(), id + ": supported tower")
  var total = 0
  for piece_id in model.pieces:
   var piece: Dictionary = model.pieces[piece_id]
   var mesh: MeshInstance3D = arena.piece_nodes[piece_id]
   check(mesh.global_position.distance_to(model.model_origin + piece.pivot * Fractured.MODEL_SCALE) < 0.0001, id + ": mesh and collision pivot " + piece_id)
   var center = Vector3.ZERO
   for point in piece.collider.points:
    center += Vector3(point[0], point[1], point[2])
   center /= piece.collider.points.size()
   center = model.model_origin + (piece.pivot + center) * Fractured.MODEL_SCALE
   check(model.intersects_piece(piece_id, center + Vector3(0,0,100), center - Vector3(0,0,100), 0.1), id + ": swept collision " + piece_id)
   total += model.weights[piece_id]
  check(total == 10000, id + ": total score")
  check(arena.impact(Vector3(100,100,0), Vector3(100,100,-300), 1, 0) == 0, id + ": miss")
  arena.impact(Vector3(-60,30,-160), Vector3(60,30,-160), 3, 0)
  check(model.remaining.is_empty(), id + ": support destruction releases all pieces")
  var earned = 0
  for i in 1200:
   for landed in arena.advance(1.0 / 60):
    earned += landed.count
   if arena.chunks.is_empty(): break
  check(earned == 10000 and arena.submerged == 10000 and arena.advance(10).is_empty(), id + ": pieces score once in water")
  arena.queue_free()
  game.choose_monster(1)
  game.ui._select_monster(id)
  check(game.ui.selected_monster == id, id + ": selectable and preview loads")
  game.start_monster(id, 1)
  var mode = game.monster_mode
  mode.set_process(false)
  mode.set_physics_process(false)
  mode.action()
  for i in 2400:
   mode.step(1.0 / 60)
   if mode.phase in ["between", "finished"]: break
  check(mode.phase in ["between", "finished"] and mode.scores[0] > 0, id + ": ordinary launch hits and scores")
  print("%s: phase=%s score=%d" % [id, mode.phase, mode.scores[0]])
 game.queue_free()
 await process_frame
 print("FRACTURED COLLECTION: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
