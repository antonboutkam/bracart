extends SceneTree
# Inspect the game's imported PackedScenes, not GLTFDocument source candidates.
var checks := 0
var failures: Array[String] = []
var details: Dictionary = {}
var out := "/home/anton/Documents/sites/boracart/persons/integration-materials-2026-11-21"

func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures.append(label)
  push_error(label)

func _initialize() -> void:
 call_deferred("run")

func compare_texture(texture: Texture2D, expected_path: String, label: String) -> void:
 check(texture != null,label+" exists")
 if texture == null: return
 check(texture.get_width()==2048 and texture.get_height()==2048,label+" imports at 2048px")
 var image := texture.get_image()
 check(image != null,label+" readable")
 if image == null:return
 if image.is_compressed(): check(image.decompress()==OK,label+" decompression")
 var expected := Image.load_from_file(expected_path)
 check(expected != null,label+" source readable")
 if expected == null or image.get_size()!=expected.get_size():return
 var delta := 0.0
 for y in range(64,2048,128):
  for x in range(64,2048,128):
   var actual := image.get_pixel(x,y)
   var wanted := expected.get_pixel(x,y)
   delta=maxf(delta,maxf(absf(actual.r-wanted.r),maxf(absf(actual.g-wanted.g),absf(actual.b-wanted.b))))
 check(delta<=0.04,label+" cached pixels match new source within compression tolerance")
 details[label]={"width":image.get_width(),"height":image.get_height(),"sampled_max_rgb_delta":delta}

func run() -> void:
 for id in ["boaz","ravi"]:
  var path := "res://assets/models/%s.glb" % id
  var packed = load(path) as PackedScene
  check(packed!=null,id+" cached game PackedScene")
  if packed==null:continue
  var model := packed.instantiate()
  root.add_child(model)
  await process_frame
  var meshes := model.find_children("*","MeshInstance3D",true,false)
  var skeletons := model.find_children("*","Skeleton3D",true,false)
  check(skeletons.size()==1 and skeletons[0].get_bone_count()==51,id+" cached skeleton")
  check(meshes.size()==1,id+" cached character mesh")
  for mesh in meshes:
   check(mesh.mesh.get_blend_shape_count()==20,id+" cached morphs")
   check(absf(mesh.mesh.get_aabb().size.y-1.15)<0.002,id+" cached height")
   for surface in mesh.mesh.get_surface_count():
    var material = mesh.get_active_material(surface) as BaseMaterial3D
    check(material!=null,id+" PBR material")
    if material:
     var source := "/home/anton/Documents/sites/boracart/persons/%s/%s_" % [id,id]
     compare_texture(material.albedo_texture,source+"basecolor.png",id+" albedo")
     compare_texture(material.roughness_texture,source+"orm.png",id+" roughness")
     compare_texture(material.metallic_texture,source+"orm.png",id+" metallic")
     check(material.roughness_texture_channel==BaseMaterial3D.TEXTURE_CHANNEL_GREEN,id+" roughness uses G")
     check(material.metallic_texture_channel==BaseMaterial3D.TEXTURE_CHANNEL_BLUE,id+" metallic uses B")
  var player = model.find_child("AnimationPlayer",true,false) as AnimationPlayer
  check(player!=null,id+" cached animation player")
  if player:
   var clips := player.get_animation_list()
   for expected in ["Idle","Run","Jump","Cheer","Kart_Sit","Kart_Steer"]:
    check(Array(clips).any(func(clip):return str(clip).get_file()==expected),id+" cached clip "+expected)
  model.queue_free()
  await process_frame
 var report := {"checks":checks,"failures":failures,"passed":failures.is_empty(),"textures":details,"Godot":Engine.get_version_info().string,"scope":"Actual imported game PackedScenes and cached material pixels; no rendered visual approval."}
 var file := FileAccess.open(out+"/game-material-validation.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  ")+"\n")
 print("GAME MATERIAL CHECKS: %d; failures: %d" % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
