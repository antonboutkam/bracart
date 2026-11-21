extends RefCounted
## A street circuit on the west bank, with one supported start hill.
const Geo = preload("res://scripts/geometry.gd")
const GROUND_Y = -22.0
const ROAD_Y = -21.82
const HILL_HEIGHT = 28.0
const CORNER_RADIUS = 24.0
const SITES = {
 "rechthuis": Vector3(-355,-20.9,-275),
 "schanskerk": Vector3(-350,-20.9,-30),
 "fort-aan-de-drecht": Vector3(-315,-20.9,125),
 "de-hoeksteen": Vector3(-255,-20.9,270),
 "thamerkerk": Vector3(-105,-20.9,-40),
 "irenebrug": Vector3(0,-21.74,-190)
}
const LABELS = {"rechthuis":"Rechthuisbocht", "schanskerk":"Schanskerkbocht", "fort-aan-de-drecht":"Fortbocht", "de-hoeksteen":"Hoeksteenhaarspeld", "thamerkerk":"Thamerkerkbocht", "irenebrug":"Irenebrugkade"}
const OUTLINE = [Vector2(-140,-330),Vector2(-410,-330),Vector2(-410,30),
 Vector2(-255,30),Vector2(-255,215),Vector2(-60,215),Vector2(-60,110),
 Vector2(-160,110),Vector2(-160,-90),Vector2(-60,-90),Vector2(-60,-215),Vector2(-140,-215)]
var curve: Curve3D
var length: float
var visits: Array[Dictionary] = []

func setup() -> void:
 var flat = Curve3D.new()
 flat.bake_interval = 0.25
 # Straight tangents and explicit quarter circles: sharp, but no folded inner lane.
 for i in OUTLINE.size():
  var p: Vector2 = OUTLINE[i]
  var incoming: Vector2 = (p-OUTLINE[posmod(i-1,OUTLINE.size())]).normalized()
  var outgoing: Vector2 = (OUTLINE[(i+1)%OUTLINE.size()]-p).normalized()
  var a = p-incoming*CORNER_RADIUS
  var b = p+outgoing*CORNER_RADIUS
  var handle = CORNER_RADIUS*0.55228475
  if i == 0:
   flat.add_point(Vector3(b.x,0,b.y),Vector3(-outgoing.x,0,-outgoing.y)*handle)
  else:
   flat.add_point(Vector3(a.x,0,a.y),Vector3.ZERO,Vector3(incoming.x,0,incoming.y)*handle)
   flat.add_point(Vector3(b.x,0,b.y),Vector3(-outgoing.x,0,-outgoing.y)*handle)
 # Close the final straight and round the start corner.
 var last_in: Vector2 = (OUTLINE[0]-OUTLINE[-1]).normalized()
 var last_a: Vector2 = OUTLINE[0]-last_in*CORNER_RADIUS
 flat.add_point(Vector3(last_a.x,0,last_a.y),Vector3.ZERO,Vector3(last_in.x,0,last_in.y)*CORNER_RADIUS*0.55228475)
 flat.add_point(flat.get_point_position(0),flat.get_point_in(0))
 var flat_length = flat.get_baked_length()
 curve = Curve3D.new()
 curve.bake_interval = 0.4
 var count = int(ceil(flat_length))
 for i in count+1:
  var d = flat_length*i/count
  var p = flat.sample_baked(d,true)
  # The return climb belongs to the same hill, so the lap joins without a teleport.
  var rise = 1.0-smoothstep(16,116,d) if d<flat_length/2 else smoothstep(flat_length-118,flat_length-18,d)
  p.y = ROAD_Y+HILL_HEIGHT*rise
  curve.add_point(p)
 length = curve.get_baked_length()
 for id in SITES:
  var p: Vector3 = SITES[id]
  visits.append({"id":id,"name":LABELS[id],"distance":curve.get_closest_offset(Vector3(p.x,ROAD_Y,p.z))})
 visits.sort_custom(func(a,b): return a.distance<b.distance)

func build_hill(track: Node3D) -> void:
 var surface = SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 surface.set_material(Geo.material(Color("79965c")))
 for i in int(ceil(length/2)):
  var a: Transform3D = track.frame(i*2.0)
  var b: Transform3D = track.frame(minf((i+1)*2.0,length))
  if maxf(a.origin.y,b.origin.y)<ROAD_Y+0.01: continue
  for side in [-1,1]:
   var upper_a = a.origin+a.basis.x*side*(track.width+0.7)-Vector3.UP*0.08
   var upper_b = b.origin+b.basis.x*side*(track.width+0.7)-Vector3.UP*0.08
   var lower_a = upper_a+a.basis.x*side*maxf(1,(a.origin.y-GROUND_Y)*1.15)
   var lower_b = upper_b+b.basis.x*side*maxf(1,(b.origin.y-GROUND_Y)*1.15)
   lower_a.y = GROUND_Y+0.015
   lower_b.y = GROUND_Y+0.015
   var vertices = [upper_a,lower_b,upper_b,upper_a,lower_a,lower_b]
   if side<0: vertices.reverse()
   for v in vertices: surface.add_vertex(v)
  # Narrow shoulders cover the join between road and earth.
  for side in [-1,1]:
   var x = a.origin+a.basis.x*side*track.width-Vector3.UP*0.08
   var y = b.origin+b.basis.x*side*track.width-Vector3.UP*0.08
   for v in [x,y+a.basis.x*side*0.7,y,x,x+a.basis.x*side*0.7,y+a.basis.x*side*0.7]: surface.add_vertex(v)
 surface.generate_normals()
 var hill = MeshInstance3D.new()
 hill.name = "StartHill"
 hill.mesh = surface.commit()
 hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
 track.add_child(hill)

func section_name(distance: float) -> String:
 var d = fposmod(distance,length)
 if d<130 or d>length-130: return "Startheuvel"
 for visit in visits:
  if d<visit.distance+45: return visit.name
 return "Terug naar de startheuvel"
