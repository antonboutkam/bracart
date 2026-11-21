extends RefCounted
## Logical blocks: face-connected to a ground anchor, or released as one chunk.
## New monsters only need a cell -> Color dictionary and ground-level feet.
const SIZE_MULTIPLIER = 1.5
const CELL = 1.3 * SIZE_MULTIPLIER
const TOWER_HEIGHT = 23
const ORIGIN = Vector3(0, CELL * 0.5, -160)
const Catalog = preload("res://scripts/monster/catalog.gd")
const NEIGHBORS = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]
var cells: Dictionary = {}
var total: int = 0
var target_cells: Dictionary = {}
var center_offset = Vector3.ZERO
var monster_name: String = "Tweekoppige draak"
var monster_id: String = "dragon"
var last_error: String = ""
var score_multiplier = 10
var debris_label = "blokjes"

func load_monster(id: String) -> bool:
 if id == "dragon":
  build_dragon()
  return true
 var entry: Dictionary = Catalog.find(id)
 if entry.is_empty():
  last_error = "Dit monster is niet beschikbaar."
  return false
 var path = Catalog.DIRECTORY + id + ".json"
 if not FileAccess.file_exists(path):
  last_error = "Het monsterbestand ontbreekt: " + id
  return false
 return load_data(JSON.parse_string(FileAccess.get_file_as_string(path)))

func load_data(data) -> bool:
 last_error = "Het monsterbestand heeft ongeldige of losse blokken."
 if not data is Dictionary or not data.get("blocks") is Array or not data.get("id") is String or not data.get("name") is String:
  return false
 if data.blocks.is_empty() or data.blocks.size() > 6000:
  return false
 var parsed: Dictionary = {}
 for block in data.blocks:
  if not block is Dictionary:
   return false
  for axis in ["x", "y", "z"]:
   var value = block.get(axis)
   if not (value is int or value is float) or not is_finite(float(value)) or absf(value) > 64 or float(int(value)) != float(value):
    return false
  var color = block.get("color")
  if not color is String or color.length() != 7 or not color.begins_with("#") or not color.substr(1).is_valid_hex_number():
   return false
  var cell = Vector3i(block.x, block.y, block.z)
  if cell.y < 0 or parsed.has(cell):
   return false
  parsed[cell] = Color(color)
 var previous: Dictionary = cells
 cells = parsed
 if not unsupported_groups().is_empty():
  cells = previous
  return false
 monster_id = data.id
 monster_name = data.name
 var low = Vector3(64, 64, 64)
 var high = -low
 for cell in cells:
  low = low.min(Vector3(cell))
  high = high.max(Vector3(cell))
 center_offset = Vector3((low.x + high.x) * 0.5, 0, (low.z + high.z) * 0.5)
 total = cells.size()
 target_cells = cells.duplicate()
 last_error = ""
 return true

func add_tower() -> void:
 # Visible breakable supports raise the target into the ascending part of the flight.
 # Supports are structural, but only the supplied monster earns points / counts to 70%.
 # Keep the platform near its original flight height while enlarging the monster.
 const HEIGHT = TOWER_HEIGHT
 var lifted: Dictionary = {}
 for cell in cells:
  lifted[cell + Vector3i(0, HEIGHT, 0)] = cells[cell]
 cells = lifted
 target_cells = lifted.duplicate()
 var low = Vector3i(64, 64, 64)
 var high = -low
 for cell in cells:
  low = low.min(cell)
  high = high.max(cell)
 var middle_z = roundi(center_offset.z)
 var left = roundi(lerpf(low.x, high.x, 0.25))
 var right = low.x + high.x - left
 var support_color = Color("b9a37a")
 for x in [left, right]:
  fill(Vector3i(x - 1, 0, middle_z - 1), Vector3i(x + 1, HEIGHT - 2, middle_z + 1), support_color)
 fill(Vector3i(low.x - 1, HEIGHT - 1, mini(low.z, middle_z - 1)), Vector3i(high.x + 1, HEIGHT - 1, maxi(high.z, middle_z + 1)), support_color)

func build_dragon() -> void:
 cells.clear()
 center_offset = Vector3.ZERO
 monster_name = "Tweekoppige draak"
 monster_id = "dragon"
 var jade = Color("26a69a")
 # Two narrow legs support a broad body. All decorations are structural blocks.
 for side in [-1, 1]:
  fill(Vector3i(side * 4 - 1, 0, -1), Vector3i(side * 4 + 1, 13, 1), jade.darkened(0.15))
  fill(Vector3i(side * 4 - 2, 0, -3), Vector3i(side * 4 + 2, 1, 1), jade)
 fill(Vector3i(-6, 13, -2), Vector3i(6, 21, 2), jade)
 fill(Vector3i(-3, 14, 3), Vector3i(3, 19, 3), Color("ffcf70"))
 for side in [-1, 1]:
  fill(Vector3i(side * 4 - 1, 21, -1), Vector3i(side * 4 + 1, 27, 1), jade)
  fill(Vector3i(side * 5 - 2, 27, -2), Vector3i(side * 5 + 2, 31, 2), jade.lightened(0.13))
  fill(Vector3i(side * 5 - 2, 27, 3), Vector3i(side * 5 + 2, 28, 4), jade)
  for eye in [-1, 1]:
   cells[Vector3i(side * 5 + eye, 30, 3)] = Color("fff5c7")
   cells[Vector3i(side * 5 + eye, 30, 4)] = Color("182e48")
   fill(Vector3i(side * 5 + eye * 2, 32, 0), Vector3i(side * 5 + eye * 2, 33, 0), Color("ffb655"))
  # Stepped wings, attached along the shoulder; thin enough to punch through.
  for reach in range(1, 12):
   for y in range(18 + reach / 3, 27 - reach / 3):
    cells[Vector3i(side * (6 + reach), y, 0)] = Color("d37bac") if y % 3 else Color("ffcf70")
 total = cells.size()
 target_cells = cells.duplicate()

func fill(low: Vector3i, high: Vector3i, color: Color) -> void:
 for x in range(low.x, high.x + 1):
  for y in range(low.y, high.y + 1):
   for z in range(low.z, high.z + 1):
    cells[Vector3i(x, y, z)] = color

func position_of(cell: Vector3i) -> Vector3:
 return ORIGIN + (Vector3(cell) - center_offset) * CELL

func bounds() -> AABB:
 var low = Vector3(INF, INF, INF)
 var high = -low
 for cell in cells:
  var point = position_of(cell)
  low = low.min(point)
  high = high.max(point)
 return AABB(low, high - low).grow(CELL * 0.5)

func unsupported_groups() -> Array:
 var supported: Dictionary = {}
 var queue: Array = []
 for cell in cells:
  if cell.y == 0:
   supported[cell] = true
   queue.append(cell)
 var cursor = 0
 while cursor < queue.size():
  var cell: Vector3i = queue[cursor]
  cursor += 1
  for direction in NEIGHBORS:
   var neighbor: Vector3i = cell + direction
   if cells.has(neighbor) and not supported.has(neighbor):
    supported[neighbor] = true
    queue.append(neighbor)
 var groups: Array = []
 for seed in cells:
  if supported.has(seed):
   continue
  var group: Array = [seed]
  supported[seed] = true
  cursor = 0
  while cursor < group.size():
   var cell: Vector3i = group[cursor]
   cursor += 1
   for direction in NEIGHBORS:
    var neighbor: Vector3i = cell + direction
    if cells.has(neighbor) and not supported.has(neighbor):
     supported[neighbor] = true
     group.append(neighbor)
  groups.append(group)
 return groups

func strike(from: Vector3, to: Vector3, radius: float) -> Array:
 # Sweep against expanded block AABBs, so a fast rocket cannot skip a thin wing.
 var hit: Array = []
 var half = Vector3.ONE * (CELL * 0.5 + radius)
 for cell in cells:
  var bounds = AABB(position_of(cell) - half, half * 2)
  if bounds.has_point(from) or bounds.has_point(to) or bounds.intersects_segment(from, to) != null:
   hit.append(cell)
 if hit.is_empty():
  return []
 var chunks: Array = []
 # Individual struck bricks fly out; disconnected structures fall as connected chunks.
 for cell in hit:
  chunks.append(take([cell]))
 for group in unsupported_groups():
  chunks.append(take(group))
 return chunks

func first_contact(from: Vector3, to: Vector3, radius: float) -> Dictionary:
 var half = Vector3.ONE * (CELL * 0.5 + radius)
 # Only visit grid cells near this short sweep. Round outward at the edges.
 var low = Vector3i(((from.min(to) - half - ORIGIN) / CELL + center_offset).floor())
 var high = Vector3i(((from.max(to) + half - ORIGIN) / CELL + center_offset).ceil())
 var nearest: Dictionary = {}
 var distance = INF
 for x in range(low.x, high.x + 1):
  for y in range(low.y, high.y + 1):
   for z in range(low.z, high.z + 1):
    var cell = Vector3i(x, y, z)
    if not cells.has(cell):
     continue
    var bounds = AABB(position_of(cell) - half, half * 2)
    var point = from if bounds.has_point(from) else bounds.intersects_segment(from, to)
    if point != null and from.distance_squared_to(point) < distance:
     distance = from.distance_squared_to(point)
     nearest = {"point": point, "target": target_cells.has(cell)}
 return nearest

func take(group: Array) -> Dictionary:
 var result: Dictionary = {}
 for cell in group:
  result[cell] = cells[cell]
  cells.erase(cell)
 return result
