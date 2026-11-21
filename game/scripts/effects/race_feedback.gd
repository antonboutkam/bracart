extends Node3D
## Fixed sprite pool for race events. Main owns update/pause and race lifecycle.
const MAX_BURSTS: int = 12
const SPRITES_PER_BURST: int = 12
const FOCUS_DISTANCE: float = 50.0
const DUST_PATH: String = "res://assets/third_party/kenney/particles/smoke.png"
const SPARK_PATH: String = "res://assets/third_party/kenney/particles/spark.png"
var race: Node
var focus_position: Vector3 = Vector3.ZERO
var bursts: Array[Dictionary] = []
var textures: Array[Texture2D] = []
var elapsed: float = 0
var serial: int = 0
var cursor: int = 0
var accepting: bool = true
var paused: bool = false

func bind(source: Node, dust: Texture2D = null, spark: Texture2D = null) -> void:
 clear()
 race = source
 if dust == null and ResourceLoader.exists(DUST_PATH): dust = load(DUST_PATH)
 if spark == null and ResourceLoader.exists(SPARK_PATH): spark = load(SPARK_PATH)
 textures = [dust,spark]
 if textures[0] == null or textures[1] == null:
  push_warning("RaceFeedback requires the selected Kenney dust and spark textures")
 _ensure_pool()
 accepting = true
 if is_instance_valid(race) and not race.feedback.is_connected(receive_feedback):
  race.feedback.connect(receive_feedback)
 _sync_focus()

func _ensure_pool() -> void:
 if not bursts.is_empty(): return
 for slot in MAX_BURSTS:
  var group := Node3D.new()
  group.name = "Burst%02d" % slot
  group.visible = false
  add_child(group)
  var sprites: Array[Sprite3D] = []
  var velocities := PackedVector3Array()
  velocities.resize(SPRITES_PER_BURST)
  for index in SPRITES_PER_BURST:
   var sprite := Sprite3D.new()
   sprite.name = "Particle%02d" % index
   sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
   sprite.shaded = false
   sprite.no_depth_test = false
   sprite.pixel_size = 0.01
   sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
   group.add_child(sprite)
   sprites.append(sprite)
  bursts.append({"node":group,"sprites":sprites,"velocities":velocities,"age":0.0,"lifetime":0.0,"kind":"","intensity":0.0,"active":false,"origin":Vector3.ZERO,"up":Vector3.UP})

func _sync_focus() -> void:
 if is_instance_valid(race) and is_instance_valid(race.get("player")) and is_instance_valid(race.get("track")):
  focus_position = race.track.position_at(race.player.progress,race.player.lateral,0.0)

func receive_feedback(kind: String, at: Vector3, intensity: float, surface: String) -> void:
 if not accepting or paused or not at.is_finite() or not is_finite(intensity): return
 if kind not in ["landing","collision","hit","finish"]: return
 if is_instance_valid(race) and (race.get("paused") == true or (race.get("done") == true and kind != "finish")): return
 _sync_focus()
 if kind != "finish" and at.distance_squared_to(focus_position) > FOCUS_DISTANCE*FOCUS_DISTANCE: return
 var texture_index: int = 0 if kind == "landing" else 1
 if textures.size() != 2 or textures[texture_index] == null: return
 var burst: Dictionary = bursts[cursor]
 cursor = (cursor+1)%MAX_BURSTS
 serial += 1
 burst.kind = kind
 burst.active = true
 burst.age = 0.0
 burst.intensity = clampf(intensity,0.1,1.0)
 burst.lifetime = 0.85 if kind == "landing" else (1.6 if kind == "finish" else 0.45)
 burst.origin = at
 var normal: Vector3 = Vector3.UP
 if is_instance_valid(race) and is_instance_valid(race.get("track")) and is_instance_valid(race.get("player")):
  # Landing dust follows the local lane frame, including inverted track sections.
  # Find the nearby actor whose ground event position produced this signal.
  var closest: float = INF
  for kart in race.racers:
   var ground: Vector3 = race.track.position_at(kart.progress,kart.lateral,0.12)
   var gap: float = ground.distance_squared_to(at)
   if gap < closest:
    closest = gap
    normal = race.track.frame(kart.progress).basis.y
 burst.up = normal
 burst.node.global_position = at
 burst.node.visible = true
 var tangent: Vector3 = normal.cross(Vector3.FORWARD).normalized()
 if tangent.length_squared() < 0.1: tangent = normal.cross(Vector3.RIGHT).normalized()
 var bitangent: Vector3 = normal.cross(tangent).normalized()
 var color: Color = Color("b6a994") if surface == "asphalt" else Color("cfb68b")
 if kind != "landing": color = Color("ffd289")
 for index in SPRITES_PER_BURST:
  var sprite: Sprite3D = burst.sprites[index]
  var angle: float = TAU*(index+fmod(serial*0.381,1.0))/SPRITES_PER_BURST
  var outward: Vector3 = tangent*cos(angle)+bitangent*sin(angle)
  var power: float = 0.6+burst.intensity*1.5
  burst.velocities[index] = outward*power+normal*(1.1+float(index%4)*0.25)
  sprite.position = Vector3.ZERO
  sprite.texture = textures[texture_index]
  sprite.rotation.z = angle
  sprite.modulate = Color.from_hsv(float(index)/SPRITES_PER_BURST,0.7,1) if kind == "finish" else color
  sprite.scale = Vector3.ONE*(0.28 if kind == "landing" else 0.13)
  sprite.visible = true

func advance(delta: float, freeze: bool = false) -> void:
 paused = freeze or (is_instance_valid(race) and race.get("paused") == true)
 if paused or delta <= 0 or not is_finite(delta): return
 elapsed += delta
 _sync_focus()
 for burst in bursts:
  if not burst.active: continue
  burst.age += delta
  if burst.age >= burst.lifetime:
   burst.active = false
   burst.node.visible = false
   continue
  var t: float = burst.age/burst.lifetime
  for index in SPRITES_PER_BURST:
   var sprite: Sprite3D = burst.sprites[index]
   var velocity: Vector3 = burst.velocities[index]
   sprite.position = velocity*burst.age-burst.up*(0.4 if burst.kind == "landing" else 1.6)*burst.age*burst.age
   var size: float = lerpf(0.28,0.8,t) if burst.kind == "landing" else lerpf(0.13,0.06,t)
   sprite.scale = Vector3.ONE*size
   sprite.modulate.a = pow(1.0-t,1.5)*0.7

func active_count() -> int:
 var count: int = 0
 for burst in bursts:
  if burst.active: count += 1
 return count

func clear() -> void:
 if is_instance_valid(race) and race.feedback.is_connected(receive_feedback):
  race.feedback.disconnect(receive_feedback)
 race = null
 for burst in bursts:
  burst.active = false
  burst.node.visible = false
 accepting = false
 paused = false
 elapsed = 0
 cursor = 0

func _exit_tree() -> void:
 clear()
