extends RefCounted
## Authored control polygons. Each route has its own rhythm; all remain single,
## closed circuits so guided racers, projectiles and the minimap share one path.
const SECTIONS = [
 ["Kermiskade", "Reuzenradbocht", "Suikerspinheuvel", "Eilandbrug", "Achtbaanvallei", "Zonsondergang"],
 ["Neonplein", "Hologramboulevard", "Lichttunnel", "Skylinebocht", "Dakroute", "Nachtpromenade"],
 ["Zonnepoort", "Wolkenslinger", "Regenboogtunnel", "Verborgen Weg", "Groene Hemeltuinen", "Gouden Afdaling", "Hemelbocht"],
 ["Grote Markt", "Gouden Straatjes", "Mechanische Grachten", "Molen De Adriaan", "Ketelfabriek", "Spaarnekade"],
 ["Dorpscentrum", "Amstelboulevard", "Uithoornse brug", "Thamerkerk", "Zonnetuinen", "Watertaxikade"],
 ["Postbocht", "Glazen Labyrint", "Kabelknoop", "Projectorpassage", "Megafooncurve", "Elektronicaslalom", "Groene Pet"]
]

static func points(index: int) -> Array[Vector3]:
 var outline: Array = []
 match index:
  0: # Broad seaside sweep, a tighter island cove and a long home straight.
   outline = [[0,-98], [57,-96], [102,-62], [116,-3], [99,57], [56,83], [5,66], [-40,94], [-94,71], [-112,14], [-82,-32], [-53,-83]]
  1: # Night-city blocks: two straights joined by an asymmetric rooftop detour.
   outline = [[0,-102], [62,-102], [110,-76], [112,-22], [86,16], [112,62], [77,101], [12,103], [-66,102], [-105,69], [-105,0], [-105,-67], [-64,-102]]
  2: # Wide cloud crescents with a substantial but gradual golden descent.
   outline = [[0,-110], [63,-107], [112,-68], [106,-9], [78,39], [91,94], [33,121], [-24,99], [-83,111], [-119,60], [-94,4], [-112,-52], [-62,-96]]
  3: # Compact old-town turns alternating with the open Spaarne waterfront.
   outline = [[0,-91], [52,-94], [91,-65], [85,-15], [112,29], [83,77], [34,90], [-19,66], [-74,85], [-106,41], [-89,-12], [-108,-57], [-59,-93]]
  4: # Legacy control polygon retained as the Stunt Edition length reference.
   # Classic track 4 uses uithoorn_ground_course.gd instead.
   outline = [[0,-116], [52,-115], [80,-79], [72,-23], [79,35], [100,80], [63,118], [12,111], [-39,123], [-81,86], [-68,29], [-74,-32], [-84,-85], [-53,-116]]
  5: # Flat tabletop slalom, kept comfortably inside the wooden table edges.
   outline = [[0,-76], [44,-79], [85,-67], [96,-32], [83,1], [95,36], [72,70], [30,79], [-9,70], [-51,81], [-89,58], [-94,23], [-82,-6], [-95,-36], [-69,-72], [-35,-72]]
 var result: Array[Vector3] = []
 for i in outline.size():
  var phase = float(i) / outline.size() * TAU
  var h = 0.12
  match index:
   0: h = 12 + sin(phase - 0.4) * 8 + sin(phase * 2) * 4
   1: h = 17 + sin(phase + 0.2) * 8 + sin(phase * 2 - 0.4) * 3
   2: h = 40 + sin(phase - 0.5) * 20 + sin(phase * 2) * 6
   3: h = 8 + sin(phase - 0.6) * 7 + sin(phase * 2 + 0.1) * 5
   4: h = 25 + sin(phase - 0.3) * 5 + sin(phase * 2) * 3 # +16m: race above residential roofs
  result.append(Vector3(outline[i][0], h, outline[i][1]))
 return result

static func section_name(index: int, fraction: float) -> String:
 var names: Array = SECTIONS[index]
 return names[mini(int(fposmod(fraction, 1.0) * names.size()), names.size() - 1)]
