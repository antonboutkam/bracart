# Keukentafel — route, lus, sprongen en PVC-effect

Overdracht Sem Jansen (GD-005), 17 oktober 2026. Alleen wereld 5 gebruikt
`worlds/kitchen_course.gd`; werelden 0–4 behouden de bestaande route-, simulatie-
en camerabranches. Ruben bezit de huishoudprops, holle buizen en gedragen
aanlopen/boek-/kaartoppervlakken. Root/Eva verzorgen onafhankelijke QA en captures.

`track.kitchen_course` bezit de eigen arc-lengthtabel en gesamplede Curve3D.
De bestaande `track.frame(distance)`, `position_at(distance,lateral,lift)` en
`length` blijven de publieke interfaces voor racers, AI, pickups en minimap.
`track.kitchen_features()` en metadata `kitchen_features` geven zes dictionaries:

| id | Betekenis en extra velden |
|---|---|
| `toilet_rolls` | Twee rollen, `entry_start`, `plateau_start`, `plateau_end`, `entry_end`, `inner_radius`, `outer_radius`, `axis_height` |
| `loose_cables` | Kabelpassage, `clearance` |
| `orange_loop` | Werkelijke 360°-lus, `radius=9`, `exit_shift=22` |
| `pvc_rainbow` | PVC-passage met dezelfde doorsnedevelden als de toiletrollen |
| `comic_ramp` | Stripalbum-schans, `lip`, `landing`, `start_frame`, `lip_frame`, `lead_length` |
| `card_ramp` | Speelkaart/Jenga-schans met dezelfde rampvelden |

Alle features hebben `start/end` als echte course-progress, `center` en `mid`
als middenprogress, `frame`, `width=14`, `half_width=7`, `height` en
`road_surface_height`. Bij schansen beschrijft `frame` het midden van de klim,
niet het midden van de vlucht. `length` bij die schansen is de afstand tussen
start en lip; `end/landing` sluit ook de virtuele vluchtgids in.

De lus is een oranje plastic ribbon met onderzijde, dikte en opstaande randen.
Het verloop wordt echt gevolgd: auto's en zittende coureurs rijden verticaal en
ondersteboven. Een zijwaartse helix van 22 meter scheidt ingang en uitgang;
een geleidelijke terugkeer sluit weer aan op het oorspronkelijke tafelparcours.
De hoogste lusweg is circa 18.12 meter. De analytische referentie-as blijft op
verticale punten bruikbaar; de code kruist de verticale rijrichting daar niet
met world-UP. Arc-lengthinterpolatie geeft orthonormale, doorlopende frames.

De keuken-camera gebruikt de actuele raceprogress en lokale baanassen, ook
wanneer de auto ondersteboven rijdt. Hij gebruikt voor deze wereld geen
`curve.get_closest_offset()` die een andere lussectie kan kiezen. Binnen de lus
zijn afstand en lokale hoogte begrensd. Een aanvullende lokale 3D-routequery
houdt de camera minstens 0.78 meter boven het nabije wegvlak; de oude vlakke
curve-offset kan hiervoor niet worden gebruikt. Buiten de lus blijft de keuken-camera
boven de rijder met zicht vooruit. De overige vijf camerabranches zijn behouden.

Bij beide buistypen ligt het rijvlak op 5.3. De toiletrollen hebben ashoogte
13.3, binnenradius 12.4 en buitenradius 13.2. De PVC-buis heeft ashoogte
16.4, binnenradius 15.5 en buitenradius 16.3; deze ruimere doorsnede houdt ook
de gekromde aanloop en afloop bij de fysieke mond vrij over de volle rijbreedte.
De buitenkant rust bij beide op tafelhoogte 0.1. De circa 15 meter lange aanloop en afloop sluiten soepel aan
op tafelvloer 0.12. Ruben levert hiervoor echte ondersteunende geometrie;
alleen een verhoogde virtuele route zou onvoldoende zijn.

De stripalbumlip ligt op 3.3 en de kaartlip op 2.5. Zodra een echte racer een lip
passeert, zet Race voor speler én AI `jump_velocity=5` en `jump_height=0.02`.
De bestaande zwaartekracht 16 verwerkt vervolgens de sprong. Een doorlopende
virtuele vluchtgids helpt de guided arcade-auto zonder teleport terug naar de
tafel; tijdens het gat staat geen wegmesh onder de auto. De schansoppervlakken
van Ruben volgen het werkelijke klimprofiel. Dit is guided arcadegedrag, geen
losse rigid-body-autosimulatie.

`track.kitchen_rainbow` / `Track/KitchenRainbow` biedt:

- `update_player(progress,active=true)`: uitsluitend de actuele spelerprogress
  wordt door Main aangeboden. AI-progress activeert de tunnel niet.
- `advance(delta)`: verwerkt de expliciete tijd en fade; `inside`, `opacity`,
  `target` en `elapsed` zijn beschikbaar voor QA en geënsceneerde review.
- PVC-zone is inclusief `start/end`. Opacity gaat in een halve seconde naar 0 of 1.
  Shaderfase draait met 0.085 cycli/seconde; maximale alpha is 0.24.

De regenboog volgt de rechte fysieke PVC-as, met radius 14.9 en asoffset 11.1
boven de wegvloer. De PVC-correctie wijzigt uitsluitend doorsnedemetadata en
effectgeometrie: routepunten, frames, afstandstabel en lengte blijven identiek.

De shader gebruikt geen `TIME`. Track-processpauze stopt de klok en hervatten
telt alleen nieuwe framedelta. Verlaten van de PVC-zone laat het effect zacht
verdwijnen. De node en zijn vaste mesh verdwijnen bij wereldwissel.

Eigen headless Godot 4.7.2-controles: **kitchen_course 15209/0**,
**world_geometry 53909/0**, **smoke 162/0**, **follow_camera 1464/0**. De nieuwe checks gebruiken alle zes
echte voertuigen, omgekeerde camera, launch/landing van vijf racers, volledige
wegbreedte boven tafel, positieve binnenstrookmetriek, 3D-clearance 18.3 meter,
shaderklok/pauze en cleanup. Een extra fijnmazige test controleert de echte
buisdoorsnede over volledige aanloop en afloop, bij drie rijstroken en vier
carrosserie-/camerahoogtes; de polygonale binnenwand krijgt 5 cm veiligheidsmarge. De oude vlakke-keukenverwachtingen zijn uitsluitend
voor wereld 5 aangepast. Observaties en hashes staan in
`validation/kitchen-course-sem-checks.txt`.

Deze technische controles zijn geen native beeldreview. Werkelijke beelden,
onafhankelijke routebaseline 0–4 en de volledige fysieke prop-/cameracorridor
worden afzonderlijk door root/Eva gecontroleerd.
