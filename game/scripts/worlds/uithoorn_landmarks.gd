extends RefCounted
## Imported, photo-informed landmarks; registry is shared by game and review captures.
const GroundCourse = preload("res://scripts/worlds/uithoorn_ground_course.gd")
const Geo = preload("res://scripts/geometry.gd")
const ENTRIES = [
 {"id":"rechthuis","label":"Het Rechthuis","section":0,"bounds":AABB(Vector3(-12.50000,0.00000,-13.50000),Vector3(25.00000,13.40000,22.80000)),"model_path":"res://assets/models/uithoorn-rechthuis.glb"},
 {"id":"schanskerk","label":"Schanskerk","section":1,"bounds":AABB(Vector3(-12.75000,0.00000,-35.80000),Vector3(25.50000,39.00000,60.63500)),"model_path":"res://assets/models/uithoorn-schanskerk.glb"},
 {"id":"fort-aan-de-drecht","label":"Fort aan de Drecht","section":4,"bounds":AABB(Vector3(-27.00000,0.00000,-20.50000),Vector3(59.20000,8.80000,44.50000)),"model_path":"res://assets/models/uithoorn-fort-aan-de-drecht.glb"},
 {"id":"irenebrug","label":"Irenebrug","section":2,"bounds":AABB(Vector3(-24.12500,0.00000,-9.85000),Vector3(48.25000,9.77500,15.85000)),"model_path":"res://assets/models/uithoorn-irenebrug.glb"},
 {"id":"thamerkerk","label":"Thamerkerk","section":3,"bounds":AABB(Vector3(-11.44000,0.00000,-8.84000),Vector3(22.88000,23.00000,19.34000)),"model_path":"res://assets/models/uithoorn-thamerkerk.glb"},
 {"id":"de-hoeksteen","label":"De Hoeksteen","section":5,"bounds":AABB(Vector3(-12.71000,0.00000,-12.71000),Vector3(32.71000,14.77500,25.58500)),"model_path":"res://assets/models/uithoorn-de-hoeksteen.glb"}
]

static func build_model(parent: Node3D, entry: Dictionary) -> bool:
 if not ResourceLoader.exists(str(entry.get("model_path",""))): return false
 var scene = load(entry.model_path) as PackedScene
 if scene == null: return false
 var model = scene.instantiate() as Node3D
 if model == null: return false
 parent.add_child(model)
 parent.name = "Landmark_"+str(entry.id).replace("-","_")
 parent.set_meta("uithoorn_landmark",entry.id)
 parent.set_meta("bounds",entry.bounds)
 parent.set_meta("section",entry.section)
 parent.set_meta("model_path",entry.model_path)
 return true

static func radius(entry: Dictionary) -> float:
 var b: AABB = entry.bounds
 return Vector2(maxf(absf(b.position.x),absf(b.end.x)),maxf(absf(b.position.z),absf(b.end.z))).length()

static func clear_site(track: Node3D, p: Vector3, envelope: float, samples: Array[Vector3]) -> bool:
 for q in samples:
  if Vector2(p.x-q.x,p.z-q.z).length()<envelope+track.width+6: return false
 for i in 360:
  var a = TAU*i/360.0
  if Vector2(p.x-83-49*cos(a),p.z-100*sin(a)).length()<envelope+7: return false
 if Vector2(p.x+38,p.z-44).length()<envelope+25: return false
 for site in track.get_meta("scenic_sites",[]):
  if Vector2(p.x-site.position.x,p.z-site.position.z).length()<envelope+float(site.radius)+8: return false
 return true

static func build(track: Node3D, _samples: Array[Vector3]) -> void:
 if track.world_index != 4: return
 # Full route sampling also protects the extended Stunt Edition track/camera.
 var corridor: Array[Vector3] = []
 for i in int(ceil(track.length/0.5)): corridor.append(track.position_at(i*0.5))
 for entry in ENTRIES:
  var envelope = radius(entry)
  var best = Vector3.INF
  var target: Vector3 = track.position_at(track.length*(entry.section/6.0+0.035))
  var candidates: Array[Dictionary] = []
  for x in range(-260,261,10):
   if entry.id == "irenebrug" and x != 0: continue
   if entry.id != "irenebrug" and absf(x)<envelope+27: continue
   for z in range(-260,261,10):
    var p = Vector3(x,-21.74 if entry.id == "irenebrug" else -20.9,z)
    candidates.append({"position":p,"score":Vector2(p.x-target.x,p.z-target.z).length_squared()})
  candidates.sort_custom(func(a,b): return a.score<b.score)
  # Authored classic-course review positions retain the same corridor guard.
  # The Schanskerk body must remain visible below its spires in the follow view.
  var preferred: Dictionary = entry.get("preferred_sites",{}).duplicate()
  if track.ground_course != null: preferred[4] = GroundCourse.SITES[entry.id]
  if preferred.has(track.track_index):
   candidates.push_front({"position":preferred[track.track_index],"score":-INF})
  for candidate in candidates:
   if clear_site(track,candidate.position,envelope,corridor):
    best = candidate.position
    if preferred.has(track.track_index) and best.is_equal_approx(preferred[track.track_index]):
     # Point the photographed front toward the nearest actual course segment.
     var nearest = INF
     for point in corridor:
      var distance = Vector2(point.x-best.x,point.z-best.z).length_squared()
      if distance<nearest:
       nearest=distance
       target=point
    break
  if not best.is_finite():
   push_warning("No safe Uithoorn landmark site: "+entry.id)
   continue
  if track.ground_course != null:
   var closest = track.curve.get_closest_offset(Vector3(best.x,GroundCourse.ROAD_Y,best.z))
   target = track.position_at(closest-({"thamerkerk":135.0}.get(entry.id,75.0)))
  var holder = Node3D.new()
  track.add_child(holder)
  holder.position = best
  if entry.id != "irenebrug":
   holder.rotation.y = atan2(target.x-best.x,target.z-best.z)
   # A reviewed front can face the approach along the road rather than its side.
   if track.ground_course == null and preferred.has(track.track_index) and best.is_equal_approx(preferred[track.track_index]):
    holder.rotation.y += entry.get("preferred_front_offsets",{}).get(track.track_index,0.0)
  if not build_model(holder,entry):
   holder.free()
   push_warning("Uithoorn model import unavailable: "+entry.id)
   continue
  if entry.id != "irenebrug":
   var b: AABB = entry.bounds
   # Ground top is -22. Imported architectural datum is placed at -20.9.
   var foundation = Geo.box(holder,Vector3(b.get_center().x,-0.55,b.get_center().z),Vector3(b.size.x+0.6,1.1,b.size.z+0.6),Color("a69a84"))
   foundation.name = "GroundSupport"
  var sites: Array = track.get_meta("scenic_sites",[])
  sites.append({"position":best,"radius":envelope+0.5,"uithoorn_landmark":entry.id})
  track.set_meta("scenic_sites",sites)
