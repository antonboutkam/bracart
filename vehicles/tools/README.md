# Verbeterde voertuigen bouwen en controleren

De vijf reconstructies gebruiken de bestaande verbeterde Toxic Turbo als technische basis. De originele GLBs, tekeningen en ontwerpdocumenten worden behouden. De nieuwe modellen heten `<voertuig>-improved.glb` en hebben een bewerkbaar `<voertuig>-improved.blend`.

- `make_paint.py`: lakkaarten voor alle vijf modellen (Python 3, Pillow, NumPy).
- `build_vehicle.py`: parametrische Blender-geometrie met voertuigkeuzes, doorgaande cockpitopening, vinnen of vlag, onafhankelijke wielen en modelspecifieke materialen. Gebruik de kleine `source/build_model.py` in de betreffende voertuigmap als ingang.
- `export_asset.py`: modifiers toepassen, trianguleren, optimaliseren, ingestorte driehoeken verwijderen, texturen inpakken en GLB/Blend exporteren.
- `check_glb.py`: container, bufferbereiken, indices, eindige attributen, driehoeken, ingebedde afbeeldingen, schaal, assen, wielpivots en unieke onderdelen controleren. Dit is geen Khronos-validator.
- `render_vehicles.py`: GLB opnieuw in Blender importeren en negen studioaanzichten renderen; er wordt geen vloer of studio in de voertuigen geëxporteerd.
- `make_overviews.py`: contactbladen per voertuig en één gezamenlijk overzicht.
- `check_godot_import.gd`: de vijf GLBs in een tijdelijk Godot-project laden, instantiëren en op materiaal- en wielhiërarchie controleren.

Voorbeeld vanuit de hoofdmap:

```bash
python3 vehicles/tools/make_paint.py
blender --factory-startup --background -t 6 --python vehicles/retro/source/build_model.py
python3 vehicles/tools/check_glb.py retro
blender --factory-startup --background -t 5 --python vehicles/tools/render_vehicles.py -- retro
```

Voor de Godot-controle: maak buiten de assetcollectie een tijdelijk Godot-project, kopieer de vijf verbeterde GLBs daarheen, voer `godot --headless --editor --path <tijdelijk-project> --import` uit, en daarna `godot --headless --path <tijdelijk-project> --script <absoluut-pad-naar-check_godot_import.gd> -- <absoluut-pad-naar-vehicles>`.

De bron is getest met Blender 5.2.2 en Python 3. Als de Snap-launcher niet binnen een beperkte omgeving draait, is dezelfde geïnstalleerde Blender-binary ook beschikbaar als `/snap/blender/current/blender`.

Deze reconstructies benaderen de getekende referenties. Exacte lakcontouren en kleine mechanische details zijn geïnterpreteerd. Eén klein centraal voorwiel is de conservatieve lezing van de tekeningen; de ambigu getekende extra achterste steunwielen zijn weggelaten. Het geheel blijft een visueel voertuigasset; physics, rijgedrag, botsingen, animaties en LODs moeten in het spel worden ingericht.
