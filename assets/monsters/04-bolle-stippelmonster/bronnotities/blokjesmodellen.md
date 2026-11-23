# Breekbare blokjesmonsters

Deze collectie is **specifiek voor het spel met afbrekende blokken**. De eerder gemaakte, gladde GLB-modellen voor het andere spel zijn niet aangepast.

## Bestanden

- `json/<monster>.json`: het belangrijkste importbestand. Het gebruikt exact de velden `id`, `name` en `blocks`. Elk blok heeft gehele `x`, `y`, `z` en een ondoorzichtige `#RRGGBB`-kleur.
- `glb/<monster>.glb`: dezelfde blokken als een echt 3D-model. **Elke kubus is een afzonderlijk node/object** en gebruikt een gedeelde kubusmesh per materiaalkleur; kubussen zijn niet versmolten tot een modelmesh.
- `manifest.json`: dimensies, aantallen, kleurenaantallen en uitgevoerde controles.
- `voorbeelden/`: afbeeldingen die uit de blokken-GLB's zijn gerenderd.

## Rooster en oriëntatie

- Kubusmaat: **1 × 1 × 1**.
- `x`: links/rechts, `y`: omhoog, `z`: diepte. **+Z is de voorkant richting de schans.**
- De blokcellen hebben gehele coördinaten vanaf `x=0`, `y=0`, `z=0`. De buitenrand van een kubus met celcoördinaat `(x,y,z)` loopt in GLB van `(x,y,z)` tot `(x+1,y+1,z+1)`.
- De onderkant van de voeten staat op **Y=0**; de centra van de onderste kubussen staan dus op Y=0,5.
- Geen roterende, overlappende of onzichtbare ondersteuningsblokken.

## Constructie en validatie

Elke positie komt maximaal eenmaal voor. Alle blokken zijn via **gedeelde zijvlakken** (zes buur-richtingen) verbonden met ten minste één blok op de grond (`y=0`). Hoek- en randcontact zijn niet meegeteld.

Een aantal grote monsters is gedeeltelijk hol gemaakt om binnen het ontwerpbudget te blijven. Dit is niet hetzelfde als een los zwevend deel: de volledige fysieke blokconstructie blijft verbonden. Bij enkele figuren zijn 1–51 extra, zichtbare verbindingsblokken toegevoegd om loshangende delen te ondersteunen. Die aantallen staan in `manifest.json`.

De kolom `single_block_breakpoints` telt onderdelen waarbij het verwijderen van **één** blok al iets kan laten loskomen. Bij modellen met waarde 0 kunnen nog steeds delen afbreken wanneer meerdere aangrenzende blokken verdwijnen; dat is afhankelijk van de simulatie in het spel.

## Vormgeving en status

Deze monsters zijn ontworpen op basis van eerdere **voor-/zij-/achteraanzichtillustraties**. Het zijn dus gestileerde voxelinterpretaties en geen nauwkeurige 3D-scans. Er is geen rigging, animatie, noppen of natuurkunde toegevoegd. De gifwolk van de rode gifspuwer hoort als apart visueel partikeleffect in het spel; de structurele blokken stellen het monster zelf voor.

**Import in het spel is nog niet geïmplementeerd**: gebruik de JSON-bestanden als bron voor de toekomstige block-instantiatie en steunberekening. De GLB's zijn vooral handig om snel te bekijken of de vormen kloppen.
