# Het Rechthuis — BoRacer asset pack

## Inhoud
- `het_rechthuis_01_front.png` t/m `het_rechthuis_06_line.png` — 1024 × 1024 px
- `het_rechthuis_07_wall_texture.png` t/m `het_rechthuis_10_roof_texture.png` — 512 × 512 px
- `het_rechthuis_06_line.svg` — SVG met gekoppelde PNG als rasterafbeelding (geen echte vectorpaden)
- `manifest.json` — machineleesbare details en indicatieve game-afmetingen
- `het_rechthuis_reference_sheet.png` — AI-referentieblad
- `het_rechthuis_asset_preview.jpg` — preview van de daadwerkelijk uitgesplitste bestanden
- `source_photos/` — de oorspronkelijke vijf foto's

## Aanpak voor Codex / Blender / Godot

1. Begin met een eenvoudige massa van circa 22 m brede, 14 m diepe en 12 m hoge hoofdbouw. Dit zijn **uitsluitend game-schattingen**, geen bouwkundige metingen.
2. Bouw het bakstenen volume met een prominent, grijs, schildvormig pannendak en dakkapellen.
3. Voeg donkere raamkozijnen en de opvallende bordeauxrood-witte decoratieve luiken toe.
4. Maak de zwarte luifels als afzonderlijke modellen. Laat het balkon, de vlaggen en entree op de straatgevel duidelijk leesbaar zijn.
5. Modelleer aan de waterzijde de brede glazen aanbouw/overkapping en het terras als apart volume met balustrade.
6. Gebruik voor de uiteindelijke detaillering zowel de PNG-aanzichten als de bronfoto's. De AI-aanzichten zijn indicatief, onderling niet volledig consistent en geen exacte orthografische tekeningen.

## Technische kanttekeningen

- De beelden zijn uitsneden uit één AI-referentieblad en opgeschaald/gecentreerd voor een vaste exportsize. Zij bevatten dus minder intrinsiek detail dan apart op 1024 px gegenereerde afbeeldingen.
- Bij de meeste aanzichten blijft het oorspronkelijke beelddecor aanwezig. Alleen de opvulling rond de panelen is transparant.
- De vier detailtextures zijn geen gegarandeerd naadloos herhaalbare PBR-textures.
- De SVG verwijst naar de bijgevoegde lijntekening-PNG en bevat geen geëxtraheerde vectorpaden.
