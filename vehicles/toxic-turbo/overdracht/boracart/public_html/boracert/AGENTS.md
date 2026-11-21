# BoRacer voertuigwerkplaats

Gebruik voor het verbeteren van voertuigmodellen de projectskill
[`voertuig-pimper`](../../.agents/skills/voertuig-pimper/SKILL.md).

De oorspronkelijke modellen en referenties staan in `../boracer/vehicles/`.
Hier staan de centrale tools en de werkmappen `vehicles/<id>/`. Houd scripts,
textures, Blender-bronnen en previews bij het betreffende voertuig. Schrijf
nieuwe exports als `<id>-improved.glb`; behoud de originele bestanden.

Werk vanuit de eigen afbeeldingen en specificaties van het gekozen voertuig.
Gebruik Toxic Turbo uitsluitend als procedureel voorbeeld. Bouw nieuwe
voertuigen niet door alleen de bestandsnaam of kleur van Toxic Turbo te wijzigen.

Gebruik de werkelijk geïnstalleerde Blender-versie. `tools/blender.sh` kiest de
lokale Blender-binary of `BORACERT_BLENDER`. `tools/vehicle.py` biedt prepare,
audit, build, check en render. Rapporteer afzonderlijk wat aan bestanden,
Blender-renders en de game-engine is gecontroleerd.
