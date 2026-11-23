# Boaz en Ravi — analyse en materiaalverbetering

21 november 2026. Gebaseerd op de actuele Blender-/GLB-bestanden, de zes opgeslagen aanzichten per speler, de originele character sheets en de procedurele modelleerbron.

De originele ontwerpen geven een duidelijke richting: kleurrijke, jonge avonturiers met zachte vormen en overtuigende materialen. 'Echter' betekent hier geloofwaardige vorm, licht en materiaal binnen die tekenfilmstijl. Boaz blijft de blauwe ridder met rode cape; Ravi de groene explorer met hoofdband, veer en rugzak.

[Bekijk Boaz en Ravi na de materiaalverbetering](PERSONAGES-VERBETERD.jpg).

## Wat ik zie

| Onderdeel | Beoordeling | Beste vervolgstap |
| --- | --- | --- |
| Herkenbaarheid | Kleur, kostuum en accessoires maken de twee spelers goed herkenbaar. | Behoud de originele ontwerpen en onderlinge verschillen. |
| Verhoudingen | Vooral Ravi is langer en slanker dan op zijn ontwerpblad. Het silhouet mist de compacte, stevige kinderbouw. | Gerichte sculpt-/proportieronde met controle van de kartzitpositie. |
| Gezicht | De glimlach is vriendelijk. Veel zichtbaar oogwit, ronde oogopeningen, vrij dunne wenkbrauwen en de lange zichtbare nek geven nog een popachtig effect. | Bovenste oogleden en oogkassen vormen, mondhoeken/wangen beter laten samenwerken; toetsen vanuit front en profiel. |
| Haar | Het kapsel heeft volume, maar de grote gladde lokken ogen verzorgd en regelmatig. Het ontwerpblad toont meer warrige richtingen en kleinere tussenvormen. | Enkele asymmetrische silhouetplukken en kleinere secundaire lokken; geen duizenden losse haren. |
| Boaz' kostuum | Cape, leeuwen, pantser en laarzen zijn aanwezig. De tuniek oogt recht en glad; de cape heeft nog weinig grote, natuurlijke massa. | Later gericht plooien en constructie verfijnen. Niet steeds extra kleine geometrische ornamenten toevoegen. |
| Ravi's kostuum | Hoofdband, vest en rugzak zijn herkenbaar. Denim en mouwen zijn vrij glad en smal; de veer wordt vanaf de zijkant erg dun. | Later ruimere broek-/mouwvolumes, knievouwen en een iets volumineuzere veer. |
| Materialen | De oorspronkelijke atlas deelt vrijwel egale kleurvlakken tussen veel onderdelen. Huid mist plaatselijke warmte; stof, leer en rubber verschillen onvoldoende. | De eerste materiaalverbetering in deze ronde. |
| Presentatie | De oude beelden zijn korrelig en hebben sterk invullicht en een lichte vloer. Daardoor verdwijnen vorm en contrast. | Ruisarme renders met een donkerder vloer en rustiger invullicht. Voor/na gebruikt dezelfde nieuwe studio. |
| Beweging | De bestaande kartpose toont bij Ravi een dunne naad aan de gebogen denimknie. De geëxporteerde positie-morphs voor smile/happy/cheer/celebrate zijn identiek; dat geldt ook voor laugh/mouth_open en confident/cheeky/playful. | Eigen skinning-/expressieronde; importtests alleen bewijzen geen natuurlijke beweging. |
| Detailbudget | Boaz telt 65.518 triangles, Ravi 46.304. Beide zitten boven de indicatieve 12.000–25.000. | Optimalisatie/LOD vóór meer kleine geometrische details; meten in de daadwerkelijke game. |

## Uitgewerkt in deze ronde

- Een reproduceerbare 2048×2048 PBR-atlas met afzonderlijke kleur-, roughness- en metallicbehandeling voor stof, denim, leer, haar, goud en staal.
- Een eigen cilindrisch UV-vlak voor het hoofd, met de naad achterop. Zachte warmte op wangen, neus en rond de mond is nu plaatsgebonden in de echte texture.
- Eigen materiaalvlakken voor het oogwit en de bruine iris: oogwit hoeft niet meer de ruwheid van Ravi's shirt te delen. Een donkere irisrand en subtiele radiale kleurnuance blijven binnen de bruine oogkleur.
- Diepere kostuumkleuren, warmere huid en meer goudblonde toonverschillen. De oorspronkelijke PNG-kleuren bleken correct; er is geen bevestigde sRGB-conversiefout gerepareerd.
- Subtiele stofweving, diagonale denimstructuur, leernerf en variatie in metaalruwheid. De details zitten in de ingebedde PNG's en gebruiken gewone glTF metallic-roughness shading.
- Ruisarme CPU-Cycles-beelden met denoising en consistent licht. De galerijbeelden zijn echte Blender-renders van de gewijzigde modellen.

Alle permanente wijzigingen staan in `tools/build_characters.py` en `tools/character_materials.py`. De bestaande haar- en kledingmodules zijn behouden. De voor/na-beelden worden gemaakt door `tools/review_materials.py`.

Dit is een gerichte materiaalverbetering. Het hoofd heeft eigen UV-ruimte; overige onderdelen delen nog materiaalvlakken. Er is geen volledige unieke productie-unwrap, tangent-space normalmap, LOD of nieuwe gezichtsrig gemaakt. De cilindrische projectie richt zich op de zichtbare hoofdhuid; de verborgen poolkapjes bij kruin en nek vragen nog om nette afzonderlijke UV-eilanden bij die volledige unwrap. De historische stap 4 is daarmee niet volledig afgevinkt.

## Bestanden en vergelijking

| Speler | Nieuw model | Bewerkbare bron | Triangles |
| --- | --- | --- | ---: |
| Boaz | [boaz.glb](boaz/boaz.glb) | [boaz.blend](boaz/boaz.blend) | 65.518 |
| Ravi | [ravi.glb](ravi/ravi.glb) | [ravi.blend](ravi/ravi.blend) | 46.304 |

- [Boaz — actuele zes aanzichten](boaz/renders/overzicht.jpg)
- [Ravi — actuele zes aanzichten](ravi/renders/overzicht.jpg)
- [Boaz — voor/na driekwart](boaz/review-materials-2026-11-21/02-three-quarter-comparison.jpg)
- [Boaz — voor/na gezicht](boaz/review-materials-2026-11-21/05-face-comparison.jpg)
- [Ravi — voor/na driekwart](ravi/review-materials-2026-11-21/02-three-quarter-comparison.jpg)
- [Ravi — voor/na gezicht](ravi/review-materials-2026-11-21/05-face-comparison.jpg)

Voor/na toont telkens de bewaarde oude mesh en de nieuwe mesh met dezelfde camera, belichting en renderinstellingen. De vergelijking verandert dus niet heimelijk ook het licht. Per beeld staan bronhashes en de werkelijke instellingen in `review-materials-2026-11-21/render-provenance.json`.

Textuurcontrole:

| Speler | Ingebedde texturemaps | Werkelijke export-UV's |
| --- | --- | --- |
| Boaz | [Kleur + ORM](boaz/review-materials-2026-11-21/texture-maps.png) | [UV-layout](boaz/review-materials-2026-11-21/uv-layout.png) |
| Ravi | [Kleur + ORM](ravi/review-materials-2026-11-21/texture-maps.png) | [UV-layout](ravi/review-materials-2026-11-21/uv-layout.png) |

De originele actieve bestanden en alle toenmalige tools zijn bewaard onder [backups/2026-11-21-materials](backups/2026-11-21-materials/manifest.json). Oude reviewdossiers zijn behouden.

## Controle en praktische grenzen

Alle eindcontroles zijn uitgevoerd; het [compacte meetrapport](materiaalcontrole.json) bevat de actuele GLB-hashes.

| Controle | Boaz | Ravi |
| --- | --- | --- |
| GLB-structuur en ingebedde textures | Geslaagd | Geslaagd |
| Verse Blender-import, 20 morphs en zes clips bemonsterd | Geslaagd | Geslaagd |
| Godot 4.7.2 kandidaatimport en Kart_Sit | 75/75 | 75/75 |
| Bestaande geometrie/normals/gewichten/morphdelta's | Bit-exact behouden | Bit-exact behouden |
| Nieuwe actuele aanzichten, bronhashes gecontroleerd | 6/6 | 6/6 |

De controles worden per speler apart vastgelegd. Beide GLB's behouden alle geometrie, normals, botgewichten en morphdelta's **bit-exact**, met hetzelfde skelet en dezelfde bindmatrices. Ravi behoudt ook alle animatiedata exact. Bij Boaz is één subnormale float in de Run-chestrotatie maximaal 2,21×10⁻³⁹ anders door de nieuwere exporter; de scopecontrole registreert dat en slaagt binnen de vermelde tolerantie van 10⁻⁷.

De in de GLB ingebedde PNG's zijn voor beide spelers pixel voor pixel gelijk aan de opgeslagen 2048px-texturen; zie `review-materials-2026-11-21/texture-validation.json`. De [morphanalyse van Boaz](boaz/review-materials-2026-11-21/morph-analysis.json) en [Ravi](ravi/review-materials-2026-11-21/morph-analysis.json) registreert de identieke expressies en de werkelijke vertexbeweging per control. Dit is geen beoordeling van combinaties van meerdere controls.

De materiaalscopecontrole vergelijkt alle daadwerkelijk geëxporteerde driehoeken inclusief normals, botgewichten en alle morphdelta's, onafhankelijk van de veranderde UV's. Skelet en animatiedata worden ook vergeleken.

Zie per speler `glb-validation.json`, `blender-import-validation.json`, `review-materials-2026-11-21/scope-audit.json` en `review-materials-2026-11-21/godot-validation.json`. De generieke Blender- en GLB-validators voeren zelf geen Godot uit; hun veld `Godot_runtime: not tested` verwijst naar de grens van die afzonderlijke controle.

De echte Godot-test importeert het kandidaatbestand met GLTFDocument, decodeert de ingebedde texturen, controleert schaal/skelet/zes clips en speelt Kart_Sit af. Dit is een headless assetcontrole. Op verzoek van de gebruiker zijn de bestanden onder `game/assets/models/` daarna **wel bijgewerkt** en opnieuw geïmporteerd. De game gebruikt nu deze materiaalversies. De werkelijke geïmporteerde game-materialen zijn gecontroleerd op 2048px-resolutie en kleur-/ORM-pixels (60 controles, geen afwijkingen op de bemonsterde pixels). Voertuigen, coureurreacties, garage met de actuele catalogus, volgcamera en spelstart zijn getest. Er zijn zes echte Godot-beelden van garage en race opgeslagen. [Integratieverslag en spelbeelden](integration-materials-2026-11-21/README.md).

De oudere standaardgaragetest heeft nog twee vaste aantallen voor zes voertuigen; de huidige catalogus bevat zeven voertuigen. De afzonderlijke controle met de actuele catalogus slaagt. Er is geen nieuwe frameratemeting of volledige intersectietest uitgevoerd.

De twee 2048px RGBA-texturen vragen samen circa 32 MiB ongecomprimeerd per speler, circa 43 MiB inclusief volledige mipketens. De daadwerkelijke GPU-geheugendruk hangt van de Godot-importcompressie af. De grotere atlas maakt geen zwaardere geometrie; de triangleaantallen blijven aandacht vragen.

## Herhalen

Vanuit deze map, één Blenderproces tegelijk:

```bash
BORACER_FAST_EXIT=1 BORACER_BUILD_ONLY=1 /snap/blender/current/blender --background -noaudio --factory-startup --threads 4 --python tools/build_characters.py -- boaz
BORACER_FAST_EXIT=1 BORACER_SAMPLES=32 BORACER_REVIEW_VARIANTS=before,after BORACER_VIEWS=02,05 /snap/blender/current/blender --background -noaudio --factory-startup --threads 4 --python tools/review_materials.py -- boaz
python3 tools/validate_glb.py boaz/boaz.glb
python3 tools/check_material_scope.py boaz
python3 tools/check_character_godot.py boaz
```

Dezelfde opdrachten met `ravi` werken voor Ravi. De standaardbuild zonder BUILD_ONLY bouwt en rendert alle zes aanzichten. `BORACER_VIEWS` en `BORACER_REVIEW_VARIANTS` laten de reviewrender per beeld hervatten. De vastgelegde bronbackup is nodig voor dezelfde voor/na-vergelijking.
