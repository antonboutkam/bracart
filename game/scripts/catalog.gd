extends RefCounted
## Designs are listed for the garage; the explicit snapshot manifest controls playability.
const DEFAULT_VEHICLE = 0 # Raketfiets; shared by player profiles and invalid-selection fallback.
const VEHICLES = [
 {"id":"raketfiets", "name":"De Raketfiets", "price":0, "speed":40.0, "accel":14.0, "handling":1.0, "color":"32c4d7"},
 {"id":"purple-passion", "name":"Purple Passion", "price":80, "speed":42.0, "accel":13.0, "handling":0.95, "color":"b56aff"},
 {"id":"golden-rocket-racer", "name":"Golden Rocket", "price":140, "speed":44.0, "accel":12.0, "handling":0.9, "color":"ffc44e"},
 {"id":"toxic-turbo", "name":"Toxic Turbo", "price":200, "speed":46.0, "accel":15.0, "handling":0.85, "color":"a4ee35"},
 {"id":"retro", "name":"Retro Racer", "price":0, "speed":41.0, "accel":16.0, "handling":1.1, "color":"ff944f"},
 {"id":"rainbow", "name":"Rainbow Jet", "price":160, "speed":43.0, "accel":14.0, "handling":1.2, "color":"ff79b9"}
]
const WORLDS = [
 {"id":"sunset-park", "name":"Sunset Park", "subtitle":"Raketpret aan de kust", "tag":"KERMIS • GLOOIEND", "sky":"dc7f99", "ground":"26576b", "road":"334c70", "accent":"ffbf61", "image":"sunset"},
 {"id":"neon-city", "name":"Neon City", "subtitle":"Een nacht boven de skyline", "tag":"NEON • SNEL", "sky":"111831", "ground":"151f36", "road":"28314c", "accent":"45e4f6", "image":"sunset"},
 {"id":"regenbogenrijk", "name":"Regenbogenrijk", "subtitle":"Volg de zon boven de wolken", "tag":"WOLKEN • HOOGTE", "sky":"8ec8ef", "ground":"b6c5e9", "road":"9db6cf", "accent":"fe9ac5", "image":"regenbogenrijk"},
 {"id":"haarlem-1888", "name":"Haarlem 1888", "subtitle":"De Grote Stoomrace", "tag":"STOOM • GRACHTEN", "sky":"cba078", "ground":"337781", "road":"806c5e", "accent":"e1a746", "image":"haarlem-1888"},
 {"id":"uithoorn-2056", "name":"Uithoorn 2056", "subtitle":"De Amstel van Morgen", "tag":"ZON • SOLARPUNK", "sky":"87d7ef", "ground":"48a9b9", "road":"a6d0c6", "accent":"ffbc60", "image":"uithoorn-2056"},
 {"id":"keukentafel", "name":"De Keukentafel", "subtitle":"Kleine racers, groot avontuur", "tag":"SPEELGOED • VLAK", "sky":"cdbb9f", "ground":"976742", "road":"b47e50", "accent":"78d4cc", "image":"keukentafel"}
]
# Track selections are independent of the six landscape/weather/audio worlds.
const TRACKS = [
 {"id":"sunset-park","world":0,"variant":1},
 {"id":"neon-city","world":1,"variant":1},
 {"id":"regenbogenrijk","world":2,"variant":1},
 {"id":"haarlem-1888","world":3,"variant":1},
 {"id":"uithoorn-2056","world":4,"variant":1},
 {"id":"keukentafel","world":5,"variant":1},
 {"id":"sunset-park-v2","world":0,"variant":2},
 {"id":"neon-city-v2","world":1,"variant":2},
 {"id":"regenbogenrijk-v2","world":2,"variant":2},
 {"id":"haarlem-1888-v2","world":3,"variant":2},
 {"id":"uithoorn-2056-v2","world":4,"variant":2},
 {"id":"keukentafel-v2","world":5,"variant":2}
]

static func track_id(index: int) -> String:
 return TRACKS[clampi(index,0,TRACKS.size()-1)].id

static func track_name(index: int) -> String:
 var selection: Dictionary = TRACKS[clampi(index,0,TRACKS.size()-1)]
 return WORLDS[selection.world].name+(" · Stunt Edition" if selection.variant==2 else "")

static func valid_track_id(id: String) -> bool:
 return TRACKS.any(func(track): return track.id==id)

const POWERS = ["Boost", "Schild", "Magneet", "Raket", "Bom", "Kanonnen"]

static func available_indices() -> Array:
 var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/manifest.json"))
 var result: Array = []
 if not manifest is Dictionary:
  return result
 for i in VEHICLES.size():
  if manifest.get(VEHICLES[i].id, {}).get("playable", false):
   result.append(i)
 return result

static func world_id(index: int) -> String:
 return WORLDS[clampi(index, 0, WORLDS.size() - 1)].id

static func vehicle_index(id: String) -> int:
 for i in VEHICLES.size():
  if VEHICLES[i].id == id:
   return i
 return -1
