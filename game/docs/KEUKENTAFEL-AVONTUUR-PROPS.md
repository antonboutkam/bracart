# Keukentafelavontuur — statische geometrieoverdracht

Ruben GD-015, GAME-10001. Sem bezit de echte route, oranje plastic360loop,
sprong-/ramplogica, cameramodus en PVCregenboogeffect. Root bezit captures en
integratie; Eva de onafhankelijke controle.

## Afgesproken vormen en eigenaren

`kitchen_adventure_props.gd` leest uitsluitend de echte `track.kitchen_features()`;
er zijn geen geraden tunnel-/rampposities. Scenery voegt deze module na de
bestaande fotovoorwerpen toe. Alle11oude fotogroepen/219foto-objectmeshes blijven
behouden; de18bronjpegs zijn niet gewijzigd.

- `toilet_rolls`: twee witte papierrollen, elk8m lang,1m tussenruimte, met
  kartonkleurige binnenwand en papier-/kartonrand. Werkelijke holle cilinderschillen.
- `pvc_rainbow`:18m lange mediumgrijze PVCbuis, grijze binnenwand en randen.
  Alleen Sem maakt het tijdelijke regenboogeffect tijdens de doorrit.
- `loose_cables`: drie ronde zwarte kabels over de baan. Het lage aflopende deel
  ligt buiten de volledige rij-/camerabreedte; boven de baan blijft ruime hoogte.
- `comic_ramp`: gesloten gebogen stripalbum met code-native kleurpanelen en titel,
  ondersteund door een houten blok onder het verhoogde uiteinde.
- `card_ramp`: gesloten licht gebogen speelkaart met rode hartensymbolen, op een
  Jengablok. Geen zwevende planken of kaartvlak los van de echte route.
- `game_controller`: aparte zwarte gamecontroller met fysieke grips, sticks,
  d-pad en knoppen, veilig op de tafel in het bestaande middendeel.

## Doorsnede en gedragen vloer

Voor de papierrollen spraken Sem en Ruben outerR13,2/innerR12,4, ashoogte13,3
en wegvloer5,3 af; PVC heeft na onafhankelijke aanloopcontrole de grotere maten
15,5/16,3/16,4 gekregen (zie correctie hieronder).
Daardoor rust de buitenkant op tafelY0,1 en ligt ook de complete zijbaan binnen
de echte ronde opening. Alleen een buisradius groter dan halve baanbreedte zou
onvoldoende zijn als de weg tangent onderin de buis lag. De nu verhoogde
vloerchord vermijdt precies dat probleem.

Er zijn drie surfaces per buisschilmateriaal: buitenwand, binnenwand en beide
annulaire eindranden. Geen driehoek dicht de centrale opening. Klokwijse
frontfaces/normals zijn expliciet; de doorrit leunt niet op dubbelzijdigheid.
Een echte vlakke bodemplaat met zijsteunen ligt in de buis onder de route.
Voor en achter sluiten gesloten onderlegwiggen aan over Sems echte15m
hoogteaanlopen; bovenkant volgt `track.frame()/position_at()`.

De eerste tangent-Box voor boek/kaart paste niet bij de werkelijk gebogen
rampcurve. Root en Ruben vonden dat vóór oplevering. De uiteindelijke gesloten
album-/kaartmesh volgt daarom de complete route om de0,35m, ook op beide
wegzijden. De top ligt1cm onder de geleide route. Dikte volgt de lokale normaal;
bij het lage uiteinde is de onderkant op tafelY0,1 begrensd als dunne bevel,
zodat de voorkant niet in het hout verdwijnt. Stripkleurpanelen en titel/symbolen
volgen dezelfde werkelijke frames. Lipsteunen blijven afzonderlijke echte blokken.

## Bestaande kamer en capturecontract

`WorldArt._room()` behoudt de bestaande kamer/keuken en voegt via dezelfde module
alleen `AdventureRoomFurniture` toe: een wandboekenkast met rustige rugkleuren en
een herkenbare kookplaat/oven in het bestaande aanrecht. Geen tweede kamer,
nieuwe hemel of andere wereld gewijzigd.

`Track/KitchenAdventureProps.features` bevat ieder statisch feature met `id`,
`kind`, `center`, `frame`, `node`, `height`, `radius`, `road_progress` en de
uiteindelijke `static_aabb` in Trackruimte. Aanvullend: tunnelradii/asoffset,
kabelpaden/cable_radius of start/lipframe en support_node. De zwarte controller
is ook als scenic_site geregistreerd; passagefeatures staan bewust boven/in de
route en worden met hun specifieke vrije doorgang getoetst, niet als blokkadecirkel.

`Track/LayeredWorldBackground/AdventureRoomFurniture.review_views` geeft twee
`{id,eye,target}` standpunten voor boekenkast en keuken/fornuis. Loop-/sprongbeelden
gebruiken Sems echte routefeaturemetadata. Root beheert centrale stap15captures.

## Verificatie en grens

`tests/kitchen_adventure_props.gd`:5600checks0fouten; daadwerkelijke Track5bouw
met zes statische featuregroepen en119nodes, plus aanvullende kamermeubels.
De test toetst annulaire meshmanifoldheid, normale winding, echte vrije stralen
voor voertuig/camera, werkelijke course-lanes/hoogtes door beide ronde buizen,
aanloopondersteuning, kabelhoogtes, alle elf oude fotogroepen en echte kamermeubels.
Boek/kaart worden met daadwerkelijke driehoek-intersecties over183lane-/routepunten
per ramp op maximaal2,5cm bovengrensgap getoetst; geen bodyvertex onder de tafel.
Bewijs: `validation/kitchen-adventure-props-checks.txt`.

Headless geometrie is geen native compositie-/materiaalbeoordeling. Er zijn hier
geen nieuwe enginebeelden gemaakt. Root en Eva doen aanvullende route-/camera- en
beeldreview; klantacceptatie en3000SC-uitbetaling blijven open.

## Onafhankelijke randgevallen en correctie

Eva vond bij de exacte stripalbum-entry/lip vier lege straalintersecties: de
raakpunten lagen slechts25..45micrometer van de fysieke meshrand. De eerdere
makertest nam57binnenpunten en miste die beide eindranden. De echte gesloten
boek-/kaartbody heeft nu15cm fysieke overlap vóór entry en na lip; de logische
route-/sprongpunten blijven gelijk. Ook de maker toetst nu61samples inclusief
beide eindpunten op de werkelijke trianglemesh, zonder ruimere raytoleranties.
De gesloten bodem blijft overal minimaal op tafelY0,1.

Daarnaast bleken acht PVCpunten in de echte bocht/aanloop al door de cilindermond
te gaan voordat zij het vlakke plateau bereikten. De eerdere makertest nam alleen
het plateau mee. In overleg met Sem behoudt de route zijn vorm en krijgt alleen
PVC een passend ruimere fysieke doorsnede: innerR15,5/outer16,3/as16,4; de papieren
rollen blijven12,4/13,2/13,3 en beide wegvloeren5,3. De zijsteunen passen zich aan
de werkelijke ondercirkel aan. Sem laat regenboog/radiustransformatie meebewegen.
De maker controleert nu alle aanlopen om de0,3m op de echte lokale polygonale
buisdoorsnede, niet alleen een opgegeven radius of plateau. Het volledige nieuwe
PVCobject wordt ook tegen de tafelgrenzen getoetst. Bestaande219fotomeshes en18
bronnen blijven exact ongewijzigd; geen route-/camera-aanpassing door Ruben.
