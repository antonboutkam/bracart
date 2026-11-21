extends SceneTree
const Models = preload("res://scripts/monster/models.gd")
const Fractured = preload("res://scripts/monster/fractured_structure.gd")
const Main = preload("res://scripts/main.gd")
var checks = 0
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures.append(message)
  push_error(message)

func _initialize() -> void:
 call_deferred("run")

func make_arena():
 var model = Models.create(Fractured.ID)
 check(model.load_monster(Fractured.ID), "Load the runtime GLB and matching fracture data")
 var arena = Models.arena_for(model)
 root.add_child(arena)
 arena.build(model)
 return arena

func run() -> void:
 var arena = make_arena()
 var model = arena.structure
 check(model.pieces.size() == 76 and arena.piece_nodes.size() == 76, "Every piece has a visible mesh")
 var sum = 0
 for weight in model.weights.values(): sum += weight
 check(sum == model.total and model.total == 10000, "Rounded volume weights preserve exactly 10,000 points")
 check(model.target_cells.is_empty(), "The block tower cannot earn monster points")
 check(model.unsupported_groups().is_empty(), "The complete platform is supported at the start")
 check(is_equal_approx(model.model_bounds.size.y, 5), "Source remains 5m high before gameplay scaling")
 for id in model.pieces:
  var piece: Dictionary = model.pieces[id]
  var node: MeshInstance3D = arena.piece_nodes[id]
  for surface in node.mesh.get_surface_count():
   var colors = node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_COLOR]
   if colors != null and not colors.is_empty():
    check(node.get_active_material(surface).vertex_color_use_as_albedo, "Vertex colors remain enabled: " + id)
  check(node.global_position.distance_to(model.model_origin + piece.pivot * Fractured.MODEL_SCALE) < 0.0001, "Mesh and collision pivot agree: " + id)
  if piece.grounded:
   check(model.cells.has(piece.anchor), "Foot has a real breakable platform anchor: " + id)
  # Any hull centroid must be hit even if the complete segment crosses it in one tick.
  var center = Vector3.ZERO
  for point in piece.collider.points: center += Vector3(point[0], point[1], point[2])
  center /= piece.collider.points.size()
  center = model.model_origin + (piece.pivot + center) * Fractured.MODEL_SCALE
  check(model.intersects_piece(id, center + Vector3(0,0,100), center - Vector3(0,0,100), 0.1), "Fast swept hit detects convex piece: " + id)
 check(arena.impact(Vector3(100,100,0), Vector3(100,100,-300), 1, 0) == 0, "A distant shot misses without damage")
 check(model.remaining.size() == 76 and arena.chunks.is_empty(), "Miss preserves every piece")
 # A precise hit on an upper horn releases pieces without tearing down the tower.
 var horn = ""
 for id in model.pieces:
  if id.begins_with("horn_l_"):
   horn = id
   break
 check(not horn.is_empty(), "A separately breakable horn exists")
 var horn_center: Vector3 = model.model_origin + model.pieces[horn].pivot * Fractured.MODEL_SCALE
 var broken: int = arena.impact(horn_center + Vector3(0,0,30), horn_center - Vector3(0,0,30), 0.25, 1)
 check(broken > 0 and model.remaining.size() > 0, "Local horn hit creates damage while leaving a standing monster")
 check(arena.submerged == 0, "Detaching pieces awards no points before water")
 var released_ids: Dictionary = {}
 var expected = 0
 for chunk in arena.chunks:
  if chunk.has("piece_id"):
   check(not released_ids.has(chunk.piece_id), "Piece released once: " + chunk.piece_id)
   released_ids[chunk.piece_id] = true
   expected += chunk.target_count
   var visible: AABB = chunk.node.get_child(0).global_transform * chunk.node.get_child(0).get_aabb()
   check(chunk.node.get_child(0).get_active_material(0).vertex_color_use_as_albedo, "Detached piece retains vertex colors")
   check(is_equal_approx(visible.end.y, chunk.node.position.y + chunk.highest), "Water test uses the whole visible piece")
 var earned = 0
 for i in 1200:
  for landed in arena.advance(1.0 / 60):
   check(landed.owner == 1, "Collapsed pieces retain the striker's ownership")
   earned += landed.count
  if arena.chunks.is_empty(): break
 check(earned == expected and arena.submerged == expected and earned > 0, "Underwater pieces earn their exact volume weight once")
 check(arena.advance(10).is_empty(), "Submerged pieces cannot score twice")
 # A second player destroys the supports; all surviving meshes fall for that player.
 arena.impact(Vector3(-60,30,-160), Vector3(60,30,-160), 3, 0)
 check(model.remaining.is_empty(), "Severing both towers releases all unsupported pieces")
 var second_score = 0
 for i in 1200:
  for landed in arena.advance(1.0 / 60):
   check(landed.owner == 0, "Later collapse belongs to the later striker")
   second_score += landed.count
  if arena.chunks.is_empty(): break
 check(earned + second_score == 10000 and arena.submerged == 10000, "Two players together earn the total exactly once; supports earn zero")
 arena.queue_free()
 await process_frame
 # Use the actual mode, flight controls, water settlement and replay transition.
 var game = Main.new()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.audio.music.stop()
 game.audio.muted = true
 var profile_before = [game.profile.coins, game.profile.records.duplicate(true)]
 game.choose_monster(1)
 game.ui._select_monster(Fractured.ID)
 check(game.ui.selected_monster == Fractured.ID, "The new model is selectable with a working preview")
 game.start_monster(Fractured.ID, 1)
 var mode = game.monster_mode
 mode.set_process(false)
 mode.set_physics_process(false)
 mode.action()
 for i in 2400:
  mode.step(1.0 / 60)
  if mode.phase in ["between", "finished"]: break
 print("GIFSPUWER NATURAL FLIGHT: phase=%s points=%d remaining=%d" % [mode.phase, mode.scores[0], mode.arena.structure.remaining.size()])
 check(mode.phase in ["between", "finished"] and mode.scores[0] > 0, "An ordinary full-gas jump hits the new monster and scores after landing")
 check(mode.scores[0] == mode.arena.submerged, "Mode uses volume points, not the old block multiplier")
 if mode.phase == "between":
  var before: Dictionary = mode.arena.structure.remaining.duplicate()
  mode.action()
  check(mode.arena.structure.remaining == before and mode.player == 0, "Next solo attempt preserves damage")
 mode.arena.impact(Vector3(-60,30,-160), Vector3(60,30,-160), 3, 0)
 var falling: Vector3 = mode.arena.chunks[0].node.position
 mode.toggle_pause()
 mode.step(1)
 check(mode.arena.chunks[0].node.position == falling, "Pause also freezes falling detailed pieces")
 mode.toggle_pause()
 mode.phase = "settling"
 for i in 1200:
  mode.step(1.0 / 60)
  if mode.phase == "finished": break
 check(mode.phase == "finished" and mode.scores[0] == 10000, "70-percent condition finishes after settlement with complete scoring")
 mode.action()
 check(game.monster_mode.monster_id == Fractured.ID and game.monster_mode.arena.structure.remaining.size() == 76 and game.monster_mode.scores == [0,0], "Replay restores all 76 pieces and clears scores")
 mode = game.monster_mode
 mode.set_process(false)
 mode.set_physics_process(false)
 # Complete a fresh game through real coasting flight and air steering only.
 var support_centers: Array[float] = []
 for side in [-1, 1]:
  var center_x = 0.0
  var cells_count = 0
  for cell in mode.arena.structure.cells:
   if cell.y == 1 and signi(cell.x) == side:
    center_x += mode.arena.structure.position_of(cell).x
    cells_count += 1
  support_centers.append(center_x / cells_count)
 for target_x in support_centers:
  if mode.phase == "between": mode.action()
  if mode.phase == "finished": break
  mode.action()
  for i in 2400:
   var steer = clampf((target_x - mode.rocket.position.x) * 0.8 - mode.velocity.x * 0.7, -1, 1) if mode.phase == "flight" else 0.0
   mode.step(1.0 / 60, 0, 0, steer)
   if mode.phase in ["between", "finished"]: break
 print("GIFSPUWER COASTING GAME: phase=%s points=%d attempts=%d" % [mode.phase, mode.scores[0], mode.turn + 1])
 check(mode.phase == "finished" and mode.scores[0] >= 7000, "Real coasting and steering can complete the refined monster without injected impacts")
 check([game.profile.coins,game.profile.records] == profile_before, "Monster integration leaves race progress untouched")
 game.queue_free()
 await process_frame
 await process_frame
 print("FRACTURED MONSTER: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
