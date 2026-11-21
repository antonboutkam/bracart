# BoRacer — Godot Racing Game & Resources

BoRacer is a planned, colorful arcade racing game built with Godot. This directory contains the resources created so far: vehicle models, character models, world concepts, track references, interface mockups, and the tools used to build some of the assets.

**Playable prototype added October 17, 2026:** open [game/project.godot](game/project.godot) in Godot 4.7.2, or run `./start.sh` from this folder. See [game/README.md](game/README.md) for controls, implementation status, verification and the remaining design work. **All six vehicle designs are now playable**. De Raketfiets and Retro are free; the others can be unlocked with race coins. Version 2 adds distinct circuits, seated driver reactions, improved AI/camera, 3D garage previews and backward-compatible saves. See [development round 2](game/docs/DEVELOPMENT.md).

**Resource inventory date:** October 17, 2026. The asset inventory below was written before the playable prototype. Its asset readiness notes describe that snapshot; gameplay now lives separately in `game/`. The local editor is available with `godot` or through the **Godot Engine** applications menu.

## Resource map

| Folder | Contents | Current role |
| --- | --- | --- |
| [game/](game/) | Runnable Godot prototype, code, runtime asset copies and checks | First playable race cycle; see its README for limitations |
| [vehicles/](vehicles/) | Six vehicle designs, GLB models, appearance references, and technical specifications | Candidate racing vehicle visuals; driving behavior still needs implementation |
| [persons/](persons/) | Boaz and Ravi, Blender sources, textures, rigs, animations, validation reports, and authoring tools | Candidate drivers; seating and animation integration still need testing |
| [worlds/](worlds/) | Four themed worlds, each with a written design and concept artwork | Environment and level design references |
| [tracks/](tracks/) | Track atmosphere and technical reference sheets | Circuit design references |
| [user-interface/](user-interface/) | Cockpit, store, and overall interface artwork | UI design references |
| [scenes/](scenes/) | Store and atmosphere images | Scene concepts; these are PNGs, not Godot scene files |
| [assets/](assets/) | Original photographs, depth references, and an empty atmosphere note | Supporting reference material |

The detailed inventory below describes the files in each folder. Existing Dutch names and original source documents are preserved; this README provides English descriptions.

## Starting the Godot game

Voor een nieuwe installatie vanuit Git, zie [INSTALL.md](INSTALL.md).

Het spel en de bijbehorende bronnen staan rechtstreeks in de hoofdmap van deze repository (voorheen `public_html/boracer`). Start vanuit deze hoofdmap met `./start.sh`; het Godot-project staat in `game/`. Alle relatieve paden tussen deze mappen blijven behouden.

De verhuizing is gecontroleerd op vaste URL’s en bestandspaden. De startscript- en hulpmiddelpaden worden vanuit hun eigen bestandslocatie bepaald. De commando’s in de documentatie en renderpagina’s zijn bijgewerkt. `res://`- en `user://`-paden en externe bron- en licentielinks blijven geldig. Historische logs, metadata, validatierapporten en het afzonderlijke overdrachtspakket bewaren hun oorspronkelijke paden.

```bash
./start.sh
```

Or open `game/project.godot` in Godot 4.7.2 and press **F5** (main scene: `game/scenes/main.tscn`). The standalone prototype contains a main menu, six procedural world circuits, five racers, three-lap races, pickups, power-ups, HUD, garage and local saves. Track-guided arcade handling is an initial implementation choice.

The runtime assets are copies in `game/assets/`; the authoring folders `persons/` and `vehicles/` remain independent. De Raketfiets is the default vehicle for new and once-migrated profiles, while AI racers each use a different vehicle. Later deliberate garage choices remain saved. Both Retro and De Raketfiets are free; all six finished designs are integrated. To refresh those approved snapshots after the model authors finish an update:

```bash
python3 game/tools/sync_assets.py
```

Changing the available vehicle list requires an explicit list of finished designs; see [the game documentation](game/README.md). Future models are not automatically declared ready merely because a GLB exists.

## Vehicle resources

| Vehicle folder | Design and available model |
| --- | --- |
| [golden-rocket-racer/](vehicles/golden-rocket-racer/) | Golden Rocket Racer; original GLB, color reference, technical sheet, and reconstruction specification |
| [purple-passion/](vehicles/purple-passion/) | Purple Passion rocket kart; original GLB and reconstruction references |
| [rainbow/](vehicles/rainbow/) | Rainbow Racer; original GLB and reconstruction references |
| [raketfiets/](vehicles/raketfiets/) | Raketfiets (rocket bicycle); original GLB and reconstruction references |
| [retro/](vehicles/retro/) | Retro 8, an orange-and-cream retro rocket racer; original GLB and reconstruction references |
| [toxic-turbo/](vehicles/toxic-turbo/) | Toxic Turbo; original GLB plus an improved model, editable Blender source, texture/build tools, and previews |

### Improved models for all vehicle designs

The five other vehicles now also have separate `*-improved.glb` assets, editable Blender sources, embedded reference-based paint maps, rebuild tools, import reports and nine inspection views. Original GLBs are retained. See [the combined preview](vehicles/verbeterde-voertuigen.jpg) and [build instructions](vehicles/tools/README.md).

| Vehicle | Improved asset | Inspection views and build notes |
| --- | --- | --- |
| golden-rocket-racer | [golden-rocket-racer-improved.glb](vehicles/golden-rocket-racer/golden-rocket-racer-improved.glb) | [Overview](vehicles/golden-rocket-racer/previews/overzicht.jpg), [source and notes](vehicles/golden-rocket-racer/source/README.md) |
| purple-passion | [purple-passion-improved.glb](vehicles/purple-passion/purple-passion-improved.glb) | [Overview](vehicles/purple-passion/previews/overzicht.jpg), [source and notes](vehicles/purple-passion/source/README.md) |
| rainbow | [rainbow-improved.glb](vehicles/rainbow/rainbow-improved.glb) | [Overview](vehicles/rainbow/previews/overzicht.jpg), [source and notes](vehicles/rainbow/source/README.md) |
| raketfiets | [raketfiets-improved.glb](vehicles/raketfiets/raketfiets-improved.glb) | [Overview](vehicles/raketfiets/previews/overzicht.jpg), [source and notes](vehicles/raketfiets/source/README.md) |
| retro | [retro-improved.glb](vehicles/retro/retro-improved.glb) | [Overview](vehicles/retro/previews/overzicht.jpg), [source and notes](vehicles/retro/source/README.md) |

Measured improved GLBs (separate from the original inventory below):

| Vehicle | Triangles | Embedded images | Width × height × length (m) | Godot import |
| --- | ---: | ---: | --- | --- |
| golden-rocket-racer | 39,454 | 3 | 0.945 × 0.852 × 1.893 | Passed: headless import and scene instantiation |
| purple-passion | 39,454 | 3 | 0.945 × 1.033 × 1.893 | Passed: headless import and scene instantiation |
| rainbow | 33,954 | 3 | 0.945 × 0.852 × 1.893 | Passed: headless import and scene instantiation |
| raketfiets | 33,955 | 3 | 0.945 × 1.139 × 1.893 | Passed: headless import and scene instantiation |
| retro | 39,465 | 3 | 0.945 × 0.852 × 1.893 | Passed: headless import and scene instantiation |

These are reconstructed interpretations of the illustrated references. Godot headless import is checked separately from Blender and binary validation; driving, physics, animation and final in-game lighting still need implementation. Measurements are recorded in each vehicle’s `source/build-report.json` and `source/validation-report.json`.

### Model contents inspected directly

These counts come from the GLB JSON data. They describe exported resources, not rendering performance or visual approval.

| GLB | Meshes | Materials | Embedded images | Skins | Animation clips |
| --- | ---: | ---: | ---: | ---: | ---: |
| [vehicles/golden-rocket-racer/golden-rocket-racer.glb](vehicles/golden-rocket-racer/golden-rocket-racer.glb) | 59 | 0 | 0 | 0 | 0 |
| [vehicles/purple-passion/purple-passion.glb](vehicles/purple-passion/purple-passion.glb) | 183 | 0 | 0 | 0 | 0 |
| [vehicles/rainbow/rainbow.glb](vehicles/rainbow/rainbow.glb) | 123 | 15 | 0 | 0 | 0 |
| [vehicles/raketfiets/raketfiets.glb](vehicles/raketfiets/raketfiets.glb) | 57 | 0 | 0 | 0 | 0 |
| [vehicles/retro/retro.glb](vehicles/retro/retro.glb) | 77 | 10 | 0 | 0 | 0 |
| [vehicles/toxic-turbo/toxic-turbo-improved.glb](vehicles/toxic-turbo/toxic-turbo-improved.glb) | 47 | 14 | 2 | 0 | 0 |
| [vehicles/toxic-turbo/toxic-turbo.glb](vehicles/toxic-turbo/toxic-turbo.glb) | 86 | 0 | 0 | 0 | 0 |

Golden Rocket Racer, Purple Passion, Raketfiets, and the original Toxic Turbo currently contain **no material definitions**. Their original appearance needs review against the color references before use; prefer the separate improved versions above. None of the vehicle GLBs contains animation clips; wheel movement and effects need their own implementation.

For Toxic Turbo, use the improved GLB as the starting visual. Its recorded validation reports 43,955 triangles, 14 materials, two embedded images, and dimensions of approximately **0.945 m wide × 0.851 m high × 1.893 m long**. Its documented orientation is **+Y up, -Z forward**. `Wheel_Rear_L`, `Wheel_Rear_R`, `Wheel_Support_Front`, and `Wheel_Support_Rear` are separate wheel pivot groups; local X is the documented wheel rotation axis. The source does not supply driving physics, collision shapes, particles, or LODs. Emissive materials are included; the final glow appearance needs Godot scene configuration.

### Vehicle files

Paths in each table are relative to the linked folder heading.

#### [vehicles/golden-rocket-racer/](vehicles/golden-rocket-racer/)

| File | Description |
| --- | --- |
| [golden-rocker-racer.png](vehicles/golden-rocket-racer/golden-rocker-racer.png) | Vehicle appearance/color reference artwork. |
| [golden-rocket-racer-technical.png](vehicles/golden-rocket-racer/golden-rocket-racer-technical.png) | Multiview technical reference sheet for vehicle reconstruction. |
| [golden-rocket-racer.glb](vehicles/golden-rocket-racer/golden-rocket-racer.glb) | Exported 3D model in binary glTF format. |
| [golden-rocket-racer.md](vehicles/golden-rocket-racer/golden-rocket-racer.md) | Vehicle reconstruction specification: intended geometry, appearance, materials, and Godot export requirements. |

#### [vehicles/purple-passion/](vehicles/purple-passion/)

| File | Description |
| --- | --- |
| [purple-passion-technical.png](vehicles/purple-passion/purple-passion-technical.png) | Multiview technical reference sheet for vehicle reconstruction. |
| [purple-passion.glb](vehicles/purple-passion/purple-passion.glb) | Exported 3D model in binary glTF format. |
| [purple-passion.png](vehicles/purple-passion/purple-passion.png) | Vehicle appearance/color reference artwork. |
| [purple_passion_3d_spec.md](vehicles/purple-passion/purple_passion_3d_spec.md) | Vehicle reconstruction specification: intended geometry, appearance, materials, and Godot export requirements. |

#### [vehicles/rainbow/](vehicles/rainbow/)

| File | Description |
| --- | --- |
| [rainbow-technical.png](vehicles/rainbow/rainbow-technical.png) | Multiview technical reference sheet for vehicle reconstruction. |
| [rainbow.glb](vehicles/rainbow/rainbow.glb) | Exported 3D model in binary glTF format. |
| [rainbow.md](vehicles/rainbow/rainbow.md) | Vehicle reconstruction specification: intended geometry, appearance, materials, and Godot export requirements. |
| [rainbow.png](vehicles/rainbow/rainbow.png) | Vehicle appearance/color reference artwork. |

#### [vehicles/raketfiets/](vehicles/raketfiets/)

| File | Description |
| --- | --- |
| [raketfiets-technical.png](vehicles/raketfiets/raketfiets-technical.png) | Multiview technical reference sheet for vehicle reconstruction. |
| [raketfiets.glb](vehicles/raketfiets/raketfiets.glb) | Exported 3D model in binary glTF format. |
| [raketfiets.md](vehicles/raketfiets/raketfiets.md) | Vehicle reconstruction specification: intended geometry, appearance, materials, and Godot export requirements. |
| [raketfiets.png](vehicles/raketfiets/raketfiets.png) | Vehicle appearance/color reference artwork. |

#### [vehicles/retro/](vehicles/retro/)

| File | Description |
| --- | --- |
| [retro-technical.png](vehicles/retro/retro-technical.png) | Multiview technical reference sheet for vehicle reconstruction. |
| [retro.glb](vehicles/retro/retro.glb) | Exported 3D model in binary glTF format. |
| [retro.md](vehicles/retro/retro.md) | Vehicle reconstruction specification: intended geometry, appearance, materials, and Godot export requirements. |
| [retro.png](vehicles/retro/retro.png) | Vehicle appearance/color reference artwork. |

#### [vehicles/toxic-turbo/](vehicles/toxic-turbo/)

| File | Description |
| --- | --- |
| [toxic-turbo-improved.blend](vehicles/toxic-turbo/toxic-turbo-improved.blend) | Editable Blender source of the improved vehicle, with packed textures. |
| [toxic-turbo-improved.glb](vehicles/toxic-turbo/toxic-turbo-improved.glb) | Improved self-contained vehicle GLB with materials and embedded paint textures; preferred Toxic Turbo starting asset. |
| [toxic-turbo-technical.png](vehicles/toxic-turbo/toxic-turbo-technical.png) | Multiview technical reference sheet for vehicle reconstruction. |
| [toxic-turbo.glb](vehicles/toxic-turbo/toxic-turbo.glb) | Exported 3D model in binary glTF format. |
| [toxic-turbo.png](vehicles/toxic-turbo/toxic-turbo.png) | Vehicle appearance/color reference artwork. |
| [toxic_turbo_3d_spec.md](vehicles/toxic-turbo/toxic_turbo_3d_spec.md) | Vehicle reconstruction specification: intended geometry, appearance, materials, and Godot export requirements. |

#### [vehicles/toxic-turbo/source/](vehicles/toxic-turbo/source/)

| File | Description |
| --- | --- |
| [README.md](vehicles/toxic-turbo/source/README.md) | Existing Dutch reconstruction notes, rebuild commands, dependencies, and validation limits. |
| [body-paint.png](vehicles/toxic-turbo/source/body-paint.png) | Source paint texture for the main vehicle body. |
| [build-report.json](vehicles/toxic-turbo/source/build-report.json) | Recorded triangle count, dimensions, material count, and wheel pivot positions. |
| [build_model.py](vehicles/toxic-turbo/source/build_model.py) | Procedural Blender reconstruction of the improved Toxic Turbo model. |
| [check_glb.py](vehicles/toxic-turbo/source/check_glb.py) | Toxic Turbo structural geometry, accessor, orientation, and wheel-pivot checks. |
| [export_asset.py](vehicles/toxic-turbo/source/export_asset.py) | Export stage executed by the builder: texture packing, triangulation, optimization, GLB/Blender export, and build report. |
| [fin-paint.png](vehicles/toxic-turbo/source/fin-paint.png) | Source paint texture for the fins. |
| [make_contact_sheet.py](vehicles/toxic-turbo/source/make_contact_sheet.py) | Combines the eight vehicle inspection views into previews/overzicht.jpg. |
| [make_textures.py](vehicles/toxic-turbo/source/make_textures.py) | Generates the body and fin paint textures using Pillow. |
| [render_preview.py](vehicles/toxic-turbo/source/render_preview.py) | Reimports the improved GLB and renders eight studio inspection views in Blender. |
| [validation-report.json](vehicles/toxic-turbo/source/validation-report.json) | Recorded structural GLB and Blender-reimport results; does not establish Godot runtime behavior. |

#### [vehicles/toxic-turbo/previews/](vehicles/toxic-turbo/previews/)

| File | Description |
| --- | --- |
| [front-right-lighting.png](vehicles/toxic-turbo/previews/front-right-lighting.png) | Additional front-right lighting preview. |
| [front-right.png](vehicles/toxic-turbo/previews/front-right.png) | Rendered front-right inspection view of the improved vehicle. |
| [front.png](vehicles/toxic-turbo/previews/front.png) | Rendered front inspection view of the improved vehicle. |
| [left.png](vehicles/toxic-turbo/previews/left.png) | Rendered left side inspection view of the improved vehicle. |
| [original.png](vehicles/toxic-turbo/previews/original.png) | Preview image of the original vehicle model for comparison. |
| [overzicht.jpg](vehicles/toxic-turbo/previews/overzicht.jpg) | Combined rendered inspection overview/contact sheet. |
| [rear-left.png](vehicles/toxic-turbo/previews/rear-left.png) | Rendered rear-left inspection view of the improved vehicle. |
| [rear-right.png](vehicles/toxic-turbo/previews/rear-right.png) | Rendered rear-right inspection view of the improved vehicle. |
| [rear.png](vehicles/toxic-turbo/previews/rear.png) | Rendered rear inspection view of the improved vehicle. |
| [right.png](vehicles/toxic-turbo/previews/right.png) | Rendered right side inspection view of the improved vehicle. |
| [top.png](vehicles/toxic-turbo/previews/top.png) | Rendered top inspection view of the improved vehicle. |

## Character resources

**Boaz** is the knight in blue, red, and gold. **Ravi** is the adventurer in green, orange, and denim. Their style specifications distinguish the primary character sheets from alternative action outfits.

Both exported GLBs contain one mesh, one material, two embedded images, one skin, and six animation clips: `Cheer`, `Idle`, `Jump`, `Kart_Sit`, `Kart_Steer`, and `Run`. Existing validation reports describe 51 joints and a height of approximately 1.15 m. They record **29,874 triangles for Boaz** and **26,994 for Ravi**; both reports mark the requested triangle target as unmet. Blender reimport reports describe 20 morph targets. Ravi's Blender report also lists duplicate `.001` animation names after import; the GLB itself contains six clips.

The reports record structural and Blender checks, with Godot runtime behavior explicitly untested. The rendering tools expect six views per character, but only the files listed below were present at inventory time; a complete rendered overview is not yet established.

#### [persons/boaz/](persons/boaz/)

| File | Description |
| --- | --- |
| [blender-import-validation.json](persons/boaz/blender-import-validation.json) | Recorded fresh Blender reimport checks; explicitly not a Godot runtime test. |
| [boaz-stijl.md](persons/boaz/boaz-stijl.md) | Detailed character appearance, outfit, modeling, rigging, and export specification. |
| [boaz.blend](persons/boaz/boaz.blend) | Editable Blender character source, including rig and animation data. |
| [boaz.glb](persons/boaz/boaz.glb) | Exported 3D model in binary glTF format. |
| [boaz.png](persons/boaz/boaz.png) | Character action/pose artwork; consult the style document for outfit differences from the primary sheet. |
| [boaz_basecolor.png](persons/boaz/boaz_basecolor.png) | Character base-color texture atlas; also embedded in the character GLB. |
| [boaz_orm.png](persons/boaz/boaz_orm.png) | Packed character occlusion/roughness/metallic texture atlas; also embedded in the GLB. |
| [character-sheet.png](persons/boaz/character-sheet.png) | Character design sheet; primary appearance reference described by the style specification. |
| [glb-validation.json](persons/boaz/glb-validation.json) | Recorded structural GLB checks, triangle counts, skeleton information, and animation names. |

#### [persons/boaz/renders/](persons/boaz/renders/)

| File | Description |
| --- | --- |
| [01-front.png](persons/boaz/renders/01-front.png) | Rendered front view of the character. |
| [02-three-quarter.png](persons/boaz/renders/02-three-quarter.png) | Rendered three-quarter view of the character. |
| [03-side.png](persons/boaz/renders/03-side.png) | Rendered side view of the character. |
| [04-back.png](persons/boaz/renders/04-back.png) | Rendered back view of the character. |

#### [persons/ravi/](persons/ravi/)

| File | Description |
| --- | --- |
| [blender-import-validation.json](persons/ravi/blender-import-validation.json) | Recorded fresh Blender reimport checks; explicitly not a Godot runtime test. |
| [character-sheet.png](persons/ravi/character-sheet.png) | Character design sheet; primary appearance reference described by the style specification. |
| [glb-validation.json](persons/ravi/glb-validation.json) | Recorded structural GLB checks, triangle counts, skeleton information, and animation names. |
| [ravi-stijl.md](persons/ravi/ravi-stijl.md) | Detailed character appearance, outfit, modeling, rigging, and export specification. |
| [ravi.blend](persons/ravi/ravi.blend) | Editable Blender character source, including rig and animation data. |
| [ravi.glb](persons/ravi/ravi.glb) | Exported 3D model in binary glTF format. |
| [ravi.png](persons/ravi/ravi.png) | Character action/pose artwork; consult the style document for outfit differences from the primary sheet. |
| [ravi_basecolor.png](persons/ravi/ravi_basecolor.png) | Character base-color texture atlas; also embedded in the character GLB. |
| [ravi_orm.png](persons/ravi/ravi_orm.png) | Packed character occlusion/roughness/metallic texture atlas; also embedded in the GLB. |

#### [persons/skills/boracer-characters/](persons/skills/boracer-characters/)

| File | Description |
| --- | --- |
| [SKILL.md](persons/skills/boracer-characters/SKILL.md) | Local character-authoring workflow instructions for coding assistants. |

#### [persons/tools/](persons/tools/)

| File | Description |
| --- | --- |
| [build_characters.py](persons/tools/build_characters.py) | Procedural Blender character builder: geometry, skin weights, facial shapes, animation, textures, and export. |
| [check_blender_import.py](persons/tools/check_blender_import.py) | Reimports character GLBs into Blender and writes import validation reports. |
| [make_overviews.py](persons/tools/make_overviews.py) | Combines six expected character render views into labeled overview sheets using Pillow. |
| [render_characters.py](persons/tools/render_characters.py) | Renders existing character Blender files without rebuilding the models. |
| [validate_glb.py](persons/tools/validate_glb.py) | Inspects exported character GLB structure using Python standard-library tools. |

#### [persons/tools/__pycache__/](persons/tools/__pycache__/)

| File | Description |
| --- | --- |
| [build_characters.cpython-313.pyc](persons/tools/__pycache__/build_characters.cpython-313.pyc) | Generated Python bytecode cache; not a game asset or editable source. |

## World concepts

These folders currently contain written designs and images, not built tracks or Godot levels.

| World | Concept |
| --- | --- |
| Haarlem 1888 | Alternate-history Haarlem with steampunk machinery, canals, bridges, and steam-powered racing routes |
| Keukentafel | Toy-sized racing across a cluttered kitchen table, using everyday objects as obstacles and scenery |
| Regenbogenrijk | A magical rainbow realm above the clouds, with floating islands and colorful routes |
| Uithoorn 2056 | An optimistic futuristic Uithoorn around the Amstel, with solarpunk architecture and changing bridges |

#### [worlds/haarlem-1888/](worlds/haarlem-1888/)

| File | Description |
| --- | --- |
| [haarlem-1888.md](worlds/haarlem-1888/haarlem-1888.md) | World design document covering setting, circuit ideas, atmosphere, and gameplay concepts. |
| [haarlem-1888.png](worlds/haarlem-1888/haarlem-1888.png) | World concept artwork; a visual reference, not a playable 3D environment. |

#### [worlds/keukentafel/](worlds/keukentafel/)

| File | Description |
| --- | --- |
| [keukentafel.md](worlds/keukentafel/keukentafel.md) | World design document covering setting, circuit ideas, atmosphere, and gameplay concepts. |
| [keukentafel.png](worlds/keukentafel/keukentafel.png) | World concept artwork; a visual reference, not a playable 3D environment. |
| [old-keukentafel.png](worlds/keukentafel/old-keukentafel.png) | Earlier kitchen-table world concept image, retained alongside the current artwork. |

#### [worlds/regenbogenrijk/](worlds/regenbogenrijk/)

| File | Description |
| --- | --- |
| [regenbogenrijk.md](worlds/regenbogenrijk/regenbogenrijk.md) | World design document covering setting, circuit ideas, atmosphere, and gameplay concepts. |
| [regenbogenrijk.png](worlds/regenbogenrijk/regenbogenrijk.png) | World concept artwork; a visual reference, not a playable 3D environment. |

#### [worlds/uithoorn-2056/](worlds/uithoorn-2056/)

| File | Description |
| --- | --- |
| [uithoorn-2056.md](worlds/uithoorn-2056/uithoorn-2056.md) | World design document covering setting, circuit ideas, atmosphere, and gameplay concepts. |
| [uithoorn-2056.png](worlds/uithoorn-2056/uithoorn-2056.png) | World concept artwork; a visual reference, not a playable 3D environment. |

## Track, interface, scene, and reference images

These images guide the eventual 3D environments and Godot UI. A full interface composition is not a collection of separately implemented controls.

#### [./](./)

| File | Description |
| --- | --- |
| [logo.png](logo.png) | BoRacer logo artwork. |
| [technisch-referentieblad.png](technisch-referentieblad.png) | Overall technical reference artwork. |

#### [tracks/](tracks/)

| File | Description |
| --- | --- |
| [referentieblad-baan.png](tracks/referentieblad-baan.png) | Track reference sheet. |
| [sweer-impressie-baan.png](tracks/sweer-impressie-baan.png) | Track atmosphere concept image; original filename spelling retained. |

#### [user-interface/](user-interface/)

| File | Description |
| --- | --- |
| [game-ui-overzicht-referentieblad.png](user-interface/game-ui-overzicht-referentieblad.png) | Overview/reference sheet for the game interface. |
| [in-game-cockpit.png](user-interface/in-game-cockpit.png) | In-race cockpit/HUD design reference. |
| [store-interface.png](user-interface/store-interface.png) | Store interface design reference. |

#### [scenes/](scenes/)

| File | Description |
| --- | --- |
| [sfeer.png](scenes/sfeer.png) | Scene atmosphere concept image. |
| [store.png](scenes/store.png) | Store scene concept image. |

#### [assets/](assets/)

| File | Description |
| --- | --- |
| [IMG_20261016_190523.jpg](assets/IMG_20261016_190523.jpg) | Original camera photograph; subject is not identified by its filename. |
| [IMG_20261016_190530.jpg](assets/IMG_20261016_190530.jpg) | Original camera photograph; subject is not identified by its filename. |
| [boaz](assets/boaz) | JPEG reference photograph stored without a file extension. |
| [boaz2.jpg](assets/boaz2.jpg) | Original photographic reference: boaz. |
| [marieke1.jpg](assets/marieke1.jpg) | Original photographic reference: marieke. |
| [papa-en-ravi.jpg](assets/papa-en-ravi.jpg) | Original photographic reference: papa en ravi. |
| [ravi1.jpg](assets/ravi1.jpg) | Original photographic reference: ravi. |
| [ravi2.jpg](assets/ravi2.jpg) | Original photographic reference: ravi. |
| [ravi3.jpg](assets/ravi3.jpg) | Original photographic reference: ravi. |
| [sfeer.md](assets/sfeer.md) | Empty Markdown placeholder for atmosphere notes (0 bytes at inventory time). |
| [vera1.jpg](assets/vera1.jpg) | Original photographic reference: vera. |

#### [assets/tracks/](assets/tracks/)

| File | Description |
| --- | --- |
| [diepte1.jpg](assets/tracks/diepte1.jpg) | Track depth/perspective reference image 1. |
| [diepte2.webp](assets/tracks/diepte2.webp) | Track depth/perspective reference image 2. |
| [diepte3.jpg](assets/tracks/diepte3.jpg) | Track depth/perspective reference image 3. |
| [diepte4.jpg](assets/tracks/diepte4.jpg) | Track depth/perspective reference image 4. |

## Toxic Turbo transfer package

[vehicles/toxic-turbo/overdracht/](vehicles/toxic-turbo/overdracht/) is a prepared vehicle-workshop handoff. Its nested `boracart/public_html/boracert/` path is spelled **boracert**, distinct from this resource root, **boracer**. Its presence does not prove it has been installed in its destination.

| Path relative to `overdracht/` | Description |
| --- | --- |
| [LEESMIJ.md](vehicles/toxic-turbo/overdracht/LEESMIJ.md) | Existing Dutch installation and handoff instructions |
| [install.py](vehicles/toxic-turbo/overdracht/install.py) | Installer with dry-run support, conflict detection, and checksum verification |
| [manifest.json](vehicles/toxic-turbo/overdracht/manifest.json) | Expected SHA-256 checksums for package files |
| [boracart/.agents/skills/voertuig-pimper/SKILL.md](vehicles/toxic-turbo/overdracht/boracart/.agents/skills/voertuig-pimper/SKILL.md) | Reusable vehicle improvement workflow |
| `boracart/.agents/skills/voertuig-pimper/scripts/audit_glb.py` | Generic GLB inspector and structural audit tool |
| `boracart/.agents/skills/voertuig-pimper/scripts/prepare_vehicle.py` | Prepares a vehicle workspace from its existing assets |
| `boracart/.agents/skills/voertuig-pimper/scripts/render_glb.py` | Generic Blender GLB inspection renderer |
| [boracart/public_html/boracert/README.md](vehicles/toxic-turbo/overdracht/boracart/public_html/boracert/README.md) | Existing Dutch workshop overview and commands |
| `boracart/public_html/boracert/AGENTS.md` | Assistant instructions for that nested workshop |
| `boracart/public_html/boracert/requirements.txt` | Python dependencies for workshop tools |
| `boracart/public_html/boracert/tools/blender.sh` | Blender binary selection and launch wrapper |
| `boracart/public_html/boracert/tools/vehicle.py` | Vehicle command entry point: prepare, audit, build, check, and render |
| `boracart/public_html/boracert/vehicles/toxic-turbo/` | Packaged snapshot of the vehicle models, reference images, specification, source scripts, reports, textures, and previews described above |
| `boracart/public_html/boracert/vehicles/toxic-turbo/vehicle-workspace.json` | Metadata identifying the packaged vehicle workspace and its source |
| `boracart/public_html/boracert/vehicles/toxic-turbo/source/generic-validation-report.json` | Additional generic structural inspection report in the packaged snapshot |

The packaged snapshot has its own file versions and preview selection. Do not assume it matches the working Toxic Turbo directory byte for byte. Use its manifest to inspect package integrity before installing it; installing the handoff is a separate action from starting the Godot game.

## Naming and readiness notes

- Preserve the actual filenames when linking or importing. Some specifications use older upload names such as `rainbow(2).png`, `raketfiets(1).png`, and `purple-passion(2).png`; the present images omit those numeric suffixes.
- The Golden Rocket Racer appearance image is actually named `golden-rocker-racer.png` (with **rocker**). The folder, GLB, and technical sheet use **rocket**.
- The Retro specification requests `retro_8.glb`, while the available export is `retro.glb`. The Toxic Turbo specification uses underscores in some requested names; the files here use hyphens.
- Ravi's specification names `character-sheet(3).png`; the present primary sheet is `persons/ravi/character-sheet.png`.
- `assets/sfeer.md` is empty. `assets/boaz` is a JPEG without an extension. Neither was renamed or filled in during documentation.
- At the time of the resource inventory there was no gameplay. The separate `game/` prototype now supplies race controllers, procedural tracks, lap tracking, pickups, garage and HUD. See its README for the actual tested scope; resource import checks do not by themselves establish final asset quality.

## Maintaining this inventory

Keep original references and editable sources alongside each asset's export. When adding or replacing a resource, update its folder entry and distinguish intended features from features verified in the exported file or in Godot. Record Godot import/playtest results separately from Blender and structural validation reports.

## GAME-10001 review

The current round adds costume step 3, sourced photographic road/facade materials,
landmark research, brighter rewards, outdoor weather and reference-based splash/HUD.
See [the game documentation](game/README.md) and [central render folder](renders/README.md).
Character UV/PBR and animation are later phases with their own review boundary.
Native screenshots still require a graphical desktop; the restricted execution
session could run Godot checks but could not connect to X11.
