extends RefCounted
const DEFAULT_ID = "gifspuwer-breekbaar"
const DIRECTORY = "res://assets/monsters/"

static func entries() -> Array:
 var result: Array = []
 result.append({"id":"gifspuwer-breekbaar", "name":"Gifspuwer · verfijnd", "format":"fractured", "pieces":76})
 result.append({"id":"slakkenoog-breekbaar", "name":"Slakkenoog · verfijnd", "format":"fractured", "pieces":72})
 result.append({"id":"stippelmonster-breekbaar", "name":"Bolle Stippel · verfijnd", "format":"fractured", "pieces":72})
 result.append({"id":"stekelmonster-breekbaar", "name":"Paars Stekelmonster · verfijnd", "format":"fractured", "pieces":72})
 result.append({"id":"pluismonster-breekbaar", "name":"Oranje Pluismonster · verfijnd", "format":"fractured", "pieces":72})
 result.append({"id":"girafnek-breekbaar", "name":"Gele Girafnek · verfijnd", "format":"fractured", "pieces":72})
 result.append({"id":"robotmonster-breekbaar", "name":"Mini-Robotmonster · verfijnd", "format":"fractured", "pieces":72})
 result.append({"id":"paars-spook-breekbaar", "name":"Paars Spook · verfijnd", "format":"fractured", "pieces":72})
 return result

static func find(id: String) -> Dictionary:
 for entry in entries():
  if entry.id == id:
   return entry
 # Legacy models stay loadable for compatibility and regression tests, but are
 # deliberately absent from every user-facing selection menu.
 var data = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "catalog.json"))
 if data is Array:
  for entry in data:
   if entry.id == id:
    return entry
 return {}
