# Stunt Edition

Variant 2 heet zichtbaar **Stunt Edition**. De interne twaalf trackdescriptors,
`-v2` IDs, records, saveformaat en routes blijven gelijk. `Catalog.track_name()`
levert de volledige naam aan HUD/finish/resultaten; oorspronkelijke namen blijven.

Baanselectie toont de editie als toggle en als decoratief lint over elke V2-kaart.
De wereldnaam staat apart zodat Regenbogenrijk en De Keukentafel volledig passen.
De cockpit toont hetzelfde lint naast het rondepaneel; alleen de V2-naam gebruikt
13px om de volledige naam binnen het bestaande paneel te houden. De Racen-tegel
op Home toont het lint uitsluitend als het huidige circuit variant 2 is.

`stunt_ribbon.gd` tekent het schuine gouden lint met cyaanrand in bestaande
branding; geen gegenereerde of externe afbeeldingen. Lint en label negeren muis,
hebben geen focus en behouden alle bestaande buttons/callbacks.

Zes echte Godotbeelden (selectie, cockpit, Home voor beide varianten), zelf door
Lina bekeken, staan onder `renders/GAME-10001/stap-23-stunt-edition/20261017T131421-645847Z/`.
Capturetool: `python3 game/tools/capture_step.py --project GAME-10001 --step stap-23-stunt-edition`.
Dit zijn vaste reviewmomenten, geen handmatig gespeelde volledige race.
Bronfreeze en beperkte diff: `validation/stunt-edition-freeze.json` en
`validation/stunt-edition-scope.diff`. Eerste sandbox-X11poging faalde;
herhaling met toegestane desktoptoegang leverde alle zes beelden zonder fout.

Bestaande `tracks_v2_ui.gd`: 74 checks, 0 failures. Deze voert alle twaalf
selectiecallbacks, pauze/herstart en variantbehoud via Home uit; geen nieuwe
copy-mirroringtests toegevoegd. Zie `validation/stunt-edition-ui-checks.txt`.
