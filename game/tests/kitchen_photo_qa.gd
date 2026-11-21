extends SceneTree
## Independent actual Track5 geometry, camera and imported photo/UV checks.
const Track = preload("res://scripts/track.gd")
const CameraRig = preload("res://scripts/follow_camera.gd")
const Photos = preload("res://scripts/worlds/kitchen_photo_materials.gd")
var checks = 0
var failures: Array[String] = []
var shapes: Array[Dictionary] = []

func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  failures.append(label)
  if failures.size() <= 12: push_error(label)

func _initialize() -> void:
 call_deferred("run")

func collect(node: Node, owner_id: String) -> void:
 if node is MeshInstance3D:
  shapes.append({"inverse":node.global_transform.affine_inverse(),"box":node.get_aabb(),"id":owner_id,"name":node.name})
 for child in node.get_children(): collect(child,owner_id)

func hit(point: Vector3, margin: float) -> String:
 for shape in shapes:
  if shape.box.grow(margin).has_point(shape.inverse*point):
   return str(shape.id)+"/"+str(shape.name)
 return ""

func mesh_bounds(node: Node3D) -> AABB:
 var result = AABB()
 var first = true
 for candidate in node.find_children("*","MeshInstance3D",true,false):
  var bound: AABB = candidate.global_transform*candidate.get_aabb()
  result = bound if first else result.merge(bound)
  first = false
 return result

func run() -> void:
 var track = Track.new()
 root.add_child(track)
 track.build(5)
 var props = track.get_node("KitchenProps")
 var expected = ["monitor","megaphone","can","remote","power","esp","scissors","paper","adapter","cloth","globe"]
 var visible_photos: Dictionary = {}
 for id in expected:
  check(props.has_node(id),"Actual table contains recognizable object: "+id)
  if not props.has_node(id): continue
  var object: Node3D = props.get_node(id)
  collect(object,id)
  var bounds = mesh_bounds(object)
  check(bounds.position.y >= -0.05 and bounds.position.y <= 0.65,"Object contacts tabletop without sinking/floating: "+id)
  check(bounds.end.y < 40 and bounds.position.x > -114 and bounds.end.x < 114 and bounds.position.z > -99 and bounds.end.z < 99,"Full primitive bounds remain on table: "+id)
  for photo in object.find_children("*","MeshInstance3D",true,false):
   if photo.has_meta("kitchen_photo_surface"):
    var surface_id: String = photo.get_meta("kitchen_photo_surface")
    visible_photos[surface_id] = true
    var arrays = photo.mesh.surface_get_arrays(0)
    var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    for index in normals.size():
     var outward = Vector3(vertices[index].x,0,vertices[index].z).normalized() if surface_id == "can_label" else Vector3.BACK
     check(normals[index].dot(outward) > 0.95,"Photo shading normal faces outside: "+surface_id)
 check(expected.size() >= 10,"At least ten independently named photo-informed object types")
 for id in ["monitor_screen","keyboard_top","can_label","remote_top"]:
  check(visible_photos.has(id),"Actual object geometry displays photo patch: "+id)
 var camera = Camera3D.new()
 root.add_child(camera)
 var rig = CameraRig.new(camera)
 for meter in range(ceili(track.length)+1):
  for lane in [-0.85,0.0,0.85]:
   for height in [0.4,1.2,2.5]:
    var result = hit(track.position_at(float(meter),track.width*lane,height),0.4)
    check(result.is_empty(),"Whole driving corridor meter%d lane%.2f h%.1f intersects %s" % [meter,lane,height,result])
   for jump in [0.0,1.2]:
    var kart = {"progress":float(meter),"lateral":track.width*lane,"speed":56.0,"jump_height":jump,"boost_time":3.0}
    rig.reset()
    rig.update(track,kart,0,true,true)
    var result = hit(camera.global_position,0.4)
    check(result.is_empty(),"Whole follow-camera corridor meter%d lane%.2f jump%.1f intersects %s" % [meter,lane,jump,result])
 # Reject a full plane across the megaphone mouth independently of topology labels.
 var horn = props.get_node("megaphone/OpenWhiteHorn")
 var faces: PackedVector3Array = horn.mesh.get_faces()
 for offset in [Vector3.ZERO,Vector3(1.0,0,0),Vector3(0,0,1.0)]:
  var intersections = 0
  for index in range(0,faces.size(),3):
   if Geometry3D.segment_intersects_triangle(offset+Vector3(0,-1,0),offset+Vector3(0,2,0),faces[index],faces[index+1],faces[index+2]) != null: intersections += 1
  check(intersections == 0,"Actual megaphone mouth triangles remain open at center/offset")
 check(props.get_node("can/CyanCan").material_override.metallic >= 0.7,"Can body retains metallic surface")
 check(props.get_node("globe/CrystalSphere").material_override.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA,"Glass object retains actual transparency")
 var texture_ids: Dictionary = {}
 var payload_bytes = 0
 for id in Photos.SURFACES:
  var corners: Array = Photos.SURFACES[id].uv
  var unit = [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]
  for index in 4:
   check(Photos.photo_uv(id,unit[index]).distance_to(corners[index]) < 0.00001,"Projective photo corner roundtrip "+id)
  for row in 17:
   for column in 25:
    var uv: Vector2 = Photos.photo_uv(id,Vector2(column/24.0,row/16.0))
    check(uv.is_finite() and uv.x>=0 and uv.y>=0 and uv.x<=1 and uv.y<=1,"Actual tessellated UV stays in photograph "+id)
  var material = Photos.material(id)
  var texture: Texture2D = material.albedo_texture
  check(texture != null and texture.get_width()>0 and texture.get_height()>0,"Shipped photo imports load: "+id)
  check(maxi(texture.get_width(),texture.get_height()) <= 2048,"GPU-import size budget: "+id)
  var image = texture.get_image()
  check(image != null and image.has_mipmaps(),"Actual imported photo retains mipmaps: "+id)
  if not texture_ids.has(texture.get_instance_id()):
   texture_ids[texture.get_instance_id()] = true
   payload_bytes += image.get_data().size()
   print("KITCHEN PHOTO IMPORT ",texture.resource_path," size=",texture.get_size()," format=",image.get_format()," compressed=",image.is_compressed()," payload=",image.get_data().size())
  check(not material.texture_repeat and material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC,"Photo uses clamped anisotropic mip filtering: "+id)
 check(texture_ids.size() == 5,"Seven surface materials share only five imported photo textures")
 print("KITCHEN PHOTO QA mesh_count=",shapes.size()," imported_textures=",texture_ids.size()," image_payload_bytes=",payload_bytes)
 camera.queue_free()
 track.queue_free()
 await process_frame
 print("BORACER KITCHEN PHOTO QA: %d checks, %d failures" % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
