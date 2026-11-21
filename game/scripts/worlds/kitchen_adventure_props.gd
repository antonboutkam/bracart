extends RefCounted
## Static tabletop adventure props. Track route/loop/camera belong to Sem.
const Geo = preload("res://scripts/geometry.gd")

# Thick open-ended cylinder along local Z, split into outer/inner/rim surfaces.
# Only the annular wall is closed: no triangle ever caps the central passage.
static func tube_mesh(inner_radius: float, outer_radius: float, length: float) -> ArrayMesh:
 var mesh = ArrayMesh.new()
 for surface in 3:
  var st = SurfaceTool.new()
  st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for i in 64:
   var a = TAU*i/64.0
   var b = TAU*(i+1)/64.0
   var n = Vector3(cos((a+b)/2),sin((a+b)/2),0)
   var oa = Vector3(cos(a)*outer_radius,sin(a)*outer_radius,-length/2)
   var ob = Vector3(cos(b)*outer_radius,sin(b)*outer_radius,-length/2)
   var ia = Vector3(cos(a)*inner_radius,sin(a)*inner_radius,-length/2)
   var ib = Vector3(cos(b)*inner_radius,sin(b)*inner_radius,-length/2)
   var offset = Vector3(0,0,length)
   if surface==0: _quad(st,oa,ob,ob+offset,oa+offset,n)
   elif surface==1: _quad(st,ia,ia+offset,ib+offset,ib,-n)
   else:
    _quad(st,ia,ib,ob,oa,Vector3.FORWARD)
    _quad(st,ia+offset,oa+offset,ob+offset,ib+offset,Vector3.BACK)
  st.commit(mesh)
 return mesh

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3,normal: Vector3) -> void:
 for triangle in [[a,b,c],[a,c,d]]:
  if (triangle[2]-triangle[0]).cross(triangle[1]-triangle[0]).dot(normal)<0: triangle=[triangle[0],triangle[2],triangle[1]]
  for point in triangle:
   st.set_normal(normal)
   st.add_vertex(point)

static func _box(parent: Node3D,p: Vector3,size: Vector3,color: Color) -> MeshInstance3D:
 var mesh = Geo.box(parent,p,size,color)
 mesh.set_meta("world_material","kitchen_adventure")
 mesh.material_override.roughness = 0.8
 return mesh

static func _metal(mesh: MeshInstance3D) -> MeshInstance3D:
 mesh.material_override.metallic = 0.65
 mesh.material_override.roughness = 0.3
 mesh.set_meta("world_material","kitchen_adventure_metal")
 return mesh

static func room(parent: Node3D) -> Node3D:
 var furniture = Node3D.new()
 furniture.name = "AdventureRoomFurniture"
 parent.add_child(furniture)
 # Bookcase at the right wall, entirely outside the tabletop/camera envelope.
 var bookcase = Node3D.new()
 bookcase.name = "Bookcase"
 furniture.add_child(bookcase)
 _box(bookcase,Vector3(458,38,-80),Vector3(3,200,250),Color("a59075"))
 for z in [-205,45]: _box(bookcase,Vector3(440,38,z),Vector3(38,200,4),Color("b6a18a"))
 for y in [-60,-20,20,60,100,138]: _box(bookcase,Vector3(440,y,-80),Vector3(38,3,250),Color("b5a084"))
 for shelf in 5:
  for column in 8:
   var h = 24.0+(column*7+shelf*3)%12
   var color = [Color("86745f"),Color("63746a"),Color("697480"),Color("8f756b")][(column+shelf)%4]
   _box(bookcase,Vector3(439,-58.5+shelf*40+h/2,-190+column*29),Vector3(26,h,19+column%3*2),color)
   _box(bookcase,Vector3(425.8,-58.5+shelf*40+h*.7,-190+column*29),Vector3(0.2,1.5,12),color.lightened(.25))
 # Add a recognisable hob and oven to the existing kitchen counter, not a duplicate room.
 var stove = Node3D.new()
 stove.name = "Stove"
 furniture.add_child(stove)
 _box(stove,Vector3(-95,-.7,320),Vector3(62,.6,47),Color("282d30"))
 for x in [-111,-82]:
  for z in [307,331]:
   _metal(Geo.cylinder(stove,Vector3(x,-.3,z),6.5,.2,Color("8f9696")))
   Geo.cylinder(stove,Vector3(x,-.15,z),5.5,.15,Color("34393b"))
 _box(stove,Vector3(-95,-35,281.7),Vector3(56,34,.7),Color("363e42"))
 _box(stove,Vector3(-95,-35,281.2),Vector3(46,23,.2),Color("4d6062"))
 _metal(_box(stove,Vector3(-95,-20,280.6),Vector3(43,1.3,1.4),Color("c2c5bd")))
 for x in [-113,-101,-89,-77]: _metal(Geo.cylinder(stove,Vector3(x,-13,280.6),1.7,1.3,Color("c2c5bd"))).rotation.x=PI/2
 furniture.set_meta("review_views",[
  {"id":"room-bookcase","eye":Vector3(105,55,-70),"target":Vector3(445,40,-80)},
  {"id":"room-kitchen-stove","eye":Vector3(20,55,90),"target":Vector3(-40,10,320)}])
 return furniture

static func _controller(parent: Node3D,p: Vector3) -> Node3D:
 var root = Node3D.new()
 root.name = "BlackGameController"
 root.position = p
 parent.add_child(root)
 _box(root,Vector3(0,1,0),Vector3(10,1.8,5.8),Color("171c20"))
 for side in [-1,1]:
  var grip = Geo.ball(root,Vector3(side*5,0.9,2.1),Vector3(5,2.1,7),Color("171c20"))
  grip.rotation.y=side*.18
  Geo.cylinder(root,Vector3(side*2.1,2.1,1.1),1.1,.7,Color("343b3f"))
 _box(root,Vector3(-3.9,2.03,-1.5),Vector3(2.5,.35,.7),Color("383e40"))
 _box(root,Vector3(-3.9,2.03,-1.5),Vector3(.7,.35,2.5),Color("383e40"))
 for offset in [Vector3(0,0,-.75),Vector3(.75,0,0),Vector3(0,0,.75),Vector3(-.75,0,0)]:
  Geo.cylinder(root,Vector3(3.9,2.04,-1.5)+offset,.35,.3,Color("929b8a"))
 _box(root,Vector3(0,2.02,-1.1),Vector3(1.6,.1,.8),Color("6e777b"))
 return root

static func build(track: Node3D) -> Node3D:
 if track.world_index!=5: return null
 var root = Node3D.new()
 root.name = "KitchenAdventureProps"
 track.add_child(root)
 var records: Array[Dictionary] = []
 var features: Array = track.call("kitchen_features") if track.has_method("kitchen_features") else []
 for feature in features:
  var id: String = feature.get("id",feature.get("kind",""))
  if id in ["toilet_rolls","pvc_rainbow"]:
   records.append(_tunnel(root,feature,id))
   if feature.has("entry_start") and feature.has("plateau_start"):
    _approach(root,track,feature.entry_start,feature.plateau_start,id+"_entry_underlay")
   if feature.has("plateau_end") and feature.has("entry_end"):
    _approach(root,track,feature.plateau_end,feature.entry_end,id+"_exit_underlay")
  elif id=="loose_cables": records.append(_cables(root,feature))
  elif id in ["comic_ramp","card_ramp"]: records.append(_ramp(root,feature,id,track))
 var controller_position = Vector3(-4,0.12,-38)
 var controller = _controller(root,controller_position)
 controller.set_meta("footprint_radius",10.0)
 records.append({"id":"game_controller","kind":"controller","center":controller_position,"radius":10.0,"node":str(controller.name),"height":3.0})
 for record in records:
  var bounds = _bounds(root.get_node(record.node),track.global_transform.affine_inverse())
  if record.has("support_node"): bounds.append_array(_bounds(root.get_node(record.support_node),track.global_transform.affine_inverse()))
  var merged: AABB = bounds[0]
  for item in bounds.slice(1): merged=merged.merge(item)
  record.static_aabb=merged
 root.set_meta("features",records)
 var sites: Array = track.get_meta("scenic_sites",[])
 sites.append({"position":controller_position,"radius":10.0,"object":"game_controller"})
 track.set_meta("scenic_sites",sites)
 return root

static func _tunnel(parent: Node3D,feature: Dictionary,id: String) -> Dictionary:
 var root = Node3D.new()
 root.name = id
 root.transform = feature.frame
 parent.add_child(root)
 var inner = float(feature.get("inner_radius",12.4))
 var outer = float(feature.get("outer_radius",13.2))
 var floor_y: float = root.position.y
 var axis_offset = float(feature.get("axis_height",13.3))-floor_y
 var length = float(feature.get("length",18))
 var paper = id=="toilet_rolls"
 for index in (2 if paper else 1):
  var tube_length = 8.0 if paper else length
  var offset_z = (-4.5+index*9) if paper else 0.0
  var tube = MeshInstance3D.new()
  tube.name = "PaperRoll_%d" % index if paper else "HollowPVC"
  tube.mesh = tube_mesh(inner,outer,tube_length)
  var outside = Geo.material(Color("e6e1d4") if paper else Color("727a7c"))
  var inside = Geo.material(Color("ac8b65") if paper else Color("555d60"))
  var rim = Geo.material(Color("d9cfb8") if paper else Color("899092"))
  outside.roughness = 0.95 if paper else 0.62
  for surface in 3:
   tube.set_surface_override_material(surface,[outside,inside,rim][surface])
  tube.set_meta("world_material","kitchen_paper_roll" if paper else "kitchen_pvc")
  root.add_child(tube)
  tube.position = Vector3(0,axis_offset,offset_z)
 # A real flat road floor lies inside the bore; its wheels never hang over empty air.
 _box(root,Vector3(0,-.15,0),Vector3(14,.24,length),Color("a88c65") if paper else Color("6d7779"))
 var support_bottom = axis_offset-sqrt(inner*inner-6.7*6.7)-.08
 var support_top = -.27
 for side in [-1,1]: _box(root,Vector3(side*6.7,(support_top+support_bottom)/2,0),Vector3(.35,support_top-support_bottom,length),Color("9c8262") if paper else Color("667174"))
 return {"id":id,"kind":"paper_tunnel" if paper else "pvc_tunnel","node":id,"frame":root.transform,"center":root.position,"inner_radius":inner,"outer_radius":outer,"length":length,"axis_offset":axis_offset,"road_progress":feature.get("center",0),"height":axis_offset+outer,"radius":Vector2(outer,length/2).length(),"footprint":Vector2(outer,length/2),"camera_clearance_radius":inner}

static func _cables(parent: Node3D,feature: Dictionary) -> Dictionary:
 var root = Node3D.new()
 root.name = "OverheadCables"
 root.transform = feature.frame
 parent.add_child(root)
 var paths: Array = []
 for cable in 3:
  var points: Array[Vector3] = []
  for step in 13:
   var x = -18+step*3.0
   var y = 9.4+1.4*cos(x/18*PI)-absf(x)/18*1.2
   # The last two segments descend only beyond the complete road/camera width.
   if absf(x)>=15: y=0.25+(18-absf(x))*2.2
   points.append(Vector3(x,y+cable*.18,-1.4+cable*1.4))
  for i in points.size()-1:
   var segment = Geo.beam(root,points[i],points[i+1],.14,Color("252b2e"))
   segment.set_meta("world_material","kitchen_cable")
  for point in points.slice(1,points.size()-1): Geo.ball(root,point,Vector3.ONE*.28,Color("252b2e"))
  paths.append(points)
 return {"id":"loose_cables","kind":"overhead_cables","node":str(root.name),"frame":root.transform,"center":root.position,"paths":paths,"cable_radius":.14,"road_progress":feature.get("center",0),"height":12.0,"radius":19.0}

static func _ramp(parent: Node3D,feature: Dictionary,id: String,track: Node3D) -> Dictionary:
 var root = Node3D.new()
 root.name = id
 root.transform = feature.frame
 parent.add_child(root)
 var length: float = feature.get("length",10)
 var width: float = feature.get("width",14)
 var comic = id=="comic_ramp"
 var thickness = .45 if comic else .13
 var start: float = feature.start
 var end: float = feature.lip
 _sheet(root,track,start,end,width+.5,thickness,Color("3e6e9c") if comic else Color("ede9db"),"ComicAlbum" if comic else "PlayingCard")
 if comic:
  for row in 2:
   for column in 3:
    var da = lerpf(start,end,.1+row*.45)
    var db = lerpf(start,end,.4+row*.45)
    _patch(root,track,da,db,-4.7+column*4.7,4.0,[Color("b69d6d"),Color("995c55"),Color("68957b")][column])
  _top_text(root,track,lerpf(start,end,.08),"STRIPAVONTUUR",64,.013,Color.WHITE)
 else:
  for t in [.22,.77]: _top_text(root,track,lerpf(start,end,t),"♥",105,.022,Color("a32f39"))
 var lip: Transform3D = feature.get("lip_frame",root.transform)
 var h = maxf(lip.origin.y-.12-thickness,.2)
 var support = Node3D.new()
 support.name = "WoodBlock" if comic else "JengaBlock"
 parent.add_child(support)
 # Horizontal support under the elevated lip; tilted album/card sits on its top.
 var horizontal_forward = -lip.basis.z
 horizontal_forward.y=0
 horizontal_forward=horizontal_forward.normalized()
 support.transform=Transform3D(Basis(horizontal_forward.cross(Vector3.UP),Vector3.UP,-horizontal_forward),lip.origin)
 support.position.y=.12
 _box(support,Vector3(0,h/2,0),Vector3(width*.85,h,2.8),Color("b69b73") if comic else Color("c5ad80"))
 if not comic:
  for x in [-width*.26,0,width*.26]: _box(support,Vector3(x,h*.5,-1.41),Vector3(.035,h,.02),Color("a78e66"))
 return {"id":id,"kind":"comic_album_ramp" if comic else "playing_card_jenga_ramp","node":id,"frame":root.transform,"center":root.position,"length":length,"width":width,"road_progress":feature.get("center",0),"start_frame":feature.get("start_frame",root.transform),"lip_frame":lip,"height":h,"radius":Vector2(width/2,length/2).length(),"support_node":str(support.name)}

static func _approach(parent: Node3D,track: Node3D,from: float,to: float,id: String) -> void:
 if to<=from: return
 var st = SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var segments = int(ceil((to-from)/.7))
 for i in segments:
  var da = lerpf(from,to,float(i)/segments)
  var db = lerpf(from,to,float(i+1)/segments)
  var fa: Transform3D = track.frame(da)
  var fb: Transform3D = track.frame(db)
  var a: Vector3 = track.position_at(da,-7.2)-fa.basis.y*.03
  var b: Vector3 = track.position_at(da,7.2)-fa.basis.y*.03
  var c: Vector3 = track.position_at(db,7.2)-fb.basis.y*.03
  var d: Vector3 = track.position_at(db,-7.2)-fb.basis.y*.03
  var bottom = .02 # Continuous underside just inside the existing tabletop.
  var aa = Vector3(a.x,bottom,a.z)
  var bb = Vector3(b.x,bottom,b.z)
  var cc = Vector3(c.x,bottom,c.z)
  var dd = Vector3(d.x,bottom,d.z)
  _quad(st,a,b,c,d,fa.basis.y)
  _quad(st,aa,dd,cc,bb,Vector3.DOWN)
  _quad(st,a,d,dd,aa,-fa.basis.x)
  _quad(st,b,bb,cc,c,fa.basis.x)
  if i==0: _quad(st,a,aa,bb,b,fa.basis.z)
  if i==segments-1: _quad(st,d,c,cc,dd,-fb.basis.z)
 var node = Geo.mesh(parent,st.commit(),Vector3.ZERO,Color("b9a588"))
 node.name = id
 node.set_meta("world_material","kitchen_paper_underlay")
 node.set_meta("route_interval",Vector2(from,to))


static func _sheet(parent: Node3D,track: Node3D,start: float,end: float,width: float,thickness: float,color: Color,name: String) -> void:
 var logical_interval = Vector2(start,end)
 # Physical cover extends beyond both logical joints; a wheel exactly on the
 # takeoff/entry seam still has a real supporting surface under it.
 start-=.15
 end+=.15
 var st = SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var inverse: Transform3D = parent.transform.affine_inverse()
 var segments = int(ceil((end-start)/.35))
 for i in segments:
  var da = lerpf(start,end,float(i)/segments)
  var db = lerpf(start,end,float(i+1)/segments)
  var fa: Transform3D = track.frame(da)
  var fb: Transform3D = track.frame(db)
  var globals = [track.position_at(da,-width/2)-fa.basis.y*.01,track.position_at(da,width/2)-fa.basis.y*.01,track.position_at(db,width/2)-fb.basis.y*.01,track.position_at(db,-width/2)-fb.basis.y*.01]
  var upper: Array[Vector3] = []
  var lower: Array[Vector3] = []
  for k in 4:
   upper.append(inverse*globals[k])
   var bottom: Vector3 = globals[k]-(fa.basis.y if k<2 else fb.basis.y)*thickness
   bottom.y=maxf(.1,bottom.y)
   lower.append(inverse*bottom)
  var up = inverse.basis*fa.basis.y
  var right = inverse.basis*fa.basis.x
  _quad(st,upper[0],upper[1],upper[2],upper[3],up)
  _quad(st,lower[0],lower[3],lower[2],lower[1],-up)
  _quad(st,upper[0],upper[3],lower[3],lower[0],-right)
  _quad(st,upper[1],lower[1],lower[2],upper[2],right)
  if i==0: _quad(st,upper[0],lower[0],lower[1],upper[1],inverse.basis*fa.basis.z)
  if i==segments-1: _quad(st,upper[3],upper[2],lower[2],lower[3],-(inverse.basis*fb.basis.z))
 var mesh = Geo.mesh(parent,st.commit(),Vector3.ZERO,color)
 mesh.name=name
 mesh.set_meta("world_material","kitchen_comic_album" if name=="ComicAlbum" else "kitchen_playing_card")
 mesh.set_meta("route_interval",logical_interval)
 mesh.set_meta("physical_route_interval",Vector2(start,end))

static func _patch(parent: Node3D,track: Node3D,start: float,end: float,x: float,width: float,color: Color) -> void:
 var st = SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var inverse: Transform3D = parent.transform.affine_inverse()
 var segments = int(ceil((end-start)/.35))
 for i in segments:
  var da = lerpf(start,end,float(i)/segments)
  var db = lerpf(start,end,float(i+1)/segments)
  var fa: Transform3D = track.frame(da)
  var fb: Transform3D = track.frame(db)
  var a: Vector3 = inverse*(track.position_at(da,x-width/2)-fa.basis.y*.007)
  var b: Vector3 = inverse*(track.position_at(da,x+width/2)-fa.basis.y*.007)
  var c: Vector3 = inverse*(track.position_at(db,x+width/2)-fb.basis.y*.007)
  var d: Vector3 = inverse*(track.position_at(db,x-width/2)-fb.basis.y*.007)
  _quad(st,a,b,c,d,inverse.basis*fa.basis.y)
 var mesh = Geo.mesh(parent,st.commit(),Vector3.ZERO,color)
 mesh.set_meta("world_material","kitchen_comic_panel")

static func _top_text(parent: Node3D,track: Node3D,progress: float,text: String,size: int,pixel_size: float,color: Color) -> void:
 var label = Geo.text(parent,text,Vector3.ZERO,size)
 var transform: Transform3D = track.frame(progress)
 transform.origin-=transform.basis.y*.003
 label.transform = parent.transform.affine_inverse()*transform
 label.rotate_object_local(Vector3.RIGHT,-PI/2)
 label.pixel_size=pixel_size
 label.modulate=color


static func _bounds(node: Node,inverse: Transform3D) -> Array[AABB]:
 var result: Array[AABB] = []
 if node is MeshInstance3D: result.append((inverse*node.global_transform)*node.get_aabb())
 for child in node.get_children(): result.append_array(_bounds(child,inverse))
 return result
