# Installeren vanuit Git

Deze repository bevat de zelfstandige Godot-game, runtime-assets, bronmodellen,
hulpmiddelen en bestaande reviewbeelden. Er is geen webserver nodig om te spelen.

## Linux

Vereist: Git, Godot **4.7.2** voor Linux x86_64 en een grafische desktopsessie.

```bash
mkdir -p ~/Documents/sites
cd ~/Documents/sites
git clone git@github.com:antonboutkam/bracart.git
cd bracart
./start.sh
```

Godot mag in `PATH` staan of als `~/.local/bin/godot` beschikbaar zijn. Een andere
locatie kan met `GODOT_BIN=/pad/naar/godot ./start.sh`. De launcher importeert
assets automatisch; de eerste start duurt daardoor langer. Caches en logs
worden niet in Git opgeslagen. Blender en Python zijn alleen nodig voor
bepaalde ontwikkelhulpmiddelen, niet om te spelen.

Bijwerken:

```bash
cd ~/Documents/sites/bracart
git pull --ff-only
./start.sh
```

De oorspronkelijke lokale werkmap heet `boracart`; gebruik daar die mapnaam.
Spelprofielen staan buiten de checkout in Godots lokale gebruikersmap.

## Controleren

Import en opstart zonder venster:

```bash
./start.sh --headless --quit-after 3
```

Een volledige racecontrole over alle zes oorspronkelijke circuits:

```bash
~/.local/bin/godot --headless --path game --script tests/smoke.gd
```

De bestaande uitgebreide testverzameling draait met `game/tools/check.sh`.
Die gebruikt tijdelijke gebruikersmappen en behoudt bestaande spelprofielen.
Een headless-controle toetst geen grafische prestaties, geluid of fysieke invoer.

## Grafische startproblemen

Start vanuit een terminal in de ingelogde desktop. Via SSH is er niet
automatisch een toegankelijk speelvenster. Zie
[Linux-opstartonderzoek](game/docs/LINUX-STARTUP.md) voor driverdiagnose en de
expliciete hersteloptie `./start.sh --safe-mode`.

## Installatiecontrole op 21 november 2026

Beide installaties gebruiken Godot `4.7.2.stable.official.ed1daf0bf` en de
GitHub-branch `main`. De tweede installatie is rechtstreeks met `git clone`
gemaakt, inclusief een volledig nieuwe Godot-assetimport.

Op beide machines slagen dezelfde zes suites: `smoke`, `profile_storage`,
`monster_breaker`, `fractured_monster`, `impact_replay` en `input_flow`.
Samen: **886 controles per machine, nul fouten**. Testprofielen zijn geïsoleerd
van bestaande speldata. De overige suites in `game/tools/check.sh` zijn bij
deze installatie niet opnieuw uitgevoerd.

Startscherm, race en Monsterbreker zijn op beide machines daadwerkelijk
gerenderd en de controlebeelden zijn bekeken. Lokaal gebeurde dit op een
NVIDIA GeForce GT 710; ook de gewone launcher met standaardaudio sloot schoon af.
De tweede machine is grafisch gecontroleerd op een tijdelijk Xvfb-scherm met
Mesa/llvmpipe en Dummy-audio, omdat daar geen gebruiker op de desktop was
ingelogd. Die controle bewijst geen prestaties op de fysieke GPU of werking
van fysieke audio- en invoerapparaten. Start daar na inloggen `./start.sh`
vanuit de checkout voor de gewone desktopsessie.
