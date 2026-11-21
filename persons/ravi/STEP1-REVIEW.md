# Ravi — stap 1: anatomie en gezicht

Deze stap past de eerder beoordeelde aanpak van Boaz toe op Ravi, met eigen
karakterparameters uit zijn originele `character-sheet.png` en `ravi-stijl.md`.
De gebruiker heeft direct aansluitend stap 2 toegestaan; dit dossier bewaart de
anatomische tussenstap afzonderlijk voordat het haar wordt veranderd.

- Doorlopend gevormde zachte wangen en korte kin; geen losse wangbollen.
- Kleiner en dieper geplaatst oogwit met bruine irissen, subtiele huidkleurige
  oogleden en afzonderlijke pupillen; geen dikke roze oogkasringen.
- Ravi heeft een eigen oogafstand/hoogte, iets rondere oogopening, een iets
  smallere neus en smallere, speelsere glimlach dan Boaz.
- Expliciete Ravi-parameters: hoofd 1,10; breedte 1,00; romp 0,95; benen 0,93.
  Dezelfde continue mapping verwerkt mesh, alle morphs en skeleton; voeten en
  accessoires blijven aangesloten en de totale hoogte wordt 1,15 meter.
- Haar, hoofdband, rood-oranje veer, utilityvest, rugzak, denim en sneakers
  behouden hun bestaande ontwerp. Ze volgen uitsluitend de anatomische mapping.
- Boaz' goedgekeurde anatomieparameters en geometrische defaults blijven intact.

## Reproductie en bewaring

De volledige oorspronkelijke Ravi en broncode zijn vóór de build bewaard in
`persons/backups/2026-10-17-ravi-step1/`. De permanente wijzigingen staan in
`persons/tools/build_characters.py`; geen eenmalige meshcorrectie is gebruikt.
Een aparte kopie van de nieuwe stap-1-outputs staat in `review-step1/after/`.
De vaste-cameravergelijkingen staan in `review-step1/*-comparison.jpg`.
Ze tonen de daadwerkelijke meshes bij dezelfde camera, licht, resolutie en
16 samples zonder denoising. Het originele blad blijft de artistieke maatstaf;
deze procedurele uitwerking is geen exacte sculpt-reconstructie.

Onderstaande buildopdracht was de historische stap-1-build. De actieve generator
bouwt inmiddels stap 2. De exacte stap-1-generator met Ravi-parameters is bewaard
als `persons/backups/2026-10-17-step2/build_characters-before-hair.py`; voor
teruglezen of vergelijken zijn de bevroren `review-step1/after/ravi.blend` en
`ravi.glb` rechtstreeks beschikbaar. De reviewhelper gebruikt deze bevroren
blend en de bewaarde renderpixels, zodat stap-2-outputs geen stap-1-bewijs vervangen.

```bash
BORACER_FAST_EXIT=1 /snap/blender/current/blender --background -noaudio --factory-startup --threads 4 --python persons/tools/build_characters.py -- ravi
python3 persons/tools/validate_glb.py persons/ravi/ravi.glb
BORACER_FAST_EXIT=1 /snap/blender/current/blender --background -noaudio --factory-startup --threads 4 --python persons/tools/check_blender_import.py -- persons/ravi/ravi.glb
BORACER_FAST_EXIT=1 /snap/blender/current/blender --background -noaudio --factory-startup --threads 4 --python persons/tools/review_character_step1.py -- ravi
python3 persons/tools/make_character_step1_review.py ravi
```

## Technische controles

De GLB-structuurcontrole slaagt: **38.902 triangles** tegenover **30.417** in de
vorige Ravi, 51 bones, zes clips, twee ingebedde textures, één materiaal,
maximaal twee niet-nul botgewichten, neutrale morph-standaardwaarden en
1,14999998 meter hoogte met voeten op Y=0. Het gezicht voegt geometrie toe;
de richtwaarde van 12.000–25.000 triangles wordt overschreden en verdere
productieoptimalisatie blijft nodig. De validator meldt dit als
`triangle_target_met: false`.

De fresh Blender-importcontrole slaagt: 1 character mesh, 1 armature,
20 neutrale morph targets, twee ingebedde textures en alle zes animaties
op drie frames met eindige meshcoördinaten; bindhoogte 1.15000079 meter.
Het rapport staat in `review-step1/after/blender-import-validation.json`.
Front, driekwart, zij, gezicht en vervormde kartpose zijn als echte mesh-renders
bekeken; de voor/na-collage toont dat wangen, oogkassen en glimlach verbeteren.
De gebogen denimknieën tonen in de prototype-kartpose nog dunne lichte naden;
skinning en animatie-afwerking horen bij stap 5 en zijn hier niet opgelost.
De ongewijzigde kostuum-/haargeometrie blijft de oorspronkelijke procedurele
uitwerking en wordt in de volgende stappen verfijnd.
De generieke GLB/Blender-rapporten testen zelf geen Godot: hun veld
`Godot_runtime: not tested` mag niet als runtimebewijs worden gelezen.


De game gebruikt deze stap-1-anatomie inmiddels ook. De daarop uitgevoerde haarstap heeft zijn eigen `STEP2-REVIEW.md`. De Godot-controle van die export slaagt 75/75; de onafhankelijke scope-audit bevestigt behoud van de stap-1-rig, animaties, textures en niet-haarvorm. Zie `godot-step2-validation.json` en `review-step2/float-drift-audit.json`.
