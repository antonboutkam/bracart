extends RefCounted
## Readable silhouettes and safe roadside placement for six procedural worlds.
## Decorative models never define race collision or replace the guided road.
const Geo = preload("res://scripts/geometry.gd")
const Art = preload("res://scripts/worlds/world_art.gd")
const Districts = preload("res://scripts/worlds/street_districts.gd")
const Tram = preload("res://scripts/worlds/tram.gd")
const Architecture = preload("res://scripts/worlds/architecture.gd")
const UithoornLandmarks = preload("res://scripts/worlds/uithoorn_landmarks.gd")
const HaarlemLandmarks = preload("res://scripts/worlds/haarlem_landmarks.gd")

static func build(track: Node3D, world: Dictionary) -> void:
 var first_scenery = track.get_child_count()
 var samples: Array[Vector3] = []
 var sample_count: int = int(ceil(track.length/1.5)) if track.v2_course != null else 240
 for i in sample_count:
  samples.append(track.position_at(track.length * i / float(sample_count)))
 if track.world_index == 5:
  _kitchen(track, samples)
  _signs(track)
  Art.finish(track,first_scenery)
  return
 if track.world_index != 2:
  Geo.box(track, Vector3(0, -23, 0), Vector3(1700, 2, 1700), Color("709b78") if track.ground_course != null else Color(world.ground))
 if track.world_index in [0, 3, 4]:
  var water = Geo.box(track, Vector3(0, -21.8, 0), Vector3(49, 0.12, 900), Color("4396a6") if track.world_index != 0 else Color("528f9e"))
  water.material_override.roughness = 0.23
 # Modest skyline: nearby silhouettes carry the identity, distant ones depth.
 var rng = RandomNumberGenerator.new()
 rng.seed = 6041 + track.world_index
 for i in 30:
  var angle = TAU * i / 30
  var radius = track.table_half.length()+rng.randf_range(90,230) if track.v2_course != null else rng.randf_range(180, 320)
  var p = Vector3(sin(angle) * radius, -21, cos(angle) * radius)
  match track.world_index:
   0: _tree(track, p, 1.5)
   1:
    _tower(track, p, rng.randf_range(28, 90), Color("26324c"), Color("5ed9eb") if i % 2 else Color("ec6bce"))
   2:
    p.y = rng.randf_range(-20, 14)
    _cloud(track, p, 2.5)
   3, 4: pass
 for i in 18:
  if track.ground_course != null: continue
  var d: float = track.length * (i + 0.45) / 18.0
  var side = -1 if i % 2 == 0 else 1
  var radius = 12.0 if track.world_index != 2 else 22.0
  var p = _site(track, samples, d, side, radius)
  if not p.is_finite(): continue
  match track.world_index:
   0:
    Geo.ball(track, p - Vector3.UP * 3, Vector3(22, 6, 20), Color("468575"))
    _tent(track, p, i)
   1: _tower(track, p - Vector3.UP * 7, 19 + (i % 4) * 9, Color("24344e"), Color("53deee") if i % 2 else Color("eb77d8"))
   2: _cloud(track, p - Vector3.UP * 6, 1.5)
   3, 4: pass
 match track.world_index:
  0: _sunset(track, samples)
  1: _neon(track)
  2: _rainbow(track, samples)
  3: _haarlem(track, samples)
  4: _uithoorn(track, samples)
 if track.world_index in [3,4]: Districts.build(track)
 if track.world_index == 4: Tram.build(track)
 load("res://scripts/worlds/outdoor_life.gd").build(track)
 _signs(track)
 Art.finish(track,first_scenery)

static func _clear(p: Vector3, radius: float, track: Node3D, samples: Array[Vector3]) -> bool:
 for q in samples:
  if Vector2(p.x - q.x, p.z - q.z).length() < track.width + radius + 3.5:
   return false
 return true

static func _site(track: Node3D, samples: Array[Vector3], d: float, side: int, radius: float) -> Vector3:
 if track.v2_course != null: d = track.v2_course.scenery_distance(d)
 for step in 10:
  var p: Vector3 = track.position_at(d, side * (track.width + radius + 7 + step * 7))
  if track.world_index == 5 and (absf(p.x) + radius > track.table_half.x-3.5 or absf(p.z) + radius > track.table_half.y-3.5):
   continue
  if _clear(p, radius, track, samples):
   var sites: Array = track.get_meta("scenic_sites", [])
   sites.append({"position":p,"radius":radius})
   track.set_meta("scenic_sites",sites)
   return p
 return Vector3.INF

static func _root(track: Node3D, samples: Array[Vector3], fraction: float, side: int, radius: float) -> Node3D:
 var p = _site(track, samples, track.length * fraction, side, radius)
 if not p.is_finite(): return null
 var root = Node3D.new()
 track.add_child(root)
 root.position = p
 # Level props, while the road is free to bank and slope independently.
 var d: float = track.length*fraction
 if track.v2_course != null: d = track.v2_course.scenery_distance(d)
 var f: Transform3D = track.frame(d)
 root.rotation.y = atan2(f.basis.x.z, f.basis.x.x) * -1
 return root

static func _tree(parent: Node3D, p: Vector3, scale_value: float = 1) -> void:
 Geo.cylinder(parent, p + Vector3.UP * 4 * scale_value, 0.65 * scale_value, 8 * scale_value, Color("8e7050"))
 Geo.ball(parent, p + Vector3.UP * 10 * scale_value, Vector3(8, 12, 8) * scale_value, Color("65a47c"))

static func _cloud(parent: Node3D, p: Vector3, scale_value: float) -> void:
 for i in 3:
  var puff = Geo.ball(parent, p + Vector3(i * 5 - 5, sin(i * 2) * 2, 0) * scale_value, Vector3(15, 8 + i, 13) * scale_value, Color("fff0ea") if i % 2 else Color("f3edf6"))
  puff.set_meta("scenery_semantic","cloud")
  puff.material_override.roughness = 0.98
  puff.material_override.metallic_specular = 0.08
  parent.add_ambient_motion(puff,Vector3.UP,0.9,0.23,i * 1.7 + p.x * 0.03)

static func _tent(parent: Node3D, p: Vector3, index: int) -> void:
 var color = Color.from_hsv(fposmod(index * 0.19, 1.0), 0.55, 0.94)
 Geo.cylinder(parent, p + Vector3.UP * 3, 5.5, 6, Color("f6deb5"))
 Geo.cylinder(parent, p + Vector3.UP * 8, 7, 5, color, 0)
 Geo.box(parent, p + Vector3(0, 2.3, -5.4), Vector3(4, 4, 0.2), color)

static func _tower(parent: Node3D, p: Vector3, height: float, color: Color, light: Color) -> void:
 # A continuous pedestal anchors the elevated skyline to the city floor.
 if p.y > -21:
  Geo.box(parent,Vector3(p.x,(-22 + p.y) / 2,p.z),Vector3(10,p.y + 22,12),color)
 Geo.box(parent, p + Vector3.UP * height / 2, Vector3(10, height, 12), color)
 for j in 4:
  var strip = Geo.box(parent, p + Vector3(0, 4 + j * (height - 5) / 4, -6.1), Vector3(8.5, 0.45, 0.12), light)
  strip.material_override = Geo.material(light, 0.65)
 Geo.box(parent, p + Vector3(0, height + 0.3, 0), Vector3(10.5, 0.6, 12.5), light)
 var windows: Array[Vector3] = []
 for row in int(height / 3.5):
  for col in 3:
   for side in [-1,1]: windows.append(p + Vector3(-3 + col * 3,2 + row * 3.5,side * 6.12))
 Art.batch_boxes(parent,windows,Vector3(1.5,1.6,0.15),light.darkened(0.2),0.3)
 Art.box(parent,p + Vector3(2,height + 2,2),Vector3(3,3.5,4),"metal",Color("819aa6"),0.4)

static func _house(parent: Node3D, p: Vector3, index: int, solar: bool) -> void:
 Architecture.house(parent, p, index, solar)

static func _arch(track: Node3D, fraction: float, color: Color, radius: float = 12, thickness: float = 0.35) -> void:
 if track.v2_course != null and not track.v2_course.scenery_safe(track.length*fraction,24): return
 var root = Node3D.new()
 track.add_child(root)
 root.transform = track.frame(track.length * fraction)
 for i in 20:
  var a = PI * i / 20
  var b = PI * (i + 1) / 20
  Geo.beam(root, Vector3(cos(a) * radius, sin(a) * radius, 0), Vector3(cos(b) * radius, sin(b) * radius, 0), thickness, color)

static func _sunset(track: Node3D, samples: Array[Vector3]) -> void:
 var stand = _root(track, samples, 0.16, 1, 27)
 if stand:
  for x in [-12, 12]:
   Geo.beam(stand, Vector3(x, -18, 0), Vector3(0, 16, 0), 0.8, Color("f0b077"))
  var wheel = Node3D.new()
  stand.add_child(wheel)
  wheel.position.y = 16
  for i in 18:
   var a = TAU * i / 18
   var b = TAU * (i + 1) / 18
   var p = Vector3(cos(a), sin(a), 0) * 23
   Geo.beam(wheel, p, Vector3(cos(b), sin(b), 0) * 23, 0.4, track.accent)
   Geo.beam(wheel, Vector3.ZERO, p, 0.12, Color("f0b7bd"))
   Geo.ball(wheel, p, Vector3(3.5, 4, 3.5), Color.from_hsv(i / 18.0, 0.6, 1))
  track.rotating.append(wheel)
 var coaster = _root(track, samples, 0.7, -1, 32)
 if coaster:
  for i in 18:
   var a = Vector3(-28 + i * 3.2, 8 + sin(i * 0.36) * 12, 0)
   var b = Vector3(-28 + (i + 1) * 3.2, 8 + sin((i + 1) * 0.36) * 12, 0)
   Geo.beam(coaster, a, b, 0.45, Color("ffbd7c"))
   if i % 3 == 0: Geo.beam(coaster, Vector3(a.x, -18, 0), a, 0.3, Color("8f6385"))

static func _neon(track: Node3D) -> void:
 # Open arches are a tunnel silhouette without hiding the camera or the road.
 for i in 8:
  _arch(track, 0.33 + i * 0.012, Color("e971d8") if i % 2 else Color("61ddf0"), 12, 0.4)
 for fraction in [0.12, 0.58, 0.83]:
  if track.v2_course != null and not track.v2_course.scenery_safe(track.length*fraction): continue
  var sign_root = Node3D.new()
  track.add_child(sign_root)
  sign_root.transform = track.frame(track.length * fraction)
  Geo.box(sign_root, Vector3(track.width + 5, 10, 0), Vector3(6, 3.5, 0.3), Color("31436a"))
  Geo.text(sign_root, "NEON →", Vector3(track.width + 5, 10, 0.2), 62)

static func _rainbow(track: Node3D, samples: Array[Vector3]) -> void:
 # Spectrum follows the tunnel; a double sunrise arch anchors the start.
 for i in 7:
  _arch(track, 0.30 + i * 0.012, Color.from_hsv(i / 7.0, 0.55, 1), 12 + sin(i * 0.4), 0.5)
 for i in 7:
  _arch(track, 0.035, Color.from_hsv(i / 7.0, 0.5, 1), 19 + i * 0.8, 0.45)
 for fraction in [0.60, 0.69, 0.76]:
  var island = _root(track, samples, fraction, -1, 17)
  if not island: continue
  Geo.ball(island, Vector3(0,-5,0), Vector3(29, 8, 25), Color("9c927c"))
  Geo.ball(island, Vector3(0,-2,0), Vector3(29, 4, 25), Color("79b88b"))
  _tree(island, Vector3(-3,0,0))
  Geo.box(island, Vector3(9,-13,0), Vector3(2,25,3), Color("a5e4ed"))
  for j in 7:
   Geo.ball(island, Vector3(sin(j * 2) * 9, 1, cos(j * 2) * 8), Vector3(1.8,1.3,1.8), Color.from_hsv(j / 7.0,0.5,1))
 # Soft low wisps mask only the outer rim, never the next bend or center lane.
 for i in 5:
  var d: float = track.length * (0.45 + i * 0.012)
  var puff = Geo.ball(track, track.position_at(d, track.width + 2, -1.5), Vector3(9, 4, 8), Color(0.96, 0.96, 1, 0.26))
  puff.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func _church(parent: Node3D, title: String, color: Color) -> void:
 Geo.box(parent, Vector3(0,7,0), Vector3(15,20,26), color)
 Geo.cylinder(parent, Vector3(0,10,0), 12, 9, Color("5e7770"), 0)
 Geo.cylinder(parent, Vector3(0,24,-5), 3.8, 28, color, 2.6)
 Geo.cylinder(parent, Vector3(0,42,-5), 4.6, 12, Color("557569"), 0)
 # A masonry quay supports this landmark next to the elevated raceway.
 var foundation_height = maxf(parent.position.y + 19,1)
 Geo.box(parent,Vector3(0,-3 - foundation_height / 2,0),Vector3(16,foundation_height,27),color.darkened(0.12))
 var nameplate = Geo.text(parent,title,Vector3(0,19,-13.2),62)
 nameplate.rotation.y = PI
 for x in [-4,4]:
  Geo.box(parent, Vector3(x,10,-13.1), Vector3(2.5,6,0.1), Color("dfc996"))

static func _bridge(track: Node3D, fraction: float, solar: bool) -> void:
 if track.v2_course != null and not track.v2_course.scenery_safe(track.length*fraction,38): return
 # Rails follow the same curved surface as the racers, even in banked bends.
 var color = Color("62b6ac") if solar else Color("b88548")
 for side in [-1,1]:
  for i in 6:
   var a: float = track.length * fraction - 18 + i * 6
   var b = a + 6
   var x: float = side * (track.width + 1.2)
   Geo.beam(track,track.position_at(a,x,2),track.position_at(b,x,2),0.35,color)
   Geo.beam(track,track.position_at(a,x,8),track.position_at(b,x,8),0.35,color)
   Geo.beam(track,track.position_at(a,x,2),track.position_at(b,x,8),0.22,color)
   if i % 2 == 0:
    Geo.beam(track,track.position_at(a,x,0),track.position_at(a,x,8),0.35,color)

static func _haarlem_landmarks(track: Node3D, samples: Array[Vector3], entries: Array = HaarlemLandmarks.ENTRIES) -> void:
 var replaced: Array[int] = []
 var section_count: int = load("res://scripts/worlds/routes.gd").SECTIONS[3].size()
 var used_ids: Array = []
 for entry in entries:
  if not HaarlemLandmarks.valid_entry(entry,section_count) or entry.section in replaced or entry.id in used_ids: continue
  var landmark = _root(track,samples,HaarlemLandmarks.section_fraction(entry,section_count),entry.side,entry.radius)
  if landmark == null: continue # Keep the original sign when no safe site exists.
  if not HaarlemLandmarks.build_model(landmark,entry):
   landmark.queue_free()
   continue
  # A closed masonry quay joins the roadside plinth to the city floor.
  var footprint: AABB = entry.bounds
  Art.box(landmark,Vector3(0,(-22-landmark.position.y)/2,0),Vector3(footprint.size.x,landmark.position.y+22,footprint.size.z),"stone",Color("a4957c"),0.35)
  # Front (-Z) faces diagonally toward the approaching driver and the road.
  landmark.rotation.y += entry.side * PI * 0.75
  replaced.append(entry.section)
  used_ids.append(entry.id)
 track.set_meta("haarlem_landmark_sections",replaced)

static func _haarlem(track: Node3D, samples: Array[Vector3]) -> void:
 _haarlem_landmarks(track,samples)
 var church = _root(track,samples,0.035,1,19)
 if church: _church(church,"SINT-BAVO",Color("c3a780"))
 _bridge(track,0.37,false)
 var mill = _root(track,samples,0.55,-1,18)
 if mill:
  Geo.cylinder(mill,Vector3(0,(-22 - mill.position.y) / 2,0),6,mill.position.y + 22,Color("9d7756"))
  Geo.cylinder(mill,Vector3(0,8,0),6,22,Color("9d7756"),3.5)
  Geo.cylinder(mill,Vector3(0,21,0),6,6,Color("574c3c"),0)
  var sails = Node3D.new()
  mill.add_child(sails)
  sails.position = Vector3(0,19,-5)
  for i in 4:
   var blade = Geo.box(sails,Vector3(0,7,0).rotated(Vector3.FORWARD,i * PI / 2),Vector3(2.5,18,0.4),Color("eddbab"))
   blade.rotation.z = -i * PI / 2
  track.rotating.append(sails)
  Geo.text(mill,"DE ADRIAAN",Vector3(0,28,-6),62)
 var boiler = _root(track,samples,0.74,1,20)
 if boiler:
  Geo.cylinder(boiler,Vector3(0,(-22 - boiler.position.y) / 2,0),9,boiler.position.y + 22,Color("ad713d"))
  Geo.cylinder(boiler,Vector3(0,6,0),9,14,Color("ad713d"))
  Geo.ball(boiler,Vector3(0,14,0),Vector3(18,8,18),Color("d7a355"))
  Geo.box(boiler,Vector3(0,3,-9.1),Vector3(7,5,0.2),Color("f3af56"))
  for i in 3:
   var steam = Geo.ball(boiler,Vector3(-5 + i * 5,19 + i * 3,0),Vector3.ONE * (3.0 + i),Color("eee1cf"))
   steam.set_meta("scenery_semantic","steam")
   steam.material_override.roughness = 0.98
   track.add_ambient_motion(steam,Vector3.UP,1.4,0.65,i * 1.8)
  for x in [-12,12]:
   Geo.cylinder(boiler,Vector3(x,8,0),1.3,25,Color("bc8c50"))
   _gear(boiler,Vector3(x,14,-2),4,track)
 var airship = _root(track,samples,0.25,-1,26)
 if airship:
  Geo.ball(airship,Vector3(0,38,0),Vector3(19,14,38),Color("edd4a1"))
  Geo.box(airship,Vector3(0,27,0),Vector3(8,5,15),Color("916a49"))
  for z in [-6,6]: Geo.beam(airship,Vector3(0,28,z),Vector3(0,34,z),0.15,Color("ae8c62"))

static func _gear(parent: Node3D, p: Vector3, radius: float, track: Node3D) -> void:
 var gear = Node3D.new()
 parent.add_child(gear)
 gear.position = p
 Art.apply(Geo.ball(gear,Vector3.ZERO,Vector3(radius * 1.7,radius * 1.7,0.8),Color("d4a44b")),"metal",Color("e2b66c"),0.7)
 for i in 10:
  var a = TAU * i / 10
  var tooth = Geo.box(gear,Vector3(cos(a),sin(a),0) * radius,Vector3(1.6,1.6,0.7),Color("d4a44b"))
  tooth.rotation.z = a
 Geo.ball(gear,Vector3(0,0,-0.5),Vector3(1.4,1.4,0.3),Color("52666b"))
 track.rotating.append(gear)

static func _uithoorn(track: Node3D, samples: Array[Vector3]) -> void:
 if track.ground_course != null:
  UithoornLandmarks.build(track,samples)
  return
 _bridge(track,0.38,true)
 for fraction in [0.18,0.28,0.81]:
  var dock = _root(track,samples,fraction,-1,19)
  if not dock: continue
  dock.position.y = -18.1
  dock.position.x = -15.0
  Geo.box(dock,Vector3(0,-3,0),Vector3(29,1,19),Color("e9dfc9"))
  for x in [-8,8]:
   var boat = Node3D.new()
   dock.add_child(boat)
   boat.position.x = x
   boat.position.y = -3.5
   Geo.box(boat,Vector3(0,-1,0),Vector3(7,2,15),Color("f1e6c9"))
   Geo.ball(boat,Vector3(0,1,-1),Vector3(5,3.4,8),Color("63b5bd"))
   Geo.box(boat,Vector3(0,3,1),Vector3(5.5,0.3,5),Color("355d81"))
   track.add_ambient_motion(boat,Vector3.FORWARD,1.4,0.3,x * 0.2)
 var garden = _root(track,samples,0.69,-1,22)
 if garden:
  garden.position.y = -19
  Geo.cylinder(garden,Vector3(0,-3,0),18,4,Color("edf0d1"))
  for j in 4:
   var p = Vector3(sin(j * 1.8) * 10,0,cos(j * 1.8) * 10)
   _tree(garden,p,0.7)
  Geo.text(garden,"AMSTEL • 2056",Vector3(0,16,0),82)
 UithoornLandmarks.build(track,samples)

static func _signs(track: Node3D) -> void:
 var names: Array = load("res://scripts/worlds/routes.gd").SECTIONS[track.world_index]
 if track.ground_course != null: names = track.ground_course.visits.map(func(visit): return visit.name)
 for i in names.size():
  if track.v2_course != null and not track.v2_course.scenery_safe(track.length*(float(i)/names.size()+0.035)): continue
  if track.world_index == 3 and i in track.get_meta("haarlem_landmark_sections",[]): continue
  var root = Node3D.new()
  root.name = "RouteSign_%d" % i
  track.add_child(root)
  root.transform = track.frame(track.ground_course.visits[i].distance-55 if track.ground_course != null else track.length * (float(i) / names.size() + 0.035))
  var x: float = track.width + 3.8
  Geo.cylinder(root,Vector3(x,3.1,0),0.12,6.2,Color("d4d7cb"))
  Geo.box(root,Vector3(x,6.2,0),Vector3(6.5,2.2,0.25),Color("233651"))
  var label = Geo.text(root,names[i],Vector3(x,6.2,0.16),38)
  label.rotation.y = 0

static func _kitchen(track: Node3D, _samples: Array[Vector3]) -> void:
 # Table/room/route ownership remains unchanged; replace the old duplicate props.
 var leg_x: float = track.table_half.x-27.5 if track.v2_course != null else 90.0
 var leg_z: float = track.table_half.y-22.5 if track.v2_course != null else 80.0
 for x in [-leg_x,leg_x]:
  for z in [-leg_z,leg_z]: Geo.box(track,Vector3(x,-30,z),Vector3(7,60,7),Color("78513b"))
 load("res://scripts/worlds/kitchen_props.gd").build(track)
 load("res://scripts/worlds/kitchen_adventure_props.gd").build(track)
