# Ontwikkelronde 2 — 17 oktober 2026

De opdrachtgever vroeg de voorgestelde verbeteringen zelfstandig met agents uit te voeren. Alle zes werelden blijven behouden, inclusief Sunset Park en Neon City. Bronmodellen en bronontwerpen zijn alleen gelezen; het spel gebruikt eigen kopieën.

## Opgeleverd

- [x] **Voertuigen en personages.** Alle zes voltooide GLB's geïntegreerd, stoelankers en schaal gecontroleerd voor beide coureurs. Wiel-/stuuranimatie, zittende sprong/finish en zichtbare schild-, magneet- en boostreacties. Een bestaande zweeffout door te ruime gedraaide meshbounds gecorrigeerd.
- [x] **Werelden.** Zes verschillende routelijnen, hoogteverloop, sectorbenamingen en aankleding. Alle oorspronkelijke werelden blijven selecteerbaar. De Keukentafel blijft vlak en heeft daadwerkelijk herkenbare tafelrommel; de wolkenwereld heeft geen steunpilaren. Bewegende wolken, stoom, molen en watertaxi's.
- [x] **Racen.** Soepeler zijwaarts sturen, remmen zonder gasconflict, geen zijwaarts rijden bij stilstand, computerracers die verkeer en pickups meewegen, betrouwbaardere projectieltreffers en nauwkeuriger rondetijden. De speler start achter de andere racers, zodat de camera tijdens de aftelling vrij blijft.
- [x] **Camera.** Volgt baanframes en hellingen; bewegingscompensatie voorkomt extra achterstand bij hoge snelheid. Voertuigprojectie gecontroleerd over alle routes, buitenstroken, snelle slalom, sprongen en verschillende updatefrequenties. Rustige-cameraoptie toegevoegd.
- [x] **Interface.** Echte 3D-voertuigvoorbeelden in de garage, grotere modelweergave, echte circuitbeelden in de wereldkeuze, rondetijd/persoonlijk record/sectornamen in HUD, leesbaardere losse teksten, menu-terugnavigatie en passende schaling op verschillende vensters.
- [x] **Aanraakbediening en toegankelijkheid.** Gelijktijdig sturen/gas, bereikbare hoekgroepen, automatische gasoptie en rustige camera. Fouten in de aanraakvlakken en het vasthouden van gas tijdens pauze zijn met synthetische events gevonden en opgelost.
- [x] **Opslag.** Stabiele wereld- en voertuig-ID's met migratie van versie 1, behoud van muntjes/aankopen, herstel uit geldige reservekopie, terugdraaien van mislukte aankopen en opnieuw opslaan van een nog niet uitbetaalde race.
- [x] **QA.** Losse tests per onderdeel, zes volledige races per integratieronde, echte schrijffout/herstel, herhaald race/hoofdmenu zonder nodegroei, native renderbeelden en een lokale prestatietest. Het startscript blijft `./start.sh`.

## Samenwerking

Drie agents werkten parallel en kregen daarna aanvullende taken binnen hun eigen bestanden:

| Agent | Taken en eigendom |
| --- | --- |
| `vehicles_characters` | `kart.gd`, voertuig/coureurtest en galerie; daarna onafhankelijke integratie-, cameracompositie- en prestatietests |
| `worlds_tracks` | `track.gd`, `scripts/worlds/`, zes routes, decor, geometriecontrole en 24 grafische routebeelden |
| `race_ai_powers` | Eerst `race.gd` en gedragstests; daarna interface, minimap, 3D-voorbeelden en synthetische controller-/multitouchtests |
| Hoofdinstantie | Assetsync/import, catalogus, opslag/migratie, camera, integratiecorrecties, gezamenlijke tests, controlebeelden en documentatie |

De gedeelde contracten bleven `track.frame/position_at/bowl`, `kart.setup/update_visual/take_hit`, `race.setup/step/use_power/jump/ranking/claim_reward`. Nieuwe methoden zijn onder andere `track.section_name`, `kart.update_effects` en `profile.record_for`. De hoofdinstantie integreerde de resultaten en beoordeelde de schermen.

Er is geen Git-repository aanwezig; de wijzigingen zijn lokaal bewaard. In de bovenstaande tweede ronde zijn geen bronbestanden in `persons/` of `vehicles/` gewijzigd. De derde ronde hieronder wijzigt wel de Boaz-generator, op uitdrukkelijk verzoek.

## Verificatie

De herhaalbare testopdracht is `game/tools/check.sh`. [Gezamenlijke testuitvoer](../validation/checks.txt) bevat sinds iteratie 3 dertien testscripts, inclusief wereldmaterialen en garagepresentatie. De hoge aantallen bij camera en geometrie zijn gesamplede meetpunten langs de routes, geen evenzoveel afzonderlijke praktijktests.

Grafische controles omvatten hoofdmenu, wereldkeuze, zes garagevoorbeelden, instellingen, alle zes circuits, pauze, resultaten, modelinspectie en garage op 1280×800, 1280×720, 800×600 en een portretvenster. Aanraakbediening is ook gerenderd. Dit zijn echte Godot-beelden met geënsceneerde racemomenten. Complete races worden daarnaast daadwerkelijk gesimuleerd.

De lokale native prestatiemeting gebruikt Godot 4.7.2/Compatibility op de GTX 1050 met vijf racers, HUD en schaduwen. [Methodiek, tabel en beperkingen](PERFORMANCE.md) en [ruwe meetgegevens](../validation/performance.json) blijven bewaard. Het is een korte steekproef, geen minimale FPS-garantie of langdurige lekvrijverklaring.

## Nog open

- Echte speelsessies voor rijgevoel en balans; fysieke controller- en touchscreencontrole.
- Loopings, spiralen, trechters, vertakkingen, echte sprongsecties en routes die per ronde veranderen.
- Bewegende bruggen als gameplay, interactieve tafelhindernissen en gedeeltelijk verborgen wolkenroutes.
- Artistiek rijkere werelden en exactere historische herkenningspunten; de tafelroute is nog geen dicht objectlabyrint.
- De circa 0,6–0,8 seconde overgang bij wereldopbouw verkorten en herhaald decor efficiënter tekenen.
- Twee onverklaarde GL-textuurwaarschuwingen bij het afsluiten van de native profiler; geen nodegroei gezien in de korte herstarttest.
- Definitieve audio, verdere economie/balans, ontwerpen 7–12, multiplayer en distributie-exports.

Vrije bandenphysics, nieuwe Blender-modellen, multiplayer en distributie zijn niet toegevoegd in deze ronde.


## Iteratie 3 — materialen, garage en Boaz-review

Drie aparte agents voerden deze ronde uit:

| Agent | Resultaat |
| --- | --- |
| `iteration3_worlds` | Textuurmaterialen, normalmaps, verdere skyline/heuvels/wolkenlagen, uitgewerkte keukenruimte en geveldetails; bestaande zes routes behouden |
| `iteration3_garage` | Geïsoleerde reflectiestudio, vloer/contactschaduw, 4× MSAA en hogere vaste renderresolutie; grote draaibare inspectie |
| `iteration3_characters` | Alleen Boaz stap 1: verhoudingen, doorlopende gezichtsgeometrie en kleinere dieper liggende ogen; reproduceerbare generator en vergelijkingsbeelden |
| Hoofdinstantie | Gegenereerde hout/baksteenbronnen, lichtintegratie, gezamenlijke regressies, native schermcontrole en documentatie |

De garage toont echte modellen met hun oorspronkelijke materialen. De reflectiestudio brengt vooral metallic lak en chroom beter in beeld; dit is geen garantie op identieke Blender/Cycles-rendering. Statische voorbeelden stoppen na enkele opstartframes met renderen.

Wereldmaterialen gebruiken wereldprojectie en mipmaps; de procedurale materialen hebben normalmaps. Decor en achtergronden voegen geen botsingsobjecten toe. De extra details veranderen de routes, economie of racebesturing niet. Bronprompts voor de twee gegenereerde beelden staan in `assets/textures/worlds/GENERATED-SOURCES.md`; de overige textures zijn reproduceerbaar met `tools/generate_world_textures.py`.

De karakterinstructie verlangt opeenvolgende visuele goedkeuring. Daarom is de nieuwe Boaz een kandidaat en blijft `game/assets/models/boaz.glb` de eerdere versie. Zie [review en voor/na](../../persons/boaz/STEP1-REVIEW.md). De oorspronkelijke bestanden zijn bewaard onder `persons/backups/2026-10-17-step1/`. Haar, outfit, UV/PBR en animatieherontwerp volgen pas na goedkeuring van de huidige stap; Ravi is nog niet opnieuw gebouwd. Het losse `tests/character_step1.gd` importeert de kandidaat direct en synchroniseert geen runtime-assets.


## Personages — Ravi stap 1 en haarstap 2

Na goedkeuring van Boaz stap 1 vroeg de gebruiker dezelfde anatomieverbetering voor Ravi en direct aansluitend stap 2. Ravi heeft eigen gezicht-, hoofd- en lichaamsparameters in de gedeelde generator. Zijn groene hoofdband, oranje veer en referentiekostuum blijven behouden. Boaz' anatomieparameters blijven intact.

De haarstap is geïsoleerd in `persons/tools/character_hair.py`, met asymmetrische brede lokvolumes, een doorlopende ondermassa en aparte Boaz/Ravi-pony. De stap-1-modellen staan afzonderlijk bewaard, zodat vergelijking met de haarversies mogelijk blijft. De bestaande kleuratlas, outfit, rig en animatieontwerpen zijn voor de haarstap behouden.

De game gebruikt de stap-1-gezichten met de afgeronde stap-2-haarmodellen. Het stoelanker leest nu de daadwerkelijke `hips`-restpositie uit de geëxporteerde rig; de eerdere vaste hoogte van 0,44 meter paste niet exact bij de aangepaste lichaamsverhoudingen. De twaalf voertuig/coureurcombinaties worden gecontroleerd op de werkelijke heuphoogte in de stoel.

De haarmodellen zijn na technische controle in de game geïntegreerd en blijven voor de volgende fase ter visuele beoordeling, met per personage een `STEP2-REVIEW.md`. De Godot-controle `tests/character_review.gd -- boaz|ravi` leest deze bron-GLB's rechtstreeks. `tests/character_review_visual.gd` maakt native reviewbeelden van beide kandidaten, zonder de game-assets te vervangen. De onafhankelijke GLB-vergelijking onder `persons/tools/check_character_hair_scope.py` controleert dat de haarstap de overige geometrie, rig, animaties en textures behoudt.


Gerichte integratiecontrole voor deze personageronde: 888 voertuig/coureurcontroles, 56 garagecontroles en 415.480 cameracompositiesamples slagen. [Uitvoer](../validation/character-step2-checks.txt). Dit is een gerichte hercontrole van de gewijzigde modellen en zitankers; de volledige dertien-suiterun in `checks.txt` hoort bij de voorgaande wereld-/garage-iteratie. De bestaande renderbenchmark is niet opnieuw uitgevoerd voor de aangepaste anatomie.


Beide haarreviewkandidaten slagen voor 75 afzonderlijke Godot-import-/rig-/animatiecontroles en hebben native front-, driekwart-, achter-, volledig en zitbeelden onder `persons/<naam>/review-step2/godot/`. Boaz behoudt alle 33.886 niet-haartriangles exact. Bij Ravi behoudt de aanvullende numerieke audit alle 31.006 niet-haartriangles; de strikte hashcontrole blijft zichtbaar afgekeurd vanwege 1,86 nanometer positieverschil en maximaal 0,00003785 normalcomponentverschil op handschoenpatches. Deze nuance is bewaard in `float-drift-audit.json`; UV's, gewichten, morphs, rig en animaties zijn gelijk. De hele modellen tellen nu 40.524 en 37.644 triangles, beide nog boven de 25k-richtwaarde.
