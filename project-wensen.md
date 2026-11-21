# BoRacer — projectvisie, wensen en ontwerpuitgangspunten

> **Status:** werkdocument, opgesteld uit de gesprekken en visuele ontwerpiteraties. Dit document beschrijft de wensen van de opdrachtgever en is bedoeld als context voor Codex en de ontwikkeling in Godot. Waar een keuze nog niet vaststaat, is dat aangegeven.

## 1. Kernconcept

**BoRacer** (in gesprekken ook *BoRacart* of *Boracer* genoemd) is een kleurrijk, speels 3D-arcaderacespel met **Boaz en Ravi** in de hoofdrol. De inspiratie komt van de echte **raketfiets** waarmee de kinderen rondrijden en van spectaculaire kart- en speelgoedracebanen zoals Mario Kart en Hot Wheels.

De ervaring moet vrolijk, snel, fantasierijk en toegankelijk zijn, met uitgesproken personages, verzamelbare muntjes, power-ups, spectaculaire banen en werelden die ieder een eigen identiteit hebben.

Het spel wordt ontwikkeld in **Godot**; **Codex programmeert al aan de game**. De gemaakte afbeeldingen zijn zowel conceptuele referenties voor Codex als uitgangspunt voor daadwerkelijke game-assets.

## 2. Visuele identiteit

- **Stijl:** gestileerde 3D-gamegraphics, cartoonesk/stripachtig, heldere silhouetten, afgeronde vormen, levendige kleuren, glanzende materialen en een lichte retro-kermisuitstraling.
- **Sfeer:** een mengeling van nostalgische kermis, futuristische races, speelgoedachtige voertuigen en cinematografische belichting; soms donkerblauwe achtergronden met oranje, blauwe en neonaccenten.
- **Referentie:** de eerder ontworpen BoRacer-splash, UI-boards, racebeelden en wereldreferentiebladen vormen de visuele basis. De stijl moet consistent blijven tussen gameplay, garage/store, menu's en werelden.
- **Logo:** herkenbare, dynamische tekst **BoRacer** met snelheid, vlammen en racegevoel. Voor overlays is een vrijstaand logo met transparante achtergrond gewenst.
- **Perspectief:** in-game camera laag achter het voertuig, met sterke dieptewerking en zicht op de baan die ver de wereld in loopt. Het beeld moet aanvoelen als een echte racescène, niet als een los baantegeltje.

## 3. Personages: Boaz en Ravi

Beide jongens zijn blond en moeten herkenbaar blijven op basis van de aangeleverde foto's en goedgekeurde character sheets.

### Boaz

- Blauwe ridderoutfit met gouden accenten en cape.
- Vrolijke, expressieve cartoonvormgeving.
- Kenmerkend detail: Boaz is tanden aan het wisselen en mist zichtbaar enkele tanden; dit hoort bij zijn herkenbare glimlach.

### Ravi

- Groene hoofdband met veer, groene outfit/vest en blauwe broek volgens zijn characterreferenties.
- Speelse, energieke uitstraling.

### Consistentie en animatie

- Per personage een **turnaround** met vooraanzicht, driekwart links, zijaanzicht, achteraanzicht en driekwart rechts.
- Character sheets liefst op **eenvoudige witte achtergrond**: zakelijk, duidelijk en zonder overbodige decoratie.
- Consistente verhoudingen, kleding, belichting en camerahoeken.
- Expressies zoals neutraal, blij, hard lachen, schrikken, boos, verdrietig, zelfverzekerd, geraakt, plagen, juichen, vieren en gespannen.
- Bewegingsreferenties voor sturen, accelereren, remmen, boost, springen, landen, botsen, power-up gebruiken, winnen en verliezen.
- Voor de daadwerkelijke game kunnen 3D-personages met rig en animaties worden ingezet; de precieze implementatie ligt bij de ontwikkeling.

## 4. Voertuigen: de raketjes

Het kenmerkende voertuigtype is een **kleine, open, raketvormige racekart**. De echte raketfiets is het belangrijkste visuele anker.

### Originele raketfiets

- Turquoise/blauwe afgeronde carrosserie en lange spitse neus.
- Gele strepen op de neus.
- Rode cockpit/zitkuip en rugdeel.
- Roze zijbies, witte/chroomkleurige onderrand.
- Zwart buizenframe, wielconstructie en herkenbare mechanische onderdelen.
- Het voertuig moet herkenbaar zijn als de oorspronkelijke raketfiets, niet slechts als een generieke raket.

### Voertuigcollectie

Er is een winkelconcept met **12 verschillende raketjes**. Uitgewerkte varianten omvatten onder andere:

- **1 — De Raketfiets:** het oorspronkelijke blauw-rode voertuig.
- **3 — Cosmic Purple / Purple Passion:** paars met gouden sterren en accenten.
- **8 — Golden Rocket:** goudgeel met donkere steremblemen.
- **9 — Toxic Turbo / Neon Biohazard:** zwart en felgroen, gifvlekken en biohazardmotief.
- **10 — Retro Racer:** oranje/crème, vlammen en racenummer 8 op de referentieafbeelding.
- **11 — Rainbow Jet:** regenboogkleuren, witte sterren en kleurrijke vinnen.

De overige ontwerpen zijn zichtbaar in de eerdere store-concepten; hun definitieve 3D-specificaties moeten afzonderlijk worden vastgelegd.

### 3D-assets

- **`.glb` (glTF 2.0)** is het gewenste uitwisselingsformaat voor Godot.
- De modellen moeten bij voorkeur modulair en in Blender later te bewerken zijn: carrosserie, neus, zitting, wielen, frame, motor, vinnen, vlag, verlichting en accessoires als afzonderlijke objecten.
- De referentiebeelden bevatten voor-, zij- en achteraanzichten; ze zijn een hulpmiddel voor reconstructie, geen exacte 3D-scans.
- Tijdelijke voertuigupgrades, zoals uitschuifbare kanonnen, moeten aan het model toegevoegd kunnen worden.

## 5. Gameplay

- Arcaderacen met meerdere racers en een duidelijk zichtbare **positie/ranking**.
- Muntjes hangen boven de racebaan en kunnen worden verzameld.
- Power-ups en verrassingsobjecten, in de geest van Mario Kart.
- Een power-up kan bijvoorbeeld **tijdelijke kanonnen** op het raketje activeren, waarmee de speler kan schieten.
- Andere visueel verkende power-ups: raketten, bommen, schilden, snelheidsboosts en magneten. Definitieve balans, aantallen en werking zijn nog niet vastgelegd.
- Snelheid, acceleratie/boost, rondes en racepositie moeten tijdens het rijden duidelijk afleesbaar zijn.
- Het spel moet speels en toegankelijk zijn; exacte besturingsmethode en physicsparameters zijn nog te bepalen.

## 6. Racebanen en camera

### Geometrie

- **Brede, komvormige banen**: het rijvlak is een vloeiende geul/halfpipe met oplopende zijkanten, zodat sturen gemakkelijker en intuïtiever wordt.
- Grote variatie in hoogte: vlak, licht en sterk stijgend, licht en sterk dalend.
- Lichte en scherpe bochten, extreme hellingen, loopings, spiralen en grote trechters.
- Het wegdek moet niet voelen als een smalle strook; de speler moet echt **in** de baan kunnen rijden.
- De baan loopt vanuit de camera door in de verte met sterke perspectiefwerking; de voorgrond mag niet eindigen in een zichtbare 'start' van een los wegstuk.
- Referentiebeelden tonen first-person of lage achter-de-kart-perspectieven, spectaculaire diepte en baanconstructies hoog boven het landschap.

### Uiterlijk

- Futuristisch, maar passend bij de gekozen wereld.
- Eerdere experimenten met rode/witte strepen, witte middenlijn en losse lampjes zijn **afgewezen** voor het generieke baanontwerp.
- Liever een schoon, breed rijoppervlak, geïntegreerde subtiele kleur-/lichtaccenten en goed leesbare randen.
- De visuele sfeer uit de BoRacer-referentiebeelden blijft belangrijk.

### Technische aanpak

Er is geëxperimenteerd met een **5×5 raster** van hellingen en stuurhoeken. Daarbij werd vastgesteld dat:

- Eerst één perfecte in-game referentie van een vlakke rechte baan maken beter werkt dan meteen 25 varianten genereren.
- Linker- en rechterbochten in symmetrische gevallen gespiegeld kunnen worden.
- Losse perspectivische PNG's geen garantie bieden op naadloos aansluitende geometrie.
- Een echte 3D-baan in Godot (eventueel procedureel opgebouwd) logischer is voor loopings, trechters en vloeiende overgangen. De afbeeldingen dienen dan als **visuele specificatie** voor Codex.

## 7. Racewerelden

De wereldontwerpen hebben een gedeelde BoRacer-vormtaal, maar elk een eigen materiaal-, kleur- en omgevingsidentiteit.

### 7.1 Sunset Park / Kermiswereld

Een kermisachtige wereld bij zonsondergang met reuzenrad, achtbanen, kust/eilanden, spectaculaire loopings, bruggen en warme roze-oranje luchten. De eerste BoRacer-sfeerbeelden zijn hiervoor de hoofdreferentie.

### 7.2 Neon City

Een futuristische nachtstad met neon, hoge gebouwen, hologrammen, verhoogde routes, tunnels en kleurrijke lichtaccenten. De wereld is spectaculair en energiek.

### 7.3 Regenbogenrijk

Een lichte, magische luchtwereld met grote zachte wolken, regenbogen, warme zonnestralen, schaarse groene zwevende eilandjes, bloemen en watervallen. Het wegdek is parelmoerachtig en soms **gedeeltelijk aan het zicht onttrokken door wolken**; de route moet wel eerlijk en herkenbaar blijven. Kenmerkende secties: Zonnepoort, Wolkenslinger, Regenboogtunnel, Verborgen Weg, Groene Hemeltuinen, Gouden Afdaling en Hemelspiraal.

### 7.4 Haarlem 1888 — De Grote Stoomrace

Vrolijke, optimistische **steampunk**-versie van historisch Haarlem. Herkenbare locaties: Grote Markt, Sint-Bavokerk, Spaarne, oude straatjes en molen De Adriaan. Koper, messing, hout, klinkers, tandwielen, stoomleidingen, luchtschepen en beweegbare bruggen. Kenmerkende routes: Gouden Straatjes, Mechanische Grachten, Grote Sprong en Ondergrondse Ketelfabriek. Interactieve elementen kunnen per ronde veranderen.

### 7.5 Uithoorn 2056 — De Amstel van Morgen

Een zonnige, optimistische **solarpunk/retrofuturistische** versie van Uithoorn, nadrukkelijk geen donkere cyberpunk. De Amstel, oude dorpsgevels, Thamerkerk en Uithoornse brug blijven herkenbaar, aangevuld met groenbegroeide gebouwen, zonnepanelen, holografische bewegwijzering, autonome watertaxi's, drijvende platforms en dynamische futuristische bruggen.

### 7.6 De Keukentafel

Een miniatuurracewereld op één **overvolle echte keukentafel**. De racers zijn speelgoedklein en rijden rechtstreeks over het **tafelblad**, zonder apart asfaltwegdek. De rommel is het landschap; vrijwel geen hoogteverschillen, maar wel scherpe bochten, slaloms en obstakels.

Belangrijke objecten:

- Computermonitor en desktop, beamer en verticale maphouder met enveloppen.
- Dupont-kabels met elastiek, ESP32, weerstanden in zakjes, USB-/meetkabels en PVC-stukjes.
- Open glazen potjes met schroeven, balletjes, kunststofonderdelen of leeg.
- Groene pet met witte **L**, zwarte ninjaband met **Ravi**, telefoon op kassabon, leesbril, schaar, plakbandrollen en pillenstrips.
- Megafoon op een kindertekening.

De omgeving moet warm, huiselijk, herkenbaar en enigszins chaotisch zijn. Voorwerpen zijn licht gestileerd, maar behouden geloofwaardige materialen. Kabels en voorwerpen vormen natuurlijke baanbegrenzing. De schaalverschillen moeten humoristisch en spectaculair voelen.

> **Bronnen:** voor Regenbogenrijk, Haarlem 1888, Uithoorn 2056 en De Keukentafel bestaan afzonderlijke uitgebreide Markdown-stijlbeschrijvingen. Die documenten blijven leidend voor de details van de betreffende werelden.

## 8. Game-interface (UI/UX)

De interface heeft een dynamische, arcadeachtige uitstraling met donkerblauwe panelen, afgeronde knoppen, contrastrijke gele/oranje accenten, heldere typografie en gestileerde icoontjes.

### Schermen

- Splash-/startscherm met BoRacer-logo en hoofdpersonages.
- Hoofdmenu en wereld-/baanselectie.
- Karakter- en voertuigselectie.
- **Store/garage** met 12 raketjes, eigendomsstatus, prijzen in spelmuntjes, voertuigstatistieken en selectie/koopactie.
- Instellingen: bijvoorbeeld muziek, geluid, besturing en beeld.
- Pauzemenu.
- Resultaten-/podiumscherm.

### In-game HUD

- **Ranking/positie** en eventueel overzicht van overige racers.
- **Snelheid** en visuele **acceleratie/boost-indicator**.
- **Ronde-informatie**, rondetijd en totale tijd.
- **Rondekaart/minimap** met voertuigposities en route.
- Beschikbare power-ups en muntjes.

De HUD moet goed leesbaar blijven bij hoge snelheid en de raceactie zo min mogelijk afdekken.

## 9. Workflow met Codex en Godot

- Codex is verantwoordelijk voor de programmeerimplementatie; dit document dient als ontwerpcontext en eisenoverzicht.
- Conceptafbeeldingen, turnarounds en technische referentiebladen zijn communicatiemiddelen voor Codex.
- 3D-modellen worden waar mogelijk als `.glb` aangeleverd, bij voorkeur met logisch benoemde losse onderdelen.
- Voor visuele consistentie worden eerst masterreferenties goedgekeurd en daarna varianten of animaties afgeleid.
- Bij grote ontwerptaken werkt een **iteratieve aanpak**: één stap opleveren, feedback vragen, pas daarna doorgaan.
- Afbeeldingen met AI-gegenereerde maten, tekst of schema's zijn **conceptueel**; exacte afmetingen, aansluitpunten en fysische eigenschappen moeten in Godot of een technische specificatie worden vastgelegd.

## 10. Nog niet definitief besloten

- Definitieve besturing (toetsenbord/controller/touch/tilt), doelplatformen en prestatiebudget.
- Exacte physics, maximumsnelheden, boostmechaniek en gedrag in loopings.
- Definitieve regels voor multiplayer, AI-tegenstanders en moeilijkheid.
- Economie van de store: muntwaarden, vrijspeelvoorwaarden en definitieve prijzen.
- Exacte aantallen en balans van power-ups.
- Definitieve afmetingen, rigs, animaties en collision shapes van voertuigen en personages.
- Welke decorstukken statisch zijn en welke interactief.

## 11. Prioriteiten

1. **Herkenbare BoRacer-identiteit** met Boaz, Ravi en de originele raketfiets.
2. **Spectaculaire, goed bestuurbare 3D-banen** met komvormig profiel en overtuigende diepte.
3. **Consistente visuele assets** die Codex rechtstreeks als referentie of als GLB in Godot kan gebruiken.
4. **Zes onderscheidende werelden** met herkenbare omgevingsdetails.
5. **Duidelijke arcadegameplay en HUD**, inclusief ranking, snelheid, rondes, muntjes en power-ups.

---

*Dit document is een samenvatting van ontwerpwensen, geen garantie dat alle genoemde onderdelen al in de game geïmplementeerd zijn.*
