# Garage en objectgalerij

De garage gebruikt de oorspronkelijke getekende torso's uit garage.png via
AtlasTexture, zonder bronbytes te wijzigen. De geselecteerde coureur staat
linksvoor met een kroontje. Hover of keyboardfocus brengt de andere tekening
naar voren; dit wijzigt geen opgeslagen selectie. Klik/activatie bevestigt de
keuze en ververst de coureur op de voertuigen. Namen blijven beschikbaar als
tooltip/toegankelijke naam; de zichtbare woordknoppen zijn vervangen.

Kopen is groen wanneer het voertuig beschikbaar en betaalbaar is. Onvoldoende
muntjes geeft een gedempte, uitgeschakelde knop met de prijs/tekortinformatie.
Selecteren van bezit blijft mogelijk; een aankoop gebruikt de bestaande
profieltransactie en kan niet tweemaal voor hetzelfde voertuig betalen.

De zes previews draaien langzaam in een eigen3Dwereld met racetrack,
wegtextuur, curbs, gras en een boom. Camera's zijn op het volledige draaiende
model afgestemd. Verborgen previews stoppen hun proces en renderupdates.
Draaiknoppen op de detailpagina blijven beschikbaar. Buffers zijn begrensd
(676×184 per kaart,960×700 detail); geen gemeten GPUbenchmark geclaimd.

## Gebouwen en objecten in hun omgeving

De centrale renderpagina heeft een directe link naar
`renders/GAME-10001/gebouwen-en-objecten/index.html`. Deze galerij groepeert
gebouwen en tafelobjecten. Tot een eigen nieuwe capture beschikbaar is, toont
zij alleen daadwerkelijk bestaande eerdere straat-/tafelbeelden, expliciet
als eerdere opname gelabeld. Er worden geen placeholders als render opgevoerd.

Fase12 maakt twintig actuele beelden: zes individuele gebouwen langs hun
echte wegen (drie Haarlemgevels, drie Uithoornwoonhuizen), twee straatoverzichten,
elf objectgroepen op hun echte keukentafel en een tafeloverzicht.
De scene blijft de volledige GameMainwereld; er wordt geen los gebouw naar
een studio gekopieerd. subjects.json koppelt beeldnamen aan Nederlandse
labels, categorie, wereld en camerarichtpunt. Metadata bewaart de bronhashes
en de hash van deze subjectmanifest. Na een geslaagde run ververst de galerij
haar afbeeldingen; eerdere runs en mislukte logs blijven bewaard.

```bash
python3 game/tools/capture_step.py --project GAME-10001 --step stap-12-gebouwen-objecten
```

Fase13 maakt vijftien garage-/hemelbeelden: coureurkeuze/hover, voldoende
en onvoldoende muntjes, gedraaide voertuigen, vijf luchten, duinen, polder/Amstel
en regen-/nachtsituaties.

```bash
python3 game/tools/capture_step.py --project GAME-10001 --step stap-13-garage-hemel
```

Voer deze absolute python3-commando's vanuit iedere werkmap uit in een grafische
desktopterminal. Ze staan kopieerbaar op de renderpagina's. capture_review.py
neemt beide fasen mee. Headless setup controleert twintig/vijftien echte
scene-/camera-opstellingen zonder plaatjes te produceren. Native compositie,
textuurweergave, uiteindelijke lucht en prestaties vragen een echte gameweergave.
