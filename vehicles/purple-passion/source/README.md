# purple-passion — verbeterde reconstructie

Dieppaarse lak met gouden vijfpuntige sterren, gouden cockpit- en neusbanden, drie vinnen en een aparte antenne met emissieve bol.

Gebaseerd op het markdown ontwerpdocument, de `-technical.png` en de kleurreferentie in de bovenliggende map. De parametrische constructie bouwt voort op de verbeterde Toxic Turbo, met aangepaste verfkaarten, vinnen/fairing, zij-uitlaten en unieke onderdelen. De oorspronkelijke GLB en referenties blijven behouden.

## Bestanden

- `../purple-passion-improved.glb`: zelfstandige GLB, ingebedde PBR-lakkaarten en emissieve materialen.
- `../purple-passion-improved.blend`: bewerkbaar Blender-bestand met ingepakte verfkaarten.
- `../previews/overzicht.jpg`: negen controleaanzichten van de opnieuw geïmporteerde GLB, inclusief onderkant.
- `build-report.json`, `validation-report.json`, `blender-import-report.json`: meetwaarden en technische controles.
- `godot-import-report.json`: geslaagde headless Godot 4.7.2-import en scène-instantiatie met materiaal- en wielhiërarchiecontrole.

## Opnieuw bouwen

Vanuit de hoofdmap `boracer`, met Python 3, Pillow, NumPy en Blender 5.2:

```bash
python3 vehicles/tools/make_paint.py
/snap/blender/current/blender --factory-startup --background -t 6 --python vehicles/purple-passion/source/build_model.py
python3 vehicles/tools/check_glb.py purple-passion
/snap/blender/current/blender --factory-startup --background -t 5 --python vehicles/tools/render_vehicles.py -- purple-passion
```

`build_model.py` is de voertuiggebonden ingang; de gedeelde geometrie en export staan in `vehicles/tools/build_vehicle.py` en `export_asset.py`. `make_paint.py` maakt originele UV-lakkaarten zonder belichting uit de referentie in te bakken. `python3 vehicles/tools/make_overviews.py` maakt de overzichten nadat alle vijf voertuigen zijn gerenderd.

## Gebruik en interpretatie

Meters, +Y omhoog en neus -Z in glTF/Godot. Root op grondniveau; de twee achterwielen en het smalle centrale voorwiel hebben aparte pivots met lokale X als draai-as. Verlichting en achterste emissiekern zijn afzonderlijk aanspreekbaar. Geen bestuurder, cameraset, vloer of lampen uit de renders in de GLB.

De tekeningen zijn gestileerd en niet overal eenduidig. Eén klein centraal voorwiel en een vereenvoudigde gesloten bodemplaat zijn conservatieve interpretaties; er is geen extra achterste steunwiel toegevoegd. Rondingen, plaatsing van kleine bevestigingen en exacte grafische contouren zijn gereconstrueerde benaderingen. Geen meetkundig exacte kopie van de illustratie.

De controles bewijzen exportstructuur en herimport; rijgedrag, physics, botsingsvormen, wiel-/vlaganimatie, LODs en definitieve Godot-belichting zijn niet meegeleverd of getest als spel. Bloom moet in Godot worden ingesteld. Zie de rapporten voor de daadwerkelijk gemeten aantallen en afmetingen.
