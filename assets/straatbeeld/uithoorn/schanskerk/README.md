# De Schanskerk — BoRacer asset pack

**Gebouw:** De Schanskerk (Sint-Jan de Doperkerk), Schans 14, Uithoorn.

## Inhoud
- `de_schanskerk_01_front.png` t/m `de_schanskerk_06_line.png`: 6 beelden, elk 1024 x 1024 pixels.
- `de_schanskerk_07_wall_texture.png` t/m `de_schanskerk_10_roof_texture.png`: 4 materiaalbeelden van 512 x 512 pixels.
- `de_schanskerk_06_line.svg`: SVG-wrapper die verwijst naar de PNG, **geen echte vectorlijnen**.
- `de_schanskerk_reference_sheet.png`: originele AI-conceptsheet.
- `de_schanskerk_asset_preview.jpg`: preview van de uitgeknipte beelden.
- `source_photos/`: vijf door de gebruiker aangeleverde foto’s/tekeningen.
- `manifest.json`: metadata, technische eigenschappen en schaalgegevens.

## Maatvoering voor Godot (1 unit = 1 meter)
- Torens: **circa 38 m** (historisch gerapporteerde maat; geen recente opmeting).
- Voor snelle blockout: **55 m lengte, 24 m breedte en circa 19 m nokhoogte van schip** — grove visuele game-inschatting, niet geverifieerd.

## Aanpak voor Codex / Blender
1. Begin met langwerpig schip van ongeveer 55 x 24 m, los van de twee circa 38 m hoge fronttorens.
2. Bouw herkenbare dubbele spitsen, klokvlakken en hoofdingang apart zodat proporties bij te sturen zijn.
3. Gebruik het dakoverzicht om de globale footprint te bepalen, niet als metrische blauwdruk.
4. Voeg hoge ramen, steunberen, baksteenstructuur, entree en leien dak toe; gebruik beelden 07-10 uitsluitend als textuurreferenties.
5. Controleer gebouwenvelop en geveldetail tegen de originele foto's. AI-aanzichten zijn artistiek en neogotischer dan het echte neoromaanse gebouw.

**Bronnoot:** `source_photos/lijnenschets.jpg` is expliciet een afbeelding van de **kathedraal van Clermont-Ferrand**. Het is geen authentieke Schanskerk-tekening. Gebruik deze niet als historische bouwkundige referentie.

## Beperkingen
De PNGs zijn uitgesneden uit een AI-spritesheet en daarna geresampled; 1024 px bestandsbreedte betekent geen native 1024 px inhoudsdetail. Binnen het beeld zitten nog de gegenereerde achtergrond/hemel; alleen canvasranden zijn transparant. De textures zijn niet bewezen seamless. De line-art SVG is een raster-wrapper en bevat geen originele vectorpaden.
