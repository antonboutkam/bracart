# BoRacer voertuigwerkplaats

Centrale werkplek voor het verbeteren van voertuigen op basis van hun eigen
referentiebeelden, specificaties en GLB-bestanden.

- Spelbestanden en oorspronkelijke voertuigen: `../boracer/vehicles/<id>/`.
- Werkmappen met bronnen, scripts, previews en verbeterde GLBs: `vehicles/<id>/`.
- Herbruikbare skill: `../../.agents/skills/voertuig-pimper/SKILL.md`.
- Blender-wrapper en bediening: `tools/`.

De Toxic Turbo-werkmap bevat de verbeterde GLB, bewerkbare Blender-bron, beide
referentiebeelden, de specificatie, bouwscripts, textures en controles.
Het oorspronkelijke voertuig in de spelmap blijft behouden.

## Werken aan een volgend voertuig

Open deze map als werkplek. Vraag bijvoorbeeld:

> Gebruik voertuig-pimper om voertuig `<id>` te verbeteren aan de hand van de
> afbeeldingen en Markdown-specificatie in de oorspronkelijke voertuigmap.

Voorbereiden en de oorspronkelijke GLB inspecteren:

```bash
python3 tools/vehicle.py <id> prepare
python3 tools/vehicle.py <id> audit
```

De skill begeleidt het maken van een **voertuigspecifiek**
`vehicles/<id>/source/build_model.py`. Bouwen, controleren en renderen:

```bash
python3 tools/vehicle.py <id> build
python3 tools/vehicle.py <id> check
python3 tools/vehicle.py <id> render --views front-right,rear-left,top
python3 tools/vehicle.py <id> render
```

`render` importeert de GLB opnieuw. `check` doet structurele controles en
rapporteert numerieke afmetingen en geometrie; dit vervangt geen volledige
glTF-validator of echte test in de race-engine. `prepare` stopt voordat het
bestaande bestanden met afwijkende inhoud zou overschrijven.

## Benodigdheden

Blender is een systeeminstallatie; `tools/blender.sh` kiest de direct beschikbare
binary. Een andere installatie stel je in met `BORACERT_BLENDER`.
`BORACERT_THREADS` bepaalt het aantal renderthreads (standaard 6).
Python-hulpmiddelen gebruiken de pakketten uit `requirements.txt`.

De scripts in `vehicles/toxic-turbo/source/` bewaren de concrete bouwgeschiedenis
van dat model. De generieke inspectie-, voorbereidings- en rendertools staan bij
de projectskill en werken ook voor volgende voertuigen. Gebruik de geometrie,
kleuren en symbolen van ieder nieuw voertuig zelf als uitgangspunt.
