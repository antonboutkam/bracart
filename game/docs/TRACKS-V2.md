# Twaalf circuits in zes landschappen

De zes oorspronkelijke circuits blijven selectie 0–5. Selectie 6–11 bevat
hetzelfde zestal landschappen als **Versie 2**, met aparte stabiele `-v2` IDs en
records. De wereldkeuze toont twee versieknoppen boven hetzelfde raster met zes
kaarten. HUD, uitslag en herstart gebruiken de gekozen circuitnaam en versie.

`Catalog.WORLDS` blijft de zes landschappen beschrijven. `Catalog.TRACKS` koppelt
iedere selectie aan `world` en `variant`. `Main.track_index`/`Track.track_index`
zijn de twaalf selecties, `world_index` blijft 0–5 voor landschap, weer en audio.
Nieuwe records komen op de whitelist via dit register. SAVE_VERSION blijft 3:
bestaande voertuigkeuzes, munten, instellingen en records krijgen geen nieuwe
voertuig-defaultmigratie. Oude numerieke recordkeys blijven uitsluitend 0–5.

## V2 route en stunts

`worlds/stunt_course_v2.gd` bezit de nieuwe routes. Iedere V2-route wordt op
werkelijke gesamplede booglengte gekalibreerd naar driemaal de bronlengte. Voor de
keuken telt de bestaande originele looping al mee in die bronlengte. De routes
hebben een eigen verhouding van lange/brede zijden; twee vrije baanstukken
ontlenen hun bochtenprofiel aan de originele controlepunten. Het zijn bewust
nieuwe, bronafgeleide circuits, geen exacte kopieën van alle originele bochten.

Dezelfde modulaire stuntcontracten geven ieder landschap:

- Een verticale looping met echte inversie en gescheiden in-/uitgang.
- Een ruimtelijke helix met volledige bankrol als kurkentrekker.
- Een rechte afdaling van 38 meter over ruim 150 meter baan.
- Twee kleine schansen en één megaschans, met drie echte wegonderbrekingen.
- S-bochten en landschapafhankelijke bochten op de vrije stukken.

De originele `routes.gd` en `kitchen_course.gd` blijven ongewijzigd. V2 gebruikt
kleine samples met analytisch stabiele assen en interpolatie van volledige
frames. De road-/randmeshes volgen per circa 65 cm in plaats van een vast aantal
segmenten per hele baan. De camera gebruikt de werkelijke voortgangsframes en
zoekt alleen nabijgelegen baanframes, zodat de verkeerde kant van een looping
niet als camerapositie wordt gekozen.

De bestaande arcadebesturing blijft afstand over de route sturen. In een V2-gap
volgt de coureur een onzichtbare Hermite-vluchtgeleiding boven echte lege ruimte,
met een extra sin²-luchtboog. Extraheffing en eerste afgeleide zijn nul bij lip en
contact. Dit houdt opstijgen en landen continu bij langzaam rijden, normaal gas
en boost. Er klinkt één landingsevent op de werkelijke landingsbaan. Het is
geleide arcadefysica, geen vrij ballistisch voertuigsysteem.

## Omgeving en schaal

Voertuigen, coureurs, huizen en huishoudobjecten worden niet geschaald. Nabije
objecten worden langs de nieuwe route geplaatst; stuntzones blijven vrij van
huizen, objecten en vaste tunnelbogen. Achtergrondringen staan bij V2 buiten de
nieuwe baanvoetafdruk. Er worden geen generieke steunpalen door inversies
gebouwd. De V2-keukentafel krijgt gericht een groter blad en buitenliggende
stoelen. De originele keuken, props en kamer blijven op hun bestaande posities.
Munten blijven op afstand verdeeld; V2-powerups behouden circa 95 meter afstand
per groep, zodat een langere route geen langere lege stroken veroorzaakt.

## Herhaalbare controle

Start vanuit `game`, met een geïsoleerde XDG_DATA_HOME:

```sh
godot --headless --path . --script tests/tracks_v2.gd
godot --headless --path . --script tests/tracks_v2_flight.gd
godot --headless --path . --script tests/tracks_v2_ui.gd
godot --headless --path . --script tests/tracks_v2_clearance.gd
python3 tools/capture_step.py --step stap-21-tracks-v2
```

`tracks_v2.gd` vergelijkt de originele zes routes met de vóórwijzigingssnapshot,
meet nieuwe lengtes/frames/seams/stunts en rijdt echte `Race.step`-races met
speler en vier AI in alle zes V2-landschappen. Het profiel wordt echt opgeslagen
en opnieuw geladen met zowel oude als nieuwe records. De afzonderlijke
vluchtcheck rijdt alle drie gaps bij 5, 12, 40, 46 en 66 m/s, controleert doorlopend
luchtstatus en landingsevents, en meet de nulovergang aan het einde.

De UI-check activeert echte selectie- en herstartknoppen voor alle twaalf
circuits en controleert de pauze. De clearancecheck vergelijkt de
stuntcorridors met werkelijk gegenereerde primitive-meshgrenzen: 81 posities per
stunt, drie rijderpunten over de baanbreedte en één analytisch camerapunt. Deze
aanvulling controleert geen volledige bewegende voertuigvolumes, MultiMeshes,
ArrayMeshes of de daadwerkelijk gedempte camera. Het is een conservatieve
punt/omgevingscontrole, geen volledige fysieke collision-engine.
Native bewijs bevat twee selectieschermen, zes technische overzichtscamera's en
acht echte auto-drive/racecamera-opnames per V2, vanaf de startgrid door de
stunts. De overzichtscamera vermindert alleen voor het overzicht de mist; de keuken
krijgt een verticale overzichtscamera binnen de kamer, onder het plafond. De
racecamera gebruikt de spelinstellingen. Het zijn screenshots, geen opgenomen
volledige racevideo en geen bewijs van handmatige klantacceptatie.
