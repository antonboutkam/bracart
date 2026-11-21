extends Node
## Original synthesized slide-whistle, chirp and jump sounds.
var voices: Array[AudioStreamPlayer] = []
var clips: Dictionary = {}
var counts: Dictionary = {"miss":0, "bird":0, "launch":0, "dive":0, "ring":0}

func _ready() -> void:
 clips.miss = glide([[0.0, 400.0], [0.20, 850.0], [0.31, 220.0], [0.52, 370.0], [0.64, 780.0], [1.25, 95.0]], 1.3)
 clips.bird = glide([[0.0, 1500.0], [0.08, 600.0], [0.15, 1900.0], [0.28, 700.0]], 0.3)
 clips.launch = glide([[0.0, 90.0], [0.15, 230.0], [0.4, 600.0]], 0.45)
 clips.dive = glide([[0.0, 560.0], [0.10, 310.0], [0.32, 85.0]], 0.36)
 clips.ring = glide([[0.0, 520.0], [0.08, 780.0], [0.16, 1040.0], [0.34, 1040.0]], 0.38)
 for i in 3:
  var voice = AudioStreamPlayer.new()
  add_child(voice)
  voices.append(voice)

func play(kind: String, volume: float, muted: bool) -> void:
 counts[kind] += 1
 if muted or volume <= 0:
  return
 var voice: AudioStreamPlayer = voices[0]
 for candidate in voices:
  if not candidate.playing:
   voice = candidate
   break
 voice.stream = clips[kind]
 voice.volume_db = linear_to_db(maxf(0.0001, volume * 0.55))
 voice.play()

func pause(value: bool) -> void:
 for voice in voices:
  voice.stream_paused = value

static func glide(keys: Array, duration: float) -> AudioStreamWAV:
 const RATE = 22050
 var bytes = PackedByteArray()
 bytes.resize(int(duration * RATE) * 2)
 var phase = 0.0
 var segment = 0
 for i in bytes.size() / 2:
  var time = float(i) / RATE
  while segment < keys.size() - 2 and time > keys[segment + 1][0]:
   segment += 1
  var blend = clampf((time - keys[segment][0]) / (keys[segment + 1][0] - keys[segment][0]), 0, 1)
  var frequency = lerpf(keys[segment][1], keys[segment + 1][1], blend)
  phase += TAU * frequency * (1 + 0.018 * sin(time * 65)) / RATE
  var envelope = minf(1, time * 60) * minf(1, (duration - time) * 18)
  var sample = (sin(phase) * 0.65 + sin(phase * 2) * 0.18 + sin(phase * 3) * 0.08) * envelope
  bytes.encode_s16(i * 2, int(sample * 22000))
 var stream = AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = RATE
 stream.data = bytes
 return stream
