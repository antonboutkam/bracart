extends TextureRect
## Isolated, slowly rotating race-track studio; suspended whenever hidden.
const GarageStudio = preload("res://scripts/ui/garage_studio.gd")
const ROTATION_SPEED = 0.15
var viewport: SubViewport
var studio: Node3D

func setup(index: int, character_id: String, hero: bool = false) -> void:
 if is_instance_valid(viewport): return
 custom_minimum_size = Vector2(760,560) if hero else Vector2(338,82)
 expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 viewport = SubViewport.new()
 viewport.size = Vector2i(960,700) if hero else Vector2i(676,184)
 viewport.own_world_3d = true
 viewport.transparent_bg = false
 viewport.msaa_3d = Viewport.MSAA_4X
 add_child(viewport)
 studio = GarageStudio.new()
 texture = viewport.get_texture()
 viewport.add_child(studio)
 studio.setup(index,character_id,hero)
 visibility_changed.connect(_sync_visibility)
 _sync_visibility()

func _sync_visibility() -> void:
 var active: bool = is_visible_in_tree()
 set_process(active)
 if is_instance_valid(viewport):
  viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED

func _process(delta: float) -> void:
 advance(delta)

func advance(delta: float) -> void:
 if is_visible_in_tree() and is_instance_valid(studio) and delta > 0 and is_finite(delta):
  studio.kart.rotation.y = fposmod(studio.kart.rotation.y + minf(delta,0.1)*ROTATION_SPEED,TAU)

func rotate_vehicle(direction: int) -> void:
 if is_instance_valid(studio):
  studio.kart.rotation.y += direction*PI/6
