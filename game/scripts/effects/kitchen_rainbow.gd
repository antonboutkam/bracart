extends Node3D
## Player-only PVC effect. All animation uses the track-owned, pausable clock.
var course_track: Node3D
var feature: Dictionary
var material: ShaderMaterial
var elapsed: float = 0
var opacity: float = 0
var target: float = 0
var inside: bool = false

func setup(track: Node3D, zone: Dictionary) -> void:
 name = "KitchenRainbow"
 course_track = track
 feature = zone
 var shader := Shader.new()
 shader.code = """shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
uniform float phase = 0.0;
uniform float strength = 0.0;
void fragment(){
 vec3 color=0.55+0.45*cos(6.2831853*(UV.x-phase+vec3(0.0,0.333333,0.666667)));
 ALBEDO=color; EMISSION=color*0.3;
 ALPHA=strength*0.24;
}"""
 material = ShaderMaterial.new()
 material.shader = shader
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 surface.set_material(material)
 for ring in 12:
  for slice in 48:
   for corner in [0,2,1,0,3,2]:
    var longitudinal: float = (ring+(1 if corner in [1,2] else 0))/12.0
    var angular: float = (slice+(1 if corner in [2,3] else 0))/48.0
    var f: Transform3D = zone.frame
    var axis_offset: float = float(zone.axis_height)-f.origin.y
    var radius: float = float(zone.inner_radius)-0.6
    var center: Vector3 = f.origin-f.basis.z*(longitudinal-0.5)*float(zone.length)+f.basis.y*axis_offset
    var angle: float = angular*TAU
    surface.set_uv(Vector2(angular,longitudinal))
    surface.add_vertex(center+(f.basis.x*cos(angle)+f.basis.y*sin(angle))*radius)
 surface.generate_normals()
 var tube := MeshInstance3D.new()
 tube.name = "SoftRotatingRainbowTunnel"
 tube.mesh = surface.commit()
 tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(tube)
 visible = false
 set_meta("player_only",true)
 set_meta("zone_start",zone.start)
 set_meta("zone_end",zone.end)

func update_player(progress: float, active: bool = true) -> void:
 var d: float = fposmod(progress,course_track.length)
 inside = active and d >= feature.start and d <= feature.end
 target = 1 if inside else 0
 set_meta("player_inside",inside)

func _process(delta: float) -> void:
 advance(delta)

func advance(delta: float) -> void:
 if delta <= 0 or not is_finite(delta): return
 elapsed += delta
 opacity = move_toward(opacity,target,delta*2.0)
 material.set_shader_parameter("phase",fmod(elapsed*0.085,1.0))
 material.set_shader_parameter("strength",opacity)
 visible = opacity > 0.001
