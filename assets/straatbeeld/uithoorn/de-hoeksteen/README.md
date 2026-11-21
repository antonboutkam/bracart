# De Hoeksteen — BoRacer landmarkpakket

**Gebouw:** De Hoeksteen, Uithoorn — Gerrit Rietveld (ontwerp 1960, voltooid 1965).  
**Hoofdvolume:** **25 × 25 × 12,5 meter** (breedte × diepte × hoogte). De lagere aanbouw en uitstekende elementen vallen buiten die maatvoering. Bron: <https://www.architectuur.org/bouwwerk/983/De_Hoeksteen.html>.

## Inhoud

- `de_hoeksteen_01_front.png` — watergevel met herkenbare grote ramen en GERRIT-letters.
- `de_hoeksteen_02_back.png` — tegenoverliggende gevel, gereconstrueerd.
- `de_hoeksteen_03_left.png` — zijaanzicht, gereconstrueerd.
- `de_hoeksteen_04_right.png` — zijaanzicht met entree en trappenhuis, gereconstrueerd.
- `de_hoeksteen_05_top.png` — schematisch dak-/bovenaanzicht, 25 × 25 m hoofdblok.
- `de_hoeksteen_06_line.png` — lijntekening van de watergevel op transparante achtergrond.
- `de_hoeksteen_06_line.svg` — dezelfde lijntekening, vectorieel te wijzigen.
- `de_hoeksteen_07_wall_texture.png` — naadloos tegelbare geveltextuur.
- `de_hoeksteen_08_window_texture.png` — glasraamtextuur (niet seamless).
- `de_hoeksteen_09_door_texture.png` — dubbele-deurtextuur (niet seamless).
- `de_hoeksteen_10_base_texture.png` — naadloos tegelbare plinttextuur.
- `de_hoeksteen_reference_sheet.png` — originele AI-referentiesheet.
- `manifest.json` — afmetingen, labels, bron- en bestandsgegevens.

## Techniek

De vijf aanzichten en de lijntekening zijn 1024 × 1024 PNG (RGBA met transparante achtergrond); de vier textures zijn 512 × 512 PNG (RGB). Het hoofdbouwvolume voor Godot is `Vector3(25.0, 12.5, 25.0)` als 1 eenheid = 1 meter.

**Let op resolutie:** de beelden zijn uit de eerder gegenereerde referentiesheet gesneden en naar hun vaste outputformaat geresampled. Dat verhoogt de pixelafmetingen, maar voegt geen fotorealistische details toe. Het bovenaanzicht en de lijntekening zijn apart opgebouwd. Dit is een bruikbare 3D-modelleer- en stijlreferentie, geen exacte bouwkundige opmeting.

De `front`-afbeelding volgt de watergevel, zoals in de referentiesheet. De aanduidingen `front/back/left/right` zijn afgesproken modelrichtingen; niet noodzakelijk de geografische geveloriëntatie.
