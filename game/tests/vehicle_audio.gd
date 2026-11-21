extends SceneTree
const VehicleAudio = preload("res://scripts/effects/vehicle_audio.gd")
var checks := 0
var failures := 0
class TestKart extends Node3D:
 var vehicle_index: int = 0
 var speed: float = 0
 var boost_time: float = 0
 var ai: bool = false
class TestRace extends Node3D:
 var racers: Array = []
func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(label)
func _initialize() -> void:
 call_deferred("run")
func test_stream() -> AudioStreamWAV:
 # Silence is an isolated routing fixture, never a production engine substitute.
 var stream := AudioStreamWAV.new()
 stream.mix_rate = 44100
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 var data := PackedByteArray()
 data.resize(8820)
 stream.data = data
 stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
 stream.loop_end = 4410
 return stream
func run() -> void:
 var controller := VehicleAudio.new()
 root.add_child(controller)
 var race := TestRace.new()
 root.add_child(race)
 for index in 5:
  var kart := TestKart.new()
  kart.vehicle_index = index
  kart.ai = index != 0
  race.add_child(kart)
  race.racers.append(kart)
 var camera := Camera3D.new()
 race.add_child(camera)
 camera.current = true
 var injected: Dictionary = {"idle":test_stream(),"drive":test_stream(),"boost":test_stream()}
 check(controller.bind(race,injected), "Injected PCM layers bind")
 await create_timer(0.1).timeout
 check(controller.banks.size() == 5 and controller.starts == 0, "Five real kart emitters own four layers each")
 for bank in controller.banks:
  for voice in bank.voices:
   check(voice is AudioStreamPlayer3D and voice.get_parent() == bank.kart.get_ref(), "Actual spatial player follows kart owner")
   check(not voice.playing and voice.volume_db == -80 and voice.max_distance == 85, "Starts silent with finite spatial range")
 controller.update(0.1,0.65,false,true,0)
 await create_timer(0.1).timeout
 check(not controller.banks[0].voices[0].stream_paused, "Race activation resumes loops")
 var idle: Vector4 = controller.banks[0].weights
 race.racers[0].speed = 35
 for tick in 60:
  controller.update(1.0/60,0.65,false,true,1)
 var loaded: Vector4 = controller.banks[0].weights
 check(loaded.z > 0.7 and loaded.x < idle.x*0.01, "Speed and throttle crossfade idle into load")
 check(controller.starts == 20, "Per-frame modulation never restarts loops")
 race.racers[0].boost_time = 2
 controller.update(0.1,0.65,false,true,1)
 check(controller.banks[0].weights.w > 0.25, "Real kart boost activates boost layer")
 for tick in 60:
  for kart in race.racers:
   kart.speed = 10 + tick
   kart.boost_time = 1 if tick % 3 == 0 else 0
  controller.update(1.0/60,1,false,true,float(tick % 2))
  var absolute_mix_bound: float = 0
  for bank in controller.banks:
   var weights: Vector4 = bank.weights
   check(weights.x+weights.y+weights.z+weights.w <= 1.0001, "Crossfade weights conserve mix headroom")
   for voice in bank.voices:
    absolute_mix_bound += db_to_linear(voice.volume_db)
    check(voice.pitch_scale >= 0.79999 and voice.pitch_scale <= 1.20001, "Total pitch retains source within twenty percent")
  check(absolute_mix_bound < 0.35, "Worst-case summed engine gain stays below 0.35 before distance attenuation")
 var before: Vector4 = controller.banks[0].weights
 controller.update(0.1,0.65,false,false,1)
 await process_frame
 check(controller.banks[0].weights == before, "Race pause freezes crossfade state")
 for bank in controller.banks:
  for voice in bank.voices:
   check(voice.stream_paused and voice.volume_db == -80, "Paused race has no active engine background")
 controller.update(0.1,0.65,false,true,1)
 check(not controller.banks[0].voices[0].stream_paused and controller.starts == 20, "Resume preserves original loops")
 controller.update(0.1,0,false,true,1)
 await process_frame
 check(controller.banks[0].voices[0].stream_paused, "Sound zero immediately silences engines")
 controller.update(0.1,1,true,true,1)
 await process_frame
 check(controller.banks[1].voices[2].stream_paused, "Mute silences AI too")
 var profiles: Array = []
 for profile in VehicleAudio.PROFILES:
  profiles.append([profile.pitch,profile.gain,profile.filter])
 check(profiles.size() == 6 and profiles[0] != profiles[1] and profiles[3] != profiles[5], "Six authored vehicle timbre profiles")
 var old: WeakRef = weakref(controller.banks[0].voices[0])
 controller.clear()
 check(controller.banks.is_empty() and race.racers[0].get_child_count() == 0, "Race clear detaches every old voice immediately")
 await process_frame
 check(old.get_ref() == null, "Old voices freed after race clear")
 for repeat in 4:
  controller.bind(race,injected)
  check(race.racers[0].get_child_count() == 4 and controller.banks.size() == 5, "Repeated bind cannot accumulate old players")
  await process_frame
 race.queue_free()
 await process_frame
 controller.update(0.1,1,false,true,1)
 controller.clear()
 check(controller.banks.is_empty(), "Owner deletion tolerated without stale kart accesses")
 controller.queue_free()
 await process_frame
 print("BORACER VEHICLE AUDIO: %d checks, %d failures" % [checks,failures])
 quit(0 if failures == 0 else 1)
