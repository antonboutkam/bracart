# Gratis en open componenten voor Boracer

Onderzoek van 17 oktober 2026. Milan GD-003 integreert de bevindingen van Fenne
GD-011 en Sem GD-005; Eva GD-006 controleert primaire bronnen en bewijsgrenzen.
Dit is een onderzoeksadvies: geen pakketten geïnstalleerd, geen spelonderdelen
vervangen en geen import-, prestatie- of renderresultaat voor deze kandidaten.

De grootste verwachte winst zit in gerichte modelvariatie, rijkere effecten en
materiaalgeluiden. Een compleet ander racesysteem overnemen levert voor onze
bestaande game meer aanpassingswerk op. De huidige game gebruikt Godot 4.7 met
GL Compatibility en eigen baanframes, inclusief de omgekeerde keukenlooping.

## Kansrijkste selectie

Uren hieronder zijn onze ramingen voor een kleine proef inclusief koppeling en
controle, geen gemeten doorlooptijden of volledige wereldombouw. De genoemde
licenties hebben geen aanschafkosten; ontwikkeling en afstemming blijven werk.

| Component en primaire bron | Concrete verbetering in onze game | Licentie | Moeite en belangrijkste grens |
|---|---|---|---|
| **[Kenney Nature Kit](https://kenney.nl/assets/nature-kit)** | Meer boom-/struiksilhouetten langs Haarlem en Uithoorn, in plaats van steeds dezelfde primitieve vormen. | CC0 | Laag: circa 3–6 uur voor 3–5 gekozen modellen in één buitenwereld. Schaal, palet en veilige bestaande plaatsingspunten behouden. Actuele ZIP-formats nog inspecteren. |
| **[Kenney Furniture Kit](https://kenney.nl/assets/furniture-kit)** | Een rijker ingerichte keukenwand en boekenkast op de achtergrond van de tafelbaan. | CC0 | Laag–middel: 4–8 uur voor één kamerwand. Eigen fotovoorwerpen en berijdbare speelgoedconstructies blijven de herkenningspunten. |
| **[Kenney Particle Pack](https://kenney.nl/assets/particle-pack)** | Stof bij landen, kleine vonken bij botsen, rook en feestelijke finishdeeltjes. Dit zijn effectplaatjes, geen kant-en-klaar 3D-effectensysteem. | CC0 | Laag–middel: 3–6 uur voor twee effecten met billboards/CPUParticles3D en vaste aantallen. Aanvullen op bestaande pickupflitsen; pauze en cleanup meenemen. |
| **[Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds)** | Hoorbaar verschil tussen landen op hout, karton of plastic en betere zachte botsingen. | CC0 | Laag–middel: 3–6 uur voor enkele beluisterde clips. Bestaande hit-cue kan aansluiten; een landingevent vraagt nog een kleine gameplaykoppeling. Raviracer-motorloops zijn een apart bestaand systeem. |
| **[Godot glow en SSAO](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html)** | Subtiele gloed rond beloningen en meer contactdiepte bij gebouwen en voertuigen. | Onderdeel van MIT-engine | Laag–middel: 2–4 uur voor een beeldproef. Officiële 4.7-tabel ondersteunt beide in Compatibility. Tonemapping bestaat al; glow/SSAO zijn niet expliciet ingeschakeld in onze scripts. Resultaat, framekosten en nacht/HUD-leesbaarheid nog beoordelen. |
| **[Trail3D van geegaz](https://gist.github.com/geegaz/8dfd61f600828c02acbbdaa749a2bbd5)** | Korte gekleurde boostsporen achter de bestaande voertuigen. | MIT-codeheader; volledige oorspronkelijke licentie behouden | Middel: 4–8 uur voor één voertuig. GDScript/ImmediateMesh maakt GL aannemelijk, maar bron is een Godot 4.1-port. Puntlimiet, allocaties, uitlaatankers en pauze controleren; geen geverifieerde 4.7-drop-in. |
| **[Dialogue Manager 4](https://github.com/nathanhoad/godot_dialogue_manager)** | Korte gesprekjes tussen Boaz en Ravi vóór een race, een opdrachtbriefing of uitspraken bij de uitslag. | MIT | Middel: 4–8 uur voor één gesprek in onze eigen UI, inclusief Nederlandse tekst. Upstream noemt Godot 4.6+; [release v4.1.0](https://github.com/nathanhoad/godot_dialogue_manager/releases/tag/v4.1.0) is voor Godot 4.7. Geen stemmen of missies inbegrepen. |
| **[SuperTuxParty-invoerpictogrammen](https://gitlab.com/SuperTuxParty/SuperTuxParty/-/raw/dev/licenses/LICENSE-ART.md)** | Duidelijke toetsen-/controllerplaatjes bij uitleg, garage en contextuele tips. Een concreet herbruikbaar onderdeel uit een andere game. | CC0-1.0 voor de expliciet genoemde bestanden; bij gamepad: arrow*/button*/dpad*.png | Laag: 2–4 uur voor geselecteerde PNG's en koppeling aan onze eigen invoer. De overige art en GPL-gamecode hebben andere voorwaarden. |

De proefuren mogen niet worden gelezen als toezegging dat een heel pakket
zonder wijzigingen past. Zelfs bij een kant-en-klaar model moeten schaal,
materialen, normals en zicht vanaf onze racecamera kloppen.

## Advies voor de eerste verbeterronde

Begin met één kleine buitencluster uit Nature Kit, twee deeltjes-effecten en
een paar materiaalgeluiden. Vergelijk met dezelfde camera en dezelfde race
voor en na de wijziging. Daarmee krijgen we zowel meer visuele variatie als
duidelijkere feedback tijdens sprongen en botsingen. Test glow/SSAO in een
aparte beeldproef; voer het alleen door wanneer het echt beter oogt en vlot blijft.

Onze bestaande vliegtuigsporen bieden al een eigen basis voor meshsporen.
Vergelijk die eerst met de oude Trail3D-gist voordat we een nieuwe afhankelijkheid
toevoegen; de gist is een kandidaat/referentie, geen noodzakelijke installatie.

Daarna is de keukenkamer een logische tweede proef met Furniture Kit. Boostsporen
kunnen snelheid aantrekkelijker maken. Dialogue Manager is vooral zinvol wanneer
we werkelijk korte verhalen of opdrachten willen schrijven; alleen voor één
los tekstballonnetje kan onze eigen UI eenvoudiger zijn. Dit is onze inschatting.

## Overige onderzochte mogelijkheden

[Kenney City Kit Suburban](https://kenney.nl/assets/city-kit-suburban) is CC0 en
bruikbaar voor een achtergrondwooncluster in Uithoorn. Generieke voorstadhuizen
geven op zichzelf geen geloofwaardig Haarlem 1888: onze straatfoto's, Nederlandse
gevelverhoudingen en landmarks blijven daarvoor leidend. Raming 6–12 uur voor
één aangepast cluster.

[Quaternius Ultimate Nature](https://quaternius.com/packs/ultimatenature.html)
is een CC0-alternatief voor groen, met FBX/OBJ/Blend volgens de maker. Selectie
en GLB-export geven meer werk; kies eerst één samenhangende groenstijl.
[Poly Haven Wood Floor Deck](https://polyhaven.com/a/wood_floor_deck) is een
aanvullend CC0-houtmateriaal, vooral voor verweerde plankjes. Vier andere Poly
Haven-materialen zitten al in het project; dat materiaalpad is dus geen nieuwe
integratie. Zie [bestaande materiaalbronnen](LANDMARKS-EN-MATERIALEN.md).

[Phantom Camera](https://github.com/ramokz/phantom-camera) en
[Beehave](https://github.com/bitbrain/beehave) zijn MIT-add-ons voor respectievelijk
cameraovergangen en AI-beslissingen. Interessant voor baanintro's of uitgebreidere
rivalen, maar geen eerste noodzaak voor onze huidige besturing. Onze keukenvolgcamera
heeft eigen eisen voor ondersteboven rijden en veilige afstand tot de baan.

## Onderdelen uit andere games

SuperTuxParty laat zien dat losse assets uit een open game herbruikbaar kunnen
zijn, mits hun eigen licentie expliciet is gecontroleerd. Dat maakt niet de hele
game of al zijn bestanden CC0.

Hetzelfde [SuperTuxParty-licentiemanifest](https://gitlab.com/SuperTuxParty/SuperTuxParty/-/raw/dev/licenses/LICENSE-ART.md)
noemt ook Quaternius-props onder CC0: `assets/models/boat/boat.glb` met atlas,
`assets/models/furniture/books/book*.glb` met atlaskaarten en onder andere
`furniture/lamp.glb`. Dat zijn interessante extra kandidaten voor een bootje op
de Amstel en boekjes/lampen in de kamer. Het manifest vermeldt de GLB-bestanden;
de modelbestanden en hun actuele inhoud zijn nog niet geïnspecteerd. Dit blijft
een aparte proef van naar schatting 3–6 uur voor één geselecteerde prop.

Bij **SuperTuxKart** is de onderzochte
[replay-/ghostcode](https://raw.githubusercontent.com/supertuxkart/stk-code/master/src/replay/replay_play.cpp)
C++ onder GPL-3.0-or-later en gekoppeld aan de eigen engine/physics. Dat is geen
eenvoudige Godot-component. Een spookrijder van een eigen record is inhoudelijk
wel aantrekkelijk, maar zou apart ontworpen werk zijn. De
[assetlicenties](https://supertuxkart.net/Licensing) verschillen per bestand;
dit onderzoek geeft geen generieke vrijgave van STK-modellen of muziek.

## Gebruiksvoorwaarden en technische selectie

Voor de gekozen CC0-assets bevestigen de makerpagina's en
[CC0](https://creativecommons.org/publicdomain/zero/1.0/) gebruik, bewerking en
distributie, ook commercieel, zonder verplichte credits. De gratis individuele
downloads vereisen geen betaalde bundel of optionele donatie. Bewaar bij uitvoering
wel de originele bron-/licentietekst en bestandsversie.

Bij MIT-code blijven copyright- en licentieteksten bij de overgenomen code:
zie bijvoorbeeld de [Dialogue Manager-licentie](https://github.com/nathanhoad/godot_dialogue_manager/blob/main/LICENSE).
Een gratis download of openbare repository zonder passende licentie is geen
voldoende hergebruikbewijs. Code, modellen, muziek en merken afzonderlijk bekijken.

De actuele [Godot 4.7-renderertabel](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html)
sluit in Compatibility onder meer volumetrische mist, Decal-nodes, SSR,
CompositorEffects, compute en ingebouwde particletrails uit. Meshsporen en
billboards zijn andere technieken. Daarom is een willekeurig spectaculair
shaderpakket geen verantwoorde aanbeveling zonder bron-/rendercontrole.

Bij implementatie eerst een kleine afzonderlijke proef: concrete download en
licentie vastleggen, native import/render en geluid beoordelen, frametijd meten,
dan pauze, nacht/regen, camera en wereldwissels toetsen. Onderzochte beschikbaarheid
en aannemelijke compatibiliteit zijn geen geslaagde integratie.

Details: [assetonderzoek](research/GRATIS-COMPONENTEN-ASSETS.md) en
[technisch onderzoek](research/GRATIS-COMPONENTEN-TECHNIEK.md).
