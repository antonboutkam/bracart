# Gratis assets voor Boracer — bronnenonderzoek

Fenne Bos, GD-011. GAME-10001, 17 oktober 2026. Opdracht: onderzoek, geen assetimport of productwijziging. Integratie-uren zijn eigen ramingen voor één beperkte proef inclusief import en review; geen bewezen Godot-resultaten of volledige wereldombouw.

## Advies

Begin met **Kenney Nature Kit**, **Kenney Furniture Kit** en **Kenney Impact Sounds**. Daarmee kunnen we bestaand groen en de kamer verfijnen en sprongen/landingen hoorbaar maken zonder voertuigbesturing te vervangen. Voor realistischere lokale gevels levert gericht modelwerk waarschijnlijk meer op dan generieke voorstadhuizen. Fototexturen zijn bovendien al deels aanwezig.

Alle zes hieronder beschreven pakketten/materialen zijn gratis beschikbaar onder CC0. Commercieel gebruik, bewerking en distributie zijn toegestaan; naamsvermelding is niet verplicht. Dat volgt uit de packpagina's en [CC0](https://creativecommons.org/publicdomain/zero/1.0/). Optionele donaties, bundelaankopen of abonnementen zijn geen voorwaarde voor deze specifieke gratis downloads. CC0 op assets is iets anders dan een open-source spelengine.

## Concrete selectie

| Component en primaire bron | Geschiktheid | Formats en bewijsgrens | Proefintegratie, eigen inschatting |
|---|---|---|---|
| [Kenney Nature Kit](https://kenney.nl/assets/nature-kit), 330 bestanden volgens maker | Bomen, rotsen en begroeiing. Hoekige stijl past bij speelse voertuigen; meerdere silhouetten verrijken huidige buitendecors. | Maker bevestigt 3D en CC0. GLB is het algemene [Kenney-importadvies](https://kenney.nl/knowledge-base/game-assets-3d/importing-3d-models-into-game-engines); precieze huidige ZIP-inhoud niet geïnspecteerd. | Laag, 3–6 uur voor 3–5 modellen, vaste meterschaal en bestaande veilige plaatsingspunten. |
| [Kenney Furniture Kit](https://kenney.nl/assets/furniture-kit), 140 bestanden volgens maker | Meer overtuigende boekenkast, stoelen en kamer achter de keukentafel. Behoud herkenbare eigen fotoprops. | Actuele pagina: CC0. Oudere [publicatie door Kenney zelf](https://opengameart.org/content/furniture-kit) noemt 120 objecten, OBJ en PNG; dat is een andere revisie. GLB indien aanwezig, anders OBJ/Blender naar GLB. | Laag tot middel, 4–8 uur voor één kamerwand. Selectie, schaal, palet en camera-/baanvrijheid controleren. |
| [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds), 130 bestanden volgens maker | Landingen op karton/hout/plastic en zachte botsingen. Aanvulling op eigen raviracer-motorgeluid. | Maker bevestigt audio en CC0; codec, bitdiepte en individuele geschikte clips staan niet op de bronpagina. WAV/OGG is ons gewenste eindformaat, geen geverifieerde packclaim. | Laag tot middel, 3–6 uur voor 4–6 beluisterde clips en landingevents. Volume, cooldown en pauze bewaken. |
| [Kenney City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban), 40 bestanden volgens maker, versie 2.0 | Achtergrondwoningen voor Uithoorn onder verhoogde baan. Minder geschikt voor historisch Haarlem: generieke voorstad is geen Nederlandse reconstructie. | [Oudere makerpublicatie](https://kenney-assets.itch.io/city-kit-suburban) noemt OBJ/FBX/DAE/STL/glTF en ruim 35 modellen; niet aannemen dat revisie 2 identiek is. GLB voorkeursroute na inspectie. CC0. | Middel, 6–12 uur voor één wooncluster. Nederlandse dak-/gevelverhoudingen en toekomstaccenten vragen aanpassing. |
| [Quaternius Ultimate Nature Pack](https://quaternius.com/packs/ultimatenature.html), 150 modellen | Alternatief groen voor polder/rivierkanten. Eerst naast Kenney vergelijken; geen willekeurige stijlenmix. | Primaire pagina noemt FBX, OBJ en Blend expliciet, plus CC0. Blender naar GLB is een bruikbare route; geen archive-/polycountinspectie. | Middel, 5–10 uur voor selectie, export en één buitencluster; schaal, culling en schaduwen op raceafstand beoordelen. |
| [Poly Haven Wood Floor Deck](https://polyhaven.com/a/wood_floor_deck), Dimitrios Savva | Nieuwe houtnerf voor houtblokjes, plankjes of verweerde buitenvlakken. Versleten buitenvloer, dus minder passend als gladde keukentafel. | Diffuse, roughness, OpenGL-normal en displacement in JPG/PNG/EXR; nominale tegelbreedte 1,8 m. [CC0](https://polyhaven.com/license). Kies lage resolutie en geen displacement voor deze proef. | Laag, 2–4 uur voor één prop. Bestaand materiaalpad; subtiele normals en gecontroleerde UV-schaal. |

Kenney bevestigt [commercieel gebruik en geen verplichte credits](https://kenney.nl/support). Zijn logo mag niet voor een eigen project worden gebruikt. Quaternius biedt deze oude gratis pack naast betaalde Patreon-/Source-aanbiedingen; die andere producten zijn niet nodig. Bij Poly Haven zijn de assetslicentie en voorwaarden voor een eventuele live API aparte zaken.

## Wat al aanwezig is

De repository bevat al Poly Haven **Red Brick**, **Cobblestone Floor 01**, **Concrete Floor 02** en **Asphalt 02**, met twaalf 1k-kanalen: zie [bestaand rapport](../LANDMARKS-EN-MATERIALEN.md) en `assets/textures/worlds/photographic/sources.json`. Die vier zijn geen nieuwe onderzoekswinst. Bomen, meubels, straatleven, regen, regenbogen, vliegtuig en vogel bestaan ook al: nieuwe packs moeten aantoonbaar verbetering of variatie geven.

## Godotroute en beoordelingscriteria

`project.godot` gebruikt `gl_compatibility`. [Godot adviseert glTF/GLB](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html); standaardmesh/materialen kunnen zonder plugin in de bestaande nodestructuur. Dat is een onderbouwde verwachting, geen geteste compatibiliteitsclaim voor deze downloads. OBJ heeft beperkte materiaal-/animatiegegevens; indien nodig expliciet naar GLB exporteren. Texturemappen behouden en ongewenste dubbele vlakken vermijden.

Kleine proef: drie boomvarianten, één kamerwand en enkele landinggeluiden. Bron-ZIP/licentietekst bewaren; auteur, versie, hashes en wijzigingen registreren. Vervolgens echte import, schaal/normals/kanalen, collision-/cameraruimte, geluidmix, pauze en cleanup controleren. Native racecaptures voor/na met dezelfde camera vergelijken en framekosten meten. Daarna pas opschalen; geen volledige ongebruikte packs meeleveren.

## Onderzoeksgrens

Primaire webpagina's geraadpleegd; geen assets geïnstalleerd of in Godot gerenderd. ZIP-metadata kon via de webtool niet worden gelezen; een beperkte netwerkpoging voor alleen directorygegevens liep tegen DNS-beperking aan. Actuele aantallen volgen makerpagina's; niet-bevestigde formats/geluidsdetails staan expliciet open. Bij daadwerkelijke download de concrete bestanden en licentie opnieuw vastleggen.
