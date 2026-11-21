# Centrale BoRacer-renders

Open [het renderoverzicht](index.html) of [GAME-10001](GAME-10001/index.html).
Vaste indeling: `renders/<project>/<stap>/<UTC-tijdstip>/`.

- Enginebeelden worden uitsluitend door native Godot gemaakt.
- Iedere geslaagde run heeft PNG's, index.html, capture.log en metadata.json met
  bron-/scripthashes; `latest` verwijst alleen naar een complete geslaagde run.
- Blender-studiobeelden staan in een aparte expliciet gelabelde galerij. Dit zijn
  echte renders van de modellen, maar geen beelden uit de game.
- Stap4/5 zijn nog niet uitgevoerd; hun pagina's tonen dat eerlijk.

## Eén commando voor de actuele review

Vanuit iedere werkmap, in een gewone grafische desktopsessie:

```bash
python3 game/tools/capture_review.py
```

Dit maakt de actuele karakterfase, de twee werelden, weer/beloningen en interface.
De wereldfase omvat ook acht dak-/gevelcloseups. De interfacefase omvat
splash/dashboard, wereldselectie, HUD, dag/nacht en touch/compact scherm.
De frames zijn geënsceneerde reviewmomenten uit de echte engine, geen opname
van een volledige race. Voor één onderdeel, bijvoorbeeld de werelden:

```bash
python3 game/tools/capture_step.py --project GAME-10001 --step stap-06-werelden
```

Na iedere nieuwe afgeronde karakterfase:

```bash
python3 game/tools/publish_character_step.py --step 3
```

Gebruik later4/5 pas na passende beoordeling. Publicatie bewaart oude runtime-
assets, kopieert alleen de bevroren karakterexports, importeert en rendert
vervolgens automatisch. De zes voertuigen en echte spelersprofielen blijven intact.

## Status van deze uitvoeromgeving

De sandbox weigert X11-connecties en lokale displaysockets met EPERM. Daardoor
zijn native screenshots hier geblokkeerd. Pogingen bevatten foutlogs en geen
nagemaakte screenshots. Headless Godot-tests werken; hun resultaten zijn
uitsluitend functionele controles en geen visuele goedkeuring.

Huidige karakterreview: [12 Blenderbeelden stap 3](GAME-10001/blender-stap-03/index.html),
met herkomst per beeld en expliciete modelbeperkingen.

Audio: [RaviRacer-luisterpagina](GAME-10001/audio/index.html), met originele opname,
drie loopassets, bronanalyse en een offline acceleratievoorbeeld. Dit is geen
geluidscapture uit de engine.

De HTML-overzichten, stappagina’s en afzonderlijke runpagina’s tonen dezelfde
absolute `python3`-aanroepen. De luisterpagina toont het absolute commando
voor `build_vehicle_audio.py`. Nieuwe pagina’s behouden die commandoblokken.

Keukentafel: [stap09](GAME-10001/stap-09-keukentafel/index.html) maakt dertien
beelden van de actuele fotovoorwerpen (racecamera, overzicht, elf close-ups):

```bash
python3 game/tools/capture_step.py --project GAME-10001 --step stap-09-keukentafel
```

Dit vereist een grafische desktopsessie; nieuwe beelden blijven per run bewaard.
