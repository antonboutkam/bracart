# Boaz — stap 2: sculpturaal haar

De nieuwe haargeometrie vervangt de oude regelmatige cirkelrijen met buisvormige lokken. Het betreft de werkelijke `.blend` en `.glb`, reproduceerbaar via `persons/tools/build_characters.py -- boaz` en de gedeelde module `character_hair.py`.

## Haarverandering

- Eén gesloten, ongelijkmatig gevormde ondermassa voorkomt kale gaten.
- 25 bewust ontworpen brede, gebogen en spits toelopende plukken met verschillende breedtes, richtingen en overlappingen.
- Asymmetrische kruin en pony; aparte zij-, oor- en nekclusters, met ook verzorgde achterzijde.
- Bestaande goudblonde tinten, palette-UV's en head-bone-gewichten behouden.
- Boaz krijgt een dominante schuin vallende pony.
- Het exacte hoogteanker van het oorspronkelijke haar blijft 1,125 in de modelleerruimte; schaalnormalisatie verandert de anatomie niet.

## Voor en na

De afbeeldingen tonen echte Blender-renders. Volledige aanzichten gebruiken dezelfde standaardcamera, verlichting, resolutie en samples. De gezichtscrops zijn voor beide opgeslagen modellen opnieuw met exact dezelfde camera gerenderd.

- [Vooraanzicht](review-step2/01-front-comparison.jpg)
- [Driekwart](review-step2/02-three-quarter-comparison.jpg)
- [Zijaanzicht](review-step2/03-side-comparison.jpg)
- [Achteraanzicht](review-step2/04-back-comparison.jpg)
- [Gezicht](review-step2/05-face-comparison.jpg)
- [Kartzitpose](review-step2/06-kart-pose-comparison.jpg)
- [Werkelijke Godot-weergave](review-step2/godot/)

## Geometrie en controles

Het totale karakter gaat van **41.782 naar 40.524 triangles**: **1.258 minder**. Het haar zelf bevat 5.990 triangles vóór de gezamenlijke weld/export. Het complete model blijft boven de richtwaarde van 12.000–25.000 triangles; een lagere LOD is niet onderdeel van deze stap.

- [Fresh Blender-import](blender-import-validation.json) geslaagd: één karaktermesh en armature, 20 morph targets; zes animaties op drie frames per clip bemonsterd op eindige coördinaten.
- GLB-structuurcontrole geslaagd: 51 joints, zes animatieclips, twee embedded textures, circa 1,15 m hoogte.
- De onafhankelijke [scope-audit](review-step2/scope-audit.json) bevestigt exact behoud van alle niet-haargeometrie, normals, UV's, vertex weights en morphs, alsmede rig, animaties en textures ten opzichte van stap 1.
- Echte Godot-import en native rendercontrole: **75/75 checks geslaagd**, zie [Godot-rapport](godot-step2-validation.json). Voor-, achter-, volledig en kartzitbeeld zijn bekeken.

## Scope en grenzen

Stap 3, 4 en 5 zijn nog niet uitgevoerd. Outfitgeometrie, UV/PBR-upgrade en animatiecorrecties blijven volgende afzonderlijke stappen. De bestaande renderopstelling heeft 16 samples zonder denoising, waardoor er korrel blijft. Het haar is duidelijk minder repetitief maar nog vrij rond en verzorgd; het is een procedurele interpretatie van de character sheet, geen exacte sculpt. De import- en steekproefcontroles bewijzen geen volledig clipvrije animaties.

De hoofdinstantie heeft deze gecontroleerde stap-2-export ook in de game geïntegreerd. De stap-1-build blijft afzonderlijk bewaard; visuele goedkeuring geldt als grens voor stap 3.
