extends RefCounted
## Version 3 makes Raketfiets the one-time default without losing earned progress.
signal storage_failed(message: String)
const Catalog = preload("res://scripts/catalog.gd")
const SAVE_VERSION = 3
const SAVE_PATH = "user://profile.json"
const RENDER_HEIGHTS = [0, 1440, 1080, 720] # 0 follows the window's native resolution.
const LEGACY_WORLDS = ["sunset-park", "neon-city", "regenbogenrijk", "haarlem-1888", "uithoorn-2056", "keukentafel"]
var coins: int = 0
var owned: Array = ["retro"]
var selected: int = Catalog.DEFAULT_VEHICLE
var character: String = "boaz"
var records: Dictionary = {}
var settings: Dictionary = {"music":0.35, "sound":0.65, "difficulty":0, "shadows":true,
 "camera_motion":true, "auto_accelerate":false, "touch_controls":false, "render_height":0}
var storage_path: String = SAVE_PATH
var available: Array
var last_error: String = ""
var recovered_backup: bool = false

func _init(path: String = SAVE_PATH) -> void:
 storage_path = path
 available = Catalog.available_indices()
 load_profile()

static func _number(value, fallback: float) -> float:
 if (value is int or value is float) and is_finite(float(value)):
  return float(value)
 return fallback

func _read(path: String):
 if not FileAccess.file_exists(path):
  return null
 var parser = JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path)) == OK and parser.data is Dictionary:
  return parser.data
 return null

func load_profile() -> void:
 var data = _read(storage_path)
 if data == null:
  data = _read(storage_path + ".bak")
  recovered_backup = data != null
 if data == null:
  _grant_free_vehicles()
  return
 coins = clampi(int(_number(data.get("coins"), 0)), 0, 999999999)
 var saved_owned = data.get("owned", [])
 if saved_owned is Array:
  for vehicle in Catalog.VEHICLES:
   if vehicle.id in saved_owned and not vehicle.id in owned:
    owned.append(vehicle.id)
 _grant_free_vehicles()
 if data.get("selected_vehicle") is String:
  selected = Catalog.vehicle_index(data.selected_vehicle)
 else:
  selected = int(_number(data.get("selected"), Catalog.DEFAULT_VEHICLE))
 if not selected in available or selected < 0 or selected >= Catalog.VEHICLES.size():
  selected = Catalog.DEFAULT_VEHICLE
 if not Catalog.VEHICLES[selected].id in owned:
  selected = Catalog.DEFAULT_VEHICLE
 character = "ravi" if data.get("character") is String and data.character == "ravi" else "boaz"
 records.clear()
 if data.get("records") is Dictionary:
  for raw_key in data.records:
   var key = str(raw_key)
   if key.is_valid_int():
    var old_index = int(key)
    if old_index < 0 or old_index >= LEGACY_WORLDS.size():
     continue
    key = LEGACY_WORLDS[old_index]
   if not Catalog.valid_track_id(key):
    continue
   var duration = _number(data.records[raw_key], -1)
   if duration > 0:
    records[key] = minf(duration, float(records.get(key, INF)))
 if data.get("settings") is Dictionary:
  for key in ["music", "sound"]:
   settings[key] = clampf(_number(data.settings.get(key), settings[key]), 0, 1)
  settings.difficulty = clampi(int(_number(data.settings.get("difficulty"), 0)), 0, 2)
  var render_height = _number(data.settings.get("render_height"), 0)
  var height_id = int(render_height)
  settings.render_height = height_id if float(height_id) == render_height and height_id in RENDER_HEIGHTS else 0
  for key in ["shadows", "camera_motion", "auto_accelerate", "touch_controls"]:
   if data.settings.get(key) is bool:
    settings[key] = data.settings[key]

 # Persist this revision immediately: later deliberate garage choices remain intact.
 if _number(data.get("version"), 0) < SAVE_VERSION:
  selected = Catalog.DEFAULT_VEHICLE
  save_profile()

func _grant_free_vehicles() -> void:
 for index in available:
  var vehicle: Dictionary = Catalog.VEHICLES[index]
  if vehicle.price == 0 and not vehicle.id in owned:
   owned.append(vehicle.id)

func _failed(message: String) -> bool:
 last_error = message
 storage_failed.emit(message)
 return false

func save_profile() -> bool:
 last_error = ""
 var file = FileAccess.open(storage_path + ".tmp", FileAccess.WRITE)
 if file == null:
  return _failed("Het profielbestand kan niet worden geopend.")
 file.store_string(JSON.stringify({"version":SAVE_VERSION, "coins":coins, "owned":owned,
  "selected_vehicle":Catalog.VEHICLES[selected].id, "character":character,
  "records":records, "settings":settings}))
 file.flush()
 var write_error = file.get_error()
 file.close()
 if write_error != OK:
  return _failed("Het profiel kon niet volledig worden geschreven.")
 var absolute = ProjectSettings.globalize_path(storage_path)
 # Keep the last valid save for recovery; don't overwrite it with damaged JSON.
 if _read(storage_path) != null:
  if DirAccess.copy_absolute(absolute, absolute + ".bak") != OK:
   return _failed("De reservekopie van je profiel kon niet worden bewaard.")
 if DirAccess.rename_absolute(absolute + ".tmp", absolute) != OK:
  return _failed("Het nieuwe profiel kon niet worden opgeslagen.")
 return true

func buy_or_select(index: int) -> bool:
 last_error = ""
 if index < 0 or index >= Catalog.VEHICLES.size() or not index in available:
  return false
 var vehicle: Dictionary = Catalog.VEHICLES[index]
 var old_coins = coins
 var old_owned = owned.duplicate()
 var old_selected = selected
 if not vehicle.id in owned:
  if coins < vehicle.price:
   return false
  coins -= vehicle.price
  owned.append(vehicle.id)
 selected = index
 if not save_profile():
  coins = old_coins
  owned = old_owned
  selected = old_selected
  return false
 return true

func record_for(world: int) -> float:
 return float(records.get(Catalog.track_id(world), 0))

func record_race(world: int, time: float, earned: int) -> bool:
 if world < 0 or world >= Catalog.TRACKS.size() or not is_finite(time) or time <= 0:
  return false
 var old_coins = coins
 var old_records = records.duplicate()
 coins += maxi(0, earned)
 var key = Catalog.track_id(world)
 if time < float(records.get(key, INF)):
  records[key] = time
 if not save_profile():
  coins = old_coins
  records = old_records
  return false
 return true
