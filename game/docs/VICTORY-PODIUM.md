# Kort overwinningspodium

Bij `race.rank == 1` maakt `interface.show_results()` naast de bestaande
uitslag een `VictoryPodium` aan. Verliezers behouden hun uitslag zonder 3D-podium.
De knoppen en eventuele opslagherhaling zijn direct bruikbaar.

De geïsoleerde SubViewport is een kind van de uitslagoverlay. De bestaande
`clear(overlay)` verwijdert dus ook de hele 3D-wereld bij opslagherhaling,
herstart of menu. Deze module kent geen beloningen of profielschrijfacties;
het bestaande `main._finish()` en `race.claim_reward()` zijn ongewijzigd.

De geselecteerde Boaz of Ravi komt rechtstreeks uit zijn bestaande GLB met de
originele staande `Cheer` van 1,6 seconde. De laatste pose blijft na de korte
viering staan; na 3,2 seconde stopt de camerabeweging. De gedeelde animatie,
rig en modellen blijven intact. De zittende `racing/finish` wordt niet gebruikt.
De laagste werkelijk geskinde schoenzoolvertex wordt bij de tijdsampling op het
podiumvlak gezet. De originele staande beenanimatie blijft behouden.

Drie verschillende voertuigen uit de huidige race verschijnen zonder coureurs
achter het podium, met de spelerkeuze altijd als eerste. Ze gebruiken de echte
racekartnormalisatie en materialen, inclusief legacy exportassen. Het podium
kent geen trackindex en werkt daarom met beide trackversies en zes voertuigen.

Verificatie:

- `godot --headless --path game --script tests/victory_podium.gd`
  controleert beide personages en zes voertuigen, originele clip, echte
  poseverandering, staande benen, voetcontact gedurende de clip, rankguard,
  zichtbaarheid, herhaalde setup, vrijgave van de wereld en echte
  opslagfout/herhaling/idempotentie van de beloning.
- `tests/tracks_v2_ui.gd` controleert de bestaande 12-trackselectie/integratie.
- `python3 game/tools/capture_step.py --step stap-22-overwinningspodium`
  maakt 18 echte GPUbeelden: zes daadwerkelijke racerosters op één echte baan,
  afwisselend Boaz/Ravi met zes spelerkeuzes, op 0,00/0,55/1,25 seconde. De
  finishstatus wordt voor deze review geforceerd; dit bewijst geen volledig
  uitgespeelde race. Het is dezelfde `_finish()` en dezelfde uitslaginterface.

Definitieve reviewrun: `../renders/GAME-10001/stap-22-overwinningspodium/20261017T130944-257622Z/`
met 18 geslaagde PNG-opnames en `contact-sheet.jpg`. Native GPU gebruikt NVIDIA
GL Compatibility. Alle 18 beelden op het contactblad beoordeeld; afzonderlijk
Boaz met opgeslagen uitslag vergroot bekeken. De capture sluit af met twee
GL-texturediagnoses (IDs 41/45, ieder 87380 bytes); de gerichte tests bewijzen
wel vrijgave van alle podium-nodewerelden bij overlayclear. Deze driverdiagnose
is geen claim dat GPU-resources bij processafsluiten volledig foutloos zijn.
