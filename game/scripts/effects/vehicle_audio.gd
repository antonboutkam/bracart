extends Node
## Racing-only layers from Ravi's supplied voice recording; no synthesized fallback.
const Catalog = preload("res://scripts/catalog.gd")
const ASSET_DIR = "res://assets/audio/vehicles/"
const LAYERS = ["idle", "cruise", "load", "boost"]
const PROFILES = [
 {"pitch":1.00,"gain":0.82,"filter":6500.0}, # Raketfiets: recognizable source voice.
 {"pitch":1.08,"gain":0.75,"filter":8200.0},
 {"pitch":0.94,"gain":0.85,"filter":7200.0},
 {"pitch":0.88,"gain":0.90,"filter":4800.0},
 {"pitch":0.96,"gain":0.80,"filter":5600.0},
 {"pitch":1.13,"gain":0.72,"filter":9500.0}
]
var streams: Dictionary = {}
var banks: Array[Dictionary] = []
var starts: int = 0
var asset_error: String = ""

func load_streams() -> bool:
 if streams.size() == 3:
  return true
 asset_error = ""
 for key in ["idle", "drive", "boost"]:
  var path: String = ASSET_DIR + key + ".wav"
  if not ResourceLoader.exists(path):
   asset_error = "Voertuigaudio ontbreekt of is nog niet geïmporteerd: " + path
   streams.clear()
   push_error(asset_error)
   return false
  var imported: AudioStreamWAV = load(path) as AudioStreamWAV
  if imported == null or imported.stereo or imported.mix_rate != 44100 or imported.format != AudioStreamWAV.FORMAT_16_BITS:
   asset_error = "Voertuigaudio vereist mono 44.1 kHz 16-bit PCM: " + path
   streams.clear()
   push_error(asset_error)
   return false
  var loop: AudioStreamWAV = imported.duplicate() as AudioStreamWAV
  loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
  loop.loop_begin = 0
  loop.loop_end = loop.data.size() / 2
  streams[key] = loop
 return true

func bind(race: Node, injected: Dictionary = {}) -> bool:
 clear()
 if not injected.is_empty():
  streams = injected
 if injected.is_empty() and not load_streams():
  return false
 for kart in race.racers:
  var profile: Dictionary = PROFILES[clampi(kart.vehicle_index, 0, PROFILES.size()-1)]
  var voices: Array[AudioStreamPlayer3D] = []
  for layer in LAYERS:
   var voice := AudioStreamPlayer3D.new()
   voice.name = "VehicleAudio_" + layer
   voice.stream = streams["drive" if layer in ["cruise", "load"] else layer]
   voice.volume_db = -80
   voice.pitch_scale = profile.pitch
   voice.unit_size = 7.0
   voice.max_distance = 85.0
   voice.attenuation_filter_cutoff_hz = profile.filter
   voice.attenuation_filter_db = -18
   voice.panning_strength = 0.8
   kart.add_child(voice)
   voice.position = Vector3(0,0.6,0)
   voices.append(voice)
  banks.append({"kart":weakref(kart), "voices":voices, "profile":profile, "started":false, "weights":Vector4(1,0,0,0), "pitch":float(profile.pitch)})
 return true

func update(delta: float, sound_level: float, muted: bool, active: bool, player_gas: float) -> void:
 var audible: bool = active and not muted and sound_level > 0
 var blend: float = 1.0 - exp(-clampf(delta,0,0.25) * 9.0)
 for bank in banks:
  var kart: Node3D = bank.kart.get_ref() as Node3D
  if not is_instance_valid(kart):
   continue
  var speed: float = clampf(kart.speed / maxf(float(Catalog.VEHICLES[kart.vehicle_index].speed),1),0,1.5)
  var gas: float = 0.75 if kart.ai else clampf(player_gas,0,1)
  var boosting: bool = kart.boost_time > 0 and kart.speed > 0.5
  var target := Vector4(clampf(1-speed*5,0,1),clampf(speed*3,0,1)*(1-gas*0.65),clampf(speed*3,0,1)*gas,0)
  if boosting:
   target *= 0.5
   target.w = 0.8
  var total: float = target.x + target.y + target.z + target.w
  if total > 1:
   target /= total
  if audible:
   bank.weights = (bank.weights as Vector4).lerp(target,blend)
   var pitch_target: float = bank.profile.pitch * (0.84 + minf(speed,1.2)*0.27 + gas*0.045)
   bank.pitch = lerpf(bank.pitch,pitch_target,blend)
  for index in bank.voices.size():
   var voice: AudioStreamPlayer3D = bank.voices[index]
   if not is_instance_valid(voice):
    continue
   # Start only on first audible race frame, then preserve the loop on pause.
   if audible and not bank.started:
    voice.play()
    starts += 1
   voice.stream_paused = not audible
   var layer_gain: float = (bank.weights as Vector4)[index] * sound_level * bank.profile.gain * (0.05 if kart.ai else 0.18)
   voice.volume_db = linear_to_db(maxf(0.0001,layer_gain)) if audible else -80
   voice.pitch_scale = clampf(bank.pitch * ([0.96,1.0,0.94,1.07][index]),0.8,1.2)
  if audible:
   bank.started = true

func clear() -> void:
 for bank in banks:
  for voice in bank.voices:
   if is_instance_valid(voice):
    voice.stop()
    var parent: Node = voice.get_parent()
    if parent != null:
     parent.remove_child(voice)
    voice.queue_free()
 banks.clear()

func _exit_tree() -> void:
 clear()
