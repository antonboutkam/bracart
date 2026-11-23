# Boaz en Ravi in het spel

21 november 2026. De twee verbeterde personages zijn geïntegreerd in de lokale Godot-game. Herstart een al geopende game om nieuwe instanties van de modellen te laden.

Bijgewerkt: `game/assets/models/boaz.glb`, `game/assets/models/ravi.glb` en uitsluitend hun eigen regels in `game/assets/manifest.json`. Godot heeft de bijbehorende uitgepakte kleur-/ORM-PNG's en importcache opnieuw gegenereerd. De geregistreerde bronnen zijn bevroren kopieën onder `persons/<naam>/review-materials-2026-11-21/after/`.

De volledige vorige gamekopieën en het toenmalige manifest staan in [previous-game-assets](previous-game-assets/). Bron- en doelhashes staan in [receipt.json](receipt.json). De nieuwe geometry, het skelet en de zes clips zijn dezelfde als in de eerder gecontroleerde materiaalversie.

## Echte spelbeelden

Deze beelden komen rechtstreeks uit Godot met de geïmporteerde game-assets, de bestaande garage en de echte spelerinstantie in de race. Hiervoor is een tijdelijk spelprofiel gebruikt. Het normale spelersprofiel is niet gewijzigd.

| Speler | Garage | Racecamera | Van dichtbij in de race |
| --- | --- | --- | --- |
| Boaz | [Garage](boaz-garage.png) | [Race](boaz-race.png) | [Coureur](boaz-race-close.png) |
| Ravi | [Garage](ravi-garage.png) | [Race](ravi-race.png) | [Coureur](ravi-race-close.png) |

[Captureherkomst en hashes](capture-results.json). De renderlog meldt X11, OpenGL ES 3.2 en de NVIDIA GeForce GT 710: dit zijn echte gamebeelden. Het zijn geen Blenderbeelden of nagebootste screenshots. De capture eindigt met exitcode 0. Godot meldt bij afsluiten twee kleine gelekte GL-texturen van 87.380 bytes in [capture.log](capture.log); dit is niet opgelost in deze modellenintegratie.

## Uitgevoerde controles

| Controle | Resultaat |
| --- | --- |
| Godot herimport | Geslaagd |
| Werkelijke gecachete game-PackedScenes/materialen | 60 controles, 0 fouten |
| Voertuigen en zit-/stuur-/sprong-/finishanimaties | 1.036 controles, 0 fouten |
| Coureurreacties, knipoog, turbo en vaste heupen/handen | 388 controles, 0 fouten |
| Garage met actuele catalogus | 70 controles, 0 fouten |
| Volgcamera | 1.464 controles, 0 fouten |
| Spelstart en algemene smoke-test | 167 controles, 0 fouten |
| Native gamebeelden | 6 opgeslagen en visueel gecontroleerd |

De werkelijke geïmporteerde albedo-, roughness- en metallictextures zijn allemaal 2048×2048. Hun bemonsterde pixels komen exact overeen met de nieuwe PNG-bronnen: maximale RGB-afwijking 0. Dit controleert dat de game geen oude 1024px-cache gebruikt. Rapport: [game-material-validation.json](game-material-validation.json).

De originele `game/tests/garage_presentation.gd` meldt daarnaast **2 fouten in 66 controles**, omdat hij twee keer vast zeven previews verwacht: zes voertuigen plus één selectiepreview. De huidige catalogus heeft zeven voertuigen, dus acht previews. Deze bestaande test is niet gewijzigd. De afzonderlijke [garage_current_catalog.gd](garage_current_catalog.gd) voert dezelfde controles uit met het actuele catalogusaantal en test ook het extra voertuig; deze slaagt 70/70. Beide uitkomsten blijven zichtbaar in [check-results.json](check-results.json), [oorspronkelijk log](garage_presentation.log) en [actueel log](garage_current_catalog.log).

Dit bewijst lokale integratie, laden, materialen, de geteste animaties en de getoonde beelden. Er is geen frameratebenchmark, volledige clip-/intersectiereview, commit, push of externe release uitgevoerd. Andere gelijktijdige wijzigingen aan voertuigen, monsters en gamecode vallen buiten deze personage-integratie.
