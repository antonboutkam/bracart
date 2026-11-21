# Verfijnde Gifspuwer — lokale integratiecontrole, 14 november 2026

De nieuwe keuze **Gifspuwer · verfijnd** gebruikt de aangeleverde 76 stukken.
GLB en breekstukken-JSON zijn byte-identieke kopieën van de bron. De bron is
niet aangepast; gif-effect en Blender-project zijn niet in het spel gekopieerd.

| Controle | Resultaat |
| --- | --- |
| [Nieuwe breekstukken](fractured.txt) | 479 controles, 0 fouten |
| [Bestaande Monsterbreker](regression.txt) | 168 controles, 0 fouten |
| [Interface-indeling](ui.txt) | 33 controles, 0 fouten |
| [Brede race-smokecheck](smoke.txt) | 162 controles, 1 fout in het wegprofiel van wereld 4 |
| [Softwarecaptures](visual.txt) | Zes beelden gemaakt en bekeken |

Een normale vol-gassprong maakt negen onderdelen los en levert na onderdompeling
498 punten op. In een afzonderlijk vers spel voltooien twee uitrollende sprongen
met luchtbesturing naar de twee steunen de wedstrijd: 10.000 punten. Hiervoor
injecteert de test geen treffers. Andere controles isoleren trefferdetectie,
steunverlies, eigenaarschap bij twee aanvallers, watergrens, pauze en replay.
De vertexkleuren zijn zowel intact als na losbreken gecontroleerd.

De smoke-fout staat buiten deze wijziging: `tests/smoke.gd` verwacht een
komhoogte groter dan 1 bij alle werelden behalve 5. De ongewijzigde
`scripts/track.gd` geeft juist 0 voor de vlakke `ground_course` van wereld 4.
Deze racecode en test zijn niet aangepast. De volledige historische suite is
niet uitgevoerd; deze resultaten zijn geen algemene groenverklaring.

## Beelden

- [Monsterkeuze met vertexkleuren](01-selection.png)
- [Intact model op de draagplaat](02-intact.png)
- [Normale vlucht naar het monster](03-approach.png)
- [Blijvende schade en 498 punten na die vlucht](04-damaged.png)
- [Instorting na een afzonderlijke, gescripte treffer door beide steunen](05-collapse.png)
- [Uitslag na die gescripte instorting](06-finished.png)

Voor de overzichtsbeelden wordt de camera door het capturescript geplaatst;
bij het intacte overzicht is de voertuigkeuzebalk tijdelijk verborgen. De
aanvliegfoto gebruikt de echte spelcamera. Het capturescript hervat uitsluitend
voor de automatische foto's na verlies van vensterfocus. Het spel zelf blijft
bij focusverlies pauzeren.

De beelden zijn lokaal gemaakt met Mesa/llvmpipe, 1280 × 800 en 50% 3D-resolutie.
De gewone driver gaf een EGL-fout; de systeemdrivers zijn niet gewijzigd.
Dit bewijst de weergave, niet de framerate op de fysieke GPU of het rijgevoel
met een controller. Vallende stukken gebruiken dezelfde vaste zwaartekracht
als de bestaande brokken, zonder onderlinge botsingen of rotatie.

Herhaalbare commando's staan in [Monsterbreker](../../docs/MONSTERBREKER.md).
