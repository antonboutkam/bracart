extends SceneTree
## Independent quickwins integration, original-byte preservation and bounded effects.
const CameraRig = preload("res://scripts/follow_camera.gd")
const Nature = preload("res://scripts/worlds/nature_accents.gd")
const Main = preload("res://scripts/main.gd")
var checks = 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:
  failures.append(label)
  if failures.size()<=20: push_error(label)
func descendants(node: Node) -> Array[Node]:
 var nodes: Array[Node]=[]
 for child in node.get_children():
  nodes.append(child)
  nodes.append_array(descendants(child))
 return nodes
func original_bytes() -> void:
 var snapshot: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://validation/quickwins-before-baseline.json"))
 for path in snapshot.sha256:
  # Track may add a scenery setup hook. Exact original routes remain separate.
  if path=="scripts/track.gd":continue
  check(FileAccess.file_exists("res://"+path),"Original source/asset remains present: "+path)
  if FileAccess.file_exists("res://"+path):
   check(FileAccess.get_sha256("res://"+path)==snapshot.sha256[path],"Original route/model/photo/vehicle audio bytes preserved: "+path)
func nature_geometry(main,world: int) -> void:
 var accents=main.track.get_node_or_null("NatureAccents")
 if world not in [3,4]:
  check(accents==null,"New nature accents remain excluded from other worlds, especially kitchen")
  return
 check(accents!=null,"Haarlem/Uithoorn actually receive nature assets")
 if accents==null:return
 var records: Array=accents.get_meta("instances",[])
 check(records.size()==12 and accents.get_child_count()==4,"Exactly twelve small accents use four bounded batches")
 var outdoor=main.track.get_node("OutdoorLife")
 check(Nature.build(main.track,outdoor.get_meta("clusters"))==accents,"Nature install reuses existing batches")
 var slabs: Array[Transform3D]=[]
 for node in descendants(outdoor):
  if node is MultiMeshInstance3D and node.multimesh.mesh is BoxMesh:
   for t in node.get_meta("instance_transforms",[]):
    if absf(t.basis.y.length()-0.6)<0.001:slabs.append(t)
 var boxes: Array[AABB]=[]
 var unique={}
 for batch in accents.get_children():
  check(batch is MultiMeshInstance3D,"Nature draw nodes are actual MultiMesh batches")
  var transforms: Array=batch.get_meta("instance_transforms",[])
  check(transforms.size()==batch.multimesh.instance_count and transforms.size()==3,"CPU geometry submissions match actual MultiMesh count")
  for t in transforms:
   var bounds: AABB=t*batch.multimesh.mesh.get_aabb()
   boxes.append(bounds)
   check(bounds.size.is_finite() and bounds.size.y<=4.51 and bounds.size.y>=1.09,"Complete submitted asset fits intended small height")
   var supported=false
   for slab in slabs:
    var inside=true
    for corner in 8:
     var bottom: Vector3=t*batch.multimesh.mesh.get_aabb().get_endpoint(corner)
     bottom.y=bounds.position.y
     var p: Vector3=slab.affine_inverse()*bottom
     if absf(p.x)>.501 or absf(p.z)>.501 or absf(p.y-.5)>.015:inside=false
    if inside:supported=true
   check(supported,"Whole accent bottom footprint rests on a physically submitted promenade slab")
   var matched=false
   for record in records:
    if record.transform.is_equal_approx(t) and record.source==batch.get_meta("source"):
     check(record.bounds.is_equal_approx(bounds),"Declared bounds agree with actual submitted mesh geometry")
     unique[record.cluster_id]=true
     matched=true
   check(matched,"Every actual submitted instance is accounted for once")
  for surface in batch.multimesh.mesh.get_surface_count():
   var mat=batch.multimesh.mesh.surface_get_material(surface)
   check(mat is BaseMaterial3D and mat.cull_mode==BaseMaterial3D.CULL_BACK,"Imported nature uses real opaque backface-culled surfaces")
 check(unique.size()==12,"Accents vary twelve separate existing clusters")
 var camera=Camera3D.new()
 root.add_child(camera)
 var rig=CameraRig.new(camera)
 var visible=0
 for sample in ceili(main.track.length/0.6):
  var progress=sample*0.6
  for lane in [-5.95,0.0,5.95]:
   for height in [0.2,1.4,2.8]:
    var p: Vector3=main.track.position_at(progress,lane,height)
    for box in boxes:check(not box.grow(0.2).has_point(p),"New actual plant bounds keep full driving envelope clear")
   var kart={"progress":progress,"lateral":lane,"speed":56.0,"jump_height":1.2,"boost_time":2.0}
   rig.reset()
   rig.update(main.track,kart,0,true,true)
   for box in boxes:check(not box.grow(0.25).has_point(camera.position),"New plant bounds keep complete actual camera corridor clear")
  if sample%20==0:
   main.race.player.progress=progress
   main._camera(0,true)
   for box in boxes:
    if main.camera.is_position_in_frustum(box.get_center()):visible+=1
 check(visible>0,"Normal race views project some of the actual nature accents")
 print("QUICKWINS NATURE world=",world," instances=",boxes.size()," projected_views=",visible)
 camera.free()
func selected_assets() -> void:
 var directory="res://assets/third_party/kenney/"
 var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(directory+"manifest.json"))
 check(manifest.license=="CC0-1.0" and manifest.author.contains("Kenney"),"Selected assets record exact maker and CC0 provenance")
 check(manifest.assets.size()==10 and manifest.licenses.size()==3,"Only ten selected assets and three pack licenses are shipped")
 for entry in manifest.assets+manifest.licenses:
  check(FileAccess.get_sha256(directory+entry.path)==entry.sha256,"Selected asset/license bytes match recorded manifest hash")
  if entry.path.ends_with(".txt"):
   check(FileAccess.get_file_as_string(directory+entry.path).contains("Creative Commons Zero"),"Original pack license explicitly supplies CC0")
func audio_checks(main) -> void:
 main.start_race(5)
 await process_frame
 var sound=main.audio
 check(sound.impact_ready and sound.impact_clips.size()==4 and sound.impact_voices.size()==4,"Four actual imported CC0 material clips and four reusable spatial voices are present")
 for surface in ["wood","paper","plastic","asphalt"]:
  var stream=sound.impact_clips[surface]
  check(stream is AudioStreamWAV and stream.format==AudioStreamWAV.FORMAT_16_BITS and stream.mix_rate==44100 and not stream.stereo,"Actual imported material clip is mono44.1k PCM16, not compressed fixture")
  check(stream.data.size()>8000 and stream.get_length()>0.1 and stream.get_length()<1 and stream.loop_mode==AudioStreamWAV.LOOP_DISABLED,"Impacts are short nonlooping actual waveforms")
 sound.muted=false
 sound.apply(0,0.65)
 var ids=[]
 for voice in sound.impact_voices:ids.append(voice.get_instance_id())
 var at: Vector3=main.race.player.global_position
 var count: int=sound.impact_serial
 check(not sound.play_impact("landing",at+Vector3(51,0,0),1,"wood",at) and sound.impact_serial==count,"Distant events never allocate or start an audible clip")
 for repeat in 80:
  sound.advance_feedback(.2,false)
  var surface: String=["wood","paper","plastic","asphalt"][repeat%4]
  check(sound.play_impact("landing",at,1,surface,at),"Nearby material impact starts through actual selected clip")
  check(not sound.play_impact("landing",at,1,surface,at),"Same kind/material burst is debounced")
  for index in 4:
   var voice: AudioStreamPlayer3D=sound.impact_voices[index]
   check(voice.get_instance_id()==ids[index] and voice.global_position.is_finite() and voice.pitch_scale>=.959999 and voice.pitch_scale<=1.040001,"Stress voice%d id=%s original=%s pos=%s pitch=%.9f" % [index,voice.get_instance_id(),ids[index],voice.global_position,voice.pitch_scale])
 sound.clear_impacts()
 main.race.countdown=-1
 main.race.player.progress=10
 main.race.player.speed=0
 main.race.player.jump_height=.01
 main.race.player.jump_velocity=-4
 main.race.player.update_visual(main.track,0)
 count=sound.impact_serial
 main.race.step(.02,0,0,0,false)
 check(sound.impact_serial==count+1 and sound.get_meta("last_impact_surface")=="wood","Real Race landing reaches Main and chooses actual wood clip")
 main.race.player.shield_time=2
 count=sound.impact_serial
 main.race._weapon_hit(main.race.player,main.race.racers[1])
 check(sound.impact_serial==count,"Shielded hit does not produce a false material impact")
 main.race.player.shield_time=0
 main.race.player.hit_cooldown=0
 sound.advance_feedback(.3,false)
 main.race._weapon_hit(main.race.player,main.race.racers[1])
 check(sound.impact_serial==count+1,"Actual successful weapon hit reaches material audio")
 # Exercise the known 3D deferred-play edge through actual frame/physics boundaries.
 main.set_process(true)
 sound.clear_impacts()
 sound.play_impact("landing",at,1,"paper",at)
 main.ui.show_pause()
 for frame in 3:await physics_frame
 for voice in sound.impact_voices:check(voice.volume_db<=-79.9,"Actual Main pause hard-mutes even a just-started deferred 3D impact")
 main.ui.resume()
 for frame in 2:await process_frame
 sound.muted=true
 await process_frame
 for voice in sound.impact_voices:check(voice.volume_db<=-79.9,"Actual muted setting holds every impact voice silent")
 sound.muted=false
 sound.apply(0,0)
 await process_frame
 for voice in sound.impact_voices:check(voice.volume_db<=-79.9,"Actual sound-zero setting holds every impact voice silent")
 main.set_process(false)
 sound.apply(0,.65)
 main.go_home()
 for frame in 3:await physics_frame
 check(sound.impact_cooldowns.is_empty(),"Home clears material cooldown state")
 for voice in sound.impact_voices:check(not voice.playing,"Home stops every active material voice")
func ramp_feedback_checks(main) -> void:
 for id in ["comic_ramp","card_ramp"]:
  main.start_race(5)
  await process_frame
  main.audio.muted=true
  var feature={}
  for candidate in main.track.kitchen_features():
   if candidate.id==id:feature=candidate
  var events: Array=[]
  main.race.feedback.connect(func(kind,at,intensity,surface):
   if kind=="landing":events.append({"at":at,"surface":surface,"progress":main.race.player.progress}))
  main.race.countdown=-1
  var player=main.race.player
  player.progress=feature.lip-.12
  player.lateral=0
  player.speed=6
  player.boost=0
  player.jump_height=0
  player.jump_velocity=0
  var saw_airborne_zero=false
  for tick in 600:
   main.race.step(1.0/60,.12,0,0,false)
   if player.progress>feature.lip+.5 and player.progress<feature.landing-.3:
    if player.jump_height==0:saw_airborne_zero=true
    check(events.is_empty(),"Slow real ramp traversal emits no landing dust/audio in unsupported virtual air gap: "+id)
   if player.progress>feature.landing+2:break
  check(saw_airborne_zero,"Slow traversal actually exercises zero jump-height before physical guide landing")
  check(events.size()==1,"Actual ramp-to-table contact emits one deferred landing: "+id)
  if events.size()==1:
   check(events[0].progress>=feature.landing and events[0].surface=="wood" and events[0].at.y<.36,"Deferred event belongs to physical table contact, with wood material")
  var count=events.size()
  for tick in 30:main.race.step(1.0/60,.12,0,0,false)
  check(events.size()==count,"Continued grounded driving never repeats the deferred landing")
func vfx_checks(main) -> void:
 main.start_race(5)
 await process_frame
 var fx=main.race_feedback
 check(is_instance_valid(fx) and fx.get_parent()==main.race,"Actual Main binds feedback to current Race lifetime")
 check(fx.bursts.size()==12 and descendants(fx).size()==156,"Exactly twelve twelve-sprite groups are preallocated")
 var node_ids=[]
 for node in descendants(fx):node_ids.append(node.get_instance_id())
 var connections=main.race.feedback.get_connections().size()
 fx.bind(main.race)
 check(main.race.feedback.get_connections().size()==connections,"Rebinding does not stack feedback signal connections")
 var loop={}
 for feature in main.track.kitchen_features():
  if feature.id=="orange_loop":loop=feature
 var inverted=0.0
 for sample in 120:
  var p: float=lerpf(loop.start,loop.end,sample/119.0)
  if main.track.frame(p).basis.y.y<-.95:
   inverted=p
   break
 check(inverted>0,"Actual course contains an inverted landing-test position")
 main.race.countdown=-1
 main.race.player.progress=inverted
 main.race.player.speed=0
 main.race.player.jump_height=.01
 main.race.player.jump_velocity=-4
 main.race.player.update_visual(main.track,0)
 var serial: int=fx.serial
 main.race.step(.02,0,0,0,false)
 check(fx.serial>serial and fx.active_count()>0,"A real inverted Race landing produces actual loaded-texture sprites")
 var burst: Dictionary=fx.bursts[(fx.cursor+11)%12]
 var up: Vector3=main.track.frame(main.race.player.progress).basis.y
 check(burst.up.dot(up)>.999,"Landing dust uses the real inverted local road normal")
 fx.advance(.12)
 var mean=Vector3.ZERO
 for sprite in burst.sprites:
  check(sprite is Sprite3D and sprite.texture!=null and sprite.texture.resource_path.ends_with("particles/smoke.png"),"Visible landing sprites use actual selected CC0 smoke texture")
  check(sprite.position.is_finite() and sprite.no_depth_test==false,"Real sprite positions stay finite and respect scene depth")
  mean+=sprite.position
 check((mean/12).dot(up)>.05,"Actual dust positions leave the surface along inverted road UP")
 for repeat in 240:
  main.race.feedback.emit(["landing","collision","hit","finish"][repeat%4],main.race.player.global_position,1,"plastic")
  check(fx.active_count()<=12,"Event flood never exceeds twelve active groups")
  check(descendants(fx).size()==node_ids.size(),"Event flood keeps fixed allocation count")
 for index in node_ids.size():check(descendants(fx)[index].get_instance_id()==node_ids[index],"Stress keeps every original particle node")
 for active in fx.bursts:
  for sprite in active.sprites:
   check(sprite.texture!=null and sprite.modulate.a>=0 and sprite.modulate.a<=1,"All rendered sprite slots retain a real texture and bounded alpha")
 serial=fx.serial
 main.race.feedback.emit("landing",main.race.player.global_position+Vector3(60,0,0),1,"wood")
 main.race.feedback.emit("unknown",main.race.player.global_position,1,"wood")
 check(fx.serial==serial,"Distant or unknown feedback cannot spawn extra VFX")
 fx.advance(2)
 check(fx.active_count()==0,"All effect kinds drain within bounded lifetime")
 for active in fx.bursts:check(not active.node.visible,"Expired sprite groups become invisible")
 main.race.feedback.emit("landing",main.race.player.global_position,1,"wood")
 main.set_process(true)
 main.ui.show_pause()
 for frame in 3:await physics_frame
 var frozen_elapsed: float=fx.elapsed
 var frozen_poses=[]
 for active in fx.bursts:
  for sprite in active.sprites:frozen_poses.append(sprite.position)
 await create_timer(.1).timeout
 check(fx.elapsed==frozen_elapsed,"Actual Main pause freezes effect clock")
 var index=0
 for active in fx.bursts:
  for sprite in active.sprites:
   check(sprite.position==frozen_poses[index],"Actual Main pause freezes all submitted particle positions")
   index+=1
 serial=fx.serial
 main.race.feedback.emit("landing",main.race.player.global_position,1,"wood")
 check(fx.serial==serial,"Paused Main rejects new feedback emissions")
 main.ui.resume()
 await create_timer(.1).timeout
 check(fx.elapsed>frozen_elapsed,"Actual Main resume restarts effect simulation")
 main.set_process(false)
 fx.clear()
 fx.bind(main.race)
 main.race.player.progress=main.track.length*3-.1
 main.race.player.speed=56
 main.race.player.jump_height=0
 main.race.player.jump_velocity=0
 main.race.player.update_visual(main.track,0)
 serial=fx.serial
 main.race.step(.02,1,0,0,false)
 check(main.race.done and fx.serial==serial+1,"Real final line crossing emits exactly one finish effect before results")
 check(fx.active_count()==1,"Results retain the one finish burst instead of clearing it immediately")
 await process_frame
 var celebration=main.ui.overlay.get_node_or_null("FinishConfetti")
 check(celebration is Control and celebration.get_index()==main.ui.overlay.get_child_count()-1,"Actual results add the visible celebration after the opaque panel")
 var celebration_ref=weakref(celebration)
 if celebration!=null:
  check(celebration.mouse_filter==Control.MOUSE_FILTER_IGNORE and celebration.focus_mode==Control.FOCUS_NONE,"Results celebration never captures mouse or keyboard controls")
  check(celebration.points().size()==18 and celebration.SPARK.resource_path.ends_with("particles/spark.png"),"Eighteen results draw points use actual selected CC0 spark asset")
  var saved_age: float=celebration.age
  var saved_size: Vector2=celebration.size
  celebration.set_process(false)
  for viewport_size in [Vector2(1280,800),Vector2(800,600),Vector2(360,640)]:
   celebration.size=viewport_size
   for tick in 160:
    celebration.age=tick*.01
    for point in celebration.points():check(point.is_finite() and Rect2(Vector2.ZERO,viewport_size).has_point(point),"Every celebration draw anchor stays inside supported viewport sizes")
  celebration.age=saved_age
  celebration.size=saved_size
  celebration.set_process(true)
  var age_before: float=celebration.age
  await create_timer(.05).timeout
  check(celebration.age>age_before,"Actual results frames animate the foreground celebration")
  main.race.paused=true
  age_before=celebration.age
  await create_timer(.08).timeout
  check(celebration.age==age_before,"Celebration follows the actual owning Race pause flag")
  main.race.paused=false

 main.race.step(1,1,0,0,false)
 check(fx.serial==serial+1,"Stepping a completed race cannot award duplicate finish confetti")
 main.set_process(true)
 await create_timer(1.8).timeout
 check(fx.active_count()==0,"Actual results frames let finish confetti expire completely")
 check(celebration_ref.get_ref()==null,"Foreground celebration expires and frees itself after its bounded lifetime")
 main.set_process(false)
 var old=weakref(fx)
 main.start_race(0)
 for frame in 3:await process_frame
 check(old.get_ref()==null and main.race_feedback!=null,"World replacement frees old pool and binds a new one")
 old=weakref(main.race_feedback)
 main.race.player.progress=main.track.length*3-.1
 main.race.player.speed=56
 main.race.countdown=-1
 main.race.step(.02,1,0,0,false)
 await process_frame
 var home_celebration=weakref(main.ui.overlay.get_node("FinishConfetti"))
 main.go_home()
 for frame in 3:await process_frame
 check(old.get_ref()==null and main.race_feedback==null,"Home frees the complete race-owned VFX pool")
 check(home_celebration.get_ref()==null,"Home clears a still-active foreground celebration")
func run() -> void:
 original_bytes()
 selected_assets()
 var main=Main.new()
 root.add_child(main)
 main.set_process(false)
 main.set_physics_process(false)
 main.audio.muted=true
 main.audio.music.stop()
 main.audio.music.stream=null
 for world in 6:
  main.start_race(world)
  await process_frame
  nature_geometry(main,world)
 await audio_checks(main)
 await ramp_feedback_checks(main)
 await vfx_checks(main)
 main.queue_free()
 for frame in 8:await process_frame
 print("BORACER QUICKWINS INDEPENDENT QA: %d checks, %d failures" % [checks,failures.size()])
 quit(1 if failures.size() else 0)
