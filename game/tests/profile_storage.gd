extends SceneTree
const Profile = preload("res://scripts/profile.gd")
const Catalog = preload("res://scripts/catalog.gd")
var checks: int = 0
var failures: Array[String] = []
var save_path = "user://profile-storage-test.json"

func check(condition: bool, title: String) -> void:
 checks += 1
 if not condition:
  failures.append(title)
  push_error(title)

func write_data(data, path: String = "") -> void:
 var file = FileAccess.open(path if path != "" else save_path, FileAccess.WRITE)
 file.store_string(JSON.stringify(data))
 file.close()

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 for suffix in ["", ".tmp", ".bak"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
 var fresh = Profile.new(save_path)
 check(fresh.selected == Catalog.DEFAULT_VEHICLE and "raketfiets" in fresh.owned, "fresh profile starts on owned Raketfiets")
 write_data({"version":1, "coins":245, "owned":["retro", "golden-rocket-racer", "unknown"],
  "selected":2, "character":"ravi", "records":{"0":58.2, "2":49.1, "regenbogenrijk":48.7, "95":10},
  "settings":{"music":0.2, "sound":0.8, "difficulty":1, "shadows":false}})
 var profile = Profile.new(save_path)
 check(profile.coins == 245 and profile.selected == Catalog.DEFAULT_VEHICLE and profile.character == "ravi", "legacy wallet preserved and default migrated")
 check(profile.records.get("sunset-park") == 58.2 and profile.record_for(2) == 48.7, "legacy world indexes migrate and keep faster matching record")
 check(profile.records.size() == 2, "unknown record world ignored")
 check("raketfiets" in profile.owned and not "unknown" in profile.owned, "free finished kart granted and unknown ownership ignored")
 check(profile.settings.music == 0.2 and not profile.settings.shadows, "legacy settings preserved")
 check(profile.save_profile(), "migrated profile saves")
 var saved = JSON.parse_string(FileAccess.get_file_as_string(save_path))
 check(saved.version == 3 and saved.selected_vehicle == "raketfiets", "version3 saves migrated default id")
 check(not saved.records.has("0") and saved.records.has("sunset-park"), "version2 records use stable world ids")
 check(FileAccess.file_exists(save_path + ".bak"), "valid old profile backed up")
 var restored = Profile.new(save_path)
 check(restored.selected == Catalog.DEFAULT_VEHICLE and restored.coins == 245, "v3 reload keeps wallet and migrated selection")
 check(restored.buy_or_select(1) and restored.coins == 165, "paid purchase works")
 check(restored.buy_or_select(1) and restored.coins == 165, "repeat selection never recharges")
 var chosen = Profile.new(save_path)
 check(chosen.selected == 1 and chosen.coins == 165, "post-migration deliberate garage choice survives reload")
 write_data({"version":2, "coins":998, "owned":["toxic-turbo"], "selected_vehicle":"toxic-turbo", "records":{"haarlem-1888":77.2}})
 var v2 = Profile.new(save_path)
 check(v2.selected == Catalog.DEFAULT_VEHICLE and v2.coins == 998 and "toxic-turbo" in v2.owned and v2.record_for(3) == 77.2, "v2 migration preserves wallet purchases records")
 check(JSON.parse_string(FileAccess.get_file_as_string(save_path)).version == 3, "migration persisted without manual save")
 check(restored.record_race(5, 72.5, 60), "race record saves")
 check(restored.record_race(5, 80, 10) and restored.record_for(5) == 72.5, "slower race keeps personal best")
 # Broken write must never spend coins or discard an owned selection.
 var broken = Profile.new("user://missing-directory/profile.json")
 broken.coins = 400
 var old_owned = broken.owned.duplicate()
 check(not broken.buy_or_select(3), "failed disk write rejects purchase")
 check(broken.coins == 400 and broken.owned == old_owned and broken.selected == Catalog.DEFAULT_VEHICLE, "failed purchase rolls back entire wallet")
 check(not broken.record_race(0, 60, 99) and broken.coins == 400 and broken.records.is_empty(), "failed race write rolls back rewards and records")
 check(not broken.last_error.is_empty(), "storage failure is actionable")
 check(not restored.record_race(-1, 50, 10) and not restored.record_race(0, NAN, 10), "invalid race results rejected")
 # Corrupt current save recovers the last valid backup without touching it.
 var file = FileAccess.open(save_path, FileAccess.WRITE)
 file.store_string("{ interrupted write")
 file.close()
 var recovered = Profile.new(save_path)
 check(recovered.recovered_backup and recovered.coins > 0, "corrupt profile recovers valid backup")
 check(recovered.save_profile(), "recovered profile can be saved")
 # Unexpected JSON types are sanitized instead of crashing the startup scene.
 write_data({"coins":[], "owned":{}, "selected_vehicle":"not-a-model", "character":[],
  "records":{"0":{}, "neon-city":-2, "haarlem-1888":true},
  "settings":{"music":{}, "sound":3, "difficulty":[], "shadows":"false"}})
 var malformed = Profile.new(save_path)
 check(malformed.coins == 0 and malformed.selected == Catalog.DEFAULT_VEHICLE, "malformed fields fall back safely")
 check(malformed.records.is_empty() and malformed.settings.sound == 1, "malformed times ignored and volumes clamped")
 check(malformed.settings.shadows, "string does not silently turn off boolean setting")
 for suffix in ["", ".tmp", ".bak"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
 print("BORACER PROFILE STORAGE: %d checks, %d failures" % [checks, failures.size()])
 quit(0 if failures.is_empty() else 1)
