extends CanvasLayer
const Catalog = preload("res://scripts/catalog.gd")
const Map = preload("res://scripts/minimap.gd")
const VictoryPodium = preload("res://scripts/ui/victory_podium.gd")
const VehiclePreview = preload("res://scripts/ui/vehicle_preview.gd")
const GarageDrivers = preload("res://scripts/ui/garage_drivers.gd")
const TouchAction = preload("res://scripts/ui/touch_action.gd")
const RaceGauge = preload("res://scripts/ui/race_gauge.gd")
const WorldConcepts = preload("res://scripts/ui/world_concepts.gd")
const StuntRibbon = preload("res://scripts/ui/stunt_ribbon.gd")
const MenuTile = preload("res://scripts/ui/menu_tile.gd")
const HomeDuoPreview = preload("res://scripts/ui/home_duo_preview.gd")
const MonsterCatalog = preload("res://scripts/monster/catalog.gd")
const MonsterPreview = preload("res://scripts/monster/preview.gd")
var selected_monster: String = MonsterCatalog.DEFAULT_ID
var monster_preview
var monster_caption: Label
var monster_players: int = 2
var race_gauge
var rank_rows: Array = []
var layout_root: Control
var active_page: String = "home"
var previous_focus: Control
var current_lap_label: Label
var record_label: Label
var section_label: Label
var game
var screen: Control
var hud: Control
var overlay: Control
var position_label: Label
var speed_label: Label
var lap_label: Label
var time_label: Label
var coin_label: Label
var power_label: Label
var standings_label: Label
var effect_label: Label
var count_label: Label
var notice_label: Label
var boost_bar: ProgressBar
var minimap
var notice_time: float = 0
var heading_font: Font = preload("res://assets/fonts/heading.ttf")
var body_font = preload("res://assets/fonts/body.ttf")
const CYAN = Color("32d5ff")
const INK = Color("071a34")
const GOLD = Color("ffce63")
const MUTED = Color("aabbd0")
const WHITE = Color("f6f1e5")

func setup(owner_game) -> void:
 game = owner_game
 # Slant the bundled, licensed Quicksand heading rather than introducing an unlicensed race font.
 var race_font = FontVariation.new()
 race_font.base_font = heading_font
 race_font.variation_embolden = 0.6
 race_font.variation_transform = Transform2D(Vector2(1, 0), Vector2(-0.16, 1), Vector2.ZERO)
 heading_font = race_font
 var theme = Theme.new()
 theme.default_font = body_font
 theme.default_font_size = 17
 var base = Control.new()
 layout_root = base
 base.size = Vector2(1280, 800)
 base.theme = theme
 base.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(base)
 screen = Control.new()
 base.add_child(screen)
 screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
 hud = Control.new()
 base.add_child(hud)
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
 overlay = Control.new()
 base.add_child(overlay)
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 get_viewport().size_changed.connect(_resize_layout)
 _resize_layout()

func _resize_layout() -> void:
 var available = get_viewport().get_visible_rect().size
 var factor = minf(available.x / 1280.0, available.y / 800.0)
 layout_root.scale = Vector2.ONE * factor
 layout_root.position = (available - Vector2(1280, 800) * factor) * 0.5

func _input(event: InputEvent) -> void:
 # The hot-seat mode owns its pause overlay and input lifecycle.
 if game.mode == "monster":
  return
 if active_page == "splash" and screen.visible:
  var start = event.is_action_pressed("ui_accept")
  if event is InputEventJoypadButton:
   start = start or (event.pressed and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START])
  if start and not event.is_echo():
   var focused = get_viewport().gui_get_focus_owner()
   if focused is Button and screen.is_ancestor_of(focused):
    focused.pressed.emit()
   else:
    show_home()
   get_viewport().set_input_as_handled()
   return
 var back = event.is_action_pressed("ui_cancel")
 if event is InputEventJoypadButton:
  back = back or (event.pressed and event.button_index == JOY_BUTTON_B)
 if not back or event.is_echo():
  return
 if overlay.get_child_count() > 0:
  if is_instance_valid(game.race) and game.race.paused:
   resume()
  elif is_instance_valid(game.race) and game.race.done:
   return
  else:
   _dismiss_message()
 elif game.mode == "menu" and active_page not in ["home", "splash"]:
  if active_page == "vehicle":
   game.refresh_preview()
   show_garage()
  else:
   show_home()
 else:
  return
 get_viewport().set_input_as_handled()

func _dismiss_message() -> void:
 clear(overlay)
 if is_instance_valid(previous_focus) and previous_focus.is_inside_tree():
  previous_focus.grab_focus()


func clear(node: Node) -> void:
 if node == screen and is_instance_valid(game) and game.has_method("set_home_presentation"):
  game.set_home_presentation(false)
 for child in node.get_children():
  node.remove_child(child)
  child.queue_free()

func panel(parent: Node, rect: Rect2, color: Color = INK) -> PanelContainer:
 var box = PanelContainer.new()
 var style = StyleBoxFlat.new()
 style.bg_color = color
 style.corner_radius_top_left = 13
 style.corner_radius_top_right = 13
 style.corner_radius_bottom_left = 13
 style.corner_radius_bottom_right = 13
 style.border_width_left = 1
 style.border_width_top = 1
 style.border_width_right = 1
 style.border_width_bottom = 1
 style.border_color = Color("258ecb")
 style.shadow_color = Color(0.0, 0.15, 0.42, 0.42)
 style.shadow_size = 5
 style.shadow_offset = Vector2(0, 3)
 style.content_margin_left = 16
 style.content_margin_right = 16
 style.content_margin_top = 14
 style.content_margin_bottom = 14
 box.add_theme_stylebox_override("panel", style)
 parent.add_child(box)
 box.position = rect.position
 box.size = rect.size
 return box

func label(parent: Node, text: String, size_value: int = 20, color: Color = WHITE) -> Label:
 var node = Label.new()
 node.text = text
 node.add_theme_color_override("font_color", color)
 node.add_theme_font_size_override("font_size", size_value)
 if size_value >= 28:
  node.add_theme_font_override("font", heading_font)
  node.add_theme_color_override("font_outline_color", Color("020c20"))
  node.add_theme_constant_override("outline_size", 6)
  node.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
  node.add_theme_constant_override("shadow_offset_y", 3)
 parent.add_child(node)
 return node

func at(parent: Node, text: String, pos: Vector2, font_size: int = 20, color: Color = WHITE) -> Label:
 var item = label(parent, text, font_size, color)
 item.position = pos
 return item

func button(parent: Node, text: String, callback: Callable, primary: bool = false) -> Button:
 var node = Button.new()
 node.text = text
 node.custom_minimum_size = Vector2(120, 48)
 node.add_theme_font_override("font", heading_font)
 node.add_theme_font_size_override("font_size", 20)
 for state in ["normal", "hover", "pressed", "focus", "disabled"]:
  var style = StyleBoxFlat.new()
  style.bg_color = GOLD if primary else Color("10365b")
  if state == "hover" or state == "focus":
   style.bg_color = Color("ffe6a4") if primary else Color("365d7f")
  elif state == "pressed":
   style.bg_color = Color("dfa542") if primary else Color("192c48")
  elif state == "disabled":
   style.bg_color = Color("263044")
  style.set_corner_radius_all(9)
  style.set_border_width_all(2)
  style.border_color = Color("ffed98") if primary else Color("258ecb")
  style.shadow_color = Color("031126")
  style.shadow_size = 3
  style.shadow_offset = Vector2(0, 3)
  style.content_margin_left = 18
  style.content_margin_right = 18
  if state == "focus":
   style.set_border_width_all(2)
   style.border_color = Color("ffffff")
  node.add_theme_stylebox_override(state, style)
 node.add_theme_color_override("font_color", INK if primary else WHITE)
 node.add_theme_color_override("font_hover_color", INK if primary else WHITE)
 node.add_theme_color_override("font_pressed_color", INK if primary else WHITE)
 node.add_theme_color_override("font_focus_color", INK if primary else WHITE)
 node.add_theme_color_override("font_disabled_color", MUTED)
 parent.add_child(node)
 node.pressed.connect(func():
  game.audio.cue("click")
  callback.call())
 return node

func dim(parent: Node, alpha: float = 0.82) -> void:
 var background = ColorRect.new()
 background.color = Color(0.025, 0.06, 0.12, alpha)
 parent.add_child(background)
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _menu_shade() -> void:
 var gradient = Gradient.new()
 gradient.set_color(0, Color(0.015, 0.035, 0.10, 0.97))
 gradient.set_color(1, Color(0.015, 0.035, 0.10, 0.08))
 var texture = GradientTexture2D.new()
 texture.gradient = gradient
 var shade = TextureRect.new()
 shade.texture = texture
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 screen.add_child(shade)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _logo(rect: Rect2) -> void:
 var logo = TextureRect.new()
 logo.texture = load("res://assets/ui/logo.png")
 logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
 screen.add_child(logo)
 logo.position = rect.position
 logo.size = rect.size

func show_splash() -> void:
 active_page = "splash"
 clear(screen)
 clear(hud)
 clear(overlay)
 screen.visible = true
 hud.visible = false
 _menu_shade()
 _logo(Rect2(40, 40, 620, 340))
 at(screen, "KLEINE RACERS. GROOT AVONTUUR.", Vector2(86, 404), 19, GOLD)
 at(screen, "HOGER. SNELLER. SAMEN.", Vector2(84, 442), 32)
 var play = button(screen, "Speel  →", show_home, true)
 play.name = "SplashPlay"
 play.position = Vector2(86, 520)
 play.size = Vector2(350, 70)
 play.add_theme_font_size_override("font_size", 32)
 play.grab_focus()
 at(screen, "ENTER / A / START   •   of tik op Speel", Vector2(88, 613), 16, CYAN)
 var badge = panel(screen, Rect2(900, 60, 320, 93), Color(0.015, 0.05, 0.13, 0.86))
 var box = VBoxContainer.new()
 badge.add_child(box)
 label(box, "BOAZ & RAVI", 25, GOLD)
 label(box, "Eén start. Zes grote avonturen.", 16)
 var solo_tile = _home_tile("SplashSoloTile", "Monsterbreker · 1 speler", func(): game.choose_monster(1), load("res://assets/ui/monster-solo.png"), "race", Vector2(850, 236), true)
 var duo_tile = _home_tile("SplashDuoTile", "Monsterbreker · 2 spelers", func(): game.choose_monster(2), load("res://assets/ui/monster-duo.png"), "race", Vector2(850, 426), true)
 for tile in [solo_tile, duo_tile]:
  tile.artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 at(screen, "Kies een monster. Neem de grote sprong!", Vector2(790, 616), 16, GOLD)
 at(screen, "BoRacer   /   RAKETRACEN MET VRIENDEN", Vector2(88, 746), 13, MUTED)

func show_home() -> void:
 active_page = "home"
 clear(screen)
 clear(hud)
 clear(overlay)
 screen.visible = true
 hud.visible = false
 _menu_shade()
 _logo(Rect2(34, 10, 300, 160))
 at(screen, "KLEINE RACERS. GROOT AVONTUUR.", Vector2(380, 50), 16, GOLD)
 at(screen, "Klaar voor de start?", Vector2(378, 82), 32)
 # Two real seated riders share one transparent rotating studio, under the header.
 var duo = HomeDuoPreview.new()
 duo.name = "HomeDuoPreview"
 screen.add_child(duo)
 duo.position = Vector2(260, 180)
 duo.size = Vector2(760, 380)
 duo.setup()
 at(screen, "BOAZ & RAVI", Vector2(575, 151), 18, GOLD)
 var garage_art = AtlasTexture.new()
 garage_art.atlas = load("res://assets/ui/garage.png")
 # Only the original Boaz/Ravi portrait illustrations, excluding store controls/prices.
 garage_art.region = Rect2(258, 697, 270, 97)
 garage_art.filter_clip = true
 var tiles: Array = []
 tiles.append(_home_tile("HomeRaceTile", "Racen  →", show_worlds, WorldConcepts.texture_for(Catalog.world_id(game.world_index)), "race", Vector2(48, 574), true))
 if Catalog.TRACKS[game.track_index].variant == 2:
  _stunt_ribbon(tiles[0], Vector2(70, 12), Vector2(190, 32))
 tiles.append(_home_tile("HomeGarageTile", "Garage & coureurs", show_garage, garage_art, "garage", Vector2(344, 574)))
 tiles.append(_home_tile("HomeSettingsTile", "Instellingen", show_settings, WorldConcepts.texture_for("keukentafel"), "settings", Vector2(640, 574)))
 tiles.append(_home_tile("HomeExitTile", "Afsluiten", func(): game.get_tree().quit(), WorldConcepts.texture_for("regenbogenrijk"), "exit", Vector2(936, 574)))
 for i in tiles.size():
  var before: Button = tiles[posmod(i - 1, tiles.size())]
  var after: Button = tiles[(i + 1) % tiles.size()]
  tiles[i].focus_neighbor_left = tiles[i].get_path_to(before)
  tiles[i].focus_neighbor_right = tiles[i].get_path_to(after)
  tiles[i].focus_previous = tiles[i].get_path_to(before)
  tiles[i].focus_next = tiles[i].get_path_to(after)
 tiles[0].grab_focus()
 var monster_button = button(screen, "Monsterbreker · solo / samen  →", game.choose_monster, true)
 monster_button.name = "HomeMonsterButton"
 monster_button.position = Vector2(425, 510)
 monster_button.size = Vector2(430, 48)
 tiles[0].focus_neighbor_top = tiles[0].get_path_to(monster_button)
 monster_button.focus_neighbor_bottom = monster_button.get_path_to(tiles[0])
 at(screen, "WASD / pijltjes rijden  •  Shift boost  •  E power-up  •  Spatie springen  •  C achterom  •  Esc pauze", Vector2(48, 753), 13, MUTED)
 at(screen, "ENTER / A kiezen", Vector2(1083, 753), 13, CYAN)
 var badge = panel(screen, Rect2(858, 45, 370, 100), Color(0.015, 0.06, 0.15, 0.9))
 var box = VBoxContainer.new()
 badge.add_child(box)
 label(box, "JOUW GARAGE", 13, GOLD)
 label(box, "%s  /  %s" % [game.profile.character.capitalize(), Catalog.VEHICLES[game.profile.selected].name], 19)
 label(box, "%d muntjes" % game.profile.coins, 14, MUTED)
 if game.has_method("set_home_presentation"):
  game.set_home_presentation(true)

func show_monsters(players: int = 2) -> void:
 monster_players = clampi(players, 1, 2)
 active_page = "monsters"
 page("Kies je monster", "Solo: versla het monster in zo weinig mogelijk sprongen." if monster_players == 1 else "Samen: speel om de beurt. De meeste punten winnen bij 70% in het water.")
 var list = GridContainer.new()
 list.columns = 2
 list.add_theme_constant_override("h_separation", 12)
 list.add_theme_constant_override("v_separation", 12)
 screen.add_child(list)
 list.position = Vector2(48, 170)
 var entries: Array = MonsterCatalog.entries()
 for entry in entries:
  var id: String = entry.id
  var choose = button(list, entry.name, func(): _select_monster(id), id == selected_monster)
  choose.name = "Choose_" + id
  choose.custom_minimum_size = Vector2(250, 62)
 var preview_panel = panel(screen, Rect2(610, 170, 620, 450))
 monster_preview = MonsterPreview.new()
 monster_preview.name = "MonsterPreview"
 preview_panel.add_child(monster_preview)
 monster_caption = at(screen, "", Vector2(630, 640), 22, GOLD)
 var start = button(screen, "Start solo" if monster_players == 1 else "Start duel", func(): game.start_monster(selected_monster, monster_players), true)
 start.name = "StartMonster"
 start.position = Vector2(890, 698)
 start.size = Vector2(340, 60)
 var switch = button(screen, "Speel samen" if monster_players == 1 else "Speel alleen", func(): show_monsters(3 - monster_players))
 switch.position = Vector2(48, 698)
 at(screen, "Gas, remmen en sturen zoals bij het racen.\nIn de lucht kun je nog maar een beetje bijsturen.", Vector2(48, 626), 16, MUTED)
 _select_monster(selected_monster)
 start.grab_focus()

func _select_monster(id: String) -> void:
 if not monster_preview.setup(id):
  show_message("Dit monster kan niet worden geladen.")
  return
 selected_monster = id
 var info: Dictionary = MonsterCatalog.find(id)
 monster_caption.text = info.name
 for entry in MonsterCatalog.entries():
  var choose = screen.find_child("Choose_" + str(entry.id), true, false)
  if choose:
   choose.text = ("✓ " if entry.id == id else "") + entry.name
   for state in ["normal", "hover", "pressed", "focus"]:
    var style: StyleBoxFlat = choose.get_theme_stylebox(state).duplicate()
    style.bg_color = GOLD if entry.id == id else Color("10365b")
    style.border_color = Color("fff4c1") if entry.id == id else Color("258ecb")
    choose.add_theme_stylebox_override(state, style)
   for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
    choose.add_theme_color_override(state, INK if entry.id == id else WHITE)

func _home_tile(node_name: String, title: String, callback: Callable, artwork: Texture2D, kind: String, pos: Vector2, primary: bool = false) -> Button:
 var tile = MenuTile.new()
 tile.name = node_name
 tile.text = title
 tile.tooltip_text = title
 screen.add_child(tile)
 tile.position = pos
 tile.size = Vector2(278, 158)
 tile.setup(artwork, kind, heading_font, primary)
 tile.pressed.connect(func():
  game.audio.cue("click")
  callback.call())
 return tile

func page(title: String, subtitle: String) -> void:
 clear(screen)
 clear(overlay)
 dim(screen, 0.94)
 at(screen, "BoRacer  /  SPEEL MEE", Vector2(48, 30), 14, GOLD)
 at(screen, title, Vector2(48, 58), 38)
 at(screen, subtitle, Vector2(50, 111), 16, MUTED)
 var back = button(screen, "← Terug", show_home)
 back.position = Vector2(1060, 51)
 back.size.x = 170
 back.grab_focus()

var world_variant: int = 1

func show_worlds() -> void:
 active_page = "worlds"
 page("Kies je wereld", "Zes landschappen, twaalf circuits. Kies je editie en race.")
 var versions = HBoxContainer.new()
 screen.add_child(versions)
 versions.position = Vector2(770,91)
 button(versions,"✓ Versie 1" if world_variant==1 else "Versie 1",func(): world_variant=1; show_worlds())
 button(versions,"✓ Stunt Edition" if world_variant==2 else "Stunt Edition",func(): world_variant=2; show_worlds())
 var grid = GridContainer.new()
 screen.add_child(grid)
 grid.position = Vector2(48, 161)
 grid.columns = 3
 grid.add_theme_constant_override("h_separation", 18)
 grid.add_theme_constant_override("v_separation", 18)
 for i in Catalog.WORLDS.size():
  var index = i+(6 if world_variant==2 else 0)
  var world: Dictionary = Catalog.WORLDS[i]
  var card = panel(grid, Rect2(0, 0, 382, 272))
  card.custom_minimum_size = Vector2(382, 272)
  var box = VBoxContainer.new()
  box.add_theme_constant_override("separation", 7)
  card.add_child(box)
  var image = TextureRect.new()
  image.name = "WorldConcept_" + world.id
  image.texture = WorldConcepts.texture_for(world.id)
  image.custom_minimum_size = Vector2(340, 100)
  image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  box.add_child(image)
  if world_variant == 2:
   _stunt_ribbon(image, Vector2(140, 8), Vector2(200, 34))
  label(box, world.name, 23)
  var record = game.profile.record_for(index)
  label(box, world.tag + ("   •   PB " + time_string(record) if float(record) > 0 else ""), 12, Color(world.accent))
  label(box, "3× langer · looping · schansen" if world_variant==2 else world.subtitle, 14, MUTED)
  button(box, "Start de race  →", func(): game.start_race(index), true)
 at(screen, "Originele sfeerbeelden • kies jouw volgende avontuur", Vector2(50, 751), 13, MUTED)

func show_garage() -> void:
 active_page = "garage"
 page("Garage & coureurs", "Zes raketjes, twee coureurs. Kies jouw favoriet en spaar voor de rest.")
 at(screen, "%d MUNTJES" % game.profile.coins, Vector2(860, 67), 23, GOLD)
 var drivers := GarageDrivers.new()
 screen.add_child(drivers)
 drivers.position = Vector2(48,135)
 drivers.setup(game.profile.character)
 var selected_preview = VehiclePreview.new()
 selected_preview.name = "GarageSelectedVehicle"
 screen.add_child(selected_preview)
 selected_preview.setup(game.profile.selected, game.profile.character)
 selected_preview.position = Vector2(350, 164)
 at(screen, "Jouw voertuig: " + Catalog.VEHICLES[game.profile.selected].name, Vector2(350, 135), 18, GOLD)
 drivers.selected.connect(func(id: String):
  var old_character: String = game.profile.character
  game.profile.character = id
  if not game.profile.save_profile():
   game.profile.character = old_character
   show_message(game.profile.last_error)
   return
  game.audio.cue("click")
  game.refresh_preview()
  show_garage())
 var grid = GridContainer.new()
 screen.add_child(grid)
 grid.position = Vector2(48, 264)
 grid.columns = 3
 grid.add_theme_constant_override("h_separation", 18)
 grid.add_theme_constant_override("v_separation", 16)
 for i in Catalog.VEHICLES.size():
  var index = i
  var vehicle: Dictionary = Catalog.VEHICLES[i]
  var available: bool = i in Catalog.available_indices()
  var owned: bool = vehicle.id in game.profile.owned
  var card = panel(grid, Rect2(0, 0, 382, 230))
  card.custom_minimum_size = Vector2(382, 230)
  card.name = "GarageCard_"+vehicle.id
  var card_style: StyleBoxFlat = card.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
  card_style.content_margin_top = 9
  card_style.content_margin_bottom = 9
  card.add_theme_stylebox_override("panel",card_style)
  var box = VBoxContainer.new()
  box.add_theme_constant_override("separation", 3)
  card.add_child(box)
  var preview_card = VehiclePreview.new()
  box.add_child(preview_card)
  preview_card.name = "GaragePreview_"+vehicle.id
  preview_card.setup(index, game.profile.character)
  label(box, vehicle.name, 22, Color(vehicle.color))
  label(box, "%s  •  %s" % ["IN AANBOUW" if not available else ("IN BEZIT" if owned else str(vehicle.price) + " MUNTJES"), "GESELECTEERD" if game.profile.selected == i else "RAKETCOLLECTIE"], 12, MUTED)
  label(box, "%d km/u  •  Acceleratie %d  •  Sturen %d%%" % [vehicle.speed * 3.6, vehicle.accel, vehicle.handling * 100], 12, MUTED)
  var row = HBoxContainer.new()
  box.add_child(row)
  if game.profile.selected != i:
   var choose = button(row, "In aanbouw" if not available else ("Selecteren" if owned else "Kopen"), func():
    if game.profile.buy_or_select(index):
     game.refresh_preview()
     show_garage()
    else:
     show_message(game.profile.last_error if game.profile.last_error != "" else "Je hebt nog niet genoeg muntjes."), true)
   choose.name = "GarageChoose_"+vehicle.id
   choose.custom_minimum_size.y = 38
   choose.disabled = not available or (not owned and game.profile.coins < vehicle.price)
   choose.tooltip_text = ("Niet genoeg muntjes: %d nodig, %d beschikbaar." % [vehicle.price,game.profile.coins]) if choose.disabled and available else ("%d muntjes" % vehicle.price if not owned else choose.text)
   if choose.disabled:
    var disabled_style: StyleBoxFlat = choose.get_theme_stylebox("disabled").duplicate() as StyleBoxFlat
    disabled_style.border_color = Color("405268")
    disabled_style.set_border_width_all(1)
    disabled_style.shadow_size = 0
    choose.add_theme_stylebox_override("disabled",disabled_style)
   if available and not owned and game.profile.coins >= vehicle.price:
    _garage_purchase_style(choose)
  var inspect: Button = button(row, "Bekijk", func(): show_vehicle(index))
  inspect.custom_minimum_size.y = 38
  inspect.disabled = not available
 at(screen, "Racebeloning: 10–60 muntjes + verzamelde muntjes. De Raketfiets en Retro zijn gratis.", Vector2(50, 751), 13, MUTED)

func _garage_purchase_style(choose: Button) -> void:
 for state in ["normal","hover","pressed","focus"]:
  var style: StyleBoxFlat = choose.get_theme_stylebox(state).duplicate() as StyleBoxFlat
  style.bg_color = Color("53bd70") if state == "normal" else Color("83de93")
  style.border_color = Color("ddffe2") if state == "focus" else Color("91e9a6")
  choose.add_theme_stylebox_override(state,style)
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
  choose.add_theme_color_override(state,Color("092a1b"))

func show_vehicle(index: int) -> void:
 active_page = "vehicle"
 clear(screen)
 game.preview_vehicle(index)
 var backdrop = ColorRect.new()
 backdrop.color = Color("101b2b")
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 screen.add_child(backdrop)
 var hero = VehiclePreview.new()
 screen.add_child(hero)
 hero.position = Vector2(458, 112)
 hero.setup(index, game.profile.character, true)
 var box = panel(screen, Rect2(48, 112, 390, 310))
 var vbox = VBoxContainer.new()
 box.add_child(vbox)
 label(vbox, Catalog.VEHICLES[index].name, 32, GOLD)
 label(vbox, "In de spotlight", 16, MUTED)
 label(vbox, "Met " + game.profile.character.capitalize(), 16, MUTED)
 label(vbox, "Draai rond en bekijk elk detail.", 15, MUTED)
 var turn = HBoxContainer.new()
 vbox.add_child(turn)
 button(turn, "↶ Draaien", func(): hero.rotate_vehicle(-1))
 button(turn, "Draaien ↷", func(): hero.rotate_vehicle(1))
 button(vbox, "← Garage", func():
  game.refresh_preview()
  show_garage()).grab_focus()

func show_settings() -> void:
 active_page = "settings"
 page("Instellingen", "Maak het jezelf gemakkelijk. Je keuzes worden lokaal bewaard.")
 var p = panel(screen, Rect2(210, 146, 860, 626))
 var scroll = ScrollContainer.new()
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus = true
 p.add_child(scroll)
 var box = VBoxContainer.new()
 box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 box.add_theme_constant_override("separation", 7)
 scroll.add_child(box)
 for entry in [["Muziek", "music"], ["Geluidseffecten", "sound"]]:
  var key: String = entry[1]
  label(box, entry[0], 22)
  var slider = HSlider.new()
  slider.min_value = 0
  slider.max_value = 1
  slider.step = 0.05
  slider.value = game.profile.settings[key]
  slider.custom_minimum_size.y = 28
  box.add_child(slider)
  slider.value_changed.connect(func(value):
   game.profile.settings[key] = value
   game.audio.apply(game.profile.settings.music, game.profile.settings.sound)
   game.persist())
 label(box, "Tegenstanders", 22)
 var difficulty = OptionButton.new()
 for name_value in ["Rustig — eerste races", "Sportief — meer uitdaging", "Turbo — snelle tegenstanders"]:
  difficulty.add_item(name_value)
 difficulty.selected = game.profile.settings.difficulty
 difficulty.custom_minimum_size.y = 44
 box.add_child(difficulty)
 difficulty.item_selected.connect(func(index):
  game.profile.settings.difficulty = index
  game.persist())
 label(box, "Spelresolutie", 22)
 var resolution = OptionButton.new()
 resolution.name = "RenderResolution"
 for entry in [["Volledige schermresolutie", 0], ["1440p — minder zwaar", 1440], ["1080p — licht", 1080], ["720p — extra licht", 720]]:
  resolution.add_item(entry[0], entry[1])
 resolution.select(resolution.get_item_index(game.profile.settings.render_height))
 resolution.custom_minimum_size.y = 44
 box.add_child(resolution)
 resolution.item_selected.connect(func(index):
  game.profile.settings.render_height = resolution.get_item_id(index)
  game.apply_render_resolution()
  game.persist())
 label(box, "Lagere resolutie maakt het 3D-beeld minder scherp en lichter voor je GPU.\nTekst en knoppen blijven scherp. Werkt direct, ook in Monsterbreker.", 14, MUTED)
 var shadows = CheckButton.new()
 shadows.text = "Schaduwen (uitzetten voor lichtere computers)"
 shadows.button_pressed = game.profile.settings.shadows
 box.add_child(shadows)
 shadows.toggled.connect(func(enabled):
  game.profile.settings.shadows = enabled
  game.sun.shadow_enabled = enabled
  game.persist())
 for entry in [["Rustige camera (minder boostbeweging)", "camera_motion"], ["Automatisch gas geven", "auto_accelerate"], ["Aanraakknoppen op het scherm", "touch_controls"]]:
  var setting_key: String = entry[1]
  var toggle = CheckButton.new()
  toggle.text = entry[0]
  toggle.button_pressed = not game.profile.settings[setting_key] if setting_key == "camera_motion" else game.profile.settings[setting_key]
  box.add_child(toggle)
  toggle.toggled.connect(func(enabled):
   game.profile.settings[setting_key] = not enabled if setting_key == "camera_motion" else enabled
   game.persist())
 label(box, "WASD / pijltjes: rijden    Shift: boost    E: power-up\nSpatie: springen    R: terug naar het midden    Esc: pauze\nC / LB vasthouden: achterom kijken (vooruitbeeld in venster)\nController: stick / RT / LT / A / X / RB / Start", 15, MUTED)
 label(box, "Stuurhulp is actief. Resolutie en geluid veranderen direct.", 14, GOLD)

func show_hud() -> void:
 clear(screen)
 clear(overlay)
 clear(hud)
 screen.visible = false
 hud.visible = true
 rank_rows.clear()
 at(hud, "POSITIE", Vector2(36, 24), 14, CYAN)
 position_label = at(hud, "1 / 5", Vector2(32, 39), 72, GOLD)
 _outline(position_label, 9)
 if Catalog.TRACKS[game.track_index].variant == 2:
  _stunt_ribbon(hud, Vector2(764, 25), Vector2(196, 34))
 var lap_panel = panel(hud, Rect2(980, 25, 272, 190), Color(0.04, 0.09, 0.16, 0.88))
 var lap_box = VBoxContainer.new()
 lap_panel.add_child(lap_box)
 lap_label = label(lap_box, "RONDE  1 / 3", 27)
 time_label = label(lap_box, "00:00.00", 22, GOLD)
 current_lap_label = label(lap_box, "Ronde  00:00.00", 15)
 record_label = label(lap_box, "", 13, GOLD)
 label(lap_box, Catalog.track_name(game.track_index), 13 if Catalog.TRACKS[game.track_index].variant == 2 else 15, MUTED)
 var standings = Control.new()
 hud.add_child(standings)
 standings.position = Vector2(28, 154)
 standings.size = Vector2(218, 234)
 standings.mouse_filter = Control.MOUSE_FILTER_IGNORE
 # Retained as a compact text summary for tooling; visual standings have individual rows.
 standings_label = label(standings, "", 16)
 standings_label.visible = false
 for i in 5:
  var row = panel(standings, Rect2(0, i * 44, 218, 39), Color(0.025, 0.06, 0.14, 0.81))
  var row_style: StyleBoxFlat = row.get_theme_stylebox("panel").duplicate()
  row_style.content_margin_top = 5
  row_style.content_margin_bottom = 5
  row_style.content_margin_left = 11
  row.add_theme_stylebox_override("panel", row_style)
  var text = label(row, "", 19)
  rank_rows.append({"panel": row, "label": text})
 var map_panel = panel(hud, Rect2(1072, 232, 180, 180), Color(0.04, 0.09, 0.16, 0.72))
 minimap = Map.new()
 map_panel.add_child(minimap)
 minimap.custom_minimum_size = Vector2(146, 146)
 minimap.configure(game.race)
 race_gauge = RaceGauge.new()
 hud.add_child(race_gauge)
 race_gauge.position = Vector2(972, 492)
 race_gauge.size = Vector2(280, 280)
 race_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
 speed_label = at(race_gauge, "0", Vector2(39, 110), 60)
 speed_label.size.x = 202
 speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 _outline(speed_label, 5)
 var units = at(race_gauge, "KM/U", Vector2(70, 176), 20, CYAN)
 units.size.x = 140
 units.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var boost_caption = at(race_gauge, "BOOST  /  SHIFT · RB", Vector2(49, 218), 12, GOLD)
 boost_caption.size.x = 182
 boost_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 # Existing integration field retained, with the vector gauge drawing its fill.
 boost_bar = ProgressBar.new()
 boost_bar.visible = false
 race_gauge.add_child(boost_bar)
 var power_panel = panel(hud, Rect2(28, 625, 340, 147), Color(0.04, 0.09, 0.16, 0.88))
 var power_box = VBoxContainer.new()
 power_panel.add_child(power_box)
 coin_label = label(power_box, "0 MUNTJES", 25, GOLD)
 power_label = label(power_box, "E / X   •   Vind een verrassingsblok", 15)
 power_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 effect_label = label(power_box, "", 13, MUTED)
 effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 count_label = at(hud, "3", Vector2(540, 240), 96, GOLD)
 count_label.size = Vector2(200, 150)
 count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 _outline(count_label, 4)
 notice_label = at(hud, "", Vector2(280, 140), 24, GOLD)
 notice_label.size.x = 640
 notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 _outline(notice_label, 3)
 var pause_button = button(hud, "Ⅱ", show_pause)
 pause_button.position = Vector2(601, 25)
 pause_button.custom_minimum_size = Vector2(78, 42)
 pause_button.focus_mode = Control.FOCUS_NONE
 section_label = at(hud, "", Vector2(300, 90), 18, MUTED)
 section_label.size.x = 650
 section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 _outline(section_label, 3)
 at(hud, "WASD rijden   •   E power-up   •   Spatie springen   •   C / LB achterom   •   Esc pauze", Vector2(405, 753), 13, MUTED)
 if game.profile.settings.get("touch_controls", false) or DisplayServer.is_touchscreen_available() or "--touch" in OS.get_cmdline_user_args():
  race_gauge.scale = Vector2(0.55, 0.55)
  race_gauge.position = Vector2(1090, 616)
  _touch_controls()

func _outline(item: Label, thickness: int) -> void:
 item.add_theme_color_override("font_outline_color", INK)
 item.add_theme_constant_override("outline_size", thickness)

func _bar_style(color: Color) -> StyleBoxFlat:
 var style = StyleBoxFlat.new()
 style.bg_color = color
 style.set_corner_radius_all(5)
 return style

func _touch_controls() -> void:
 var entries = [["←", "steer_left"], ["→", "steer_right"], ["Rem", "brake"], ["Gas", "accelerate"], ["Boost", "boost"], ["Power", "power"], ["Spring", "jump"]]
 var positions = [Vector2(28, 550), Vector2(124, 550), Vector2(1068, 550), Vector2(1164, 550), Vector2(1164, 464), Vector2(28, 464), Vector2(124, 464)]
 for i in entries.size():
  var touch = TouchAction.new()
  hud.add_child(touch)
  touch.position = positions[i]
  touch.setup(entries[i][1], entries[i][0], heading_font)

func _enable_touch_controls(enabled: bool) -> void:
 for child in hud.get_children():
  if child is TouchAction:
   child.set_enabled(enabled)

func update_hud(delta: float) -> void:
 if not hud.visible or not is_instance_valid(game.race):
  return
 var race = game.race
 position_label.text = "%d / 5" % race.rank
 speed_label.text = "%d" % (race.player.speed * 3.6)
 race_gauge.set_readings(race.player.speed * 3.6, race.player.boost)
 lap_label.text = "RONDE  %d / 3" % mini(3, maxi(1, floori(race.player.progress / race.track.length) + 1))
 time_label.text = "Totaal  " + time_string(race.elapsed)
 current_lap_label.text = "Ronde  " + time_string(maxf(0, race.elapsed - race.lap_start))
 var record: float = game.profile.record_for(game.track_index)
 record_label.text = "Beste race  " + time_string(record) if record > 0 else "Beste race  —"
 section_label.text = race.track.section_name(race.player.progress) if race.track.has_method("section_name") else ""
 coin_label.text = "%d MUNTJES" % race.collected
 power_label.text = "E / X  •  " + (race.player.power if race.player.power != "" else "Vind een verrassingsblok")
 if race.player.cannon_time > 0:
  power_label.text = "E / X  •  Kanonnen — schieten!"
 var effects: Array[String] = []
 for entry in [["Schild", "shield_time"], ["Magneet", "magnet_time"], ["Kanonnen", "cannon_time"], ["Boost", "boost_time"]]:
  var remaining = float(race.player.get(entry[1]))
  if remaining > 0:
   effects.append("%s %ds" % [entry[0], ceili(remaining)])
 effect_label.text = " • ".join(effects)
 boost_bar.value = race.player.boost
 count_label.text = str(ceili(race.countdown)) if race.countdown > 0 else ("GO!" if race.countdown > -0.9 else "")
 var lines: Array[String] = []
 var sorted: Array = race.ranking()
 for i in sorted.size():
  var is_player: bool = sorted[i] == race.player
  lines.append("%d   %s%s" % [i + 1, sorted[i].racer_name, "  ◀" if is_player else ""])
  if i < rank_rows.size():
   var row: Dictionary = rank_rows[i]
   row.label.text = "%d   %s%s" % [i + 1, sorted[i].racer_name, "  ◀" if is_player else ""]
   row.label.add_theme_color_override("font_color", GOLD if is_player else WHITE)
   var style: StyleBoxFlat = row.panel.get_theme_stylebox("panel")
   style.bg_color = Color(0.015, 0.27, 0.65, 0.94) if is_player else Color(0.025, 0.06, 0.14, 0.81)
   style.border_color = CYAN if is_player else Color("1c4867")
   style.set_border_width_all(2 if is_player else 1)
 standings_label.text = "\n".join(lines)
 minimap.queue_redraw()
 notice_time = maxf(0, notice_time - delta)
 if notice_time <= 0:
  notice_label.text = ""

func notify(message: String) -> void:
 if is_instance_valid(notice_label):
  notice_label.text = message
  notice_time = 3.5

func show_pause() -> void:
 if not is_instance_valid(game.race) or game.race.done:
  return
 game.race.paused = true
 _enable_touch_controls(false)
 clear(overlay)
 dim(overlay, 0.65)
 var p = panel(overlay, Rect2(420, 210, 440, 365))
 var box = VBoxContainer.new()
 box.add_theme_constant_override("separation", 15)
 p.add_child(box)
 label(box, "Even uitblazen", 34)
 label(box, "De race wacht op je.", 16, MUTED)
 button(box, "Verder racen", resume, true).grab_focus()
 button(box, "Opnieuw starten", func(): game.start_race(game.track_index))
 button(box, "Naar het hoofdmenu", game.go_home)
 label(box, "Een afgebroken race levert geen muntjes op.", 13, MUTED)

func resume() -> void:
 clear(overlay)
 _enable_touch_controls(true)
 if is_instance_valid(game.race):
  game.race.paused = false

func show_results() -> void:
 _enable_touch_controls(false)
 clear(overlay)
 dim(overlay, 0.78)
 var victory: bool = game.race.rank == 1
 var p = panel(overlay, Rect2(48, 75, 1184, 650) if victory else Rect2(230, 104, 820, 594))
 var content: Node = p
 if victory:
  var columns := HBoxContainer.new()
  columns.add_theme_constant_override("separation",22)
  p.add_child(columns)
  var podium := VictoryPodium.new()
  columns.add_child(podium)
  podium.setup(game.race)
  content = columns
 var box = VBoxContainer.new()
 box.add_theme_constant_override("separation", 10)
 box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 content.add_child(box)
 var race = game.race
 label(box, "FINISH  /  " + Catalog.track_name(game.track_index), 15, GOLD)
 label(box, "Gewonnen!" if race.rank == 1 else "Goed geracet!", 48)
 label(box, "Positie %d van 5   •   %s" % [race.rank, time_string(race.elapsed)], 24)
 label(box, "+%d muntjes    /    %d verzameld + %d racebeloning" % [race.reward, race.collected, race.reward - race.collected], 20, GOLD)
 for i in race.lap_times.size():
  label(box, "Ronde %d     %s" % [i + 1, time_string(race.lap_times[i])], 16, MUTED)
 var names: Array[String] = []
 var ranking: Array = race.ranking()
 for i in mini(3, ranking.size()):
  names.append("%d. %s" % [i + 1, ranking[i].racer_name])
 var ranking_label = label(box, "PODIUM  /  " + ("\n" if victory else "    •    ").join(names), 18 if victory else 20)
 ranking_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 if race.payout_claimed:
  label(box, "Opgeslagen • je garage heeft nu %d muntjes." % game.profile.coins, 17, MUTED)
 else:
  var warning = label(box, "Opslaan is niet gelukt. Je racebeloning wacht nog.", 16, GOLD)
  warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  button(box, "Opnieuw opslaan", func():
   if race.claim_reward(game.profile, game.track_index):
    game.last_save_error = ""
   else:
    game.last_save_error = game.profile.last_error
   show_results(), true)
 var buttons = HBoxContainer.new()
 box.add_child(buttons)
 buttons.add_theme_constant_override("separation", 12)
 button(buttons, "Nog een race", func(): game.start_race(game.track_index), true).grab_focus()
 button(buttons, "Hoofdmenu", game.go_home)
 var note = label(box, "Tegenstanders die nog onderweg zijn, staan op hun huidige voortgang.", 13, MUTED)
 note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func show_message(message: String) -> void:
 previous_focus = get_viewport().gui_get_focus_owner()
 clear(overlay)
 dim(overlay, 0.4)
 var p = panel(overlay, Rect2(390, 280, 500, 170))
 var box = VBoxContainer.new()
 p.add_child(box)
 var message_label = label(box, message, 18)
 message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 button(box, "Oké", _dismiss_message).grab_focus()

static func time_string(seconds: float) -> String:
 return "%02d:%05.2f" % [int(seconds / 60), fmod(seconds, 60)]

func _stunt_ribbon(parent: Node, pos: Vector2, dimensions: Vector2) -> Control:
 var ribbon = StuntRibbon.new()
 ribbon.name = "StuntEditionRibbon"
 parent.add_child(ribbon)
 ribbon.position = pos
 ribbon.size = dimensions
 ribbon.setup(heading_font)
 return ribbon
