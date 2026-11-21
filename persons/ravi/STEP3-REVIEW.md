# Ravi — stap 3, kostuumgeometrie

Datum: 17 oktober 2026. Uitvoerder: Bram Vos GD-008; onafhankelijke visuele/scope-review: Omar GD-012. Status: **reviewkandidaat; geen klantacceptatie of uitbetaling**. Stap 4/5 blijven open.

Primaire bronnen: originele [character sheet](character-sheet.png) en [ravi-stijl.md](ravi-stijl.md). Anatomie en haar uit stap 1/2 zijn intact; bestaande atlas/PBR en animatieontwerp zijn behouden. Geen actieblad-outfit overgenomen.

## Herkenbare kostuumonderdelen

- Groene utility-bodywarmer met gevormde kraag, volumetrische zakken en oranje rand-/naaddetails.
- Roomwit shirt met afgeronde gesloten mouwbovenkant; de te laag hangende shirtzoom is ingekort tot de riem.
- Oranjegroene rugzak met zachte zijvolumes, flap/cinches en groene klaver; beide doorlopende schouderbanden behouden.
- Donkere vingerloze handschoenen, riemtasjes, denim en opgerolde cuffs behouden; zijnaad volgt nu dij- én scheenbeweging in plaats van één star bot.
- Afgeronde groen-oranje-witte sneakers met gerolde kraag, kruisveters en zoolprofiel. Nieuwe los uitstekende vouwcurves zijn na echte zij/zitcontrole verwijderd.

## Werkelijke bewijsstukken

- [Bevroren GLB](review-step3/after/ravi.glb), [bewerkbare Blenderbron](review-step3/after/ravi.blend) en [zes werkelijke Blenderbeelden](review-step3/after/renders/overzicht.jpg).
- [GLB-structuurcontrole](review-step3/after/glb-validation.json): één materiaal, twee embedded textures, 51 joints en alle zes bestaande clips; geslaagd.
- [Verse Blender-import](review-step3/after/blender-import-validation.json): één skinned karaktermesh/armature, 20 neutrale morphs, alle zes clips bemonsterd, hoogte circa 1,15 m; geslaagd. Blender-hulpicospheres zijn geen extra karaktermesh.
- [Werkelijke Godot 4.7.2-import](godot-step3-validation.json): **75/75 controles**, geen failures, zes clips aanwezig. Root heeft na kopiëren van beide definitieve gameassets ook **888 kart-, 56 garage- en 1.464 volgcameracontroles** met nul failures uitgevoerd; [testuitvoer](../../game/validation/character-step3-checks.txt). Dit zijn headless controles.
- [Scope-audit](review-step3/after/scope-audit.json): 9/9 geslaagd. Ongeroonde float32-positiepayloads van alle beschermde hoofd/haar/huidtriangles exact gelijk; normals/UV/gewichten/morphs gelijk op gerapporteerde precisie. Rig, inverse-bind, node-transforms, alle animatiepayloads, morphnamen/defaults, materialen en beide embedded textures gelijk.
- Beschermde triangles: 23,168 hoofd/nek/haar en 1,192 overige huid. Haarmodule byte-identiek; beschermde anatomie-/gezicht-/skelet-/animatie-/atlasfuncties AST-identiek aan baseline.
- Eigen GLB-scope-audit door Omar staat apart in `review-step3/qa-scope-audit.json`; werkelijk gevoerde QA staat in `organisatie/projecten/GAME-10001/overleg/2026-10-17-character-qa.md` vanaf repositoryroot.

| GLB-triangles | Aantal |
|---|---:|
| Stap 2 baseline | 37,644 |
| Definitieve stap 3 | 46,304 |
| Richtwaarde | 12.000–25.000 |

**Het trianglebudget is niet gehaald.** De nieuwe volumes en, bij Boaz, geometrisch aansluitende cape-heraldiek kosten extra triangles. Optimalisatie/LOD en een runtimebenchmark blijven open; geslaagde structuur-/importtests bewijzen geen framerate.

## Visuele vergelijking

[Voor](review-step3/01-front-comparison.jpg) · [Driekwart](review-step3/02-three-quarter-comparison.jpg) · [Zij](review-step3/03-side-comparison.jpg) · [Achter](review-step3/04-back-comparison.jpg) · [Gezicht](review-step3/05-face-comparison.jpg) · [Kartzit](review-step3/06-kart-pose-comparison.jpg).

Dit zijn echte Cycles-renders van opgeslagen geometrie, met dezelfde camera/lichtopstelling als de baseline: 600×720, 16 samples, denoising uit. Ruis blijft zichtbaar; presentatie/PBR wordt pas in stap 4 aangepast. Dit zijn **Blenderbeelden**. Native Godot-capture blijft geblokkeerd door de bevestigde AF_UNIX-sandboxbeperking; headless engine-/game-integratie is hierboven met echte rapporten vastgelegd. De [centrale bladergalerij](../../renders/GAME-10001/blender-stap-03/index.html) bevat twaalf echte, als Blender gelabelde beelden.

Alle zes afbeeldingen zijn opnieuw gerenderd voor de definitieve GLB, zonder de verwijderde vouwcurves. [Per beeld bronhash](review-step3/render-provenance.json).

De getoonde kartpose is werkelijk vervormde geometrie zonder voertuig. Volledige voertuigvrijloop, alle animaties en precieze retargeting worden hiermee niet bewezen. Bij Ravi blijft de kleine knienaad bij buiging een expliciet aandachtspunt voor skinning in stap 5. De procedurele kandidaat is herkenbaar, geen exacte sculpt van de illustraties.

## Bewaren en herhalen

Baseline inclusief volledige outputs en tools: `persons/backups/2026-10-17-step3/`. Definitieve bronkopieën: `persons/backups/2026-10-17-step3/sources-after/`. De permanente entrypoint blijft `persons/tools/build_characters.py` met `character_hair.py` en `character_clothes.py`.

Korte hervatbare calls voorkomen verlies bij een runner-SIGTERM. Vanuit `boracer/`:

```bash
BORACER_FAST_EXIT=1 BORACER_BUILD_ONLY=1 /snap/blender/current/blender --background -noaudio --factory-startup --threads 4 --python persons/tools/build_characters.py -- ravi
BORACER_FAST_EXIT=1 BORACER_VIEWS=01,02,03 /snap/blender/current/blender --background -noaudio --factory-startup --threads 4 --python persons/tools/render_characters.py -- ravi
BORACER_FAST_EXIT=1 BORACER_VIEWS=04,05,06 /snap/blender/current/blender --background -noaudio --factory-startup --threads 4 --python persons/tools/render_characters.py -- ravi
BORACER_FAST_EXIT=1 /snap/blender/current/blender --background -noaudio --factory-startup --python persons/tools/measure_character_sources.py -- ravi
```

Bij een onderbroken render kan één view worden hervat. Meet na `BUILD_ONLY` de opgeslagen bron voor actuele `validation.json`; het GLB-rapport blijft leidend voor exportcounts (Ravi's Blender-evaluatie telt acht triangles minder). Draai één Blenderproces tegelijk. Bestaande standaardaanroep zonder `BUILD_ONLY` bouwt en rendert nog steeds volledig. Bevroren `review-step3/after` nooit blind overschrijven.

Definitieve GLB SHA-256: `69bae3d32cc5e240b9f1c42c57ddacbfa9822ef5a00a6f9f8dacb29110efcf6d`.
