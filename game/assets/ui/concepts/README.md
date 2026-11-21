# Originele sfeerbeelden in de parcourskeuze

De parcourskaarten gebruiken oorspronkelijke, door de klant aangeleverde
conceptbeelden. Ze tonen geen beelden van het huidige speelbare circuit.
`game/scripts/ui/world_concepts.gd` bevat de zes bronverwijzingen en exacte
pixelregio’s. De selectie gebruikt Godot `AtlasTexture`, zodat de bronbestanden
intact blijven. Engine-overviews onder `assets/ui/worlds/` worden niet als
selectiebeeld gebruikt.

| Wereld | Origineel, vanaf `public_html/boracer/` | Regio x, y, breedte, hoogte |
|---|---|---|
| Sunset Park | `tracks/sweer-impressie-baan.png` | 0, 0, 1672, 941 |
| Neon City | `user-interface/game-ui-overzicht-referentieblad.png` | 592, 354, 149, 103 |
| Regenbogenrijk | `worlds/regenbogenrijk/regenbogenrijk.png` | 3, 105, 867, 304 |
| Haarlem 1888 | `worlds/haarlem-1888/haarlem-1888.png` | 3, 105, 884, 327 |
| Uithoorn 2056 | `worlds/uithoorn-2056/uithoorn-2056.png` | 3, 105, 892, 330 |
| De Keukentafel | `worlds/keukentafel/keukentafel.png` | 3, 153, 1047, 304 |

De vier wereldsheets worden alleen als herouitsnede getoond, zonder legenda,
overzichtskaart, logoblok of tekstpaneel. Bij De Keukentafel begint de uitsnede
onder het tekstpaneel dat tot circa y145 over de illustratie ligt. Neon City
gebruikt uitsluitend de nachtstadthumbnail uit het wereldselectiepaneel; deze
bron bevat minder detail dan de grotere hero’s. `neon-reference.png` is een
ongewijzigde kopie van het volledige originele UIreferentieblad. De uitsnede
wordt uitsluitend bij het tonen toegepast.

Op 17 oktober 2026 zijn alle zes gamekopieën via SHA256 byte-identiek bevonden
aan hun bron. De originele beelden zijn daadwerkelijk bekeken. Er zijn geen
nieuwe externe afbeeldingen of licenties toegevoegd; de bestaande herkomst van
de klantbeelden blijft gelden. `tests/world_concepts.gd` controleert onder meer
uitsnedebounds, zes juiste startacties, namen, records, focus en layout. Deze
headless controles vervangen geen visuele controle in de grafische game.
