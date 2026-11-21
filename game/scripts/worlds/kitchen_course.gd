extends RefCounted
## World-five-only sampled arc-length route, with analytic bank axes through inversion.
const Geo = preload("res://scripts/geometry.gd")
const LOOP_RADIUS = 9.0
const LOOP_SHIFT = 22.0
const LOOP_REPLACE = 14.0
var base: Curve3D
var base_length: float
var length: float
var loop_right: Vector3
var loop_start: float
var loop_span: float = TAU*LOOP_RADIUS+LOOP_REPLACE
var loop_extra: float = TAU*LOOP_RADIUS
var frames: Array[Transform3D] = []
var distances := PackedFloat64Array()
var q_values := PackedFloat64Array()
var curve: Curve3D
var features: Array[Dictionary] = []
var source_specs: Array[Dictionary] = []

func setup(source: Curve3D) -> void:
 base = source
 base_length = base.get_baked_length()
 loop_start = base_length*0.26
 loop_right = _base_forward(loop_start).cross(Vector3.UP).normalized()
 source_specs = [
  {"id":"toilet_rolls","base":base_length*0.055,"length":18.0,"height":5.3},
  {"id":"loose_cables","base":base_length*0.18,"length":12.0,"height":0.12},
  {"id":"orange_loop","base":loop_start,"length":LOOP_REPLACE,"height":18.12},
  {"id":"pvc_rainbow","base":base_length*0.52,"length":18.0,"height":5.3},
  {"id":"comic_ramp","base":base_length*0.68,"length":10.0,"height":3.3},
  {"id":"card_ramp","base":base_length*0.84,"length":10.0,"height":2.5}
 ]
 var total: float = base_length+loop_extra
 var samples: int = int(ceil(total/0.28))
 curve = Curve3D.new()
 curve.bake_interval = 0.28
 var previous := Vector3.ZERO
 var travelled: float = 0
 for index in samples+1:
  var q: float = total*index/samples
  var position_value: Vector3 = _position(q)
  var tangent: Vector3 = (_position(q+0.14)-_position(q-0.14)).normalized()
  var on_loop: bool = q >= loop_start and q <= loop_start+loop_span
  var reference: Vector3 = _base_forward(_base_distance(q)).cross(Vector3.UP).normalized() if on_loop else tangent.cross(Vector3.UP).normalized()
  # Reference is a horizontal axle, never forward.cross(UP) on the vertical loop.
  var right: Vector3 = (reference-tangent*reference.dot(tangent)).normalized()
  var up: Vector3 = right.cross(tangent).normalized()
  if index > 0: travelled += previous.distance_to(position_value)
  frames.append(Transform3D(Basis(right,up,-tangent).orthonormalized(),position_value))
  distances.append(travelled)
  q_values.append(q)
  curve.add_point(position_value)
  previous = position_value
 length = travelled
 _metadata()

func _base_distance(q: float) -> float:
 var d: float = fposmod(q,base_length+loop_extra)
 if d < loop_start: return d
 if d <= loop_start+loop_span: return loop_start+LOOP_REPLACE*(d-loop_start)/loop_span
 return d-loop_extra

func _base_forward(d: float) -> Vector3:
 return (base.sample_baked(fposmod(d+0.6,base_length),true)-base.sample_baked(fposmod(d-0.6,base_length),true)).normalized()

func _height(d: float) -> float:
 for spec in source_specs:
  var center: float = spec.base
  if spec.id in ["toilet_rolls","pvc_rainbow"]:
   var edge: float = absf(d-center)-spec.length*0.5
   if edge <= 0: return spec.height
   if edge < 15: return lerpf(spec.height,0.12,smoothstep(0,15,edge))
  elif spec.id in ["comic_ramp","card_ramp"]:
   var t: float = (d-center)/10
   if t >= 0 and t <= 1:
    return 0.12+(spec.height-0.12)*(2*t*t-t*t*t)
   var u: float = (d-center-10)/22
   if u > 0 and u < 1:
    # Continuous virtual flight guide above the visible ramp gap, easing to table.
    var h: float = spec.height-0.12
    return 0.12+(2*u*u*u-3*u*u+1)*h+(u*u*u-2*u*u+u)*(h/10*22)
 return 0.12

func _position(q: float) -> Vector3:
 var wrapped: float = fposmod(q,base_length+loop_extra)
 var d: float = _base_distance(q)
 var forward: Vector3 = _base_forward(d)
 var right: Vector3 = forward.cross(Vector3.UP).normalized()
 var point: Vector3 = base.sample_baked(d,true)
 if wrapped >= loop_start and wrapped <= loop_start+loop_span:
  var t: float = (wrapped-loop_start)/loop_span
  point += forward*LOOP_RADIUS*sin(t*TAU)+Vector3.UP*(LOOP_RADIUS*(1-cos(t*TAU)))+loop_right*LOOP_SHIFT*smoothstep(0,1,t)
 else:
  point.y = _height(d)
  var after: float = d-loop_start-LOOP_REPLACE
  if after >= 0 and after < 45:
   point += loop_right*LOOP_SHIFT*(1-smoothstep(0,45,after))
 return point

func _lookup(values: PackedFloat64Array, value: float) -> int:
 var low: int = 0
 var high: int = values.size()-1
 while high-low > 1:
  var middle: int = (low+high)/2
  if values[middle] <= value: low = middle
  else: high = middle
 return low

func frame(distance: float) -> Transform3D:
 var d: float = fposmod(distance,length)
 var index: int = _lookup(distances,d)
 var fraction: float = (d-distances[index])/maxf(0.00001,distances[index+1]-distances[index])
 return Transform3D(frames[index].basis.slerp(frames[index+1].basis,fraction).orthonormalized(),frames[index].origin.lerp(frames[index+1].origin,fraction))

func mapped(base_distance: float) -> float:
 var q: float = base_distance+(loop_extra if base_distance > loop_start+LOOP_REPLACE else 0.0)
 var index: int = _lookup(q_values,q)
 return lerpf(distances[index],distances[index+1],(q-q_values[index])/(q_values[index+1]-q_values[index]))

func _metadata() -> void:
 for spec in source_specs:
  var feature: Dictionary = spec.duplicate()
  feature.width = 14.0
  feature.half_width = 7.0
  if spec.id == "orange_loop":
   feature.start = mapped(loop_start)
   var q: float = loop_start+loop_span
   var index: int = _lookup(q_values,q)
   feature.end = lerpf(distances[index],distances[index+1],(q-q_values[index])/(q_values[index+1]-q_values[index]))
   feature.radius = LOOP_RADIUS
   feature.exit_shift = LOOP_SHIFT
  elif spec.id in ["toilet_rolls","pvc_rainbow"]:
   feature.start = mapped(spec.base-9)
   feature.end = mapped(spec.base+9)
   feature.entry_start = mapped(spec.base-24)
   feature.entry_end = mapped(spec.base+24)
   feature.plateau_start = feature.start
   feature.plateau_end = feature.end
   feature.inner_radius = 15.5 if spec.id == "pvc_rainbow" else 12.4
   feature.outer_radius = 16.3 if spec.id == "pvc_rainbow" else 13.2
   feature.axis_height = 16.4 if spec.id == "pvc_rainbow" else 13.3
  elif spec.id in ["comic_ramp","card_ramp"]:
   feature.start = mapped(spec.base)
   feature.lip = mapped(spec.base+10)
   feature.end = mapped(spec.base+32)
   feature.landing = feature.end
   feature.lead_length = feature.lip-feature.start
   feature.start_frame = frame(feature.start)
   feature.lip_frame = frame(feature.lip)
   feature.length = feature.start_frame.origin.distance_to(feature.lip_frame.origin)
  else:
   feature.start = mapped(spec.base-spec.length*0.5)
   feature.end = mapped(spec.base+spec.length*0.5)
   feature.clearance = 5.5
  feature.center = (feature.start+feature.end)*0.5
  feature.mid = feature.center
  feature.frame = frame((feature.start+feature.lip)*0.5) if feature.has("lip") else frame(feature.center)
  feature.road_surface_height = feature.frame.origin.y
  features.append(feature)

func feature_at(distance: float) -> Dictionary:
 var d: float = fposmod(distance,length)
 for feature in features:
  if d >= feature.start and d <= feature.end: return feature
 return {}

func build_loop(track: Node3D) -> void:
 var loop: Dictionary = features[2]
 var root := Node3D.new()
 root.name = "OrangeToyLoop"
 track.add_child(root)
 for side in [0,1,2]:
  var material := Geo.material(Color("f27422") if side == 0 else Color("e35413"))
  material.roughness = 0.32
  var surface := SurfaceTool.new()
  surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  surface.set_material(material)
  for index in 300:
   var a: Transform3D = frame(lerpf(loop.start,loop.end,float(index)/300))
   var b: Transform3D = frame(lerpf(loop.start,loop.end,float(index+1)/300))
   var left: float = -7 if side == 0 else (-7.15 if side == 1 else 6.95)
   var right: float = 7 if side == 0 else (-6.95 if side == 1 else 7.15)
   var lift: float = 0 if side == 0 else 0.65
   var p: Vector3 = a.origin+a.basis.x*left+a.basis.y*lift
   var q: Vector3 = a.origin+a.basis.x*right+a.basis.y*lift
   var r: Vector3 = b.origin+b.basis.x*right+b.basis.y*lift
   var s: Vector3 = b.origin+b.basis.x*left+b.basis.y*lift
   for vertex in [p,r,q,p,s,r]: surface.add_vertex(vertex)
   if side > 0:
    var below_a: Vector3 = a.basis.y*0.87
    var below_b: Vector3 = b.basis.y*0.87
    for vertex in [p,s-below_b,s,p,p-below_a,s-below_b,q,r,r-below_b,q,r-below_b,q-below_a]: surface.add_vertex(vertex)
   # Underside gives the plastic ribbon real thickness, visible while inverted.
   for vertex in [p-a.basis.y*0.22,q-a.basis.y*0.22,r-b.basis.y*0.22,p-a.basis.y*0.22,r-b.basis.y*0.22,s-b.basis.y*0.22]: surface.add_vertex(vertex)
  surface.generate_normals()
  var mesh := MeshInstance3D.new()
  mesh.mesh = surface.commit()
  root.add_child(mesh)

func launch_velocity(before: float, after: float) -> float:
 for feature in features:
  if not feature.has("lip"): continue
  var lap: float = floor(before/length)
  var crossing: float = lap*length+feature.lip
  if before < crossing and after >= crossing: return 5.0
 return 0.0
