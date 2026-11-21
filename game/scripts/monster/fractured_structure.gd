extends "res://scripts/monster/structure.gd"
## Visible pieces plus a support graph, on the existing breakable block tower.
const ID = "gifspuwer-breekbaar"
const DIRECTORY = "res://assets/monsters/gifspuwer-breekbaar/"
const MODEL_SCALE = 8.0
const SCORE_UNITS = 10000
var pieces: Dictionary = {}
var remaining: Dictionary = {}
var weights: Dictionary = {}
var packed: PackedScene
var model_bounds: AABB
var model_origin = Vector3(0, 0, -160)
var tower_added = false

func _init() -> void:
 score_multiplier = 1
 debris_label = "onderdelen"

func load_monster(id: String) -> bool:
 last_error = "De breekbare Gifspuwer kan niet worden geladen."
 if id != ID:
  return false
 var data = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "breekstukken.json"))
 var derived = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "collision-planes.json"))
 if not data is Dictionary or not derived is Dictionary or not data.get("pieces") is Array:
  return false
 if derived.get("source_sha256") != FileAccess.get_sha256(DIRECTORY + "breekstukken.json"):
  return false
 packed = load(DIRECTORY + "gifspuwer-breekbaar.glb") as PackedScene
 if packed == null:
  return false
 var scene = packed.instantiate()
 pieces.clear()
 remaining.clear()
 weights.clear()
 cells.clear()
 target_cells.clear()
 tower_added = false
 model_origin = Vector3(0, 0, -160)
 var first = true
 var fractions: Array = []
 var allocated = 0
 for source in data.pieces:
  var node = scene.find_child(source.node, true, false) as MeshInstance3D
  if node == null or not derived.planes.has(source.id):
   scene.free()
   return false
  var piece: Dictionary = source.duplicate(true)
  piece.pivot = Vector3(source.pivot[0], source.pivot[1], source.pivot[2])
  piece.bounds = node.get_aabb()
  piece.planes = derived.planes[source.id]
  var box: AABB = node.transform * node.get_aabb()
  model_bounds = box if first else model_bounds.merge(box)
  first = false
  pieces[source.id] = piece
  remaining[source.id] = true
  var exact: float = source.scoreWeight * SCORE_UNITS
  weights[source.id] = floori(exact)
  allocated += weights[source.id]
  fractions.append({"id":source.id, "fraction":exact - floor(exact)})
 scene.free()
 # Largest remainders preserve the supplied proportions and an exact 10,000 total.
 fractions.sort_custom(func(a, b): return a.fraction > b.fraction if a.fraction != b.fraction else a.id < b.id)
 for i in SCORE_UNITS - allocated:
  weights[fractions[i].id] += 1
 model_origin.x -= model_bounds.get_center().x * MODEL_SCALE
 model_origin.z -= model_bounds.get_center().z * MODEL_SCALE
 center_offset = Vector3.ZERO
 for id_key in pieces:
  var piece: Dictionary = pieces[id_key]
  if piece.grounded:
   var at: Vector3 = model_origin + piece.pivot * MODEL_SCALE
   piece.anchor = Vector3i(roundi(at.x / CELL), 0, roundi((at.z + 160) / CELL))
   cells[piece.anchor] = Color.WHITE
 total = SCORE_UNITS
 monster_id = ID
 monster_name = "Gifspuwer · verfijnd"
 last_error = ""
 return true

func add_tower() -> void:
 if tower_added:
  return
 super.add_tower()
 # The seed cells only define the footprint; the real feet are visible meshes.
 for piece in pieces.values():
  if piece.grounded:
   cells.erase(piece.anchor + Vector3i(0, TOWER_HEIGHT, 0))
   piece.anchor += Vector3i(0, TOWER_HEIGHT - 1, 0)
 center_offset = Vector3.ZERO
 target_cells.clear()
 model_origin.y = TOWER_HEIGHT * CELL
 tower_added = true

func bounds() -> AABB:
 var transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * MODEL_SCALE), model_origin)
 var result: AABB = transform * model_bounds
 return result.merge(super.bounds()) if tower_added else result

func release_pieces(from: Vector3, to: Vector3, radius: float) -> Array:
 var released: Array = []
 for id_key in remaining.keys():
  if intersects_piece(id_key, from, to, radius):
   remaining.erase(id_key)
   released.append(id_key)
 # Flood fill from surviving feet whose platform cells still exist.
 var supported: Dictionary = {}
 var queue: Array = []
 for id_key in remaining:
  var piece: Dictionary = pieces[id_key]
  if piece.grounded and (not tower_added or cells.has(piece.anchor)):
   supported[id_key] = true
   queue.append(id_key)
 var index = 0
 while index < queue.size():
  for neighbor in pieces[queue[index]].neighbors:
   if remaining.has(neighbor) and not supported.has(neighbor):
    supported[neighbor] = true
    queue.append(neighbor)
  index += 1
 for id_key in remaining.keys():
  if not supported.has(id_key):
   remaining.erase(id_key)
   released.append(id_key)
 return released

func intersects_piece(id_key: String, from: Vector3, to: Vector3, radius: float) -> bool:
 var piece: Dictionary = pieces[id_key]
 var a: Vector3 = (from - model_origin) / MODEL_SCALE - piece.pivot
 var b: Vector3 = (to - model_origin) / MODEL_SCALE - piece.pivot
 # Clip the swept rocket against outward convex planes, expanded by its radius.
 # Expansion is conservative at corners and prevents fast thin-piece tunneling.
 var enter = 0.0
 var leave = 1.0
 for values in piece.planes:
  var normal = Vector3(values[0], values[1], values[2])
  var distance: float = values[3] + radius / MODEL_SCALE
  var da = normal.dot(a) - distance
  var db = normal.dot(b) - distance
  if da > 0 and db > 0:
   return false
  if da <= 0 and db <= 0:
   continue
  var crossing = da / (da - db)
  if da > 0:
   enter = maxf(enter, crossing)
  else:
   leave = minf(leave, crossing)
  if enter > leave:
   return false
 return true

func instantiate_visual() -> Node3D:
 var node = packed.instantiate() as Node3D
 # Some primitives omit COLOR_0; Godot then disables vertex color on their
 # shared imported surface material. Explicit per-instance overrides keep
 # colored primitives correct without mutating the cached imported resource.
 var materials: Dictionary = {}
 for mesh in node.find_children("*", "MeshInstance3D", true, false):
  for surface in mesh.mesh.get_surface_count():
   var source: StandardMaterial3D = mesh.mesh.surface_get_material(surface)
   if source == null:
    continue
   var key = source.get_instance_id()
   if not materials.has(key):
    var material = source.duplicate() as StandardMaterial3D
    material.vertex_color_use_as_albedo = true
    materials[key] = material
   mesh.set_surface_override_material(surface, materials[key])
 node.scale = Vector3.ONE * MODEL_SCALE
 node.position = model_origin
 return node
