# BoRacer — speelbare versie 2

Godot-project bij `../project-wensen.md`. Deze tweede ontwikkelronde integreert de zes voltooide voertuigen en werkt circuits, coureurs, rijgedrag, camera, interface en opslag verder uit. Alle zes werelden blijven behouden, ook Sunset Park en Neon City.

## GAME-10001 — nieuwe presentatie en weer

- Raketfiets als startkeuze voor nieuw en bestaand profiel (eenmalige migratie),
  de vier AI-racers krijgen ieder een ander voertuig. Andere voertuigen blijven kiesbaar.
- Splash en dashboard/HUD naar de oorspronkelijke sfeerreferenties: cyaan/donkerblauw,
  gouden accenten, grote positie, losse ranglijstrijen en ronde snelheids-/boostmeter.
- Gouden coins en transparante powerboxes met expliciete glansranden en pickupburst.
- Voertuiggeluiden uit `assets/audio/raviracer.mp3`: gefilterde stationair-/rij-/boostloops,
  zes klankprofielen en ruimtelijk geluid voor speler en AI. Snelheid/gas/boost sturen
  vloeiende overgangen; effectvolume, mute en pauze werken ook op de motorlagen.
  Zie [audiobewerking en luistervoorbeelden](docs/VOERTUIGAUDIO.md).
- Willekeurige regenbuien, regenboog na opklaren en nacht met zichtbare rijbaan.
  Pauze stopt het weer. Keukentafel blijft binnen; geen grip-/economieaanpassing.
- Gebouwen hebben gesloten dakvolumes en kopgevels, plus ramen met kozijnen,
  neggen en vensterbanken aan alle vier zijden.
- De parcourskaarten gebruiken de oorspronkelijke sfeerbeelden met gecontroleerde uitsneden.
- Haarlem en Uithoorn gebruiken fotografische gevel- en wegmaterialen. Zie het
  [landmark- en materiaalonderzoek](docs/LANDMARKS-EN-MATERIALEN.md) voor bronnen,
  licenties en voorstellen. Het latere [straatbeeldvervolg](docs/STRAATBEELD-BRONKAART.md)
  voegt woonwijken en een vrij geïnterpreteerd Spoorhuis toe.

De [straatbeeldbronkaart](docs/STRAATBEELD-BRONKAART.md) koppelt de 22 aangeleverde foto’s aan vorm-/kleurkeuzes; foto’s zijn niet als textures gekopieerd.

De functionaliteit heeft headless Godot-controles. Native screenshots zijn in
deze uitvoeromgeving geblokkeerd doordat X11- en lokale displaysockets worden
geweigerd. Dit is geen visuele goedkeuring van interface, weer of materialen.

### Vaste renderplek en één reviewcommando

Vanuit `boracer/`, in een gewone grafische desktopsessie:

```bash
python3 game/tools/capture_review.py
```

De beelden komen onder **`renders/GAME-10001/<stap>/<tijdstip>/`**, met HTML-index,
asset-/scripthashes en capturelog. `latest` verwijst uitsluitend naar een geslaagde
run; eerdere runs blijven staan. De centrale [rendermap](../renders/README.md)
onderscheidt echte enginebeelden van Blender-studiorenders en mislukte captures.

Na iedere volgende afgeronde karakterfase publiceert dit gerichte commando alleen
beide bevroren personages, bewaart vorige gamekopieën, importeert en rendert automatisch:

```bash
python3 game/tools/publish_character_step.py --step 3
# Later --step 4 of --step 5, uitsluitend met de juiste review-stepN/after-snapshots.
```

Dit vervangt geen klantacceptatie en verandert geen voertuigen of profieldata.
Binnen een omgeving zonder grafisch display meldt de capture een fout met log;
kopieën worden dan niet als visueel beoordeeld gepresenteerd.

## Starten

Vanuit de bovenliggende map:

```bash
./start.sh
```

Of open `game/project.godot` in Godot **4.7.2** en druk op **F5**. Het startscript importeert de assets vóór het starten; de eerste import duurt langer. Er zijn geen Python-pakketten, Blender, server of internetverbinding nodig om te spelen.

```bash
./start.sh -- --demo
```

Deze optie start een automatisch bestuurde demonstratierace. Python is alleen nodig om later modelkopieën te verversen.

Bij GLX/OpenGL- of PulseAudio-opstartfouten op Linux kun je tijdelijk starten met:

```bash
./start.sh --safe-mode
```

Deze herstelstart kiest OpenGL ES en schakelt geluid tijdelijk uit. De gewone start blijft ongewijzigd. Combineer bijvoorbeeld met `./start.sh --safe-mode -- --demo`. Een X11-`BadMatch` bij focus is een afzonderlijke melding; deze optie is geen bewezen oplossing daarvoor. Zie [Linux-opstartdiagnose](docs/LINUX-STARTUP.md) voor controles en beperkingen.

## Lagere spelresolutie op een groot scherm

Open **Instellingen → Spelresolutie** en kies een instelling van **540p** tot **1800p**, bijvoorbeeld **900p** als tussenstap tussen 720p en 1080p.
**Volledige schermresolutie** behoudt de oorspronkelijke scherpte. De keuze
werkt direct, wordt lokaal bewaard en geldt ook voor Monsterbreker.

De instelling begrenst de hoogte van het 3D-beeld; de beeldverhouding volgt het venster. Op een 16:9-scherm levert 900p bijvoorbeeld ongeveer 1600×900 3D-pixels. Breedbeeld gebruikt de extra ruimte voor de wereld; de bediening blijft gecentreerd. Op een volledig gevuld 3840×2160-scherm geeft 1080p een 3D-beeld van
1920×1080, met een kwart van het oorspronkelijke aantal pixels. Teksten en
knoppen blijven op de normale schermresolutie. Een kleiner venster wordt niet
extra groot gerenderd. Garagevoorbeelden gebruiken hun bestaande kleine buffers.

Dit gebruikt Godots [3D-resolutieschaling met bilineaire filtering](https://docs.godotengine.org/en/stable/tutorials/3d/resolution_scaling.html),
die de Compatibility-renderer ondersteunt. Minder pixels betekent niet automatisch
een evenredig hogere beeldsnelheid; deze wijziging bevat geen GPU-prestatiemeting.
Controle: `tests/render_resolution.gd`, ook opgenomen in `game/tools/check.sh`.
De nieuwe opties en breedbeeldindeling zijn ook headless te controleren; beeldkwaliteit en FPS moeten op de gebruikte computer zelf worden beoordeeld.

## Garage en coureurs

Alle zes voertuigen zijn beschikbaar. **De Raketfiets en Retro zijn gratis**. Bestaande aankopen, muntjes en records blijven behouden. Profielen van vóór versie 3 kiezen bij migratie eenmaal de Raketfiets; een daarna bewust gemaakte garagekeuze blijft opgeslagen. De Raketfiets wordt ook gratis aan bestaande garages toegevoegd.

| Voertuig | Prijs in spelmuntjes |
| --- | ---: |
| De Raketfiets | Gratis |
| Retro Racer | Gratis |
| Purple Passion | 80 |
| Golden Rocket | 140 |
| Rainbow Jet | 160 |
| Toxic Turbo | 200 |

De garage toont echte 3D-voorbeelden van de zes modellen met de gekozen coureur. **Bekijk** opent een grotere voorvertoning. Prijzen en voertuigstatistieken zijn voorlopige balansinstellingen. Voor plaatsen 7–12 zijn nog geen definitieve modellen toegevoegd.

Boaz en Ravi zitten op het stoelanker van ieder voertuig. De game gebruikt de huidige karakterexports en afgeleide zittende animaties voor sturen, springen en finishen; de benen blijven daarbij in de cockpit. Treffereacties, wielrotatie, meesturende voorwielen, boostvlam, schildreactie en magneet zijn zichtbaar. De normalisatie gebruikt echte meshvertices, zodat gedraaide wielbounds de kart niet meer boven het wegdek tillen.

Alle zes runtimevoertuigen hebben een linker- en rechterspiegel. Houd **C** of **LB** ingedrukt: achteruit wordt het hoofdbeeld en het actuele vooruitbeeld verschijnt in een klein venster. Loslaten herstelt het vooruitbeeld. De spiegels op de voertuigen hebben een chromen oppervlak; de live beelden worden door de racecamera's getoond. Pauze, focusverlies, een losgekoppelde controller en finish sluiten het achteruitbeeld. Laat de knop los voordat je opnieuw achterom kijkt.

## Besturing en instellingen

| Actie | Toetsenbord | Controller |
| --- | --- | --- |
| Gas | W / ↑ | RT |
| Remmen | S / ↓ | LT |
| Rijrichting binnen de baan | A/D / ←/→ | Linkerstick |
| Boost | Shift vasthouden | RB vasthouden |
| Power-up / kanonnen | E | X |
| Springen | Spatie | A |
| Terug naar baanmidden | R | Y |
| Achterom kijken (vasthouden) | C | LB |
| Pauze | Esc / P | Start |
| Terug in menu | Esc | B |

Menu's ondersteunen muis en focusbesturing met toetsenbord/controller. Instellingen bevatten muziek, geluid, drie moeilijkheidsniveaus, schaduwen, **rustige camera**, **automatisch gas geven** en **aanraakknoppen**. Aanraakknoppen verschijnen ook automatisch op een touchscreen; forceer ze met `./start.sh -- --touch`. Gas en sturen kunnen tegelijk worden ingedrukt. Pauzeren, resultaten tonen en een race verlaten laten ingedrukte aanraakacties los.

Een aangesloten **DragonRise Wired Wheel** (USB `0079:189c`) is op Linux herkend als Xbox-controller. Sturen werkt met het stuur; het rechterpedaal geeft gas en het linkerpedaal remt. Ook de rechter- en linkerflipper geven respectievelijk gas en rem door. Bij een controle met het fysieke stuur ontving Godot de vier bijbehorende spelacties; het rijgevoel in een echte race is daarbij nog niet beoordeeld. Andere stuurmodellen kunnen anders werken.

De overige controller- en multitouchinvoer is met synthetische Godot-events gecontroleerd. Een fysiek touchscreen is nog niet gebruikt voor de eindcontrole.

De **stuurhulp** blijft actief: de kart volgt de lengterichting van het circuit. Je regelt zelf snelheid, remmen, laterale rijlijn, boost, springen en power-ups. Er is geen vrije banden-/ophangingssimulatie en nog geen achteruitrijden. Bij stilstaan schuift de kart niet meer zijwaarts; na een treffer kun je kort niet springen. Randen begeleiden zacht terug naar de rijbaan. Botsingen tussen racers geven een zet en kosten snelheid.

## Zes circuits

De werelden hebben nu ieder een eigen gesloten route van ongeveer **630–816 meter**, met eigen bochtenritme, hoogteverloop, sectorbenamingen en aankleding. De wereldkeuze gebruikt uitsneden uit de oorspronkelijke sfeerillustraties; dit zijn geen gameplaybeelden.

- **Sunset Park:** kust-/kermiscircuit met brede bochten, een reuzenrad, eilandjes en tenten.
- **Neon City:** verhoogde stadsroute met rechte stukken, dakbochten, torens en neonpoorten.
- **Regenbogenrijk:** grotere hoogteverschillen, regenboogpoorten, bewegende wolken, zwevende tuinen en een lange afdaling. Het blauwachtige parelmoerwegdek blijft zichtbaar.
- **Haarlem 1888:** 198 smalle huisjes langs de weg, met trap-, lijst- en puntgevels, witte kozijnen, winkelplinten en stoepen. Waterfront, kerk, molen en koperen installaties blijven.
- **Uithoorn 2056:** straatcircuit op grondniveau, met een startheuvel van 28 meter en scherpe bochten langs de zes herkenbare landmarks. Huizen, tuinen en tram blijven naast de rijbaan. De afzonderlijke Stunt Edition behoudt zijn stuntparcours. Zie [het grondtracé](docs/UITHOORN-GRONDTRACE.md).
- **De Keukentafel:** een vlakke route over hout met voorwerpen uit de aangeleverde foto’s: zwarte monitor met toetsenbord/muis, staande wit-rode megafoon, cyaan blik, afstandsbediening, kabelbundels/stekkerblok, printplaatjes, schaar, papier/doordrukstrip, USB-voeding, groene stof en glazen bol. Echte fotodetails liggen op passende 3D-vormen.

De wegen blijven breed; de keukentafel en het gewone Uithoorn-straatcircuit hebben een vlak dwarsprofiel. Er zijn geen generieke rood-witte strepen, middenlijnen of losse lampjes toegevoegd. Haarlem en het gewone Uithoorn-straatcircuit houden de volledige rij- en cameracorridor vrij van woningen. Overige decorvoetafdrukken blijven buiten de rijbaan; de wolkenwereld heeft geen ondersteuningspilaren.

Dit zijn procedurele interpretaties van de wereldontwerpen. Historische herkenningspunten zijn eenvoudige silhouetten. De keukentafel is nog een brede route langs de rommel, geen dicht objectlabyrint. Loopings, vertakkingen, echte trechters, veranderende bruggen en per ronde veranderende rijgeometrie zijn nog niet geïmplementeerd.

## Raceregels en HUD

- Vijf racers, drie rondes en een startaftelling. De speler start achter de computerracers, zodat er tijdens het aftellen geen voertuig door de volgcamera steekt. Computerracers kiezen rijlijnen op basis van verkeer en nuttige pickups, halen in en gebruiken power-ups.
- Muntjes vullen de boostvoorraad een beetje aan en tellen mee voor je racebeloning. Verrassingsblokken geven één van zes power-ups.
- **Boost:** tijdelijk sneller. **Schild:** vangt één treffer op. **Magneet:** trekt muntjes van een grotere afstand aan.
- **Raket:** volgt de rijlijn van een voorligger. **Bom:** blijft op de baan liggen. **Kanonnen:** zeven seconden beschikbaar, met een schietinterval van 0,3 seconde.
- Projectielen controleren hun afgelegde traject, zodat een trage frame geen kart zomaar overslaat. Springen kan een projectiel ontwijken; treffers veroorzaken tijdelijke vertraging. Botsingen en projectielen werken ook over de start-/finishnaad.
- HUD: ranking, snelheid, boostvoorraad, ronde, rondetijd, totale tijd, persoonlijk racerecord, huidige sector, minimap, muntjes, power-up en effectduur.
- Camera: volgt positie, hellingen en verkanting zonder de extra achterstand die voorheen bij hoge snelheid ontstond. Rustige camera schakelt de snelheids-/boostverandering van het gezichtsveld uit.
- De race pauzeert wanneer de toepassing focus verliest. Pauze stopt ook de coureur- en decoranimaties.

Rondelijnpassages worden binnen de simulatiestap geïnterpoleerd. Bij de finish van de speler eindigt de race; de resterende volgorde gebruikt de actuele voortgang van de andere racers. De racebeloning is **10–60 muntjes plus verzamelde muntjes**. Afbreken levert niets op; opnieuw de uitslag openen kan niet nogmaals uitbetalen.

## Opslag en bestaande voortgang

Godot bewaart `user://profile.json`, op Linux doorgaans onder `~/.local/share/godot/app_userdata/BoRacer/`.

Profielschema 3 bewaart wereldrecords en voertuigkeuze met vaste ID's en introduceert de eenmalige Raketfiets-default. Profielen uit versie 1 met numerieke wereld-/voertuigposities worden bij het laden overgenomen. Ongeldige velden worden genegeerd; bestaande muntjes en aankopen blijven behouden. Als het hoofdbestand beschadigd is probeert het spel de laatste geldige `.bak`-reservekopie.

Opslaan gebeurt eerst naar een tijdelijk bestand en daarna via hernoemen. Bij een mislukte koop worden muntjes, bezit en selectie teruggedraaid. Bij een mislukte finishopslag blijft de beloning openstaan en biedt de uitslag **Opnieuw opslaan**. Na succesvol opslaan is dezelfde beloning niet opnieuw te claimen. Een nieuwe race starten of de toepassing sluiten voordat een mislukte finish is opgeslagen verliest die nog openstaande beloning.

Voor een schone start kun je buiten het spel het profiel én de bijbehorende `.bak` hernoemen. Ontwikkeltests draaien in aparte tijdelijke gebruikersmappen.

## Bronmodellen en gamekopieën

De werkmappen `../persons/` en `../vehicles/` worden alleen gelezen. De game gebruikt eigen GLB-kopieën in `assets/models/`. Blenderbestanden, bouwscripts, renders en brontextures worden niet veranderd of opnieuw gebouwd.

```bash
# Vanuit de hoofdmap: ververs de huidige zes goedgekeurde modellen en personages.
python3 game/tools/sync_assets.py

# Alleen als je de volledige beschikbare lijst bewust wilt wijzigen:
python3 game/tools/sync_assets.py --vehicles retro golden-rocket-racer raketfiets purple-passion toxic-turbo rainbow
```

Zonder `--vehicles` blijft de vorige beschikbare lijst behouden. Het script verkiest `*-improved.glb`, controleert de GLB-header, bestandslengte en ingebedde bronnen en legt bronpad en SHA-256 vast in `assets/manifest.json`. Tijdens een nog lopende export kan de controle mislukken. Stop game/editor vóór het synchroniseren en laat Godot daarna opnieuw importeren. Het bestaan van een nieuwe GLB maakt deze niet zonder expliciete keuze beschikbaar.

Gamevoertuigen worden op ongeveer 1,95 meter lengte genormaliseerd en met hun wielen op de grond gezet. Modelvoorbeelden en races gebruiken dezelfde integratiecode. Textures die Godot uit de GLB haalt blijven uitsluitend in de gamekopie.

## Monsterbreker voor één of twee spelers

Het startscherm heeft aparte tegels voor **1 speler** en **2 spelers**. Kies uit
de tien aangeleverde blokjesmonsters, acht verfijnde monsters met 72 of 76
breekstukken, of de tweekoppige proefdraak. Scroll in de lijst om alle monsters
te zien. Rijd vanuit
vlak achter het zitje een lange, steile helling af, neem de schans en vlieg naar het monster.
De richtcirkel laat zien of je op het monster of een steun afvliegt. Stuur bij
in de lucht en druk opnieuw op Shift of RB voor één duikboost per sprong.
Daarmee buig je de vlucht omlaag en maak je de klap breder en harder.
Onderweg geeft de groene ring links extra hoogte en de oranje ring rechts
extra snelheid. De richtcirkel rekent de ring mee als je erop afvliegt.
Vogels kunnen je raken en een misser krijgt een komisch geluidje.

Solo probeer je het monster in zo weinig mogelijk sprongen te verslaan. Samen
speel je om de beurt. Vóór iedere sprong kies je zelf een raketje. In pauze
kun je direct op een monstertegel klikken om een nieuw spel te starten.
De blokjesmonsters zijn 50% groter. Een monsterblokje in het water levert 10
punten op. Bij 70% in het water wint in een duel de hoogste score.
Bij de verfijnde monsters tellen volledig gezonken stukken naar hun volumegewicht:
het hele monster is 10.000 punten, de wedstrijdgrens is 7.000. De breekbare torens
tellen niet mee voor punten. Zie
[bediening, spelregels, monsterimport en controles](docs/MONSTERBREKER.md).

## Technische indeling

| Bestand | Verantwoordelijkheid |
| --- | --- |
| `scripts/catalog.gd` | Vaste wereld-/voertuig-ID's, catalogus, prijzen en spelstatistieken |
| `scripts/profile.gd` | Profielmigratie, reservekopie, aankopen en records |
| `scripts/track.gd` | Curve, komprofiel, wegmesh, randen, baanframes en decoranimaties |
| `scripts/worlds/routes.gd` | Zes eigen routelijnen, hoogteverloop en sectornamen |
| `scripts/worlds/scenery.gd` | Werelddecor, veilige plaatsing en omgevingsbeweging |
| `scripts/worlds/world_art.gd` | Textuurmaterialen, gelaagde achtergronden en omgevingslicht |
| `scripts/geometry.gd` | Herbruikbare primitieve geometrie |
| `scripts/kart.gd` | Modelintegratie, stoelanker, coureur, wielen en effecten |
| `scripts/race.gd` | Simulatie, AI, pickups, projectielen, rondes en beloningen |
| `scripts/follow_camera.gd` | Camera, bewegingscompensatie en zicht op de rijbaan |
| `scripts/main.gd` | Lifecycle, input, licht, wereldwissel en integratie |
| `scripts/interface.gd`, `scripts/ui/` | Schermen, losse 3D-voorbeelden en aanraakdoelen |
| `scripts/minimap.gd` | Route en racerposities |
| `scripts/audio.gd` | Eenvoudige eigen gesynthetiseerde muziek en geluiden |

De game gebruikt de Compatibility-renderer zonder externe addons. Er is nog geen distributie-export voor web, mobiel of andere besturingssystemen getest.

Iteratie 3 voegt echte oppervlaktetextures en verder uitgewerkte achtergronden aan alle zes werelden toe. De garage gebruikt een aparte reflectiestudio met scherpere voorbeelden en draaibare modelinspectie. De hout- en baksteenbeelden zijn met de ingebouwde beeldgenerator gemaakt; [bronprompts](assets/textures/worlds/GENERATED-SOURCES.md) en de procedurele generator voor overige materialen blijven bewaard.

**Personages:** stap 1–2 (gezicht en haar) zijn behouden. GAME-10001 werkt het kostuum uit in stap 3; de actuele bevroren runtimebron en SHA-256 staan in `assets/manifest.json`. Zie de stap-3-verslagen in `persons/<naam>/STEP3-REVIEW.md` zodra de fase is opgeleverd. Unieke karakter-UV/PBR en animatieherontwerp zijn de afzonderlijke fasen 4 en 5 en wachten op de afgesproken fasekeuze/visuele beoordeling.

## Controles en beelden

```bash
game/tools/check.sh
```

Dit importeert met Godot en voert alle automatische tests uit met een aparte tijdelijke gebruikersmap. De suites omvatten profielmigratie en echte schrijffouten, baan-/decorgeometrie, twaalf voertuig/coureurcombinaties, racegedrag, camera, interface, synthetische controller-/multitouchinvoer, complete races en herhaald opnieuw starten.

Geometrie- en cameracontroles gebruiken veel meetpunten langs de baan; de aantallen in de logs zijn dus gesamplede controles, geen afzonderlijke handmatig geschreven praktijkscenario's. [Laatste testuitvoer](validation/checks.txt).

Gerenderde controle met toegang tot een grafische sessie:

```bash
XDG_DATA_HOME=/tmp/boracer-visual-data godot --path game --audio-driver Dummy --script tests/visual.gd
```

Deze test schrijft `/tmp/boracer-visual/` met echte enginebeelden van alle schermen, zes circuits, garage op meerdere vensterformaten en aanraakbediening. De beelden gebruiken geënsceneerde racemomenten; de volledige racecyclus wordt apart gesimuleerd. Een afzonderlijk visueel testprofiel voorkomt wijzigingen aan je spelvoortgang.

Voorbeelden: [garage](validation/garage.png), [wereldkeuze](validation/wereldkeuze.png), [Regenbogenrijk](validation/regenbogenrijk.png), [De Keukentafel](validation/keukentafel.png), [aanraakbediening](validation/aanraakbediening.png).

[Prestatiemetingen en verificatiegrenzen](docs/PERFORMANCE.md) beschrijven de lokale native rendersteekproef, opbouwtijd en open technische aandachtspunten. [Werkverdeling en oplevering](docs/DEVELOPMENT.md) beschrijven de agentronde.

## Verdere ontwikkeling

- Rijgevoel met Boaz/Ravi in echte speelsessies afstellen; fysieke controller-/touchbediening beoordelen.
- De tijdelijke procedurele werelden artistiek verdiepen, de keukentafel tot een echt objectlabyrint maken en de historische locaties herkenbaarder uitwerken.
- Loopings, spiralen, trechters, sprongsecties en vertakkingen met passende baanframes en spelregels toevoegen.
- Dynamische bruggen, routes per ronde en eerlijk gedeeltelijk verborgen wolkenroutes uitwerken.
- De overgangspauze bij wereldopbouw verkorten, herhaald decor efficiënter tekenen en prestaties op gekozen doelplatformen meten.
- Geluid, animatieovergangen, effecten, economie en moeilijkheid verder afstellen.
- Ontwerpen 7–12, multiplayer/co-op en distributie pas uitwerken zodra daarvoor de gewenste richting is gekozen.

Het oorspronkelijke wensenbestand blijft de ontwerpbron. Deze versie werkt de eerste racecyclus verder uit en verklaart niet alle oorspronkelijke wensen voltooid.

Voertuigaudio: de drie WAV-loops zijn lokaal inbegrepen; ffmpeg/Python zijn alleen
nodig om ze opnieuw uit de bron te bouwen. De [luisterpagina](../renders/GAME-10001/audio/index.html)
biedt de bron, losse loops en een offline acceleratie-/boostvoorbeeld; dit is geen
opname uit Godot. Menselijke beoordeling van het geluid in de game blijft open.

## Keukentafel uit fotoreferenties

Elf voorwerpgroepen uit achttien klantfoto’s, opgebouwd met dozen, cilinders,
bollen, ringen en ronde kabels. Vijf fotovlakken gebruiken ongewijzigde foto’s
met UV-perspectiefcorrectie: scherm, toetsenbord, remote, megafoonkap en
gebogen bliklabel. Zie [geometrie en referenties](docs/KEUKENTAFEL-GEOMETRIE.md)
en [fotoherkomst/import](assets/textures/kitchen/photos/README.md).
De vijf foto’s importeren maximaal1536×2048 met mipmaps en DXT1-compressie;
gecomprimeerde afbeeldingsdata samen10.485.880 bytes, geen fysieke VRAMmeting.

Maak de racecamera, een overzicht en elf objectclose-ups vanuit iedere werkmap:

```bash
python3 game/tools/capture_step.py --project GAME-10001 --step stap-09-keukentafel
```

Gebruik hiervoor een grafische desktopterminal. De nieuwe
[keukentafelpagina](../renders/GAME-10001/stap-09-keukentafel/index.html)
toont ook de absolute aanroep. De complete `capture_review.py` neemt deze fase mee.
De gedeelde map bevat inmiddels dertien echte native beelden uit run
`20261017T075800-394731Z`, gemaakt vóór de laatste correctie van fotovlaknormalen.
Die beelden tonen plaatsing, silhouetten en foto-UV’s; herhaal het commando voor
de definitieve belichting. De headless setupvalidatie controleert dezelfde
dertien camera-opstellingen zonder zelf plaatjes te genereren.

## Dashboardtegels en roterende duo

Home toont vier geïllustreerde tegels met de bestaande navigatie. Het logo en
de wereldachtergrond zijn behouden. Centraal draaien Boaz en Ravi, ieder op
een echte Raketfiets, in een transparant eigen3D-viewport.

```bash
python3 game/tools/capture_step.py --project GAME-10001 --step stap-10-dashboard
```

[Dashboardbeelden](../renders/GAME-10001/stap-10-dashboard/index.html): zes
opstellingen inclusief verschillende vensterformaten. De headless tests
controleren navigatie, plaatsing en lifecycle; native visuele beoordeling apart.

## Straatleven buiten

De vijf buitenwerelden hebben bomen, geparkeerde voertuigen, banken,
prullenbakken, bloembakken en lantaarns. Mensen wandelen met hondjes aan de
lijn over veilige lokale stroken. Haarlem heeft historische stoomvoertuigen;
Uithoorn krijgt straatleven op wijkniveau; Regenbogenrijk gedragen eilandjes.
Zie [plaatsing en lifecycle](docs/STRAATLEVEN.md).

```bash
python3 game/tools/capture_step.py --project GAME-10001 --step stap-11-straatleven
```

[Renderpagina](../renders/GAME-10001/stap-11-straatleven/index.html): twintig
opstellingen, inclusief twee momenten met dezelfde wandelcamera. De gedeelde
map bevat een eerdere native run; herhaal het commando voor de nieuwste
Uithoornvloerhoogte, wolkondersteuning en camerastandpunten. Headless controles maken geen beelden.

## Garage, Nederlandse lucht en galerie

De garage toont getekende coureurtorso's, groene betaalbare koopknoppen en
roterende voertuigen op een racetrackdiorama. Zie
[bediening en captureopstellingen](docs/GARAGE-EN-RENDERGALERIJ.md).
De vijf buitenwerelden hebben wolkenluchten; Neon heeft maan/sterren.
Haarlem toont lage duinen en Uithoorn weilanden met Amstelbochten.
[Omgevingsopbouw](docs/LUCHT-VERGEZICHT-GEOMETRIE.md). Keukenhemel behouden.

De [gebouw-/objectgalerij](../renders/GAME-10001/gebouwen-en-objecten/index.html)
toont modellen op hun echte plek langs de weg of op tafel. Actuele opnamen:

```bash
python3 game/tools/capture_step.py --project GAME-10001 --step stap-12-gebouwen-objecten
python3 game/tools/capture_step.py --project GAME-10001 --step stap-13-garage-hemel
```

Het renderoverzicht opent stabiele onderdeelpagina's die direct de laatste
geslaagde opname tonen, met uitsluitend het bijbehorende python3commando.
Nieuwere mislukte pogingen verdringen dat beeld niet. Zonder geslaagde
opname toont de pagina zijn eigen titel, commando en status. Het projectoverzicht
biedt daarnaast één absoluut `python3 capture_review.py`-commando om alle
actuele renderonderdelen achter elkaar te maken.

Af en toe passeert hoog boven de vijf buitenwerelden een vliegtuig met twee
langzaam vervagende condenssporen. Pauze bevriest de passage; de keuken blijft
uitgesloten. [Gedrag en rendercommando](docs/VLIEGTUIG.md),
[renderpagina](../renders/GAME-10001/stap-14-vliegtuig/index.html).

## Keukentafelavontuur

De keukenbaan rijdt door twee toiletrollen en een grijze PVCbuis, onder losse
kabels en door een oranje plastic speelgoedlooping. Twee schansen bestaan uit
een stripalbum op hout en een speelkaart op een Jengablok. Een zwarte controller,
wandboekenkast en keuken met fornuis vullen de omgeving aan. De bestaande elf
fotovoorwerpgroepen blijven staan.

De looping draait voertuig en volgcamera volledig mee. Beide schansen geven
speler en AI een echte sprong; in de PVCbuis verschijnt rondom de speler een
draaiende regenboog. Pauze bevriest de effectanimatie.

```bash
python3 game/tools/capture_step.py --project GAME-10001 --step stap-15-keuken-avontuur
```

[Renderpagina met eigen commando](../renders/GAME-10001/stap-15-keuken-avontuur/index.html).
Twintig opstellingen omvatten tunneldoorritten, de onderstebovenpositie,
sprongen, twee regenboogmomenten en beide kamerachtergronden. Headless
setupvalidatie maakt geen beelden; native materiaal- en compositiereview blijft
apart. [Geometrie en objecten](docs/KEUKENTAFEL-AVONTUUR-PROPS.md),
[rijroute, camera en effect](docs/KEUKENTAFEL-AVONTUUR-ROUTE.md).


Af en toe vliegt een klein vogeltje door de buitenlucht, met afwisselend
vleugelslag en glijden. De passage pauzeert mee met het spel.
[Eigen renderpagina](../renders/GAME-10001/stap-16-vogeltje/index.html) met drie
opstellingen en uitsluitend dit absolute commando:

```bash
python3 game/tools/capture_step.py --project GAME-10001 --step stap-16-vogeltje
```

Headless controles maken geen afbeeldingen; native beelden vereisen een
grafische desktopsessie.

Onderzoek naar gratis/open uitbreidingen: [geprioriteerd componentenadvies](docs/GRATIS-COMPONENTEN-ADVIES.md),
met primaire bronlinks, licenties en geraamde integratiemoeite. Onderzoek is geen installatie.


## Geïntegreerde gratis componenten

Groenaccenten in Haarlem/Uithoorn, materiaalgeluiden, landingsstof, botsingsvonken
en een korte finishviering zijn geïntegreerd. Zie [selectie, commando’s en QA](docs/QUICKWINS-CC0.md).

In de garage staat het gekozen voertuig naast de coureurs. Bij de kaart van
dat voertuig vervalt de selectieknop; de andere voertuigen kun je blijven
selecteren of kopen.
