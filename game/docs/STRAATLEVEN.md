# Straatleven in de buitenwerelden

Alleen Track0..4 bouwen OutdoorLife en StreetWalkers. Track5 behoudt de
fotogebaseerde keukentafelobjecten. Decoratieve voertuigen hebben geen invloed
op AI-racers, garagekeuze of botsingen.

| Wereld | Aankleding |
|---|---|
| Sunset Park | Palmbomen, warme parkstroken, geparkeerde auto's en banken |
| Neon City | Stadsbomen, donkere voertuigen en lichtaccenten |
| Regenbogenrijk | Pastelbomen en straatleven op gedragen wolkenpromenades |
| Haarlem1888 | Groene parkstroken en gestileerde historische stoomvoertuigen |
| Uithoorn2056 | Bomen, buurtstraatmeubilair en auto's op wijkniveau onder de baan |

Per buitenwereld staan24 clusters en vier wandelgezelschappen. Nieuwe
scene-nodes inclusief wandelaars:254/256/258/254/255 voor de vijf werelden.
Dit is een structuurtelling, geen gemeten GPU-/beeldsnelheid.

Elke cluster combineert een boom, geparkeerd voertuig, bank, prullenbak,
bloembak en lantaarn; een deel heeft een fietsenrek. Herhaalde onderdelen
worden per vorm/materiaal met MultiMeshes getekend. Vier lokale wandelroutes
per wereld bevatten telkens één mens met één hond aan de lijn. Mensen en honden
zijn lichte primitieve modellen, met bewegende benen, armen, poten en staart.
De lijn volgt de hand en halsband. De gesloten routes blijven op de promenade.

Meer meetgegevens en plaatsingsmarges: [geometrie](BUITENLEVEN-GEOMETRIE.md).

De plaatsing gebruikt de volledige clusterstraal, dichte baansamples, bestaande
landmarkreserveringen en huisafdrukken. Water, race-/cameracorridor en Uithoorns
tramlus blijven vrij. Verhoogde parkstroken hebben een grondfundering;
wolkenpromenades hebben een zichtbaar dragend eiland. Uithoorns straatleven
staat op wijkniveau -20.85, niet zwevend naast de verhoogde racebaan.

De actieve Track bezit alle nieuwe nodes. Wandelaars gebruiken procesdelta
in plaats van een doorlopende klok; de bestaande gamepauze bevriest hun
beweging en hervat zonder tijdsprong. Wereldwissels verwijderen de oude groep.

## Beelden maken

```bash
python3 game/tools/capture_step.py --project GAME-10001 --step stap-11-straatleven
```

Vanuit een grafische desktopterminal. Resultaten verschijnen onder
`renders/GAME-10001/stap-11-straatleven/`.
Elke run behoudt zijn metadata, bronhashes en log. Twintig beelden: per wereld
een racecamera, cluster-overzicht en twee momenten van mens/hond vanuit dezelfde
camera. De getoonde racepositie is geënsceneerd, geen opgenomen volledige race.
`capture_review.py` neemt deze fase ook mee.

Headless setupvalidatie controleert dezelfde twintig camera-opstellingen,
maar produceert geen plaatjes. Geometrie-/lifecycletests bewijzen geen native
beeldkwaliteit, zichtbaarheid vanuit iedere racepositie of beeldsnelheid op
het doelsysteem. Definitieve controle blijft een echte Godot-/speelsessie.

## Native steekproef17oktober

De gedeelde renderpagina bevat20echte beelden uit desktoprun
`20261017T081807-879995Z`. Zes hiervan zijn daadwerkelijk bekeken. De
Uithoorn-straat was deels begraven in de grasbank; de nieuwste code verhoogt
de propvloer tot-20.85,5cm boven de bank. De wolksteunen van Regenbogenrijk zijn ook verlaagd tot onder het dek.
Die wijzigingen en de betere
race-/wandelcamera's zijn headless gecontroleerd; herhaal het rendercommando
voor actuele pixels. De bestaande native run blijft als eerder bewijs bewaard.

Laatste gerichte broncontrole:157.043 plaatsingschecks en169.348 onafhankelijke
controles, geen fouten; wandelmodule120.817 plus zes echte Main-controles.
Bewijs in `validation/outdoor-life-freeze3-checks.txt` en
`validation/street-walkers-sem-checks.txt`. Deze checks bevestigen geometrie
en gedrag; de genoemde eerdere native run bevat de twee nog ongecorrigeerde
hoogtes en is geen beeldgoedkeuring van de nieuwste bron.
