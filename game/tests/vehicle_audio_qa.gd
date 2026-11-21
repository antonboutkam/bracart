extends SceneTree
## Independent integration QA with shipped WAVs, actual Main and five real racers.
const Main = preload("res://scripts/main.gd")
const Catalog = preload("res://scripts/catalog.gd")
var checks = 0
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures.append(label)
  if failures.size() <= 12: push_error(label)

func spatial_voice_count(node: Node) -> int:
 var total = 1 if node is AudioStreamPlayer3D else 0
 for child in node.get_children(): total += spatial_voice_count(child)
 return total

func voice_count(controller: Node) -> int:
 # Count actual descendants of bound kart owners, including any accidental
 # stale voice not present in a bank. Material impact voices belong to Audio.
 var total: int = 0
 for bank in controller.banks:
  var kart: Node = bank.kart.get_ref()
  if is_instance_valid(kart): total += spatial_voice_count(kart)
 return total

func check_impact_pool(main: Node, expected_vehicle_voices: int) -> void:
 check(main.audio.impact_voices.size() == 4,"Material impacts retain their separate four-voice pool")
 for voice in main.audio.impact_voices:
  check(is_instance_valid(voice) and voice.get_parent() == main.audio,"Material voice belongs to Audio rather than a kart")
 check(spatial_voice_count(main) == expected_vehicle_voices+4,"Total spatial emitters equal vehicle voices plus four material voices")

func settled(_main, gas: float = 0.0) -> void:
 Input.action_press("accelerate",gas)
 if gas <= 0: Input.action_release("accelerate")
 for tick in 40:
  await physics_frame
  await process_frame

func check_silent(controller, label: String) -> void:
 for bank in controller.banks:
  for voice in bank.voices:
   check(voice.stream_paused and voice.volume_db <= -80,label + " paused=%s db=%.1f playing=%s processing=%s" % [voice.stream_paused,voice.volume_db,voice.playing,voice.can_process()])

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var main = Main.new()
 root.add_child(main)
 await process_frame
 main.set_physics_process(false)
 main.audio.music.stop()
 main.audio.music.stream = null
 main.audio.muted = false
 main.audio.apply(0,1)
 check(main.vehicle_audio.banks.is_empty() and voice_count(main.vehicle_audio) == 0,"Menu starts without vehicle voices")
 check_impact_pool(main,0)
 var observed_profiles: Array = []
 for vehicle in Catalog.VEHICLES.size():
  main.profile.selected = vehicle
  main.start_race(5)
  await process_frame
  var controller = main.vehicle_audio
  check(controller.asset_error.is_empty() and controller.banks.size() == 5,"Shipped assets bind all real racers for vehicle%d: %s" % [vehicle,controller.asset_error])
  check(controller.streams.size() == 3,"Controller retains exactly the three shipped source loops")
  check(voice_count(controller) == 20,"Only twenty racing layer voices exist after vehicle%d rebind" % vehicle)
  check_impact_pool(main,20)
  if controller.banks.size() != 5: break
  var bank: Dictionary = controller.banks[0]
  observed_profiles.append([bank.profile.pitch,bank.profile.gain,bank.profile.filter])
  main.race.player.speed = 0
  await settled(main)
  # Spatial audio starts on Godot's internal physics/audio update, not our
  # synchronous Main modulation calls. Let the real backend acquire playback.
  await create_timer(0.1).timeout
  check(bank.weights.x > 0.95,"Stationary real player retains idle")
  main.race.player.speed = Catalog.VEHICLES[vehicle].speed * 0.7
  await settled(main,1)
  check(bank.weights.z > 0.65 and bank.weights.x < 0.02,"Actual Main gas and speed drive load crossfade")
  var loaded: float = bank.weights.z
  await settled(main,0)
  check(bank.weights.z < loaded*0.02 and bank.weights.y > 0.9,"Released Main throttle produces cruise layer")
  main.race.player.boost_time = 2
  await settled(main,1)
  check(bank.weights.w > 0.35,"Real boost state selects source boost layer")
  var total_gain = 0.0
  for index in controller.banks.size():
   var current: Dictionary = controller.banks[index]
   var kart = main.race.racers[index]
   kart.progress += 6
   kart.update_visual(main.track,0)
   check(current.kart.get_ref() == kart,"Bank references corresponding actual player/AI kart")
   for voice in current.voices:
    check(voice.get_parent() == kart and voice.global_position.distance_to(kart.to_global(Vector3(0,0.6,0))) < 0.001,"3D emitter follows actual moving owner")
    check(voice.max_distance > 0 and voice.pitch_scale >= 0.65 and voice.pitch_scale <= 1.6,"Spatial range and pitch stay bounded")
    check(voice.stream is AudioStreamWAV and voice.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and voice.stream.loop_end == voice.stream.data.size()/2,"Shipped WAV loops cover complete PCM stream")
    total_gain += db_to_linear(voice.volume_db)
  check(total_gain < 0.35,"All player and AI layers retain summed linear gain headroom")
  var starts: int = controller.starts
  main.ui.show_pause()
  main._process(0.1)
  await process_frame
  await create_timer(0.05).timeout
  check_silent(controller,"Main race pause silences every voice")
  main.ui.resume()
  main.audio.apply(0,0)
  main._process(0.1)
  await process_frame
  await create_timer(0.05).timeout
  check_silent(controller,"Actual sound setting zero silences all five karts")
  main.audio.apply(0,1)
  main.audio.muted = true
  main._process(0.1)
  await process_frame
  await create_timer(0.05).timeout
  check_silent(controller,"Global mute silences player and AI")
  main.audio.muted = false
  main._process(0.1)
  check(controller.starts == starts,"Pause/settings resume never restart or stack voices")
  var old_voice = weakref(bank.voices[0])
  controller.bind(main.race)
  await process_frame
  check(old_voice.get_ref() == null and voice_count(main.vehicle_audio) == 20,"Actual race rebind frees old voices before keeping one bank")
 check(observed_profiles.size() == 6,"All six real garage vehicles bind their authored profiles")
 for a in observed_profiles.size():
  for b in range(a+1,observed_profiles.size()):
   check(observed_profiles[a] != observed_profiles[b],"Vehicle timbre profiles remain individually distinct")
 main.race.done = true
 main.race.reward = 0
 main.race.elapsed = 60
 main._finish()
 await process_frame
 check(main.vehicle_audio.banks.is_empty() and voice_count(main.vehicle_audio) == 0,"Real results handler removes all vehicle loops")
 check_impact_pool(main,0)
 main.start_race(4)
 main.go_home()
 await process_frame
 check(main.vehicle_audio.banks.is_empty() and voice_count(main.vehicle_audio) == 0,"Race-to-menu transition removes all vehicle loops")
 check_impact_pool(main,0)
 Input.action_release("accelerate")
 main.queue_free()
 await process_frame
 print("BORACER VEHICLE AUDIO QA: %d checks, %d failures" % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
