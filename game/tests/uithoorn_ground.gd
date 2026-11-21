extends SceneTree
const Track = preload("res://scripts/track.gd")
const Race = preload("res://scripts/race.gd")
const Rig = preload("res://scripts/follow_camera.gd")
var checks = 0
var failures = 0
func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures += 1
  if failures<20: push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var track = Track.new()
 root.add_child(track)
 track.build(4)
 check(track.ground_course != null and track.v2_course == null,"classic Uithoorn uses street course")
 check(track.has_node("StartHill"),"visible earth supports start hill")
 check(absf(track.position_at(-14).y-track.position_at(0).y)<0.02,"whole starting grid on hilltop")
 var ground_samples = 0
 var raised_intervals = 0
 var raised_before = true
 var max_height = -INF
 var max_grade = 0.0
 var min_inner_tangent = INF
 for i in 1876:
  var d = track.length*i/1876.0
  var f = track.frame(d)
  var raised = f.origin.y>-21.81
  if not raised: ground_samples += 1
  if raised and not raised_before: raised_intervals += 1
  raised_before = raised
  max_height = maxf(max_height,f.origin.y)
  max_grade = maxf(max_grade,absf(f.basis.z.y))
  check(f.origin.y>=-21.83,"road never buried below ground")
  for side in [-7.5,7.5]:
   var p = track.position_at(d,side)
   if not raised: check(absf(p.y+21.82)<0.03,"entire road width flat on ground")
   min_inner_tangent = minf(min_inner_tangent,(track.position_at(d+0.2,side)-p).dot(-f.basis.z)/0.2)
 check(float(ground_samples)/1876>0.85,"over 85 percent of lap on ground")
 check(raised_intervals==1,"only one raised hill across start-finish seam")
 check(absf(max_height-6.18)<0.03 and max_grade>0.3 and max_grade<0.45,"28 metre steep but continuous start hill")
 check(min_inner_tangent>0.5,"sharp turns retain forward inner lanes")
 # Geometry clearance also covers nearby tram poles and the original Spoorhuis.
 var tram_clearance = INF
 for i in int(track.length):
  var p = track.position_at(i)
  for j in 180:
   var a = TAU*j/180
   tram_clearance = minf(tram_clearance,Vector2(p.x-83-49*cos(a),p.z-100*sin(a)).length())
 check(tram_clearance>track.width+7,"ground racers do not intersect tram or overhead poles")
 var race = Race.new()
 root.add_child(race)
 race.setup(track,4,"boaz",1)
 race.countdown = 0
 var camera = Camera3D.new()
 root.add_child(camera)
 var rig = Rig.new(camera)
 race.auto_drive = true
 var ticks = 0
 while not race.done and ticks<3500:
  race.step(0.1,1,0,0,false)
  rig.update(track,race.player,0.1,false,ticks==0)
  check(camera.position.is_finite() and camera.position.y>-21.3,"normal race camera stays above ground for complete race")
  check(race.player.jump_height<0.01,"street course has no unintended jumps")
  ticks += 1
 check(race.done and race.lap_times.size()==3,"three complete laps and finish remain playable")
 print("UITHOORN GROUND: ",checks," checks, ",failures," failures; length=",track.length," ground=",ground_samples*100.0/1876,"% inner_tangent=",min_inner_tangent)
 race.free()
 camera.free()
 track.free()
 quit(0 if failures==0 else 1)
