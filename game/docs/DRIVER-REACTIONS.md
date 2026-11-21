# Coureurreacties — runtime, stap 20

Schieten via de bestaande `Race.fire`-route geeft Boaz en Ravi een korte
achteromblik en echte `wink_left`. De melding komt na de bulletcooldown;
afgewezen herhaalschoten veranderen de reactie niet. Speler en AI delen dit pad.
De bestaande `boost_time` stuurt de stoelreactie, zowel bij ingedrukte turbo als
bij de Boost-powerup. Er is geen winkel of nieuwe voorraad geïmplementeerd.

`driver_reactions.gd` is één kleine additieve poselaag op de bestaande clips.
`Kart` herstelt eerst de vorige laag, samplet de bestaande AnimationPlayer
handmatig en past daarna de reactie toe. Daarmee lopen clips niet door tijdens
echte racepauze en ontstaat bij overlap geen opeenstapeling. Hips blijven op
hun clippositie, de beide clavicle/armketens blijven in hun bestaande pose in
skeletonruimte. Bovenlijf en hoofd draaien; turbo kantelt spine/chest/hoofd
achteruit. Jump/finish hebben voorrang. De laag hoort bij de kart en wordt met
de race vrijgegeven. De huidige GLBs, 51 bones, zes clips en neutrale morphs
zijn ongewijzigd; dit is geen uitvoering of acceptatie van de historische stap 5.

De schietbeweging duurt 1,25 s: aanloop 0–0,28, knipoog 0,30–0,78,
terugkeer 0,78–1,25. Herhaald vuur houdt de blik vast met een kleine hernieuwde
knipoog. Turbo bouwt in 0,2 s op en keert in ongeveer 0,33 s terug.

Gerichte verificatie:

```sh
XDG_DATA_HOME=/tmp/boracer-reaction-data godot --headless --path game --script tests/driver_reactions.gd
python3 game/tools/check_driver_reaction_morphs.py
python3 game/tools/capture_step.py --project GAME-10001 --step stap-20-coureurreacties
```

388 gerichte checks controleren beide rigs, piek/terugkeer, herhaald schieten met
turbo, stabiele hips/handen, manual-animationfreeze en echte Race-integratie met
speler/AI, cooldown, pauze, Boostpower, ingedrukte turbo en cleanup. De morphaudit
controleert de werkelijk geëxporteerde vertexdelta's per gezichtshelft en legt
GLBhashes vast. Native serie: per coureur acht opeenvolgende momenten vanuit
de gewone racecamera en een gezichtcamera, plus neutraal/turbo zijaanzicht.
Dit zijn geënsceneerde tijdreeksen in de echte racewereld, geen volledige
opgenomen of handmatig gespeelde race. De bestaande racecamera staat ver weg;
de knipoog is daarom vooral in de close-up te beoordelen. Camera/HUD zijn
niet voor de reactie aangepast.

Tijdens de eerste capture trad focusverlies op, waardoor het bestaande
pauzepaneel in de racebeelden kwam. De captureharness maakt daarom voor iedere
opname de HUD opnieuw zichtbaar. Die eerste serie is geen eindbewijs voor de
racecamera. Native Godot meldt bij afsluiten twee bekende GL-textureleaks
(2 × 87380 bytes); de captures en exitcode worden apart gecontroleerd.

Definitief bewijs: `renders/GAME-10001/stap-20-coureurreacties/20261017T123951-830036Z/`
met36frames, complete=true en exitcode0. Bestaande `kart_visuals.gd`
regressiesuite slaagt met888checks. De mislukte zijcamera-uitbreidingsrun is
bewaard als failedmetadata; de bool/intfout betrof uitsluitend de captureharness.
