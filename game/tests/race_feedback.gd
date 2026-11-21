extends SceneTree
const Track = preload("res://scripts/track.gd")
const Race = preload("res://scripts/race.gd")
const Feedback = preload("res://scripts/effects/race_feedback.gd")
var checks: int = 0
var failures: int = 0
var events: Array[Dictionary] = []
func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(label)
func record(kind: String, at: Vector3, intensity: float, surface: String) -> void:
 events.append({"kind":kind,"at":at,"intensity":intensity,"surface":surface})
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var image := Image.create(16,16,false,Image.FORMAT_RGBA8)
 image.fill(Color.WHITE)
 var texture: Texture2D = ImageTexture.create_from_image(image)
 for world in [0,5]:
  var track = Track.new()
  root.add_child(track)
  track.build(world)
  var race = Race.new()
  root.add_child(race)
  race.setup(track,0,"boaz",1)
  race.countdown = 0
  race.feedback.connect(record)
  events.clear()
  for index in 5:
   var kart = race.racers[index]
   kart.progress = 30.0+index*55
   kart.lateral = 0
   kart.jump_height = 0.06
   kart.jump_velocity = -2
  race.step(0.1,0,0,0,false)
  check(events.size() == 5,"Real race emits one actual landing for every player and AI world%d" % world)
  for event in events:
   check(event.kind == "landing" and event.at.is_finite() and event.intensity >= 0.2 and event.intensity <= 1,"Landing has finite world pose and bounded impact")
  var count: int = events.size()
  race.step(0.1,0,0,0,false)
  check(events.size() == count,"Grounded racers do not repeatedly land")
  if world == 5:
   for feature in track.kitchen_features():
    if feature.id not in ["comic_ramp","card_ramp"]: continue
    events.clear()
    for index in 5:
     var kart = race.racers[index]
     kart.progress = feature.lip-0.2
     kart.lateral = -4+index*2
     kart.speed = 18
     kart.jump_height = 0
     kart.jump_velocity = 0
    for frame in 90: race.step(1.0/60.0,1,0,0,false)
    var landings: int = 0
    for event in events:
     if event.kind == "landing":
      landings += 1
      check(event.surface == "wood","Every real player/AI ramp landing chooses physical table material")
    check(landings == 5,"Actual kitchen ramp launch/flight produces five real landing events "+feature.id)
    events.clear()
    var runner = race.player
    runner.progress = feature.lip+14
    runner.lateral = 0
    runner.jump_height = 0.01
    runner.jump_velocity = -1
    runner.speed = 22
    race._step_kart(runner,0,1.0/60.0,1,0,0,false)
    check(runner.jump_height == 0 and runner.has_meta("feedback_landing") and events.is_empty() and track.position_at(runner.progress,0,0).y > 0.2,"Virtual guide touchdown above empty gap defers dust/audio "+feature.id)
    while runner.progress < feature.landing:
     race._step_kart(runner,0,1.0/60.0,1,0,0,false)
     if runner.progress < feature.landing: check(events.is_empty(),"No landing feedback while still above ramp gap")
    check(events.size() == 1 and events[0].kind == "landing" and events[0].surface == "wood" and not runner.has_meta("feedback_landing"),"Physical table landing releases exactly one wood event "+feature.id)
    events.clear()
    runner.progress = feature.start+2
    runner.jump_height = 0.01
    runner.jump_velocity = -1
    runner.speed = 0
    race._step_kart(runner,0,1.0/60.0,0,0,0,false)
    check(events.size() == 1 and events[0].surface == "paper","Manual jump onto real album/card lead retains immediate paper contact")
  events.clear()
  race.player.hit_cooldown = 0
  race.player.shield_time = 0
  race._weapon_hit(race.player,race.racers[1])
  race._weapon_hit(race.player,race.racers[1])
  check(events.size() == 1 and events[0].kind == "hit","Successful player hit emits once; cooldown-protected hit emits none")
  race.player.hit_cooldown = 0
  race.player.shield_time = 3
  race._weapon_hit(race.player,race.racers[1])
  check(events.size() == 1,"Shielded hit does not pretend to be damaging hit")
  events.clear()
  race.elapsed = 10
  race._collision_feedback(race.player,0.4)
  race._collision_feedback(race.player,0.9)
  check(events.size() == 1,"Contact feedback debounces persistent overlap without altering physics")
  events.clear()
  race.elapsed += 1
  race.player.progress = 30
  race.player.lateral = 0
  race.player.jump_height = 0
  for index in range(1,5):
   race.racers[index].progress = 30+index*40
   race.racers[index].lateral = 3
   race.racers[index].jump_height = 0
  race.racers[1].progress = 30.5
  race.racers[1].lateral = 0.2
  race._collisions(1.0/60.0)
  check(events.size() == 1 and events[0].kind == "collision","Actual player-rival overlap produces contact spark event")
  var effect = Feedback.new()
  race.add_child(effect)
  effect.bind(race,texture,texture)
  var nodes: int = effect.find_children("*","Node",true,false).size()
  check(nodes == 12*13,"Pool allocates only twelve fixed groups with twelve sprites")
  var center: Vector3 = track.position_at(race.player.progress,race.player.lateral,0.12)
  for index in 200:
   effect.receive_feedback("landing" if index%2 else "collision",center,0.8,"wood")
   effect.advance(0.001)
   check(effect.active_count() <= 12,"Burst count remains bounded under flood")
  check(effect.find_children("*","Node",true,false).size() == nodes,"Flood adds no nodes")
  var total: int = effect.serial
  effect.receive_feedback("landing",center+Vector3.ONE*100,1,"asphalt")
  effect.receive_feedback("unknown",center,1,"wood")
  effect.receive_feedback("landing",Vector3(INF,0,0),1,"wood")
  check(effect.serial == total,"Distant or invalid events do not allocate or display bursts")
  var age: float = effect.bursts[0].age
  race.paused = true
  effect.receive_feedback("hit",center,1,"wood")
  effect.advance(2)
  check(effect.bursts[0].age == age and effect.serial == total,"Pause freezes lifetime and rejects events")
  race.paused = false
  effect.advance(0.2,true)
  check(effect.bursts[0].age == age,"Explicit Main freeze also preserves lifetime")
  effect.advance(0.1,false)
  check(effect.bursts[0].age > age,"Resume advances new frame time")
  for burst in effect.bursts:
   for sprite in burst.sprites:
    check(sprite.position.is_finite() and sprite.scale.is_finite() and sprite.modulate.a >= 0 and sprite.modulate.a <= 1,"Actual sprite poses/fades remain finite")
  race.done = true
  effect.receive_feedback("finish",center,1,"wood")
  effect.advance(0.1)
  check(effect.active_count() > 0,"Finish celebration remains visible while completed race drains")
  total = effect.serial
  effect.receive_feedback("landing",center,1,"wood")
  check(effect.serial == total,"Completed race rejects new landing bursts")
  effect.advance(2)
  check(effect.active_count() == 0,"All bursts expire after done without leaking")
  for index in 10: effect.bind(race,texture,texture)
  check(effect.find_children("*","Node",true,false).size() == nodes and race.feedback.get_connections().size() == 2,"Repeated bind keeps fixed pool and single effect connection")
  effect.clear()
  check(effect.active_count() == 0 and race.feedback.get_connections().size() == 1,"Clear disconnects effect and hides pool")
  race.done = false
  race.player.finish_time = -1
  race.player.progress = Race.LAPS*track.length-0.02
  race.player.speed = 20
  race.player.jump_height = 0
  events.clear()
  race.step(0.1,1,0,0,false)
  var finishes: int = 0
  for event in events:
   if event.kind == "finish": finishes += 1
  check(race.done and finishes == 1,"Actual finish emits exactly one celebration")
  count = events.size()
  race.step(0.1,1,0,0,false)
  check(events.size() == count,"Done race produces no more events")
  var old: WeakRef = weakref(effect)
  race.queue_free()
  track.queue_free()
  await process_frame
  check(old.get_ref() == null,"Race deletion frees complete sprite pool")
 print("BORACER RACE FEEDBACK: %d checks, %d failures" % [checks,failures])
 quit(0 if failures == 0 else 1)
