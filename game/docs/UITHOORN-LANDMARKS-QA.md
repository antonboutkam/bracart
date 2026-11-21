# Uithoorn landmarks — onafhankelijke QA

**Oordeel: geslaagd voor lokale oplevering**, 18 oktober 2026, Eva Meijer
(GD-006). Definitieve native run: **20261018T142424-440362Z**, centraal onder
`renders/GAME-10001/stap-25-uithoorn-landmarks/`. Geen klantacceptatie of
uitbetalingsbesluit. Daan reviewt Eva's eigen QA-bewijs/vergoeding.

## Visueel oordeel

Alle **38 echte Godotbeelden** van de definitieve run daadwerkelijk bekeken:
12 studioaanzichten (voor/achter van alle zes modellen), 12 wereldbeelden,
12 gewone racecamera's en 2 overzichten. Alle beelden zijn 1280×800;
capture compleet met 38/0, exit 0. De drie kritische racebeelden
Schanskerk-v1, Hoeksteen-v1 en Hoeksteen-v2 zijn daarnaast afzonderlijk op
volledige resolutie geopend. Geen pauzemodal of onbedoelde viewportwisseling.

Alle zes modellen hebben herkenbare driedimensionale massa's en materialen.
Vergeleken met 18 daadwerkelijk bekeken aangeleverde foto's/luchtbeelden/
schetsen: Rechthuis met schilddak/dakkapellen/luiken/terras; Schanskerk met
twee vierkante torens en lang schip; laag Fort met groen dek en ronde
betonnen geschutsvorm; Irenebrug met dek/relingen/bedienhuis; Thamerkerk met
zaalkerk/portico/dakruiter; Hoeksteen met modern raster/glas en rode details.
Dit zijn vrije game-interpretaties, geen bouwkundig opgemeten reconstructies.

De gewone racecamera's tonen alle zes als decor in beide varianten. Sommige
klassieke gebouwen zijn klein en gedeeltelijk door baanrand, steunpaal of HUD
afgedekt. De Schanskerk heeft nu zichtbaar lang schip en dubbele torens links;
Hoeksteen heeft zichtbaar glasraster/zijgevel rechts. Irenebrug toont dek en
relingen onder de minimap. Detailinspectie hoort bij de aparte studio- en
omgevingbeelden. Dit bewijs garandeert geen voortdurend volledig zicht vanaf
iedere rijpositie, weersituatie of schermverhouding. Overzichten tonen de
samengestelde wereld met atmosferische mist.

## Techniek, bronnen en afleverbestanden

- Zelf uitgevoerde definitieve Godot 4.7.2-gate: **42.199 controles, 0 fouten**.
  Werkelijke geneste meshgrenzen, materiaalimport, volledige halve-meter
  rij-/cameracorridor, tram, huizen, andere landmarks en grondsteun in tracks
  4 en 10. Log: `validation/uithoorn-landmarks-independent-checks.txt`.
- Laatste gerichte plaatsingsfix verandert uitsluitend klassieke Schanskerk
  (-190,-20.9,-180) en Hoeksteen (-150,-20.9,-80), met veilige guard en
  gerichte voorzijde. De andere tien posities blijven gelijk. Runtimebronhashes
  zijn na de eigen gate opnieuw vergeleken en onveranderd.
- Makerregressies na plaatsing: StreetDistricts **166.127/0** (83 huizen,
  36 onder de baan), OutdoorLife **157.043/0** (24 clusters, 4 wandelroutes).
  HaarlemLandmarks **5.054/0** is eerdere ongewijzigde makerregressie. Dit is
  makerbewijs; Eva heeft deze drie volledige suites niet opnieuw uitgevoerd.
- Alle **144 oorspronkelijke bronbestanden** behouden hun exacte beginhash,
  ook na de laatste previewkopieën. Alle **zes standalone GLB's** zijn exact
  byte-identiek aan hun runtimebestand en de gecontroleerde modelhash.
- Zelf GLB-binaire gegevens onderzocht: embedded PNG-bufferViews, geen externe
  afbeelding-URI's, UV-coördinaten en gewone backfaceculling. Centrale manifest-
  hashes en materiaal-/beeld-/trianglecounts zijn onafhankelijk vergeleken.
- Eigen triangleanalyse: nul degenerates en nul open grensranden. Bij welding
  op coördinaten ontstaan 144 gedeelde randen bij Irenebrug en 24 bij
  Schanskerk met multipliciteit vier door samenvallende gesloten onderdelen.
  Geen claim dat de gehele samengestelde GLB één monolithisch manifoldvolume
  vormt. Builder rapporteert gesloten afzonderlijke componenten.
- Alle zes `preview.png`-bestanden zijn onafhankelijk byte-vergeleken met de
  studiofront-PNG van de definitieve native run. Bewerkbare `.blend`-bronnen
  en ingebedde-PBR `model.glb` staan in de zes betreffende bronmappen.
- Bewijs: `validation/uithoorn-independent-artifacts.json`,
  `validation/uithoorn-independent-topology.json`, native `metadata.json` en
  `subjects.json`. De preview is een echte studio-render, geen gameplaybeeld.

## Afgekeurde iteraties en gesloten bevindingen

De eerste model-/beeldgate vond dubbelzijdige standaardmaterialen, verborgen
achtergevelglas en sterk vervormde dak-/raamtexturen. Dit is in bronmaterialen,
uitwaartse raamoffsets, schone dakcrop en UV-aspect hersteld, inclusief
achterroeden. Alle twaalf nieuwe studioaanzichten bevestigen het herstel.
De eerste 86 enginefouten blijven bewaard in
`validation/uithoorn-landmarks-initial-double-sided-failure.txt`.

Eerdere camera's bewezen uitsluitend frustumzicht, ook achter het baandek.
De capture gebruikt nu een vaste echte viewport, strict first-hit op tijdelijke
mesh-raygeometrie met tweezijdige baan, bodypunten buiten HUD en legale
laterale spelerposities met de gewone followrig. Toch bleven klassieke
Schanskerk/Hoeksteen verborgen; Sem heeft uitsluitend deze veilige plaatsen
herzien. De definitieve beelden bevestigen daadwerkelijk zichtbaar
gebouwlichaam. De mislukte run 142057 met Hoeksteen-v2-filterfout is geen
opleveringsbewijs; capturefilters zijn daarna per variant gecorrigeerd.

## Grenzen en organisatie

De editorimport had exit 0, met een door de sandbox geblokkeerde TCP-listener;
geen model-/scriptimportfout. De native log meldt bij afsluiten twee GL-textuur-
lekkagediagnoses van elk 87.380 bytes. Deze blijven zichtbaar in het bewijs;
de run heeft geen scriptfouten, 38 geldige beelden en exit 0. Geen algemene
lekvrijheids- of langdurige performancetest claimen.

Foto's zijn vormreferentie en gereconstrueerde platen leveren kleurpatches.
Roughness/metallic zijn artistiek; geen gemeten PBR of ingebedde gebakken
normalmaps claimen. Geen externe publicatie/licentiebeoordeling of fysieke
controllerspeeltest verricht voor deze landmarktaak.

B=79.500 SC conserveert; acceptatie/vrijgave pending, transactielog leeg,
betaald 0. Uitbreiding: W 3.400, Q 800, R 800. Eigen 800 Q blijft ter review
bij Daan. QA-goedkeuring voor lokale oplevering is geen klantacceptatie.
