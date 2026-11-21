extends RefCounted
const DEFAULT_ID = "02-schouderreus-turkoois"
const DIRECTORY = "res://assets/monsters/"

static func entries() -> Array:
 var data = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "catalog.json"))
 var result: Array = data if data is Array else []
 result.append({"id":"gifspuwer-breekbaar", "name":"Gifspuwer · verfijnd", "format":"fractured", "pieces":76})
 result.append({"id":"dragon", "name":"Tweekoppige draak", "blocks":0})
 return result

static func find(id: String) -> Dictionary:
 for entry in entries():
  if entry.id == id:
   return entry
 return {}
