# Lokale prestatie- en integratiecontrole

Gemeten op 17 oktober 2026 met Godot 4.7.2, Linux, NVIDIA GeForce GTX 1050 en driver 580.178.04. De game draaide echt in de native **GL Compatibility** renderer op 1280 × 800, met schaduwen, vijf racers, coureurs, HUD en minimap. VSync stond uit en er was geen FPS-limiet. Muziek en geluid waren gedempt.

## Rendersteekproef — derde iteratie

Deze meting bevat de vernieuwde wereldachtergronden, echte scenerytextures en de destijds geïntegreerde voertuigen/personages. De later uitgevoerde anatomie- en haarverbeteringen voor Boaz en Ravi zijn niet opnieuw gebenchmarkt; de tabel is dus geen nieuwe prestatiemeting van die personage-update. De voorgaande meting blijft bewaard in `validation/performance-v2.json`; de huidige gegevens staan in `validation/performance.json`. De zes PNG-beelden ernaast zijn uit de echte race vastgelegd.

Per wereld zijn 45 opwarmframes en 150 gemeten frames gebruikt. De normale Godot-physics stuurde de race en AI aan. Na 50 en 100 meetframes is het racersgroepje naar het volgende derde van de route verplaatst en de camera opnieuw geplaatst; vier tussenframes zijn buiten de meting gehouden. Daardoor bevat de meting drie lokale spelbeelden per wereld. De zes beschikbare spelersvoertuigen zijn over de zes werelden verdeeld.

Dit is een korte lokale steekproef met kunstmatig gekozen cameragebieden. Het is geen volledige racebenchmark, gegarandeerde minimum-FPS, langdurige geheugentest of bewijs voor andere computers. Shadercompilatie, desktopactiviteit en eerste bezoeken aan nieuwe gebieden kunnen uitschieters veroorzaken. De definitieve run is uitgevoerd zonder gelijktijdige Blender-render of testsuite. Een eerdere meting tijdens die belasting is verworpen.

| Wereld | Gemiddeld ms/frame | P95 ms/frame | Maximum ms/frame | Sceneopbouw ms | Piek draw calls | Piek miljoen primitives |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| sunset-park | 7.0 | 10.4 | 12.3 | 712 | 2934 | 1.00 |
| neon-city | 10.3 | 18.7 | 29.8 | 619 | 2991 | 1.24 |
| regenbogenrijk | 9.4 | 13.6 | 19.6 | 668 | 2902 | 1.29 |
| haarlem-1888 | 11.7 | 19.6 | 23.5 | 723 | 3377 | 1.22 |
| uithoorn-2056 | 13.0 | 21.3 | 28.4 | 794 | 3782 | 1.29 |
| keukentafel | 8.9 | 18.4 | 25.9 | 672 | 2736 | 1.13 |

De gemiddelde framesnelheid bedroeg ongeveer **77–143 FPS** in deze steekproef. P95 is de frametijd waar 95% van de gemeten frames onder bleef; die waarde maakt haperingen beter zichtbaar dan alleen het gemiddelde.

De scèneopbouw van circa **0,6–0,8 seconde** gebeurde synchroon en valt buiten de rendersteekproef. Het voorbereiden van werelden en modellen blijft een geschikte vervolgstap voor kortere overgangen.

Godot rapporteerde tijdens de samples ongeveer **72–96 MB static memory** en **215–266 MB video memory**. Dit zijn enginecounters, geen totale proces-RAM- of GPU-metingen. `physics_process_mean_ms` is een bemonsterde engine-monitorwaarde die ook opstartwerk kan weerspiegelen; die is niet geschikt als zuivere kostprijs per racestap.

## Afwegingen bij wereldmaterialen

`worlds/world_art.gd` projecteert naadloze hout-, baksteen-, dakpan-, gras-, steen-, metaal-, papier- en zonneceltextures op echte 3D-geometrie. Wereldprojectie voorkomt uitgerekte UV's bij verschillende objectgroottes. Mipmaps en anisotrope filtering beperken flikkering in de verte. De aanvullende 256 × 256 tiles en bijpassende normalmaps worden reproduceerbaar gemaakt met `tools/generate_world_textures.py`; de twee grotere hout- en baksteentiles zijn AI-rasterafbeeldingen. Materialen worden gedeeld en raamherhalingen gebruiken MultiMesh. Deze aanpak kost extra texture-samples tegenover effen kleuren; de gemeten framerates hierboven omvatten die kosten.

Wolken en stoom blijven effen en mat; glas, emissieve accenten, kunststoffen en schermen behouden eigen materiaaleigenschappen. Huizen hebben expliciete gevel-, dak- en kozijnmaterialen. De keuken heeft een getextureerd tafelblad, aparte vloer, kastfronten, aanrecht, achterwand, raam en stoelen. Drie horizonlagen en lichte mist geven buitenwerelden diepte. Decor in de verte werpt geen schaduw waar dat voor het racebeeld geen bruikbaar verschil maakt. Baanvorm, botsingen en rijgedrag zijn niet gewijzigd.

## Integratie en herstarten

`tests/integration_audit.gd` voerde 98 controles uit met echte Main-, Race-, Profile-, Track- en Kart-objecten:

- Zes volledige races met drie rondes, echte modellen en een gemigreerd prototypeprofiel.
- Racetijden, opgetelde rondetijden, persoonlijke records, eenmalige uitbetaling en herladen van de opgeslagen resultaten.
- Projectieltreffers en botsingen over de start-/finishnaad van een echt circuit.
- Een daadwerkelijke schrijffout bij de finish, terugdraaien van de portemonnee en daarna eenmalig alsnog opslaan.
- Acht complete race/hoofdmenuwisselingen, inclusief uitgestelde verwijdering van oude scènes.

Alle 98 controles slaagden. De laatste vastgelegde levenscyclusrun hield na terugkeer naar hetzelfde hoofdmenu **495 nodes als uitgangspunt en maximaal 495 nodes na iedere herstart**. Dat toont geen nodegroei in deze korte test; het bewijst geen afwezigheid van alle soorten geheugenlekken.

De native profiler gaf bij afsluiten tweemaal een GL-textuurwaarschuwing van 349.524 bytes, ook nadat het SubViewport en de weergavetextuur expliciet waren vrijgegeven. De precieze oorzaak is niet vastgesteld. De waarschuwing bewijst geen groei tijdens het spelen en is als open technisch aandachtspunt bewaard.

## Bewegende cameracompositie

`tests/camera_composition.gd` controleert de schermprojectie zonder GPU: alle zes routes plus finishnaad, drie vaste rijstroken en actieve slalom tussen de buitenstroken, 56 m/s met boost, sprongen en de bewegingsinstelling aan en uit. De physics loopt op 60 Hz en de cameraupdates op 100 Hz, zodat verschil tussen beide frequenties ook wordt gecontroleerd.

Alle **415.480 controles** slaagden. Het hoofd en midden van de speler bleven tussen x=0,317–0,679 en y=0,454–0,716 van het scherm; de camera bleef op 4,313–8,663 meter afstand. De positie en basis bleven eindig en orthonormaal en de rustige instelling hield FOV 72. Dit bewijst geometrische compositie voor die scenario's; de native beelden blijven nodig voor occlusie, verlichting en leesbaarheid.

## Herhalen

Vanuit de projectroot, met een beschikbare grafische desktop voor de tweede opdracht:

```bash
XDG_DATA_HOME=/tmp/boracer-integration-audit XDG_CACHE_HOME=/tmp/boracer-cache XDG_CONFIG_HOME=/tmp/boracer-config godot --headless --path game --script tests/integration_audit.gd
XDG_DATA_HOME=/tmp/boracer-performance XDG_CACHE_HOME=/tmp/boracer-cache XDG_CONFIG_HOME=/tmp/boracer-config godot --path game --script tests/performance.gd
```

De profiler schrijft `/tmp/boracer-performance/performance.json` en zes PNG-beelden. Gebruik een aparte XDG_DATA_HOME zodat de controles je gewone spelprofiel ongemoeid laten. De profiler weigert bewust een headless run, omdat die geen echte renderprestaties aantoont.
