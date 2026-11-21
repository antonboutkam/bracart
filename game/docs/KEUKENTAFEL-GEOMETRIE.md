# Keukentafel — geometrische overdracht

Ruben GD-015, GAME-10001. Foto's: alle18directe jpg-bestanden in
`assets/straatbeeld/keukentafel/`, daadwerkelijk bekeken via een contactblad.
Fenne beheert de afzonderlijke foto-/UVmodule en herkomstregistratie.

## Vormen en feitelijke fotoreferenties

- 093205/093232/093236: zwarte dunne monitor met codebeeld, zwart toetsenbord
  en zwarte muis. Foto's op de scherm- en toetsenbordvlakken, gesloten kast,
  voet/staander en fysieke muis eromheen.
- 093220/093223: witte rechtopstaande megafoon met smalle rode geribbelde
  bovenkant. De brede witte trechter wijst naar beneden, zoals op de foto's.
  De horn heeft binnen-/buitenwand en ringvormige randen; geen mondafdichtplaat.
  De rode elektronica-afsluiting zit bovenaan de smalle hals. Witte handgreep.
- 093210/093242/093244/093246: één slank cyaan/zilverkleurig blik met rood
  beeldmerk, zilveren gesloten boven-/onderkant, lipje en donkere drinkopening.
  Een gebogen fotografische labelsector volgt de cilindervorm; geen fotokubus.
- 093239: zwarte afstandsbediening met foto op bovenvlak en echte
  reliëfknoppen. 093213: witte USB-voeding; metalen pennen en donkere USB-poort.
- 093208/093250/093253: zwart stekkerblok, ronde kabelbossen en twee kleine
  blauwe printplaatjes met zilverkleurige chips/USB en metalen pennetjes.
- 093159/093213/093236: papier en zilver/witte doordrukstrip; vormgeometrie
  gebruikt omdat de gefotografeerde vlakken onvoldoende intact zijn voor UV.
- 093228: groene stof met witte binnenkant als zachte gevouwen volumes.
- 093230: glazen bol op zwart/zilveren voet boven een doosje naast het scherm.
- Schaar als twee metalen bladen met open ronde zwarte handgrepen; geen
  massieve roodbruine placeholderhandvatten meer.

Dit is een vrije herschikking van de echte tafelvoorwerpen voor het circuit,
geen schaalvaste fotogrammetrische reconstructie. Geen extra kopieën per foto:
de vier blikbeelden leiden samen tot één blik.

## Contracten

`scripts/worlds/kitchen_props.gd` is eigenaar van alle11voorwerpgroepen.
`scenery.gd::_kitchen` vervangt de oude dubbele placeholderobjecten met deze
module. De vier bestaande tafelpoten, WorldArt-interieur, tafel/circuitgeometrie,
brug-/sprongcontracten, physics en overige werelden zijn niet aangepast.

Rootnode `Track/KitchenProps` heeft metadata `objects` met per groep `id`,
`label`, `center` (in trackruimte), `radius`, `height`, `front` (+Z) en `node`.
Iedere groepsnode heeft `kitchen_object` en `footprint_radius`. `scenic_sites`
registreert dezelfde conservatieve cirkels. Kabels en alle uitstekende delen
vallen binnen die cirkels. Plaatsing wordt afgewezen als de volledige cirkel niet
binnen tafelgrenzen en minimaal4m naast de rijbaan past, gemeten elke0,5m.
Dat geeft ook zijwaartse ruimte bij sprong- en camerahoogtes; de footprint bevat
alle hoogtes van het voorwerp. Alle meshes zijn uitsluitend decoratief.

Kabels zijn echte ronde CylinderMeshes met ronde aansluitingen. Megafoontrechter
is een annulaire, volledig gesloten wand-shell met een werkelijk open as/mond.
Geen dubbelzijdigheid nodig om ontbrekende wandgeometrie te verbergen. Zwarte,
witte, cyaan, rode en groene basislichamen blijven gewoon echte objectkleuren;
alleen passende labels/scherm/knoppenvlakken krijgen Fennes foto-UVpatches.
Geen bruikbare papier-/blister-/voeding-/ESPfoto wordt geforceerd op een kubus.

## Uitgevoerde verificatie en open visuele gate

`tests/kitchen_props.gd`: werkelijke `Track.build(5)`, alle11groepen,219mesh-nodes
(<500), footprintgrenzen van ieder getransformeerd mesh inclusief kabels, ieder
voorwerp raakt het tafelvlak, circuitbreedte behouden, route/camera-guard bij
0,5m samples, vijf echte fotovlakken, slanke blikproporties en glazen bol.

De echte trechterdriehoeken zijn getest op degeneraties, tweezijdige
randincidentie van de wand-shell en een vrije mondstraal door de as. Dit bewijst
het ontbreken van een verborgen mondplaat in de hornmesh; de smalle hals wordt
zoals een werkelijk object verder bovenaan afgesloten door elektronica.
Bewijs: `validation/kitchen-props-checks.txt`.

Native X11 blijft geblokkeerd: geen echte enginebeelden gemaakt. De test bewijst
geen fotohelderheid, UVherkenbaarheid, schaduw, glasreflectie, objectuitstraling of
kijkgevoel tijdens rijden. Eva voert een onafhankelijke rij-/camera- en
regressiereview uit; native beeldreview blijft nodig. Geen klantacceptatie,
SC-uitbetaling of geslaagde visuele gate geregistreerd.

## Eindcontrole en later aangetroffen native beelden

Eva: fotomaterialen/geometrie24.075 controles, props16.607, wereldgeometrie27.289,
WorldArt362 en cameracompositie415.480, telkens nul fouten. De historische
site-telling is vervangen door elf expliciete groepen en vijf subcomponenten;
alle corridorchecks blijven behouden. Fennes windingcorrectie richt de normalen
van vlakke fotoquads naar+Z en van het bliklabel naar buiten, met dezelfde UV’s.

In de gedeelde rendermap is daarna de native run `20261017T075800-394731Z`
aangetroffen met dertien echte PNG’s. Root heeft overzicht, megafoon, blik en
monitor bekeken. Die run gebruikt de eerdere helperhash802c8ff5; de definitieve
helper heeft hashf71e88b5. Het verschil is de richting van fotovlaknormalen;
UV’s en objectvormen blijven gelijk. De propverschillen daarna zijn alleen
benamingen/metadata. Dit geeft beeldbewijs voor silhouetten/plaatsing/texturen,
geen beoordeling van de definitieve normaalbelichting of klantacceptatie.
Het absolute python3-commando op de renderpagina maakt een nieuwe actuele run.
