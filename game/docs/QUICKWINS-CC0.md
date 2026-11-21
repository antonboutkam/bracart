# Geïntegreerde quickwins — 17 oktober 2026

De selectie uit het componentenonderzoek is in drie stappen geïntegreerd.

1. Vier Kenney Nature Kit-modellen: twee bomen, een struik en een bloem. Haarlem en Uithoorn krijgen elk twaalf exemplaren op bestaande gedragen groenstroken. Vier MultiMeshes per wereld, afstandsculling en behoud van bestaande aankleding beperken de belasting.
2. Echte race-events sturen vier korte materiaalgeluiden aan: asfalt, hout, papier en plastic. Papier gebruikt een geselecteerd plankgeluid, plastic een zachte impact; dit zijn onze toepassingen, geen materiaalclaims van de leverancier. Vier hergebruikte audiovoices, afstandslimiet, cooldown, pauze en mute begrenzen de weergave. Bij de keukenschansen volgt landingfeedback pas bij werkelijk contact na de vliegfase.
3. Twee Kenney Particle Pack-textures leveren landingsstof, botsingsvonken en een korte finishviering. Maximaal twaalf hergebruikte groepen met twaalf sprites. Als vervolgwinst toont een lichte, niet-interactieve confettilaag achttien getekende deeltjes boven het resultatenscherm, zodat de viering ook daar zichtbaar blijft. Na 1,6 seconde verdwijnt deze laag.

De tien geselecteerde assets zijn samen 347.958 bytes. Originele CC0-licenties, bron-URL's, archiefhashes en geselecteerde bestandshashes staan in [het manifest](../assets/third_party/kenney/manifest.json). Onafhankelijke QA vergeleek ook met de originele archieven. De bestaande voertuigen, foto's en rijroute blijven het uitgangspunt.

## Bekijken en beluisteren

- [Groenaccenten: vier renderopstellingen](../../renders/GAME-10001/stap-17-groen-cc0/index.html).
- [Racefeedback: vijf renderopstellingen](../../renders/GAME-10001/stap-18-racefeedback/index.html).
- [Vier materiaalgeluiden direct beluisteren](../../renders/GAME-10001/materiaalgeluiden/index.html). Dit zijn de bronclips, geen opgenomen gameplaymix.
- [Renderoverzicht met commando voor alles](../../renders/GAME-10001/index.html).

Elke deelpagina toont uitsluitend het eigen absolute python3-commando. De batchgenerator neemt de nieuwe stappen en luisterpagina mee.

## Controle en bewijsgrens

[De eindrapportage](../validation/quickwins-final-gate.json) bevat 47 suites, 4.892.875 controles en nul fouten in de laatste uitkomsten. Eén brede seriële run is aangevuld met drie gerichte hercontroles. De eerste brede run eindigde met code 1 omdat een bestaande audiotest alle audiovoices als voertuigstemmen telde; die test onderscheidt nu twintig voertuigstemmen en vier impactstemmen. Er wordt geen ononderbroken brede exit-0-run geclaimd.

Negen captureopstellingen zijn headless gevalideerd; dit levert geen afbeeldingen op. Nieuwe native renders en beoordeling van het gemixte geluid op echte audiohardware blijven open. De renderpagina's verwijzen alleen naar werkelijk geslaagde beelden als die beschikbaar zijn.

## Commits en administratie

De hoofdrepository heeft alleen-lezen Gitmetadata en 625 eerder klaargezette bestanden. Die index blijft intact. Drie echte wijzigingscommits worden daarom geleverd als patches en Gitbundle in [de oplevermap](../../../../organisatie/projecten/GAME-10001/oplevering/quickwins/README.md). De aparte reviewrepository bevat een beperkte baseline van tien aangeraakte bestanden en is geen zelfstandig speelbare checkout. Alle spelwijzigingen staan al in deze werkmap; pas de patches hier niet opnieuw toe.

Het fictieve projectbudget is 62.500 SC; de aanvulling voor deze ronde is 6.000 SC. Alle vergoedingen blijven gereserveerd tot expliciete klantacceptatie. Gratis assets brengen geen aanschafkosten mee.
