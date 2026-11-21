# Uithoorn — referentielandmarks

De zes aangeleverde pakketten zijn beoordeeld in
[de referentiebeoordeling](UITHOORN-REFERENTIEBEOORDELING.md). Het Rechthuis,
Schanskerk, Fort aan de Drecht, Irenebrug, Thamerkerk en De Hoeksteen worden
als herkenbare interpretaties geïmporteerd in beide Uithoornbanen. Dit is een
samengesteld racegebied, geen geografisch nauwkeurige stadsplattegrond.

## Bestanden en materiaal

Het centrale register staat in `scripts/worlds/uithoorn_landmarks.gd`:
`ENTRIES` bevat id, label, section, bounds en model_path. `build_model(parent,
entry)` laadt dezelfde GLB als de standalone versie. Runtimebestanden staan
in `game/assets/models/uithoorn-<id>.glb`. Standalone bestanden en bewerkbare
bron staan in de overeenkomstige `assets/straatbeeld/uithoorn/<id>/` map.
De GLB bevat PBR-materialen en texturen; de renderende viewer verzorgt licht,
camera en achtergrond. Gevelplaten en herkomst worden toegelicht bij de bron.
De originele referenties blijven ongewijzigd. De modelvoorzijde is Godot +Z.

## Plaatsing en grenzen

De modellen krijgen nodes `Landmark_<id_met_underscores>` en metadata
`uithoorn_landmark`, `bounds`, `section` en `model_path`. Ze zijn decoratief;
ze bepalen zelf geen botsingen of routebesturing. De gewone Uithoorn-baan heeft inmiddels een [nieuw grondtracé](UITHOORN-GRONDTRACE.md) langs deze gebouwen. De oude generieke
Thamerkerk wordt vervangen. Andere werelden krijgen geen nieuwe landmarks.

De plaatsingszoeker gebruikt een halve meter bemonstering van de volledige
actuele route, ook de Stunt Edition. Het volledige horizontale modelvolume
plus rijbaanbreedte en zes meter vrije cameraruimte blijft buiten de route.
Daarnaast blijven tramellipse, Spoorhuis, bestaande sceneryreserveringen en
andere landmarks vrij. Registratie in `scenic_sites` beschermt de gebouwen
tegen latere plaatsing van straatleven. Nieuwe huizen houden het model en
zijn voorruimte vrij. Gebouwen staan met een aparte sokkel op de grond;
de Irenebrug overspant de Amstel op x=0. De plaatsing is deterministisch en
geeft een waarschuwing als een model niet geïmporteerd of veilig geplaatst
kan worden, zonder een onveilige noodplaatsing te maken.

## Controle

`godot --headless --path game --script res://tests/uithoorn_landmarks.gd`
controleert de zes imports in beide varianten, werkelijke geneste meshgrenzen,
PBR-texturen, normale backfaceculling, baanvrijheid per halve meter, tram,
bebouwing, andere landmarks en grondsteun. Bestaande district- en
straatleventests bewaken de aansluitende omgeving. Werkelijke Godotbeelden
staan centraal in `renders/GAME-10001/stap-25-uithoorn-landmarks/`.
Testuitslagen en beeldacceptatie worden afzonderlijk vastgelegd; dit document
op zichzelf is geen bewijs van een geslaagde test of klantacceptatie.

Makerregressies (Godot 4.7.2): StreetDistricts 166.127 controles, OutdoorLife
157.043 controles en HaarlemLandmarks 5.054 controles; elk nul fouten.
De onafhankelijke integratiegate is na de herstelde definitieve exports herhaald: 42.155 controles, nul fouten. De eerste native beeldrun is afgekeurd wegens raamafdekking, UV-strepen en camera-occlusie. De gerichte herstelronde is technisch gecontroleerd; de nieuwe native beeldbeoordeling staat afzonderlijk in [het QA-rapport](UITHOORN-LANDMARKS-QA.md).

Voor het gewone straatcircuit staan de zes vaste locaties in
`scripts/worlds/uithoorn_ground_course.gd`. Dezelfde corridorcontrole keurt
ook deze locaties vóór plaatsing. De voorgevels kijken naar de aanrijrichting.
De eerdere verhoogde-baanposities van Schanskerk en Hoeksteen zijn hiermee
vervangen. De Stunt Edition gebruikt de bestaande plaatsingszoeker.

De specifieke gevelcontrole gebruikt werkelijke lage kerkvlakken (lokale Y2..14)
en voor Hoeksteen de glasrastervlakken (lokale |Z|>12.3, Y2..11.5, |X|<11).
Een ray moet het geselecteerde oppervlak als eerste raken. De maximale
landmarkhoogte als lichaamsgrens gebruiken bleek te ruim: kerkspitsen en een
dak konden daardoor onterecht voldoen. De actuele straatcircuitcontrole staat in `tests/uithoorn_ground_visual.gd`;
de oudere onafhankelijke beoordeling hierboven betreft het verhoogde tracé.
