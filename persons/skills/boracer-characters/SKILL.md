---
name: boracer-characters
description: Maak en wijzig de BoRacer-personages Boaz en Ravi met Blender, exporteer GLB-modellen en controleer de werkelijke modellen met renders. Gebruik bij werk aan hun character sheets, modellen, rig, materialen en animaties.
---

# BoRacer-personages met Blender

## Locatie en bronnen

De gewenste projectstructuur is `boracer/tools/`, `boracer/skills/boracer-characters/` en `boracer/persons/{boaz,ravi}/`.
Als de sandbox alleen `persons/` beschrijfbaar maakt, kunnen `tools/` en `skills/` tijdelijk daar staan. Verplaatsen naar de projectroot vereist schrijfrechten op die root. De tools detecteren beide locaties; maak geen tweede kopie van de broncode.

Lees per personage `persons/<naam>/<naam>-stijl.md` en bekijk `character-sheet.png`. Dit zijn de primaire ontwerpbronnen. De afzonderlijke `boaz.png` en `ravi.png` zijn actiebeelden met afwijkende kostuums en mogen het basiskostuum niet vervangen.

- **Boaz:** goudblond haar, bruine ogen, blauwe tuniek, gouden heraldische leeuwen op borst/schouder/cape, zilveren schouderplaten, rode cape en bruin-gouden ridderlaarzen.
- **Ravi:** goudblond haar, bruine ogen, groene hoofdband met rood-oranje veer en bladeren, groen utilityvest over roomwit shirt, oranjegroene rugzak met klaver, vingerloze handschoenen, opgerolde denim en groen-oranje-witte sneakers.

## Software en reproductie

De eerste uitvoering gebruikt **Blender 5.2.2 LTS**, Python met `bpy`, `bmesh` en `mathutils`, Cycles voor renders en de ingebouwde glTF-exporter. Geen externe 3D-generator, afbeeldingsreconstructieservice of betaalde dienst. Pillow wordt alleen voor een overzicht van bestaande renders gebruikt.

De controlebeelden gebruiken 600×720 pixels, 16 samples en CPU-rendering zonder denoising. Denoising bleef in de beperkte uitvoeromgeving na het renderen hangen. De controlebeelden kunnen daardoor korrelig zijn; verhoog samples en test denoising apart voor presentatierenders op de desktop.

Voer vanuit `boracer/` uit (of vanuit `persons/` zolang de tools daar staan):

```bash
/snap/blender/current/blender --background -noaudio --factory-startup --threads 8 --python tools/build_characters.py -- boaz ravi
python3 tools/validate_glb.py persons/boaz/boaz.glb persons/ravi/ravi.glb
python3 tools/make_overviews.py
/snap/blender/current/blender --background -noaudio --factory-startup --python tools/check_blender_import.py -- persons/boaz/boaz.glb persons/ravi/ravi.glb
```

Vanuit `persons/` vervalt `persons/` in de argumenten van de validator en importcontrole. Gebruik op andere machines de aanwezige Blender executable. De directe Snap executable is lokaal bruikbaar wanneer de Snap-launcher faalt met `cap_dac_override`; dit verandert de sandboxrechten niet. Geef headless runs `-noaudio` mee. Losse renders opnieuw maken zonder herbouw kan met `--python tools/render_characters.py -- boaz ravi`. De eenmalige `refine_first_pass.py` werkte de oorspronkelijke bestanden bij met extra achterhaar en afstand tussen tuniek en cape; deze correcties zitten ook in een schone build en hoeven niet opnieuw te worden toegevoegd.

Let op: de build overschrijft de gegenereerde `.blend`, `.glb`, atlasbestanden en renderbestanden voor het gekozen personage. Controleer vooraf of er handmatige Blender-wijzigingen zijn die behouden moeten blijven; verwerk die in het bronbestand of bewaar een afzonderlijke versie.

Een onderbroken render kan per personage en aanzicht worden hervat: zet bijvoorbeeld `BORACER_VIEWS=06` voor alleen de kartzitpose of `BORACER_VIEWS=02,04` voor driekwart en achter. Deze omgevingsvariabele geldt voor `render_characters.py`; bestaande andere renders worden dan behouden. Draai bij beperkte middelen één Blender-proces tegelijk.

Lokaal verscheen na voltooid werk soms `pa_write() failed while trying to wake up the mainloop`, waarna Blender bij afsluiten bleef hangen. Met `BORACER_FAST_EXIT=1` beëindigen de batchtools alleen in background-modus hun eigen proces na de laatste geslaagde save en rapportage, vóór die driver-afsluiting. Dit is optioneel en wordt nooit in interactieve Blender gebruikt. `--debug-cycles` maakt renderprogressie zichtbaar bij diagnose van lange stille renderstappen.

## Opbouw van de modellen

De volledige modelleerbron staat in `tools/build_characters.py`. Verander de passende functie en bouw alleen de gewijzigde personages opnieuw:

1. `atlas`: gedeelde 1024×1024 kleur- en ORM-atlas; één glTF metallic-roughness PBR-materiaal. ORM gebruikt G voor roughness en B voor metallic. Textures worden in GLB en Blender ingesloten.
2. `mesh`, `tube`, `ringbody`, `ell`, `box`, `leaf`: geometrische bouwstenen met afgeronde vormen, materiaal-UV's en expliciete botgewichten.
3. `make_head`: hoofd met gevormde kin/wangen, oren, neus, afzonderlijke ogen/irissen, mond en gelaagde spits toelopende haarplukken. Houd verschillen in ooghoogte en hoofdvorm tussen Boaz en Ravi.
4. `limbs` en `outfit`: armen/vingers, benen en de afzonderlijke kledingdetails. De cape is een raster met botgewichten; het leeuwenreliëf wordt op de geplooide stof geprojecteerd en krijgt dezelfde gewichten.
5. `build_skeleton`: gedeeld humanoid skelet, vingers en drie cape-ketens. `face_shapes` maakt eenvoudige geometrische expressies; dit is nog geen zorgvuldig gesculpte gezichtsrig.
6. De modeldelen worden samengevoegd tot één mesh met vertexgroepen. Dubbele poolvertices worden gelast en normals herberekend. Triangulatie gebeurt via een modifier bij export. De daadwerkelijke silhouethoogte, inclusief veer, wordt op 1,15 m gezet.
7. De oorspronkelijke modelleerrichting is Blender -Y. Mesh en skelet worden samen 180° gedraaid voordat ze geëxporteerd worden. glTF/Godot: +Y boven, kijkrichting -Z, voeten op Y=0.
8. `animations`: clips `Idle`, `Run`, `Jump`, `Cheer`, `Kart_Sit`, `Kart_Steer`. Dit zijn startanimaties voor controle en verdere uitwerking, geen bewezen gameplayanimaties.
9. Exporteer uitsluitend karaktermesh en armature via `use_selection=True`. Studio, vloer, lampen en camera komen alleen in het bewerkbare `.blend`-bestand en de renders.

## Uitvoer en controles

Per personage: `<naam>.blend`, `<naam>.glb`, twee atlas-PNG's, `validation.json`, `glb-validation.json` en `renders/` met vooraanzicht, driekwart, zijde, achterzijde, gezicht en kartzitpose. Controleer de **werkelijk gerenderde geometrie**, geen AI-afbeelding die kwaliteit suggereert die niet in de GLB zit.

Gebruik `tools/validate_glb.py` voor ingesloten textures, skinning, maximaal vier gewichten, animaties, morph targets, UV's, bounds en triangleaantallen. Gebruik een verse Blender-import voor een aanvullende export/import-controle. Leg fouten en werkelijke aantallen vast; de doelwaarde uit de stijlbeschrijvingen is 12.000–25.000 triangles en kan om verdere optimalisatie vragen.

Zet na het toevoegen van iedere shape key expliciet `key.value = 0`. De eerste renders legden gelijktijdig actieve expressies bloot; dat vergrootte ogen en mond onbedoeld. De GLB-validator vereist daarom neutrale morph-standaardwaarden. De Blender glTF-importer kan bovendien een extra `Icosphere` als botweergave aanmaken: tel voor de karaktercontrole de meshes met een Armature-modifier, niet iedere hulpmesh als karakteronderdeel.

Bekijk altijd gezicht, silhouette, kostuumidentiteit en een daadwerkelijk vervormde pose. Let op oogleden, schouders, ellebogen, knieën, losse vingers, cape en ornamenten. Corrigeer zichtbare fouten en render opnieuw.

Dit is een **procedurele eerste 3D-uitwerking**, geen exacte sculpt of automatische reconstructie van de illustraties. De UV's delen bewust kleurtegels; dit vervangt geen unieke paint-atlas. Accessoires en lichaamsdelen zijn deels overlappende oppervlakken. Blendshapes en animaties zijn een prototype en vragen artistieke verfijning. Een geslaagde Blender-export/import bewijst geen geslaagde Godot-import, runtimeprestaties, retargeting, kartbesturing of clipvrije gameplay. Benoem wat daadwerkelijk gecontroleerd is en wat nog openstaat.
