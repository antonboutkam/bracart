extends RefCounted
## V2-only modular course. Distances are true sampled arc metres; scenery and karts
## keep their original scale. Each rectangular leg owns an explicit stunt zone.
const Routes=preload("res://scripts/worlds/routes.gd")
var source_points: Array[Vector3] = []
var curve: Curve3D
var frames: Array[Transform3D] = []
var distances := PackedFloat64Array()
var q_values := PackedFloat64Array()
var features: Array[Dictionary] = []
var length: float
var base_length: float
var a: float
var b: float
var radius: float
var base_height: float
var loop_start := 38.0
var loop_radius := 18.0
var loop_replace := 24.0
var loop_extra: float = TAU*18.0
var loop_span: float = TAU*18.0+24.0
var right_start: float
var bottom_start: float
var left_start: float
var world: int
var table_half := Vector2.ZERO

func setup(original_length: float, world_index: int) -> void:
 world = world_index
 source_points = Routes.points(world)
 base_height = [12.0,17.0,40.0,16.0,25.0,0.12][world]
 var scale_value := 1.0
 for iteration in 5:
  a = (430.0+world*5)*[1.30,0.82,1.15,0.92,0.78,1.05][world]*scale_value
  b = (285.0-world*3)*[0.82,1.35,1.05,1.05,1.45,0.93][world]*scale_value
  radius = 38*scale_value
  base_length = 2*(a+b)+TAU*radius
  right_start = a+PI*radius*0.5
  bottom_start = right_start+b+PI*radius*0.5
  left_start = bottom_start+a+PI*radius*0.5
  _sample()
  scale_value *= (original_length*3.0-loop_extra)/(length-loop_extra)
 table_half = Vector2(a*0.5+radius+48,b*0.5+radius+48)
 _metadata()

func _base_distance(q: float) -> float:
 var d := fposmod(q,base_length+loop_extra)
 if d < loop_start: return d
 if d <= loop_start+loop_span: return loop_start+loop_replace*(d-loop_start)/loop_span
 return d-loop_extra

func _flat(d: float) -> Transform3D:
 var distance := fposmod(d,base_length)
 var origin := Vector3(-a*0.5,base_height,b*0.5+radius)
 var forward := Vector3.RIGHT
 var cursor := 0.0
 for leg in 4:
  var span: float = a if leg%2==0 else b
  if distance <= cursor+span:
   return Transform3D(Basis(forward.cross(Vector3.UP),Vector3.UP,-forward),origin+forward*(distance-cursor))
  origin += forward*span
  cursor += span
  var axle := forward.cross(Vector3.UP)
  var angle := clampf((distance-cursor)/radius,0,PI*0.5)
  if distance <= cursor+PI*radius*0.5:
   var position_value := origin+forward*(radius*sin(angle))-axle*(radius*(1-cos(angle)))
   var tangent := forward*cos(angle)-axle*sin(angle)
   return Transform3D(Basis(tangent.cross(Vector3.UP),Vector3.UP,-tangent),position_value)
  origin += forward*radius-axle*radius
  forward = -axle
  cursor += PI*radius*0.5
 return Transform3D.IDENTITY

func _jump_specs() -> Array:
 return [
  {"id":"small_jump_1","base":a-61,"ramp":14.0,"gap":28.0,"height":3.2},
  {"id":"small_jump_2","base":bottom_start+a-65,"ramp":14.0,"gap":28.0,"height":3.8},
  {"id":"mega_jump","base":left_start+b*0.52,"ramp":22.0,"gap":72.0,"height":9.0}
 ]

# Two free legs keep recognisable world-specific rhythms derived from the
# original authored control polygon. Stunt legs remain deliberately straight.
func _source_offset(d: float) -> float:
 var t := -1.0
 var shift := 0
 if d >= 140 and d <= a-83:
  t = (d-140)/(a-223)
 elif d >= bottom_start+185 and d <= bottom_start+a-83:
  t = (d-bottom_start-185)/(a-268)
  shift = source_points.size()/2
 if t < 0 or t > 1: return 0.0
 var segment := t*4
 var index := int(floor(segment))
 var u := segment-index
 var values := PackedFloat64Array()
 for j in range(-1,7):
  var point: Vector3 = source_points[posmod(j+shift,source_points.size())]
  values.append(point.z/125.0 if shift==0 else point.x/125.0)
 var j := index+1
 var value := 0.5*((2*values[j])+(-values[j-1]+values[j+1])*u+(2*values[j-1]-5*values[j]+4*values[j+1]-values[j+2])*u*u+(-values[j-1]+3*values[j]-3*values[j+1]+values[j+2])*u*u*u)
 return value*[68.0,95.0,100.0,82.0,45.0,58.0][world]*pow(sin(PI*t),2)

func _position(q: float) -> Vector3:
 var d := _base_distance(q)
 var flat := _flat(d)
 var forward := -flat.basis.z
 var point := flat.origin
 point += flat.basis.x*_source_offset(d)
 var wrapped := fposmod(q,base_length+loop_extra)
 if wrapped >= loop_start and wrapped <= loop_start+loop_span:
  var t := (wrapped-loop_start)/loop_span
  point += forward*loop_radius*sin(t*TAU)+Vector3.UP*loop_radius*(1-cos(t*TAU))+flat.basis.x*25*smoothstep(0,1,t)
 elif d >= loop_start+loop_replace and d < loop_start+loop_replace+65:
  point += flat.basis.x*25*(1-smoothstep(0,65,d-loop_start-loop_replace))
 var cork_t := (d-right_start-28)/125.0
 if cork_t >= 0 and cork_t <= 1:
  var angle := TAU*smoothstep(0,1,cork_t)
  point += flat.basis.x*14*sin(angle)+Vector3.UP*(14*(1-cos(angle))+25*pow(sin(PI*cork_t),2))
 var climb_start := right_start+b*0.62
 var downhill_start := bottom_start+18
 if d >= climb_start and d < downhill_start:
  point.y += 38*smoothstep(climb_start,downhill_start,d)
 elif d >= downhill_start and d <= downhill_start+150:
  point.y += 38*(1-smoothstep(0,1,(d-downhill_start)/150))
 var s := (d-left_start-12)/100.0
 if s >= 0 and s <= 1: point += flat.basis.x*19*sin(TAU*s)*pow(sin(PI*s),2)
 for spec in _jump_specs():
  var t := (d-float(spec.base))/float(spec.ramp)
  if t >= 0 and t <= 1:
   point.y += float(spec.height)*(2*t*t-t*t*t)
  var u := (d-float(spec.base)-float(spec.ramp))/float(spec.gap)
  if u > 0 and u < 1:
   var height: float = spec.height
   point.y += (2*u*u*u-3*u*u+1)*height+(u*u*u-2*u*u+u)*(height/float(spec.ramp)*float(spec.gap))
 return point

func _sample() -> void:
 frames.clear()
 distances.clear()
 q_values.clear()
 curve = Curve3D.new()
 curve.bake_interval = 0.35
 var total := base_length+loop_extra
 var count := int(ceil(total/0.32))
 var previous := _position(0)
 var travelled := 0.0
 for i in count+1:
  var q := total*i/count
  var p := _position(q)
  var tangent := (_position(q+0.08)-_position(q-0.08)).normalized()
  var d := _base_distance(q)
  var axle := _flat(d).basis.x
  var right := (axle-tangent*axle.dot(tangent)).normalized()
  var up := right.cross(tangent).normalized()
  var roll_t := (d-right_start-28)/125.0
  if roll_t >= 0 and roll_t <= 1:
   var roll := TAU*smoothstep(0,1,roll_t)
   right = right.rotated(tangent,roll)
   up = up.rotated(tangent,roll)
  if i > 0: travelled += previous.distance_to(p)
  frames.append(Transform3D(Basis(right,up,-tangent).orthonormalized(),p))
  distances.append(travelled)
  q_values.append(q)
  curve.add_point(p)
  previous = p
 length = travelled

func _lookup(values: PackedFloat64Array, value: float) -> int:
 var low := 0
 var high := values.size()-1
 while high-low>1:
  var mid: int = (low+high)/2
  if values[mid]<=value: low=mid
  else: high=mid
 return low

func frame(distance: float) -> Transform3D:
 var d := fposmod(distance,length)
 var index := _lookup(distances,d)
 var t := (d-distances[index])/maxf(0.000001,distances[index+1]-distances[index])
 return Transform3D(frames[index].basis.slerp(frames[index+1].basis,t).orthonormalized(),frames[index].origin.lerp(frames[index+1].origin,t))

func mapped(d: float) -> float:
 var q := d+(loop_extra if d>loop_start+loop_replace else 0.0)
 return _mapped_q(q)

func _mapped_q(q: float) -> float:
 var index := _lookup(q_values,q)
 return lerpf(distances[index],distances[index+1],(q-q_values[index])/maxf(0.000001,q_values[index+1]-q_values[index]))

func _metadata() -> void:
 features = [
  {"id":"loop","name":"Looping","start":_mapped_q(loop_start),"end":_mapped_q(loop_start+loop_span)},
  {"id":"corkscrew","name":"Kurkentrekker","start":mapped(right_start+28),"end":mapped(right_start+153)},
  {"id":"downhill","name":"Lange rechte afdaling","start":mapped(bottom_start+18),"end":mapped(bottom_start+168)},
  {"id":"s_bends","name":"S-bochten","start":mapped(left_start+12),"end":mapped(left_start+112)}
 ]
 for spec in _jump_specs():
  features.append({"id":spec.id,"name":"Megaschans" if spec.id=="mega_jump" else "Kleine schans","start":mapped(spec.base),"lip":mapped(spec.base+spec.ramp),"end":mapped(spec.base+spec.ramp+spec.gap),"landing":mapped(spec.base+spec.ramp+spec.gap)})
 for feature in features: feature.center=(feature.start+feature.end)*0.5

func feature_at(distance: float) -> Dictionary:
 var d := fposmod(distance,length)
 for feature in features:
  if d>=feature.start and d<=feature.end: return feature
 return {}

func is_gap(distance: float) -> bool:
 var feature := feature_at(distance)
 return feature.has("lip") and fposmod(distance,length)>feature.lip and fposmod(distance,length)<feature.end

func launch_velocity(before: float, after: float) -> float:
 for feature in features:
  if not feature.has("lip"): continue
  var crossing: float = floor(before/length)*length+feature.lip
  if before < crossing and after >= crossing: return 10.0 if feature.id=="mega_jump" else 6.0
 return 0.0


func scenery_safe(distance: float, margin: float = 16.0) -> bool:
 var d := fposmod(distance,length)
 for feature in features:
  if d >= feature.start-margin and d <= feature.end+margin: return false
 return frame(d).basis.y.y > 0.96

func scenery_distance(distance: float) -> float:
 for step in int(ceil(length/3)):
  var d := fposmod(distance+step*3,length)
  if scenery_safe(d): return d
 return distance


func flight_state(distance: float) -> Dictionary:
 var feature := feature_at(distance)
 if not feature.has("lip"): return {}
 var d := fposmod(distance,length)
 if d <= feature.lip or d >= feature.landing: return {}
 var span: float = feature.landing-feature.lip
 var t: float = (d-feature.lip)/span
 var amplitude := 2.0 if feature.id=="mega_jump" else 0.6
 # Additional lift over the unsupported Hermite flight guide. Both value and
 # first derivative are zero at takeoff/contact, independent of vehicle speed.
 return {"height":amplitude*pow(sin(PI*t),2),"slope":amplitude*PI*sin(TAU*t)/span,"feature":feature.id}
