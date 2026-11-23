# Nieuwe kermisvoertuigen

Vier eerste ontwerpen voor dezelfde kermisfamilie als de bestaande raketten:

- [Hobbelpaard](hobbelpaard/README.md)
- [Brandweerauto](brandweerauto/README.md)
- [Helikopter](helikopter/README.md)
- [Ufo](ufo/README.md)

Elk concept heeft een eigen 3D-briefing. De brandweerauto heeft een 3D-prototype en de ufo een eerste volumestudie; het hobbelpaard en de helikopter zijn ontwerpstudies. De afbeeldingen zijn geen 3D-modellen; perspectief en details kunnen per aanzicht verschillen. Kies bij het modelleren een consistente interpretatie en controleer die rondom.

## Van ontwerp naar speelbaar voertuig

1. Maak en controleer per voertuig een bewerkbaar model en een zelfstandige GLB. Vergelijk schaal, onderzijde, wielen en zitpositie met de bestaande modellen. Test beide bestuurders en het camerazicht.
2. De huidige game verwacht een GLB onder `game/assets/models/<id>.glb`. De garagecatalogus staat in `game/scripts/catalog.gd`; `game/assets/manifest.json` bepaalt met `playable` welke catalogusvoertuigen beschikbaar zijn. Kies eigenschappen en prijs pas bij integratie en behoud bestaande IDs en volgorde.
3. In `game/scripts/kart.gd` wordt het model geladen en de bestuurder geplaatst met onder meer `Seat_Cushion`; controleer de schaal en positie per model. Beoordeel of bijzondere onderdelen zoals rotoren aparte animatie nodig hebben.
4. Test import, garage, selectie, opslaan/laden, race, camera, botsingen en de plaatsing van beide bestuurders in Godot. Controleer ook de monsterstand en het podium. Maak pas na geslaagde controles het voertuig beschikbaar.

De ufo is aan de lokale spelmap toegevoegd; de overige voertuigen zijn nog niet toegevoegd. Een conceptafbeelding alleen is niet voldoende voor de spelintegratie.

Zie [Werkwijze 3D](WERKWIJZE-3D.md) voor de kwaliteitsstappen en aandachtspunten per voertuig.
