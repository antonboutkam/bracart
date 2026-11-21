# Uithoorn — straatcircuit met startheuvel

De gewone **Uithoorn 2056**-baan (track 4) rijdt langs de zes geïmporteerde
landmarks op grondniveau. De afzonderlijke **Stunt Edition** (track 10) behoudt
zijn bestaande route, sprongen en loopings. Dit is een samengesteld racegebied,
geen geografisch nauwkeurige kaart van Uithoorn.

## Route

- Een gesloten ronde van circa 1.876 meter, op de westelijke Amsteloever.
- De startgrid staat op een heuvel van 28 meter. Na een kort vlak stuk volgt
  ongeveer 100 meter afdaling. De terugweg klimt naar dezelfde heuvel zodat
  de ronde vloeiend aansluit; er is geen teleport of los einde.
- 87% van de route ligt vlak op het maaiveld. Het asfalt ligt 18 cm boven
  de grond. Buiten de startheuvel zijn er geen verhogingen, sprongen of pilaren.
- Bochten hebben een nominale straal van 24 meter, met rechte tussenstukken.
  De rijbaan blijft 16 meter breed en heeft een vlak dwarsprofiel.
- Rechthuis, Schanskerk, Fort aan de Drecht, De Hoeksteen, Thamerkerk en
  Irenebrug staan bij de bochten en aanrijstukken. Hun gevels zijn op de
  aanrijrichting gericht; routeborden dragen de bijbehorende namen.
- Huizen en voortuinen worden uit de nieuwe rij- en cameracorridor gehouden.
  De tram, zijn bovenleiding, het Spoorhuis en de Amstel blijven vrij.
- De heuvel heeft zichtbare aarden taluds. De afdaling voegt zwaartekracht
  toe aan de bestaande racebesturing; remmen blijft werkzaam.

## Implementatie

`scripts/worlds/uithoorn_ground_course.gd` bevat de route, afgeronde hoeken,
hoogteverloop, landmarklocaties en taluds. `track.gd` gebruikt deze alleen
voor track 4. De oude Uithoorn-controlepunten blijven de lengtereferentie voor
Stunt Edition; de historische v1-testfixture blijft daarom behouden.

Het landmarkregister controleert de volledige route per halve meter vóór
plaatsing. Er blijft ruimte voor het volledige gebouwvolume plus rijbaan en
zes meter camera-/zijruimte. Het gewone district vermijdt ook huizen en
voortuinen bij de weg. De geleverde GLB's en bronbestanden zijn ongewijzigd.

Het vlakke wegprofiel gebruikt twee dwarssegmenten in plaats van de zestien
voor komvormige wegen. Bij vrijwel parallelle camera-upvectoren voorkomt
normaliseren na lineaire interpolatie een instabiele slerp-rotatieas. Op de
vlakke straat kijkt de gewone volgcamera een halve meter hoger, zodat gevels
beter zichtbaar zijn. Deze aanpassing neemt vóór en op de startheuvel af;
het raketje blijft binnen de vrije ruimte tussen de HUD-panelen.

## Controle

```bash
XDG_DATA_HOME=/tmp/boracart-uithoorn-test/data \
XDG_CONFIG_HOME=/tmp/boracart-uithoorn-test/config \
godot --headless --audio-driver Dummy --path game --script tests/uithoorn_ground.gd
```

De grondtracésuite controleert het hoogteprofiel, aansluitende startgrid,
berm, vlakke rijstroken, tramvrijheid, normale racecamera en drie volledige
ronden met finish. Deze suite en de landmarkcontrole staan in `tools/check.sh`.
`world_geometry`, `street_districts`, `race_behavior` en `tracks_v2` bewaken
de algemene geometrie en bestaande race-/stuntwerking.

`tests/uithoorn_ground_visual.gd -- --validate-only` controleert met tijdelijke
ray-geometrie de werkelijke gevelzichtbaarheid vanuit de gewone racecamera.
Er wordt alleen in de middelste rijstrook gereden; de camera wordt niet op
landmarks gericht. Voor Schanskerk tellen lage gevelvlakken, voor Hoeksteen
de glasrastergevels. Een landmark moet op meerdere opeenvolgende naderingspunten
leesbaar zijn; alleen een zichtbare dakpunt is onvoldoende.

`tests/uithoorn_ground_capture.gd` rendert de door deze controle opgeslagen
cameraposities in `/tmp/boracart-uithoorn-ground`, zonder de tijdelijke
ray-geometrie. Gebruik bij de lokale driverfout eventueel
`__GLX_VENDOR_LIBRARY_NAME=mesa LIBGL_ALWAYS_SOFTWARE=1 LP_NUM_THREADS=4`.
De beelden gebruiken 50% 3D-resolutie met scherpe HUD. Deze softwareweergave
is geen GPU-prestatiemeting. De geslaagde tests, zichtmetingen en beperking van de native beeldcontrole
staan in [het validatierapport](../validation/uithoorn-ground/README.md).
Native screenshots konden in deze sessie niet worden afgerond; daadwerkelijke
beeldacceptatie en GPU-prestaties blijven dus onbevestigd.
