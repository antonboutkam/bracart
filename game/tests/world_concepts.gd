extends SceneTree
## Verify the world chooser uses original art, bounded hero crops and all six actions.
const Interface = preload("res://scripts/interface.gd")
const Catalog = preload("res://scripts/catalog.gd")
const Concepts = preload("res://scripts/ui/world_concepts.gd")
var checks = 0
var failures: Array[String] = []

class PreviewProfile:
 extends RefCounted
 func record_for(index: int) -> float:
  return 12.34 if index == 3 else 0.0

class PreviewAudio:
 extends RefCounted
 func cue(_id: String) -> void:
  pass

class PreviewGame:
 extends Node
 var profile = PreviewProfile.new()
 var audio = PreviewAudio.new()
 var chosen_world: int = -1
 func start_race(index: int) -> void:
  chosen_world = index

func check(value: bool, title: String) -> void:
 checks += 1
 if not value:
  failures.append(title)
  push_error(title)

func descendants(node: Node, type: String) -> Array:
 var found: Array = []
 for child in node.get_children():
  if child.is_class(type):
   found.append(child)
  found.append_array(descendants(child, type))
 return found

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var game = PreviewGame.new()
 root.add_child(game)
 var ui = Interface.new()
 game.add_child(ui)
 ui.setup(game)
 ui.show_worlds()
 await process_frame
 await process_frame
 check(Concepts.CONCEPTS.size() == Catalog.WORLDS.size(), "Every playable world has its own original-art mapping")
 var pictures = descendants(ui.screen, "TextureRect")
 check(pictures.size() == 6, "World chooser shows six concept pictures")
 for i in mini(6, pictures.size()):
  var world: Dictionary = Catalog.WORLDS[i]
  var picture: TextureRect = pictures[i]
  check(picture.name == "WorldConcept_" + world.id, "Picture order matches world: " + world.id)
  check(picture.texture is AtlasTexture, "Selection uses a non-destructive atlas for " + world.id)
  if not picture.texture is AtlasTexture:
   continue
  var atlas: AtlasTexture = picture.texture
  check(atlas.atlas.resource_path == Concepts.CONCEPTS[world.id].asset, "Selection displays original source for " + world.id)
  check(not "/ui/worlds/" in atlas.atlas.resource_path, "Engine overview never overrides concept art for " + world.id)
  var full_image = Rect2(Vector2.ZERO, atlas.atlas.get_size())
  check(full_image.encloses(atlas.region) and atlas.region.has_area(), "Concept crop lies inside original image: " + world.id)
  if world.id != "sunset-park":
   check(atlas.region.get_area() < full_image.get_area() * 0.35, "Concept shows an illustration instead of the whole reference sheet: " + world.id)
  check(not Concepts.CONCEPTS[world.id].source.is_empty(), "Concept documents original source for " + world.id)
 var start_buttons: Array = []
 for candidate in descendants(ui.screen, "Button"):
  if candidate.text == "Start de race  →":
   start_buttons.append(candidate)
 check(start_buttons.size() == 6, "All six existing start actions remain available")
 for i in start_buttons.size():
  start_buttons[i].pressed.emit()
  check(game.chosen_world == i, "Concept card starts the correct circuit: " + Catalog.world_id(i))
 check(root.gui_get_focus_owner() is Button and root.gui_get_focus_owner().text == "← Terug", "World chooser retains keyboard/controller entry focus")
 var text_content = ""
 for candidate in descendants(ui.screen, "Label"):
  text_content += candidate.text + "\n"
 for world in Catalog.WORLDS:
  check(world.name in text_content, "Existing world name remains visible: " + world.name)
 check("PB 00:12.34" in text_content, "Existing personal record remains visible")
 check("Originele sfeerbeelden" in text_content, "Caption identifies the pictures as concept art")
 for dimensions in [Vector2i(1280, 800), Vector2i(1280, 720), Vector2i(800, 600), Vector2i(600, 900)]:
  root.content_scale_size = Vector2i.ZERO
  root.size = dimensions
  ui._resize_layout()
  var page_bounds: Rect2 = ui.layout_root.get_global_rect()
  for picture in pictures:
   check(page_bounds.encloses(picture.get_global_rect()), "Concept picture remains inside %s layout" % dimensions)
  for button in start_buttons:
   check(page_bounds.encloses(button.get_global_rect()), "Start action remains inside %s layout" % dimensions)
  check(page_bounds.position.x >= -0.1 and page_bounds.position.y >= -0.1 and page_bounds.end.x <= dimensions.x + 0.1 and page_bounds.end.y <= dimensions.y + 0.1, "World chooser fits %s viewport" % dimensions)
 game.queue_free()
 await process_frame
 print("BORACER WORLD CONCEPTS: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
