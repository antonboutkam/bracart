# Keukentafel — originele klantfoto's als oppervlak

Fenne GD-011, GAME-10001, 17 oktober 2026.

De 18 klantfoto's in `../../../../../assets/straatbeeld/keukentafel/` blijven intact.
`sources.json` registreert SHA-256, bytes en dimensies van alle 18. Vijf JPG's
zijn zonder pixelwijziging naar deze map gekopieerd. Geen CC0-claim op klantfoto's;
gebruiksbasis is de expliciete klantopdracht. Runtimekopieën zijn exact dezelfde
bytes, inclusief bestaande fotovervaging, perspectief, reflecties en kabelocclusie.

`kitchen_photo_materials.gd` selecteert brongebieden uitsluitend via UV-coördinaten.
Er zijn geen uitgeknipte, geretoucheerde, gerectificeerde of gegenereerde rasterbestanden.
De vier gemeten UV-hoeken worden door een homografie verbonden; 24 × 16 vlakdelen
vermijden één zichtbare diagonale perspectiefbreuk. Logo's, toetsopschriften en
knoppen komen rechtstreeks uit de bron en worden niet overgetekend.

| ID | Foto | Gebruik en grens |
|---|---|---|
| can_label | 093242 | Front van cyan/rode energydrink; gebogen sector rond echte cilinder. Achterzijde blijft metaal, geen herhaalde voorlogo's |
| keyboard_top | 093205 | Gefotografeerd hoofdtoetsgebied; rechter toetsenborddeel valt buiten de bron. Dit is geen volledige 104-toetsenreconstructie |
| remote_top | 093239 | Zwarte Samsung-afstandsbediening, inclusief gefotografeerde kabel over voorzijde |
| monitor_screen | 093236 | Zichtbaar terminalscherm; bovenzijde valt buiten de foto, geen verzonnen volledige desktop |
| megaphone_cap | 093220 | Wit bedieningspaneeltje met rode knoppen; rode kap en witte hoorn zijn aparte geometrie |
| adapter_label | 093205 | Optioneel klein/onscherp adapterdetail; geen nauwkeurigheidsclaim over tekst |
| esp_top | 093220 | Optioneel klein blauw printplaatdetail aan fotorechterrand; lage resolutie, geen technische ESP32-bordidentificatie |

`patch(parent,id,size)` bouwt een XY-vlak met front +Z. `rotation.x=-PI/2` draait
het naar een +Y-topvlak. `wrap_can(parent,radius,height)` maakt uitsluitend een
gebogen voorsector van ±0,8 rad; oorsprong ligt midden in de labelhoogte. De props
leveren gesloten fysieke lichamen, dikte, randen en metalen uiteinden.
`material(id)` is beschikbaar, maar gebruikt op een standaard PlaneMesh zonder
de helper-UV's zou de hele foto tonen en is daarom niet voldoende.

`palette.json` bevat gemeten gemiddelde sRGB-kleuren uit kleine brongebieden,
met hun coördinaten. Dit zijn lichtafhankelijke fotometingen, geen materiaalkalibratie.
Cyan blik, rode kap/logo, wit kunststof, zwart remote en warm tafelplankhout
bepalen het palet; geen lege blikjes, lampionnen of porseleinen kopjes verzonnen.

## Importcontract voor de coördinator

Doe één seriële Godot-import nadat props en helper klaar zijn. Stel op deze vijf
JPG's in de `.import`-parameters `mipmaps/generate=true`, `process/size_limit=2048`,
`compress/mode=2` (VRAM), `compress/high_quality=false`, `compress/normal_map=2`
(disabled), `detect_3d/compress_to=1` (VRAM). Zij zijn sRGB albedo, geen normals.
De projectie herhaalt niet. Godot mag zijn geïmporteerde cache downsamplen en
comprimeren; de versiebeheer-JPG's zelf blijven byte-identiek. Als VRAMcompressie
niet beschikbaar blijkt, documenteer de werkelijke fallback en geheugenkosten.
Bij 1536×2048, BC1/BC3 + mipmaps is circa 2–4 MiB per foto een ruwe bovengrens;
verifieer de werkelijke engineformaten voordat een definitief VRAMgetal wordt geclaimd.

QA toetst alle18 bronhashes, vijf kopiehashes, UVbounds en hoekmapping, fysieke
objectgeometrie en echte Godot-captures dichtbij/vanuit de race. Een materiaaltest
bewijst geen perfecte visuele plaatsing of leesbaarheid van brononscherpte.
