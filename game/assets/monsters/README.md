# Breekbare monsters

Monsterbreker biedt naast de blokjesmodellen acht verfijnde monsters: Gifspuwer, Slakkenoog, Bolle Stippel, Paars Stekelmonster, Oranje Pluismonster, Gele Girafnek, Mini-Robotmonster en Paars Spook. Elk gebruikt een GLB met losse stukken, `breekstukken.json` met steunverbindingen en scoregewichten, en `collision-planes.json` met afgeleide botsingsvlakken. De laatste verwijst met een SHA-256 naar de bijbehorende JSON.

De zeven andere modellen komen uit de gelijknamige Monsterbreker-zipbestanden in `assets/monsters/`. De Gifspuwer komt uit `assets/monters/gifspuwer-monsterbreker-test/`.

Werk de expliciete bronnenlijst in `game/tools/sync_fractured_monster.py` bij wanneer een nieuw model klaar is, registreer het model in `game/scripts/monster/catalog.gd` en voer vanaf de projectroot `python3 game/tools/sync_fractured_monster.py` uit. Het script controleert onder meer de verbindingen, scoregewichten en botsingsvormen. Importeer daarna het Godot-project en test selectie, botsingen, instorten en scoren in Monsterbreker; bronvalidatie alleen bewijst niet dat een model speelbaar is.
