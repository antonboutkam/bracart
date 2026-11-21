# Gesloten gebouwen — GAME-10001

Eigenaar: Ruben van Dalen GD-015. Onafhankelijke reviewer: Eva GD-006.
Status: geometrieherstel en headless-controle uitgevoerd; visuele gate open.

## Werkelijke oorzaak en wijziging

De werkelijk door `Track.build(3/4)` gebruikte `_house()` in
`scripts/worlds/scenery.gd` bestond uit een massief gevelblok en twee losse,
schuin gedraaide BoxMeshes als dak. De ruimte tussen gevelblok en dakvlakken
had geen driehoekige kopgevels. Vanaf de kopse kanten keek je hierdoor de kap
in. Dubbelzijdige materialen zouden die ontbrekende geometrie niet herstellen.

`_house()` delegeert nu naar `scripts/worlds/architecture.gd`. De kap is één
volledig gesloten driehoekig prisma met twee kopgevels, twee dakvlakken en een
onderzijde. Hoeken delen geometrische posities; UV-/normaalvertices zijn bewust
gesplitst voor scherpe randen. Vlakken gebruiken klokwijse frontfaces en expliciete
uitwendige normalen. De gevels overlappen de kap 15 cm bij de goot.
De driehoekige kopgevelbekleding heeft metselwerk/concrete van Fennes materialen;
het kapvolume blijft ook zonder die bekleding gesloten. Nok, gootranden en
schuine windveren maken de aansluitingen herkenbaar.

Alle vier gevels hebben ramen met donkere neggen, terugliggende glasvlakken,
uitstekende houten stijlen/dorpels en stenen vensterbanken. De deur heeft diepe
omlijsting en latei. Plint en kroonlijst lopen rond het gehele volume. Dit zijn
visuele reliëfdetails bovenop een gesloten blok, geen werkelijke binnenruimtes of
raamopeningen. Herhaalde details delen BoxMeshes via MultiMeshes per huis.
Zonnepanelen volgen exact de dakhelling; elke onderhoek ligt 8 cm boven hetzelfde
dakvlak. Er blijft dus geen horizontaal zwevend paneel door de nok steken.

Gebouwlocaties, footprint, rijcorridor, trackdata en collidercontracten blijven
behouden. Alle details passen binnen de oude horizontale envelope (x ±6,5 en
z ±6,2 meter, inclusief bestaande stoompijp). Er zijn geen colliders toegevoegd.
Fennes `world_material`-tags en oppervlaktes worden behouden: gesloten gevelblokken
en kopgevels krijgen via `Art.finish()` dezelfde Haarlem-/Uithoornmaterialen.

## Uitgevoerde controle

Gerichte test: `tests/architecture.gd`, Godot 4.7.2 headless, geïsoleerde tijdelijke
XDG-configuratie. Bewijs staat in `validation/architecture-checks.txt`.

- Iedere kapdriehoek: niet ontaard, klokwijse winding, normale naar buiten.
- Alle geometrische randen exact twee aansluitende driehoeken met tegengestelde
  randrichting; geen open of niet-manifold kapranden.
- Getekend volume gelijk aan analytisch prismavolume.
- Segmenten vanaf beide kopse kanten, beide zijkanten, boven en onder raken
  werkelijk de driehoeken van de kap (ook op voormalige gathoogte).
- Werkelijke `Track.build(3)` en `Track.build(4)`, elk 48 huizen; backface-culling
  actief, geen collision-objecten en alle detailgrenzen binnen de oude footprint.
- Alle Uithoornpanelen: normale parallel aan daknormale en vier onderhoeken exact
  8 cm boven het dakvlak.

Geen echte Godot-enginebeelden gemaakt: native X11 is in deze sessie geblokkeerd.
Headless-controle bewijst de genoemde geometrische eigenschappen, maar beoordeelt
geen visuele compositie, fototextuurschaal, schaduwen, leesbaarheid tijdens rijden
of uitstraling van materialen. Geen klantacceptatie of SC-uitbetaling geregistreerd.

## Vaste beeldreview na herstel native capture

Sla echte enginebeelden op onder `renders/GAME-10001/stap-06-werelden/`, met wereld,
standpunt en datum in metadata. Gebruik per wereld één nabij geplaatst huis en
bewaar minimaal: racecamera op ongeveer 25 m afstand; front links en front rechts
op goothoogte; achteraanzicht op goothoogte; bovenaanzicht op beide dakhelften.
Voor een huis met `p=house.global_position` en `h=eaves_height` zijn reproduceerbare
camera-posities `p+(-16,h+1,-19)`, `p+(16,h+1,-19)` en `p+(0,h+1,20)`, gericht op
`p+(0,h+1,0)`. Een extra camera `p+(14,h+12,8)` toont paneelaansluitingen.
Controleer daksluiting, windveren, materiaalaansluitingen en straatvrijheid bij
zowel droog daglicht als regen/nacht. Eva moet de echte beelden nog beoordelen.

`tools/capture_review.py` neemt voor stap 06 automatisch acht nabijbeelden op
(vier standpunten per wereld), naast de twaalf character-/HUD-beelden.
De capture is hier nog niet native uitgevoerd.

## Bijwerking — fotostraatbeeld en gedeelde wijkgeometrie

De bovenstaande eerste implementatie met48losse prototypehuizen per Track is
vervangen door `street_districts.gd`; zie [bronkaart](STRAATBEELD-BRONKAART.md).
Het eerdere resultaat6417checks/0fouten was de historische gesloten-dakcontrole.
De actuele architectuurtest gebruikt vier expliciete prototypevarianten per
wereld naast de echte instanced wijklaag:599checks/0fouten. Actueel bewijs:
`validation/architecture-checks.txt`. De door de echte Track gebouwde wijk bevat
198Haarlemhuizen en99Uithoornwoningen inclusief de twee landmarkvolumes.
`validation/street-district-checks.txt` bevat de zelfstandige wijk-/corridorchecks.
De primaire complete kap is dezelfde gesloten prismamesh; instancing past alleen
transformaties en oppervlaktematerialen toe. Er zijn geen duizend losse nodes
meer nodig voor deze huisjes: Haarlem21MultiMeshes, Uithoorn20 plus1naamplaat.

Gebruik voor captures nu de `StreetDistricts`-metadata `buildings`: iedere stamp
heeft een wereldtransform `frame`, `width`, `depth`, `height`, `variant` en `future`.
Camera's volgen de lokale geveloriëntatie uit `frame`; een wereld-as-gebaseerde
camera kan anders achter het huis belanden. Hoofdagent beheert de uitgebreide
capturelijst met22scenario's en schrijft echte beelden pas na een succesvolle
native renderer. Headless setupvalidatie levert geen plaatjes op. Centrale
resultaatmap blijft `renders/GAME-10001/`; raadpleeg het capturemanifest voor de
exacte stapmap en logs. Het oorspronkelijke reviewadvies blijft de visuele gate,
geen bewijs dat die gate al geslaagd is.
