# Monsterbreker — prototype met aangeleverde monsters

Kies op het startscherm **Monsterbreker · 1 speler** of
**Monsterbreker · 2 spelers**. Het hoofdmenu heeft daarnaast
**Monsterbreker · solo / samen**. Kies een monster, bekijk het 3D-model
en druk op **Start solo** of **Start duel**.

```bash
./start.sh -- --solo
./start.sh -- --monster
```

De tien aangeleverde blokjesmonsters, **Gifspuwer · verfijnd** en de oorspronkelijke
tweekoppige proefdraak zijn speelbaar: twaalf keuzes. De verfijnde Gifspuwer
gebruikt de 76 afzonderlijke stukken uit `gifspuwer-monsterbreker-test`.
De eerdere gladde fase-1-modellen worden niet gebruikt.

## Afdaling, vlucht en camera

De baan begint op 82 meter hoogte. Eerst volgt 130 meter horizontale afdaling
met 79 meter hoogteverlies, daarna een oplopende schans van 60 meter. De totale
horizontale aanloop is 190 meter; over het gebogen oppervlak is de afstand groter.
Het monster staat 160 meter voorbij de afzet, op twee zichtbare breekbare torens.
De blokjesmonsters zijn 50% groter in breedte, hoogte en diepte. Blokken, noppen en
botsingsvlakken groeien mee; de draagplaat blijft op ongeveer dezelfde hoogte.

Tijdens het rijden en vliegen kijk je **vlak achter en boven het zitje**, vooruit
in de richting van het raketje. Zo zie je meer van je voertuig. De coureur wordt
voor deze camera verborgen. Na een treffer en de plons zie je de impact nog één
keer vanuit een camera schuin naast het monster, op grotere afstand. De replay
toont 0,8 seconde aanvlucht en 2,4 seconden na de eerste treffer, op 60% snelheid.
Met **Replay overslaan**, spatie of controllerknop A ga je direct verder.
Pauze werkt ook tijdens de replay. Een gemiste sprong krijgt geen replay.
Daarna volgt het overzicht voor de resterende puntentelling en beurtwissel.

| Bediening | Toetsenbord | Controller |
| --- | --- | --- |
| Gas / start vanaf stilstand | W / pijl omhoog | RT |
| Remmen | S / pijl omlaag | LT |
| Links / rechts sturen | A/D / pijltjes | Linkerstick |
| Boost op de baan | Shift | RB |
| Start of volgende poging | Knop op scherm / spatie | A |
| Aanloop opnieuw proberen | R, tijdens de aanloop | Y |
| Pauze | Escape / P | Start |

De automatische-gasinstelling wordt tijdens de aanloop gerespecteerd. Vanaf het
klaarstaande raketje is nog steeds een expliciete start nodig. R zet alleen een
nog lopende aanloop terug; schade en scores kunnen daarmee niet worden teruggedraaid.

Gas en remmen bepalen de afzetsnelheid en daarmee de vlieghoogte. De afdaling
geeft ook zonder gas vaart. Vol gas bereikt het doelwit normaal nog stijgend;
uitrollen geeft een lagere vlucht richting de steunen. Boost verandert de
vluchtbaan en kan je voorbij een lager deel van het monster laten vliegen.
Sturen vlak voor de afzet bepaalt de zijwaartse snelheid. In de lucht kun je naar links en rechts bijsturen;
loslaten remt de zijwaartse drift rustig af. De stuurkracht is 4,5 m/s² met een
richtsnelheid van maximaal 10 m/s opzij. De correcties blijven beperkt:
geen extra lift met W, geen luchtboost en geen automatische doelzoeker.

Af en toe kruisen vogels de vlucht. Een botsing geeft een kleine afwijking,
een piepje en sterretjes; de vogel herstelt en vliegt weg. Vogels leveren geen
punten op. Een gemiste sprong krijgt eenmaal een komisch **wie-wo-weeuh**-geluid.
Dit is een oorspronkelijk gesynthetiseerd glijfluitgeluid, geen opgenomen stem.
Geluidseffectvolume en dempen worden gerespecteerd; pauze bevriest ook vogels,
brokken en de eigen monstergeluiden.

## Spelregels

- **Solo:** versla het monster in zo weinig mogelijk sprongen. De uitslag toont
  je punten en aantal pogingen. Je blijft Boaz en kiest voor iedere sprong je raketje.
- **Twee spelers:** Boaz en Ravi spelen om de beurt op hetzelfde scherm, met
  hetzelfde toetsenbord of dezelfde controller. De bediening wordt pas
  doorgegeven nadat de raket en alle losse brokken in het water liggen.
- Vóór iedere sprong staan de zes beschikbare raketjes naast elkaar. Klik op
  een naam om dat voertuig direct te bekijken en druk op **Start afdaling**.
  Een volgend raketje staat alvast klaar, maar je mag ook hetzelfde kiezen.
  De voertuigen hebben voor deze modus
  dezelfde snelheids- en stuureigenschappen, onafhankelijk van garageaankopen.
- Elk **monsterblokje** dat volledig onder water verdwijnt levert 10 punten op.
  De torens en draagplaat zijn afbreekbaar, maar leveren zelf geen punten op.
- Losgeraakte onderdelen tellen voor degene die de instorting veroorzaakte.
  Een blokje kan maar eenmaal punten opleveren. Gaten blijven bestaan.
- Bij minimaal **70% van het oorspronkelijke monster** in het water eindigt
  de wedstrijd na de lopende sprong en het uitvallen van losse brokken.
- In een duel wint de hoogste score, niet automatisch de laatste aanvaller.
  Gelijke punten geven een gelijkspel. Er is geen extra gelijkmakende beurt.
- Het pauzemenu biedt hervatten, opnieuw beginnen met hetzelfde monster en
  spelersaantal en het hoofdmenu. Daaronder staan alle elf monsters in twee
  rijen met afbeeldingen. Een klik start dat monster met hetzelfde spelersaantal
  en een nieuwe puntentelling.

Een poging die in de aanloop langer dan 45 seconden blijft hangen, wordt als
mislukt afgesloten. Vluchten zijn begrensd op 16 seconden. De stand van een
wedstrijd wordt niet opgeslagen; garage, muntjes en racerecords blijven onafhankelijk.
De ingestelde lagere spelresolutie geldt ook voor deze modus.

## Aangeleverde bestanden bijwerken

De authoringbron staat in `assets/monters/monster-blokjes-10/json/` in de
repositoryhoofdmap. De bestaande spelling **monters** is behouden.
De game gebruikt eigen JSON-kopieën in `game/assets/monsters/` en leest tijdens
het spelen niets buiten het Godot-project.

```bash
python3 game/tools/sync_monsters.py
```

Dit controleert alle tien monsters voordat het runtimekopieën schrijft:
veilige en overeenkomende ID's, unieke gehele roosterposities, kleuren,
grondverbindingen via zes zijvlakken en maximaal 6.000 blokken. De catalogus
bevat gemeten bezette afmetingen en SHA-256 van de bronbytes. De bronbestanden
worden niet aangepast. Een bijgewerkt bestaand monster behoudt dezelfde ID.

Speel-, start- en hervatknoppen hebben een goudgele achtergrond met donkere
tekst. Ook de twee Monsterbreker-starttegels en de racetegel gebruiken die kleur.

De twee starttegels gebruiken ongewijzigde kopieën van de aangeleverde
Schouderreus- en Paars Spook-voorbeelden. De monsterkiezer rendert het echte
monster in een klein, eenmalig getekend viewport, inclusief de verfijnde GLB.

Import centreert X en Z op de vluchtbaan. Opgebouwde torens worden alleen aan
de runtimeconstructie toegevoegd: de originele monsterblokken en hun kleuren
blijven afzonderlijk herkenbaar voor de puntentelling. Een ongeldig bestand
geeft een melding en start geen kapotte wedstrijd.

## Technische indeling

| Bestand | Verantwoordelijkheid |
| --- | --- |
| `scripts/monster/catalog.gd` | Selecteerbare ID's en namen |
| `scripts/monster/models.gd` | Keuze tussen blokken en breekstukken |
| `scripts/monster/structure.gd` | JSON-validatie, centrering, torens, botsingen en verbindingen |
| `scripts/monster/fractured_structure.gd` | GLB-stukken, convexe treffervolumes, steunverbindingen en volumegewichten |
| `scripts/monster/arena.gd` | Helling, schans, water, blokken/noppen, brokken en plonseffecten |
| `scripts/monster/fractured_arena.gd` | Zichtbare GLB-stukken losmaken en laten vallen |
| `scripts/monster/mode.gd` | Solo/duo, rijden, vrije vlucht, cockpit, beurten, punten en uitslag |
| `scripts/monster/impact_replay.gd` | Begrensde visuele opname en vertraagde herhaling vanuit een externe camera |
| `scripts/monster/preview.gd` | Werkelijke blokmodellen in het keuzescherm |
| `scripts/monster/birds.gd` | Bewegende vogels, botsingen en herstel |
| `scripts/monster/sounds.gd` | Eigen glijfluit, vogelgeluid en lanceergeluid |
| `tools/sync_monsters.py` | Herhaalbare validatie en runtimekopieën |
| `tools/sync_fractured_monster.py` | Gifspuwer kopiëren en convexe botsingsvlakken afleiden |

De constructie gebruikt verbindingen via blokzijvlakken. Een losgeraakte groep
valt met behoud van zijn vorm onder zwaartekracht. Er zijn geen onderlinge
botsingen tussen brokken; vallende brokken veroorzaken dus niet zelfstandig
weer nieuwe schade. Blokken en noppen gebruiken MultiMesh; GLB's met duizenden
losse objecten hoeven niet te worden geladen. Een grove grens rond het doelwit
voorkomt dat de hele constructie tijdens ieder vluchtframe wordt doorzocht.
Kleine brokstukken vlak voor de cockpitcamera worden tijdelijk verborgen om
niet vanuit de binnenkant van zo'n blok te kijken; punten en grote brokken blijven gelijk.

De replay bewaart zichtbare geometrie en transformaties op 30 beelden per seconde,
met interpolatie tijdens het afspelen. Hij gebruikt de echte opgenomen bewegingen
van blokken en GLB-breekstukken. Tijdens het afspelen staat de spelsimulatie stil:
botsingen, schade, geluiden en punten worden niet opnieuw uitgevoerd. De opname
wordt bij iedere nieuwe sprong gewist.

## Verfijnde Gifspuwer

De bron staat in `assets/monters/gifspuwer-monsterbreker-test/`. Bronbestanden,
Blender-project en gif-effect blijven ongewijzigd. Alleen de GLB en `breekstukken.json`
worden naar `game/assets/monsters/gifspuwer-breekbaar/` gekopieerd:

```bash
python3 game/tools/sync_fractured_monster.py
```

Het script valideert de steunverbindingen en scoregewichten en genereert
`collision-planes.json` uit de geleverde lokale convexe botsingspunten, zonder
extra Python-pakketten. Een bronhash voorkomt gebruik van verouderde botsingsvlakken.
De game laadt de GLB via Godots normale import, ook bij export van het spel.
De twee gedeelde materialen krijgen lokale overrides met vertexkleuren aan:
deze Godot-import schakelt die anders voor het buitenmateriaal uit omdat enkele
primitives geen kleurattribuut hebben. De gecachte import wordt niet gewijzigd.

Het 5 meter hoge bronmodel wordt uniform achtmaal vergroot tot 40 meter hoogte.
Het staat gecentreerd op de vluchtbaan, met de voeten op de breekbare draagplaat.
Bekanker, pivots, treffervolumes en zichtbare stukken krijgen dezelfde transformatie.
Treffers gebruiken het hele afgelegde segment, afgeknipt tegen convexe vlakken
die met de raketradius zijn verruimd. Dit is bij scherpe hoeken iets ruimer dan
een exacte bolbotsing, maar slaat dunne stukken bij hoge snelheid niet over.

Na een treffer zoekt de game vanaf de overgebleven voeten naar ondersteunde
stukken. Een voet heeft alleen steun zolang zijn ankerblok in de draagplaat
aanwezig is. Geraakte en niet langer ondersteunde stukken vallen afzonderlijk;
dezelfde aanvaller krijgt hun punten. De stukken gebruiken de bestaande
voorspelbare valbeweging: geen onderlinge botsingen, rotatie of kettingschade.
Pauze bevriest deze beweging. Verwijderde stukken blijven weg tot een nieuw spel.

Pas wanneer het hele zichtbare stuk onder water is, telt het aangeleverde
`scoreWeight` mee. De gewichten zijn met grootste-restafronding verdeeld over
precies **10.000 punten**. Torens leveren nul punten op. Bij minstens **7.000 punten**
in het water eindigt de wedstrijd na het uitvallen van alle brokken; in een duel
wint de hoogste score. Dit wijkt bewust af van het bronvoorstel om al bij losbreken
te scoren en bewaart de bestaande waterspelregel.

Het optionele gif-effect is niet geïmporteerd. De kleine opening in `leg_lf_001`
en de zichtbare shadingnaden zijn eigenschappen van de aangeleverde mesh;
de gesloten convexe treffervolumes zijn daarvan onafhankelijk.

## Controles

```bash
XDG_DATA_HOME=/tmp/boracart-prototype-test/data \
XDG_CONFIG_HOME=/tmp/boracart-prototype-test/config \
godot --headless --audio-driver Dummy --path game --script tests/monster_breaker.gd
```

`tests/impact_replay.gd` controleert echte treffers op een blokjesmonster en de
verfijnde Gifspuwer: opname, camerahoek, vertraging, pauze, overslaan, hervatten,
ongewijzigde schade en punten, missers en beurtwissel. Deze test draait ook via
`tools/check.sh`. Voeg bij een grafische test `-- --visual` toe voor screenshots
in `/tmp/boracart-impact-*.png`.

Deze suite staat ook in `game/tools/check.sh`. Ze controleert alle imports,
steunen, snelle botsingen, echte startscherm-/toetsinvoer, de cockpitcamera,
beperkte luchtbesturing, missers, vogelbotsingen, solo-uitslag, duowinnaar,
pauze, opnieuw starten, racevoortgang en een complete sprong op ieder
geleverd monster. Voertuigkeuze, de monstertegels in pauze, de grotere blokken
en luchtcorrecties worden ook gecontroleerd. Een solo-overwinning wordt met echte stuur- en gasinvoer
in de simulatie bereikt, zonder blokken voor die overwinning te verwijderen.

De normale racebediening, resolutie-instelling, interface-indeling,
startschermbediening en smokecontrole worden apart gecontroleerd.
Zie [lokale uitvoer](../validation/monster-prototype-checks.txt).
Dit is gerichte validatie; de volledige historische suite is hiervoor niet opnieuw gedraaid.

De aparte `tests/fractured_monster.gd` staat ook in `game/tools/check.sh` en
controleert alle 76 pivots en snelle treffers, gedeeltelijke schade, instorting,
toewijzing aan twee spelers, eenmaal scoren na onderdompeling, een volledige
gewone sprong, pauze, uitslag en opnieuw beginnen. Uitvoeren:

```bash
XDG_DATA_HOME=/tmp/boracart-fractured-test/data \
XDG_CONFIG_HOME=/tmp/boracart-fractured-test/config \
godot --headless --audio-driver Dummy --path game --script tests/fractured_monster.gd
```

`tests/fractured_monster_visual.gd` maakt beelden van selectie, intact model,
aanvliegroute, schade, instorting en uitslag in `/tmp/boracart-gifspuwer-visual/`.
Gebruik dezelfde softwareweergave-instellingen als bij de onderstaande native captures.
Zie de [lokale resultaten en beoordeelde beelden](../validation/gifspuwer/README.md):
479 nieuwe controles, 168 bestaande Monsterbreker-controles en 33 layoutcontroles
slagen. Een complete solo-overwinning lukt met twee gewone, gerichte uitrolsprongen.
De bredere race-smokecheck meldt één fout in de bestaande wegprofielverwachting
voor de vlakke Uithoorn-baan; die test en racecode vallen buiten deze wijziging.

Controle van de wijzigingen van 14 november 2026:
[testuitvoer](../validation/monster-kids-checks.txt),
[voertuigkeuze](../validation/monster-vehicle-choice.png),
[zicht tijdens de afdaling](../validation/monster-visible-vehicle.png),
[voertuig en groter monster tijdens de vlucht](../validation/monster-air-steering-view.png),
[monstertegels in pauze](../validation/monster-pause-tiles.png) en
[gekozen garagevoertuig naast de coureurs](../validation/garage-selected-vehicle.png).
De beelden zijn lokaal met softwareweergave gecontroleerd; het rijgevoel met
een fysieke controller moet nog door de spelers worden beoordeeld.

Native beelden en het misgeluid genereren:

```bash
__GLX_VENDOR_LIBRARY_NAME=mesa LIBGL_ALWAYS_SOFTWARE=1 \
XDG_DATA_HOME=/tmp/boracart-prototype-visual/data \
XDG_CONFIG_HOME=/tmp/boracart-prototype-visual/config \
godot --audio-driver Dummy --path game --script tests/monster_visual.gd
```

De softwareweergave omzeilt de lokale OpenGL-driverfout zonder systeemdrivers
te wijzigen. De capture schrijft naar `/tmp/boracart-monster-prototype/`.
Het startscherm wordt zonder de 3D-achtergrond vastgelegd; gameplaybeelden
gebruiken 50% 3D-resolutie met scherpe interface. Dit is geen meting van
prestaties op de echte GPU. Fysieke controllerbediening en het rijgevoel
blijven onderdeel van een menselijke speelsessie.

Beoordeelde voorbeelden: [startscherm](../validation/monster-prototype-splash.png),
[monsterkeuze](../validation/monster-prototype-selection.png),
[afdaling vanuit het zitje](../validation/monster-prototype-downhill.png),
[vrije vlucht](../validation/monster-prototype-flight.png).
[Luister naar het misgeluid](../validation/monster-prototype-miss.wav).
