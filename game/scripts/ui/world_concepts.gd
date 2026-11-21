extends RefCounted
## Original customer concept art for world selection, not engine overview captures.
## Source paths are relative to the repository root; PNG originals remain untouched.
## Atlas regions deliberately exclude sheet labels, legends and adjacent panels.
const CONCEPTS = {
 "sunset-park": {
  "asset": "res://assets/ui/sunset.png",
  "source": "tracks/sweer-impressie-baan.png",
  "region": Rect2(0, 0, 1672, 941),
  "detail": "Standalone coastal fairground illustration."
 },
 "neon-city": {
  "asset": "res://assets/ui/concepts/neon-reference.png",
  "source": "user-interface/game-ui-overzicht-referentieblad.png",
  "region": Rect2(592, 354, 149, 103),
  "detail": "Night-city thumbnail inside panel 2, world selection; no adjacent character panel or thumbnail caption."
 },
 "regenbogenrijk": {
  "asset": "res://assets/ui/regenbogenrijk.png",
  "source": "worlds/regenbogenrijk/regenbogenrijk.png",
  "region": Rect2(3, 105, 867, 304),
  "detail": "Upper-left hero illustration, below the logo and title."
 },
 "haarlem-1888": {
  "asset": "res://assets/ui/haarlem-1888.png",
  "source": "worlds/haarlem-1888/haarlem-1888.png",
  "region": Rect2(3, 105, 884, 327),
  "detail": "Upper-left canal-race hero, above the circuit overview."
 },
 "uithoorn-2056": {
  "asset": "res://assets/ui/uithoorn-2056.png",
  "source": "worlds/uithoorn-2056/uithoorn-2056.png",
  "region": Rect2(3, 105, 892, 330),
  "detail": "Upper-left riverside hero, below the logo and above the overview."
 },
 "keukentafel": {
  "asset": "res://assets/ui/keukentafel.png",
  "source": "worlds/keukentafel/keukentafel.png",
  "region": Rect2(3, 153, 1047, 304),
  "detail": "Desktop hero below the overlaid world-description panel, which ends around y145."
 }
}

static func texture_for(world_id: String) -> AtlasTexture:
 if not CONCEPTS.has(world_id):
  push_error("No original concept art mapped for world: " + world_id)
  return null
 var concept: Dictionary = CONCEPTS[world_id]
 var original: Texture2D = load(concept.asset)
 if original == null:
  push_error("Original world concept art is missing: " + concept.asset)
  return null
 var result = AtlasTexture.new()
 result.atlas = original
 result.region = concept.region
 result.filter_clip = true
 return result
