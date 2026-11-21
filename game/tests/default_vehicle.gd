extends SceneTree
const Catalog = preload("res://scripts/catalog.gd")
const Track = preload("res://scripts/track.gd")
const Race = preload("res://scripts/race.gd")
var checks := 0
var failures := 0
func check(value: bool, label: String) -> void:
 checks += 1
 if not value:
  push_error(label)
  failures += 1
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 check(Catalog.VEHICLES[Catalog.DEFAULT_VEHICLE].id == "raketfiets", "Shared player default is Raketfiets")
 var available: Array = Catalog.available_indices()
 check(available.size() >= 5, "Current asset manifest supports a unique five-vehicle field")
 var track := Track.new()
 root.add_child(track)
 track.build(0)
 var default_field: Array = []
 for selection in [Catalog.DEFAULT_VEHICLE, 1, -1, Catalog.DEFAULT_VEHICLE]:
  var race := Race.new()
  root.add_child(race)
  race.setup(track, selection, "ravi", 0)
  var expected: int = selection if selection in available else Catalog.DEFAULT_VEHICLE
  check(race.player.vehicle_index == expected, "Player default, deliberate choice or invalid fallback respected")
  check(race.racers.size() == 5, "Real setup creates five racers")
  var used: Array = [race.player.vehicle_index]
  var field: Array = [race.player.vehicle_index]
  for index in range(1, race.racers.size()):
   var kart = race.racers[index]
   check(kart.ai and kart.vehicle_index in available, "AI uses a playable catalog vehicle")
   check(kart.vehicle_index != expected, "AI does not duplicate the player vehicle")
   check(kart.vehicle_index not in used, "Every AI has its own distinct vehicle")
   used.append(kart.vehicle_index)
   field.append(kart.vehicle_index)
  if selection == Catalog.DEFAULT_VEHICLE:
   if default_field.is_empty():
    default_field = field
   else:
    check(field == default_field, "Repeated setup assigns deterministic vehicles")
  if selection == -1:
   check(field == default_field, "Invalid player selection produces the same safe default field")
  race.queue_free()
  await process_frame
 track.queue_free()
 await process_frame
 print("BORACER DEFAULT VEHICLE: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
