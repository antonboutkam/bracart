# Beloningen en wereldweer — GAME-10001

Eigenaar: Tess GD-013. Gameplay, economie en pickups blijven eigendom van Race.
Deze presentatie gebruikt echte meshes, PBR, vertexkleur en emissie. Het effect
vereist geen bloom of screen-space reflecties die Compatibility niet levert.

## Integratiecontract

- `RewardVisuals.create_pickup(parent, kind, position) -> Node3D`: `coin` en
  `power`; Race beheert de draaiing, cooldown en zichtbaarheid van deze root.
- `RewardVisuals.burst(race, position, kind) -> Node3D`: korte animatie van
  0,55 s, zes kleine sparks en één uitdijende ring. Parent is Race met `paused`;
  pauze bevriest levensduur. Geef alleen de speler een burst om AI-spam te beperken.
  De animatie ruimt zichzelf op; raceverwijdering verwijdert alle kinderen.
- `Weather.new()` als child van de actuele track; daarna
  `setup(track, env, sun, camera, random_seed=-1)` aanroepen nadat WorldArt de
  omgeving heeft ingericht. Env is `WorldEnvironment.environment`.
- Main roept `advance(delta, focus_position, paused)` vanuit `_process` aan.
  Focus is de actuele racerpositie; zonder race kan camera dienen als focus.
  De controller verwerkt zichzelf niet automatisch. Niet daarnaast handmatig
  `_process` of een tweede timer gebruiken. Bij wereldwissel wordt de oude
  track inclusief weer verwijderd; Main initialiseert een nieuwe controller.
- QA: `force_event("rain"|"rainbow"|"night"|"sun", true)` stelt direct de
  toestand in; `advance(0.01, focus)` positioneert geometrie voor een capture.
  Onbekende events en buitenweer op de Keukentafel retourneren `false`.
  Een meegegeven seed maakt de planning reproduceerbaar; zonder seed is deze
  per sessie willekeurig. Rain/rainbow/night veranderen geen grip of besturing.

## Regie en grenzen

Eerste weersomslag na 32–55 s, evenementduur 18–32 s. Daarna komt de zon terug.
Een bui gaat eerst over in een regenboog; zo heeft de boog een bewuste context.
Regenbogenrijk krijgt automatisch alleen nacht/zon (een bewuste fantasiekeuze
boven de wolken); QA mag expliciet regen forceren. Keukentafel blijft binnen.
Overgangen zijn exponentieel: circa 3,3 s voor 95% van een lichtomslag.
Nacht heeft een donkerblauwe hemel, koel maanlicht, ambient minimum en één
shadowless fill rondom de racer zodat baan en voertuig leesbaar blijven.
De regenboog staat als verre halve cirkel voor de kijkrichting, buiten de
route; dit is een gestileerde landschapspresentatie, geen atmosferische simulatie.

Regendetail is begrensd tot 160 instanced strepen. Regenboog: één mesh met
448 quads / 896 triangles. Coins hebben een metalen lijf, gouden buitenrand, ingeslagen
binnenrand en dubbelzijdig B-stempel. Powerboxes hebben een transparante
kern, twaalf afzonderlijke gouden randen en een leesbaar billboard-vraagteken.
Natte weg verlaagt roughness en verhoogt specular; de originele waarden keren
terug bij zon en na verwijdering. Geen globale materiaalswap of economie-edit.

## Controle

`godot --headless --path game --log-file /tmp/boracer-vfx-test.log --script res://tests/reward_weather.gd`

21 gerichte checks: begrensde instances, positie, pauze, regen-naar-boog,
leesbaarheidsparameters nacht, onveranderde bronhemel, keukenrestricties,
coin/PBR/boxdetails en burst cleanup. Dit bewijst geen native beeldkwaliteit,
frametime of langdurige gameplay. Native capture-slot wordt met Sem/directie
gecoördineerd; visuele acceptatie en uitbetaling blijven bij de klant.
