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
