---
name: voertuig-pimper
description: Verbeter BoRacer GLB-voertuigen aan de hand van hun eigen referentieafbeeldingen en Markdown-specificaties, met echte 3D-geometrie, Blender-bron, renders en gecontroleerde exports. Gebruik voor voertuigmodellen in boracart/public_html/boracer/vehicles en de werkmap public_html/boracert; niet voor aanpassingen aan de race-engine.
---

# Voertuig-pimper

Werk per voertuig vanuit zijn eigen ontwerp. Toxic Turbo is een voorbeeld van de
werkwijze, geen geometrische basis voor andere voertuigen.

## Locaties en hulpmiddelen

Bepaal de projectroot vanaf deze skill: `.agents/skills/voertuig-pimper` onder
`boracart`. Oorspronkelijke voertuigmappen staan naast elkaar in
`public_html/boracer/vehicles/`. De centrale werkplek is `public_html/boracert/`;
voertuigwerk staat daar in `vehicles/<voertuig-id>/`.

Lees `public_html/boracert/AGENTS.md` en de instructies in de gekozen voertuigmap.
Gebruik de bestaande Blender-bron wanneer die bruikbaar is. Scripts en paden
blijven relatief aan het project of aan `__file__`.

Vanuit `public_html/boracert`:

```bash
python3 tools/vehicle.py <voertuig-id> prepare
python3 tools/vehicle.py <voertuig-id> audit
python3 tools/vehicle.py <voertuig-id> build
python3 tools/vehicle.py <voertuig-id> check
python3 tools/vehicle.py <voertuig-id> render
```

`prepare` kopieert bestaand materiaal naar de werkplek en stopt bij inhoudelijke
bestandsconflicten. `build` vereist een voor dit voertuig geschreven
`source/build_model.py`; er wordt geen Toxic Turbo-model als ander voertuig
verpakt. De generieke tools onder `scripts/` zijn ook rechtstreeks bruikbaar.

## Van referentie naar model

- Bekijk alle relevante referentieafbeeldingen en lees de Markdown-specificatie.
  Identificeer voor/achter, assen, schaal, silhouet, kleuren, cockpit,
  wielindeling, mechanische lagen en zichtbare symbolen. Afgeleide of onzichtbare
  maten blijven aannames. Een genoemde ontbrekende bron is geen gelezen bron.
- Inspecteer de originele GLB met `scripts/audit_glb.py` en maak zo nodig een
  vergelijkbare baselinerender. Stel vast wat al klopt en wat verbetering vraagt.
  Controleer bij strijdige assen/schaal ook de daadwerkelijke game-import; leg een
  betekenisvolle afwijking vast in plaats van het bestaande contract te raden.
- Bouw eerst de hoofdvolumes en vergelijk enkele hoeken. Werk daarna de eigen
  kenmerkende details uit. Gebruik echte geometrie voor holtes, zittingen,
  buizen, wielen, ophanging en dikke vinnen; geen referentiebeelden als model.
- Maak een bewerkbare `.blend` en een uitvoerbaar Blender-bouwscript. Gebruik
  glTF-compatibele PBR-materialen en ingebedde UV-textures voor grote graphics.
  Bake procedurele shaders wanneer de glTF-export die niet kan meenemen.
  Behoud herkenbare symbolen en leesrichting op beide zijden.
- Gebruik de assen en maten uit de betreffende specificatie. Voor Toxic Turbo
  zijn dat meters, +Y omhoog en -Z vooruit in glTF/Godot. Dit is geen stilzwijgende
  verplichting om elk ander bestaand voertuig te heroriënteren.
- Geef beweegbare onderdelen eigen namen en gecentreerde pivots. Verbind frames
  en ophanging zichtbaar met de carrosserie. Controleer vinnen en cockpit ook van
  voren en boven; een fraaie zijaanblik bewijst geen goede 360°-vorm.

## Blender-valkuilen en export

Roep `bpy.context.view_layer.update()` aan vóór het vastleggen van world-matrices
voor het groeperen van zojuist geschaalde onderdelen. Anders kunnen bijvoorbeeld
wielonderdelen onbedoeld hun standaardmaat behouden. Controleer daarna de
geëxporteerde afmetingen, niet alleen de bedoelde invoermaten.

Bewaar geen lijsten met later verwijderde Blender-objecten tijdens `join`.
Groepeer vooraf op blijvende namen of selecteer alleen de blijvende parentnodes.
Pas schaal en relevante modifiers toe, corrigeer normals, trianguleer bewust en
verwijder samengevallen driehoeken. Verminder details gericht wanneer het budget
wordt overschreden; behoud silhouet, cockpit, wielen, vinnen en grote uitlaat.
Hanteer het budget van het voertuig, niet automatisch één universeel aantal.

Exporteer alleen het voertuig, zonder studiovloer, camera's of presentatielichten.
Gebruik `<voertuig-id>-improved.glb` voor de nieuwe versie en behoud de originele
GLB. Voeg geen gameplay, particles, collision-gedrag of publicatie toe zonder dat
het onderdeel van de opdracht is.

## Afronden met bewijs

Importeer de definitieve GLB opnieuw. `audit_glb.py --strict` controleert container,
indices, numerieke geometrie, ingesloten bronnen en gerapporteerde materiaaldata;
het is geen volledige Khronos-validator. Controleer het voertuig tevens visueel
van voren, achteren, beide zijden, boven en diagonale hoeken. Begin met een paar
lage-resolutierenders bij vormcorrecties; maak het volledige overzicht nadat vorm
en belichting goed zijn. Houd de studio vergelijkbaar voor voor/na-beelden en
voorkom dat belichting of kleurbeheer de lak onherkenbaar verbleekt.

Lever de GLB, Blender-bron, voertuigspecifieke scripts en previews op. Vermeld
werkelijk gemeten afmetingen, driehoeken, textures en relevante aannames. Test
in de bedoelde engine als die beschikbaar is; benoem anders dat Blender-import
plus structurele controles de engine-test nog niet vervangen. Het rechtstreeks
wijzigen van spelbestanden of originele voertuigen volgt alleen uit de opdracht.
