# Boaz — stap 1: anatomie en gezicht, ter beoordeling

Uitgevoerd volgens `todo/10001-boaz-ravi-verbeteren.md`, uitsluitend stap 1 van 5.
Dit is een kandidaat voor visuele beoordeling. De bestaande Boaz in de game
blijft staan totdat deze stap is goedgekeurd. Ravi is niet opnieuw gebouwd.

Geometrische wijzigingen:

- Doorlopend hoofdoppervlak met geïnterpoleerde profielringen. Wangen, kaak,
  zachte kin en oogkassen zijn vormen van hetzelfde oppervlak, geen losse
  vergrote wangbolletjes.
- Kleiner, dieper gelegen oogwit, bruine irissen en afzonderlijke pupillen.
  Dikke roze oogkasringen zijn verwijderd; subtiele huidkleurige oogleden blijven.
- Kleinere, minder uitstekende neus; bredere gekromde glimlach met afzonderlijke
  kleine tanden en een spleetje tussen de voortanden. De mond volgt de werkelijke
  kromming van de wangen en wordt daardoor niet daarin verborgen.
- Relatief groter hoofd en compactere romp/benen, met dezelfde continue
  rest-ruimtemapping voor mesh, alle morphs en alle bones. Schoenzolen blijven
  op grondniveau. Haar/kleding behouden hun bestaande ontwerp en volgen alleen
  de minimaal noodzakelijke anatomische aansluiting.
- Expliciete profielparameters voor hoofdmaat, oogbreedte/hoogte/diepte,
  wangvolume, mondbreedte, romp- en beenlengte. Ravi behoudt de oude waarden.

## Controlebeelden

De gewone renders staan in `renders/`. De gelabelde vergelijkingen staan als `review-step1/*-comparison.jpg`. De
losse objectieve vergelijking staat in `review-step1/before/renders/` en `review-step1/after/renders/` met voor, driekwart,
zij en gezicht. Voor/na gebruiken dezelfde camera, studiobelichting, resolutie en
16 samples zonder denoising. Dit zijn renders van de echte opgeslagen meshes.
De drie nieuwe fullbody-aanzichten hergebruiken de exact overeenkomende pixels
uit de schone build; de close-ups worden beide met dezelfde camera opnieuw
gerenderd.

Het originele bronblad is `character-sheet.png`; het is de artistieke maatstaf.
De bestaande renders waren slechts de technische beginsituatie. Deze kandidaat
is nog geen exacte sculpt-reconstructie van het bronblad.

## Reproductie en backup

De fresh Blender-importcontrole slaagde voor één character mesh/armature,
20 neutrale morphs en alle zes gesamplede animaties, hoogte 1,15000015 m.

Alle oorspronkelijke Boaz-bestanden en de oorspronkelijke tools staan in
`persons/backups/2026-10-17-step1/`. Geen handmatige `refine_first_pass.py`-stap
is toegepast. Alle blijvende veranderingen staan in de generator.

Vanuit de projectroot:

```bash
BORACER_FAST_EXIT=1 /snap/blender/current/blender --background -noaudio --factory-startup --threads 4 --python persons/tools/build_characters.py -- boaz
python3 persons/tools/validate_glb.py persons/boaz/boaz.glb
BORACER_FAST_EXIT=1 /snap/blender/current/blender --background -noaudio --factory-startup --threads 4 --python persons/tools/check_blender_import.py -- persons/boaz/boaz.glb
BORACER_FAST_EXIT=1 /snap/blender/current/blender --background -noaudio --factory-startup --threads 4 --python persons/tools/review_character_step1.py
python3 persons/tools/make_character_step1_review.py
godot --headless --path game --log-file /tmp/boracer-character-step1-godot.log --script res://tests/character_step1.gd
```

De GLB- en Blender-importcontroles tonen technische bruikbaarheid en behouden
clips, niet artistieke goedkeuring of bewezen spelprestaties. Het veld
`Godot_runtime: not tested` in deze generieke rapporten betekent dat die twee
validators zelf geen Godot uitvoeren. De afzonderlijk werkelijk uitgevoerde
Godot-runtimecontrole staat in `godot-step1-validation.json`, zoals hieronder
beschreven; de generieke structurele rapporten vervangen die test niet.

De afzonderlijke Godot 4.7.2-runtimecheck (`game/tests/character_step1.gd`) leest
de kandidaat rechtstreeks via GLTFDocument, zonder hem naar de game te kopiëren.
75 controles slaagden: scène-instantiatie, 51 bones, zes clips, twee gedecodeerde
ingebedde textures en geladen albedo/roughness/metallic-referenties, eindige bounds,
exact 1,15 m hoogte en voeten op Y=0, plus werkelijk afspelen van Kart_Sit waarbij
de dijbeenpose verandert. Dit is een headless import/animatiecontrole; geen native
beeldgoedkeuring of volledige gameplaytest. Rapport: `godot-step1-validation.json`.

De kandidaat telt **41.782 triangles**, tegenover **33.306** in de oorspronkelijke
Boaz. De extra geometrie zit in de gevormde gezichtsovergangen en ogen en oogleden.
De oude en nieuwe versie overschrijden de richtwaarde 12.000–25.000. Er is dus
nog optimalisatiewerk nodig voor een definitieve productieversie; de technische
validator meldt `triangle_target_met: false` eerlijk. Unieke UV's,
textuurwerk, haarherontwerp, kostuumdetails en expressie-/animatieverbeteringen
horen bij de volgende stappen en zijn hier niet uitgevoerd.

**Goedkeuringsgrens:** beoordeel nu eerst front, driekwart, zij en gezicht.
Graag expliciete visuele goedkeuring of gerichte correcties voor stap 1 voordat
stap 2 (haar) of een andere vervolgstap wordt uitgevoerd.
