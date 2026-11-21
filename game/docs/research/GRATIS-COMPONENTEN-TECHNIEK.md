# Gratis componenten — technische selectie

Onderzoek: Sem Jansen GD-005, GAME-10001, 17 oktober2026. Alleen brononderzoek;
geen packs gedownload, plug-ins geïnstalleerd of game-/engineinstellingen gewijzigd.
De lokale `project.godot` kiest `gl_compatibility`; Race stuurt progress/lateral
langs eigen baanframes, inclusief de omgekeerde keukenlus. Moeite hieronder is
onze inschatting, geen upstreambelofte of aangetoonde integratie.

## Vijf concrete mogelijkheden

| Onderdeel | Toevoeging aan Boracer | Godot/GL-bewijs en beperking | Licentie code / assets | Aanpassing en afhankelijkheden |
|---|---|---|---|---|
| **Godot Environment: zachte glow en SSAO** | Subtiele lichtgloed rond power-ups; meer diepte bij gevels en voertuigen. Beste eerste beeldproef. | Officiële 4.7-renderertabel vermeldt beide als ondersteund in Compatibility. De werkelijke Godot4.7.2-render, kosten en nacht/HUD-leesbaarheid zijn nog niet getest. | Enginecode **MIT**; geen nieuw asset vereist. | **Laag–middel**: bestaande Main/WorldArt-environment en Weather afstemmen; kleine kwaliteitsinstelling. Geen rendererwissel of extra bibliotheek. |
| **geegaz `Trail3D`** | Korte gekleurde boostsporen achter onze bestaande voertuigen, met behoud van modellen en branding. | Bron is een Godot4.1-GDScriptport op `MeshInstance3D`/`ImmediateMesh`. Daardoor GL-aansluiting aannemelijk; geen eigen4.7/GL-test of upstreamgarantie. Geen ingebouwde GPU-particletrail nodig. | Codeheader **MIT**, oorspronkelijke volledige MIT-tekst beschikbaar; geen artwork mee selecteren. Eigen materiaal kan textureloos. | **Laag–middel**: Kart boost_time → emit, lokale uitlaatankers en duidelijke segmentlimiet. Bron maakt per-frame tijdelijke arrays/punten: eerst profileren en pauze/stop/fade aanpassen. Bestaande eigen vliegtuigsporen blijven behouden. |
| **Phantom Camera** | Mooie baanintro, korte finishshot of garagepresentatie met vloeiende camerawissels. | Upstream noemt Godot4 en Camera3D; plugin.cfg noemt0.11.0.3. Gewone camerabesturing maakt GL aannemelijk, maar renderer-/4.7-integratie niet aangetoond. | Add-oncode **MIT**; voorbeeldscènes/art niet nodig en niet als apart vrij assetpakket beoordeeld. | **Middel**: add-onfolder/Host/PhantomCamera plus overgang naar bestaande Main-camera. Kies passende vaste release en controleer GDScript-pad/dependencies. Keuken-follow-camera met eigen progress/frame/clearance behouden; generieke opvolging kent die eisen niet. |
| **Beehave** | Rivalen met herkenbare keuzes: inhalen, power-up bewaren of defensief rijden. | `godot-4.x/project.godot` vermeldt **4.7 én gl_compatibility**. README noemt4.5+ bij2.10+; actuele plugin.cfg noemt nog2.9.4-dev. Dus releasekeuze expliciet verifiëren. | Add-oncode **MIT**; geen nieuwe modellen/geluiden vereist. Voorbeeldlogo’s niet nodig. | **Middel**: GDScriptgedragsboom en blackboard vullen uit Race; alleen beslissingen laten teruggeven aan `_choose_ai_lane`/powerbeleid, nooit eigen physics. Plugin/debug-autoloads bij installatie nalopen. Voor onze vier eenvoudige AI’s mogelijk meer structuur dan nodig. |
| **SuperTuxParty: invoerpictogrammen** | Duidelijke toetsen-/gamepadplaatjes bij bediening en contextuele tips; helpt vooral kinderen/controllergebruikers. | De actuele **dev**-README gebruikt Godot4.2; de oude masterpagina vermeldt3.2.2. Alleen PNG’s hergebruiken is engine-/rendereronafhankelijk. Geen bewijs nodig dat de volledige partygame bij ons draait. | Gamecode **GPL-3.0-or-later**, die nemen we hiervoor niet over. `assets/textures/controls/keyboard/*.png` en `mouse/*.png`, plus bij `gamepad` alleen `arrow*.png`, `button*.png` en `dpad*.png`, staan expliciet als **CC0-1.0** van Terazilla in LICENSE-ART, inclusief beschreven wijzigingen door Florian Kothmeier. Andere SuperTuxParty-assets hebben andere licenties. | **Laag**: alleen geselecteerde PNG’s en herkomst opnemen; eigen InputMap/laatste invoer laten bepalen welk plaatje Interface toont. Geen gameplaycode/dependency van de partygame; behoud tekst/tooltip als toegankelijk alternatief. |

Primaire bronnen per rij:

1. [Rendererondersteuning](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html), [Environment-eigenschappen](https://docs.godotengine.org/en/stable/classes/class_environment.html), [engine-MIT](https://raw.githubusercontent.com/godotengine/godot/master/LICENSE.txt).
2. [Godot4-Trail3D met code/licentieheader](https://gist.github.com/geegaz/8dfd61f600828c02acbbdaa749a2bbd5), [oorspronkelijke MIT-tekst](https://raw.githubusercontent.com/OBKF/Godot-Trail-System/master/LICENSE).
3. [Phantom Camera functies/installatie](https://github.com/ramokz/phantom-camera), [MIT](https://raw.githubusercontent.com/ramokz/phantom-camera/main/LICENSE), [versieconfiguratie](https://raw.githubusercontent.com/ramokz/phantom-camera/main/addons/phantom_camera/plugin.cfg).
4. [Beehave versiebeleid/installatie](https://github.com/bitbrain/beehave), [project4.7/GL](https://raw.githubusercontent.com/bitbrain/beehave/godot-4.x/project.godot), [pluginversie](https://raw.githubusercontent.com/bitbrain/beehave/godot-4.x/addons/beehave/plugin.cfg), [MIT](https://raw.githubusercontent.com/bitbrain/beehave/godot-4.x/LICENSE).
5. [SuperTuxParty dev-README](https://gitlab.com/SuperTuxParty/SuperTuxParty/-/raw/dev/README.md), [exacte assetfamilies/auteurs/licenties](https://gitlab.com/SuperTuxParty/SuperTuxParty/-/raw/dev/licenses/LICENSE-ART.md).

## SuperTuxKart: interessant voorbeeld, geen eenvoudige Godot-module

De concrete replay-/ghostcomponent bewaart racegegevens en maakt spookkarts;
waardevol voor een later persoonlijk-recordduel. De onderzochte implementatie is
C++ en koppelt aan eigen World/Track/GhostKart/Controller plus Bullet-types.
Dit past niet rechtstreeks bij onze Godot-GDScript/guidedRace. Kopiëren/porteren
is **hoge** moeite; de code is **GPL-3.0-or-later**, geen permissieve MIT-module.
Bij verspreiding van daarvan afgeleide code moeten de toepasselijke GPL-plichten
worden verwerkt. Advies: geen STK-code importeren als kleine visuele upgrade.
Een eigen eenvoudig ghostontwerp op onze progress/lateral/trackversiegegevens
kan later afzonderlijk worden ontworpen; dat is nieuw werk, geen gevonden
kant-en-klare component. [Concrete replaybron](https://raw.githubusercontent.com/supertuxkart/stk-code/master/src/replay/replay_play.cpp).

STK gebruikt verschillende open assetlicenties. De officiële richtlijn verlangt
per item auteur, licentie en herkomst; voor addons staat dit in `licenses.txt`.
De GPL-code geeft dus geen algemene toestemming om alle karts, textures of
muziek onder één licentie te behandelen. Er is hier **geen individueel STK-asset
vrijgegeven**: eerst het exacte bestand en zijn licentievermelding selecteren.
Eigen Boaz/Ravi en de zes voertuigen behouden.
[Code/assetlicentiebeleid](https://supertuxkart.net/Licensing),
[eigen C++-codebase](https://github.com/supertuxkart/stk-code).

## Selectie voor een volgende opdracht

Voor een boosttrail eerst onze bestaande begrensde vliegtuigsporen als eigen
basis vergelijken. De oude Trail3D-gist heeft een VIEW-eindpuntartefact en
laat bij `emit=false` bestaande punten niet verder verouderen; het is dus
geen automatische verbetering van onze eigen spoorbuffer.

Begin met **één glow/SSAO-beeldproef** en **één korte boosttrail**. Invoerpictogrammen
zijn een kleine afzonderlijke UX-winst. Phantom Camera is vooral zinvol zodra
baanintro’s gewenst zijn; Beehave pas zodra complexere AI-beslissingen werkelijk
nodig zijn. Kopieer geen volledige voorbeeldprojecten of buitenlandse mascottes.

GL sluit volgens de actuele primaire tabel onder andere compute-shaders,
CompositorEffects, Decal-nodes, volumetrische mist, SSR en ingebouwde
particletrails uit. Mesh-ribbons zijn een andere techniek. BRibbon is daarom
niet onze eerste keus: README noemt alleen Godot4.6 getest en concrete
frustum-/normalproblemen en een standaardgrens van10 instances. De Rust
Trail3D-variant ondersteunt wel Compatibility maar voegt Rust-builds en native
platformbinaries toe. [BRibbon-beperkingen](https://github.com/SoulErasers/BRibbon),
[Rust Trail3D](https://github.com/SomeRanDev/Godot-Trail3D).

Bij eventuele implementatie: release/commit vastzetten en de geselecteerde
licentieteksten bewaren; daarna echte GL-captures, frametijd, pauze/cleanup,
regen/nacht en volledige keukenlus controleren. Webonderzoek bewijst die
runtime-/beeldkwaliteit nog niet. Het onderzoek geeft geen opdracht tot installatie.
