# Lucht en Nederlandse vergezichten — technische overdracht

Ruben GD-015, GAME-10001. Dit zijn originele procedurele interpretaties, geen
fotogrammetrie of geografisch/historisch onderzoek. Geen externe rasterbeelden.

## Lucht en weer

`worlds/dutch_sky.gd` houdt het bestaande ProceduralSkyMaterialcontract intact.
Een lokaal gegenereerd equirectangulair1024x512cloudpanorama voegt brede lage
cumulusbanken en heldere open plekken toe; Neon krijgt maan, sterren en gedempte
nachtwolken. De overige buitenwerelden krijgen een zon, blauwere bovenlucht en
lichte horizon; Sunset behoudt een warme horizon/wolktint. Beide panoramapaletten
worden eenmaal opgebouwd en gecachet; geen texture-/geometriebouw per frame.
De basis is Godots bestaande [ProceduralSkyMaterial sky_cover](https://docs.godotengine.org/en/4.2/classes/class_proceduralskymaterial.html),
waarbij de equirectangulaire overlay bij de procedurele lucht wordt opgeteld.

`WorldArt.setup_environment(env,sun,index,track)` installeert een Track-owned
DutchSkycontroller. Weather dupliceert daarna het materiaal; `sync_weather()`
haalt daarom telkens het actuele materiaal uit de echte Environment. Dezelfde
rain_amount/night_amount sturen de wolktint en dag-/nachtpalette. Nacht verbergt
de procedurele zonneschijf en toont maan/sterren. Geen ShaderTIME of onafhankelijke
cloudtime: pauze laat de toestand stilstaan. Weather behoudt eigenaarsschap van
basiskleuren, regen, nachtlicht, regenboog en wegvocht; terugkeer naar zon herstelt
die bestaande baseline. Neon blijft ook bij weerszon een passende nachtwereld.

Keukentafel5wordt vóór skyinstallatie uitgesloten: oude skyparameters,
interieurgeometrie en alle voorwerpen blijven exact behouden. World0verandert
alleen van lucht; de bestaande achtergrondhills daar blijven intact.

## Vergezichten en fysieke grenzen

`worlds/dutch_horizons.gd` vervangt uitsluitend de oude hoge achtergrondhills
voor Haarlem3 en Uithoorn4. Haarlem krijgt12brede, lage zandduinen op de westelijke
horizon en korte helmgrasachtige plukken. Uithoorn krijgt vlakke wisselend groene
weilanden, perceelslootjes en twee zachte Amstelbochten. De rivierarmen sluiten
bijZ±440aan op het bestaande rechte water en lopen binnen het bestaande verre
terrein door totZ±840. Weilanden worden langs de rivier uitgespaard zodat ze het
wateroppervlak niet bedekken. Aangrenzende ribbonsegmenten delen dezelfde
randposities: geen gaten tussen de bochten.

Iedere uiteindelijke landscapeboundingbox blijft buiten300m van de wereldoorsprong.
Er is geen nieuwe grond onder racebaan, promenade, auto of wandelaar gelegd. De
bestaande dichtbijgelegen grasbanken en kademuren zijn geheel behouden: eerdere
native vloer-/cloudcorrecties worden hiermee niet omzeild. Geen colliders of
per-framehorizonopbouw. Statische delen zijn gebundeld via MultiMeshes; de rivier
is een gewone aaneengesloten, naar boven gerichte oppervlaktestrook.

## Capture-/QAcontract

`Track/DutchHorizons` bestaat alleen voor wereld3/4, met metadata:

- `review_views`: één `{id,eye,target}` per wereld in Trackruimte.
- `geometry_records`: uiteindelijke wereld-AABBs, soort en waar relevant ingediende
  transform/rivierpunten/breedte.
- `minimum_radius`:300; `landscape`: specifiek landschapstype.

Batchnodes bewaren exact ingediende `instance_transforms`, omdat headless
RenderingServerDummy geen betrouwbaar instantiebufferreadback levert. DutchSky
heeft `sync_weather()` voor captures die na force_event direct willen synchroniseren.
De reguliere controller doet dit ook per frame en via het bestaande weerevent.

Gerichte integratietest: `tests/dutch_sky_horizons.gd`; bewijs in
`validation/dutch-sky-horizons-checks.txt`. De test bouwt werkelijk Main/Track voor
allezeswerelden en toetst weerregen/nacht/regenboog, herstel/pauze, skyduplicatie,
panoramacache/longitudeseam, herkenbare cloud-/helder-gebiedsverdeling, exacte
keukenuitsluiting, zachte duinverhouding, alle horizon-AABBs en het onbedekte
Amstelwater. Dit bewijst geen aantrekkelijke native compositie of materiële
leesbaarheid; root beheert echte externe captures en Eva de onafhankelijke review.
Geen klantacceptatie of uitbetaling geregistreerd.
