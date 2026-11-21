extends RefCounted
## UV-only extraction from byte-identical customer photographs. No raster edits.
## patch: XY rectangle, front +Z. Rotate X=-PI/2 for a top surface facing +Y.
const PHOTO_ROOT = "res://assets/textures/kitchen/photos/"
# Four normalized photo corners in local TL,TR,BR,BL order.
const SURFACES = {
 "can_label": {"photo":"093242", "uv":[Vector2(.285,.231),Vector2(.625,.215),Vector2(.609,.784),Vector2(.349,.793)]},
 "monitor_screen": {"photo":"093236", "uv":[Vector2(.259,.002),Vector2(.995,.002),Vector2(.995,.244),Vector2(.271,.234)]},
 "keyboard_top": {"photo":"093205", "uv":[Vector2(.226,.646),Vector2(.990,.457),Vector2(.995,.768),Vector2(.321,.943)]},
 "remote_top": {"photo":"093239", "uv":[Vector2(.040,.404),Vector2(.898,.572),Vector2(.860,.708),Vector2(.011,.507)]},
 "megaphone_cap": {"photo":"093220", "uv":[Vector2(.303,.111),Vector2(.478,.077),Vector2(.522,.215),Vector2(.339,.228)]},
 "adapter_label": {"photo":"093205", "uv":[Vector2(.425,.417),Vector2(.531,.399),Vector2(.569,.454),Vector2(.468,.478)]},
 "esp_top": {"photo":"093220", "uv":[Vector2(.904,.342),Vector2(.995,.360),Vector2(.995,.419),Vector2(.888,.395)]}
}
static var _materials: Dictionary = {}

static func material(id: String) -> StandardMaterial3D:
 assert(SURFACES.has(id),"Unknown kitchen photo surface: " + id)
 if _materials.has(id): return _materials[id]
 var mat = StandardMaterial3D.new()
 mat.albedo_texture = load(PHOTO_ROOT + "IMG_20261017_" + SURFACES[id].photo + ".jpg")
 mat.albedo_color = Color.WHITE
 mat.roughness = 0.72
 mat.metallic_specular = 0.18
 mat.cull_mode = BaseMaterial3D.CULL_DISABLED
 mat.texture_repeat = false
 mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
 if id == "monitor_screen":
  mat.emission_enabled = true
  mat.emission_texture = mat.albedo_texture
  mat.emission = Color.WHITE
  mat.emission_energy_multiplier = 0.16
 _materials[id] = mat
 return mat

static func photo_uv(id: String, point: Vector2) -> Vector2:
 # Homography from unit rectangle to the photo's measured perspective quadrilateral.
 var q: Array = SURFACES[id].uv
 var a: Vector2 = q[0]
 var b: Vector2 = q[1]
 var c: Vector2 = q[2]
 var d: Vector2 = q[3]
 var dx1 = b.x-c.x
 var dx2 = d.x-c.x
 var dy1 = b.y-c.y
 var dy2 = d.y-c.y
 var sx = a.x-b.x+c.x-d.x
 var sy = a.y-b.y+c.y-d.y
 var denominator = dx1*dy2-dx2*dy1
 var g = (sx*dy2-dx2*sy)/denominator if absf(denominator)>0.000001 else 0.0
 var h = (dx1*sy-sx*dy1)/denominator if absf(denominator)>0.000001 else 0.0
 var divisor = g*point.x+h*point.y+1.0
 return Vector2(((b.x-a.x+g*b.x)*point.x+(d.x-a.x+h*d.x)*point.y+a.x)/divisor,((b.y-a.y+g*b.y)*point.x+(d.y-a.y+h*d.y)*point.y+a.y)/divisor)

static func patch(parent: Node3D, id: String, size: Vector2) -> MeshInstance3D:
 return _surface(parent,id,size,0.0)

static func wrap_can(parent: Node3D, radius: float, height: float) -> MeshInstance3D:
 # Front cylindrical label sector, with an actual metallic can body supplied by props.
 # The hidden rear remains cyan metal: do not repeat one front logo around the can.
 return _surface(parent,"can_label",Vector2(radius*1.6,height),radius)

static func _surface(parent: Node3D, id: String, size: Vector2, radius: float) -> MeshInstance3D:
 var st = SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 st.set_material(material(id))
 var columns = 24
 var rows = 16
 for y in rows:
  for x in columns:
   for corner in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(0,1)]:
    var t = Vector2((x+corner.x)/columns,(y+corner.y)/rows)
    st.set_uv(photo_uv(id,t))
    var vertex = Vector3((t.x-.5)*size.x,(.5-t.y)*size.y,0)
    if radius>0:
     var angle = (t.x-.5)*1.6
     vertex.x = sin(angle)*radius
     vertex.z = cos(angle)*radius
    st.add_vertex(vertex)
 st.generate_normals()
 var mesh = MeshInstance3D.new()
 mesh.name = "KitchenPhoto_" + id
 mesh.mesh = st.commit()
 mesh.set_meta("kitchen_photo_surface",id)
 mesh.set_meta("photo_source",PHOTO_ROOT+"IMG_20261017_"+SURFACES[id].photo+".jpg")
 mesh.set_meta("photo_uv_corners",SURFACES[id].uv)
 mesh.set_meta("world_material","customer_photo")
 parent.add_child(mesh)
 return mesh
