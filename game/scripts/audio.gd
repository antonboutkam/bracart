extends Node
## Original music/cues, with a bounded pool for selected CC0 material impacts.
var music: AudioStreamPlayer
var effects: Array[AudioStreamPlayer] = []
var sound_volume: float = 0.65
var music_volume: float = 0.35
var muted: bool = false
var impact_clips: Dictionary = {}
var impact_voices: Array[AudioStreamPlayer3D] = []
var impact_cooldowns: Dictionary = {}
var impact_serial: int = 0
var impact_ready: bool = false

func _ready() -> void:
 music = AudioStreamPlayer.new()
 add_child(music)
 music.stream = _song()
 for i in 6:
  var voice = AudioStreamPlayer.new()
  add_child(voice)
  effects.append(voice)
 _prepare_impacts()
 music.play()
 apply(music_volume, sound_volume)

func apply(music_level: float, sound_level: float) -> void:
 music_volume = music_level
 sound_volume = sound_level
 if music:
  music.volume_db = linear_to_db(maxf(0.0001, music_level * 0.28))
  music.stream_paused = music_level <= 0 or muted

func cue(kind: String) -> void:
 if sound_volume <= 0 or muted:
  return
 var notes = {"coin": [880.0, 1320.0], "power":[440.0, 660.0, 880.0], "start":[660.0], "lap":[523.25, 659.25, 783.99], "jump":[330.0, 440.0], "shot":[220.0, 110.0], "hit":[130.0, 70.0], "click":[660.0]}.get(kind, [440.0])
 var voice: AudioStreamPlayer = effects[0]
 for item in effects:
  if not item.playing:
   voice = item
   break
 voice.stream = _tones(notes, 0.065)
 voice.volume_db = linear_to_db(maxf(0.0001, sound_volume * 0.25))
 voice.play()

func _prepare_impacts() -> void:
 for pair in [["wood","wood_light"],["paper","wood_plank"],["plastic","soft_medium"],["asphalt","generic_light"]]:
  var path: String = "res://assets/third_party/kenney/impacts/"+pair[1]+".wav"
  if ResourceLoader.exists(path): impact_clips[pair[0]] = load(path)
 impact_ready = impact_clips.size()==4
 for index in 4:
  var voice := AudioStreamPlayer3D.new()
  voice.name = "MaterialImpact%02d" % index
  voice.unit_size = 8
  voice.max_distance = 50
  add_child(voice)
  impact_voices.append(voice)

func play_impact(kind: String, at: Vector3, intensity: float, surface: String, listener: Vector3) -> bool:
 if not impact_ready or muted or sound_volume<=0 or kind not in ["landing","collision","hit"]: return false
 if not at.is_finite() or not listener.is_finite() or not is_finite(intensity) or at.distance_squared_to(listener)>2500: return false
 var key: String = kind+":"+surface
 if float(impact_cooldowns.get(key,0))>0: return false
 var material: String = surface if impact_clips.has(surface) else "asphalt"
 var voice: AudioStreamPlayer3D = impact_voices[impact_serial%impact_voices.size()]
 for candidate in impact_voices:
  if not candidate.playing:
   voice = candidate
   break
 impact_serial += 1
 voice.stop()
 voice.stream = impact_clips[material]
 voice.global_position = at
 voice.set_meta("impact_gain",0.28*clampf(intensity,0.15,1))
 voice.volume_db = linear_to_db(maxf(0.0001,sound_volume*float(voice.get_meta("impact_gain"))))
 voice.pitch_scale = 0.96+0.02*(impact_serial%5)
 voice.stream_paused = false
 voice.play()
 impact_cooldowns[key] = 0.1 if kind=="landing" else 0.18
 set_meta("impact_play_count",impact_serial)
 set_meta("last_impact_surface",material)
 return true

func advance_feedback(delta: float, paused: bool) -> void:
 for voice in impact_voices:
  if muted or sound_volume<=0: voice.stop()
  # Also silence deferred play commands until Godot has applied stream_paused.
  voice.volume_db = -80 if paused or muted or sound_volume<=0 else linear_to_db(maxf(0.0001,sound_volume*float(voice.get_meta("impact_gain",0.0))))
  voice.stream_paused = paused
 if paused or delta<=0 or not is_finite(delta): return
 for key in impact_cooldowns: impact_cooldowns[key] = maxf(0,float(impact_cooldowns[key])-delta)

func clear_impacts() -> void:
 for voice in impact_voices: voice.stop()
 impact_cooldowns.clear()

func _tones(notes: Array, duration: float) -> AudioStreamWAV:
 var rate = 22050
 var data = PackedByteArray()
 var total = int(rate * duration * notes.size())
 data.resize(total * 2)
 for i in total:
  var note_index = mini(notes.size() - 1, int(i / (rate * duration)))
  var t = fmod(float(i) / rate, duration)
  var sample = sin(TAU * float(notes[note_index]) * t) * (1 - t / duration) * minf(1, t * 300)
  data.encode_s16(i * 2, int(sample * 15000))
 var stream = AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = rate
 stream.data = data
 return stream

func _song() -> AudioStreamWAV:
 var notes: Array = []
 for midi in [60, 64, 67, 72, 67, 64, 62, 67, 59, 62, 67, 71, 67, 62, 64, 67,
  57, 60, 64, 69, 64, 60, 62, 64, 55, 59, 62, 67, 62, 59, 62, 67]:
  notes.append(440.0 * pow(2, (midi - 69) / 12.0))
 var stream = _tones(notes, 0.22)
 stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
 stream.loop_end = int(stream.data.size() / 2)
 return stream
