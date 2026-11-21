# Toxic Turbo — verbeterde reconstructie

Het aangeleverde `toxic-turbo.glb` blijft behouden. De nieuwe versie staat in
`../toxic-turbo-improved.glb`; `../toxic-turbo-improved.blend` bevat de bewerkbare
geometrie en ingepakte textures. De Blender-bron bevat alleen het voertuig;
studiovloer, camera en lampen worden pas voor de previews aangemaakt.

De reconstructie volgt `toxic_turbo_3d_spec.md`, `toxic-turbo.png` en
`toxic-turbo-technical.png`. Het is een procedurele interpretatie van de
illustraties, geen exacte kopie van alle getekende details.

De huidige export is circa **1,5 MB**, heeft **43.955 driehoeken**, **14 materialen**
en twee ingebedde textures. Gemeten lengte × breedte × hoogte:
**1,893 × 0,945 × 0,851 m**. Dit ligt dicht bij de streefmaat; de breedste
ophangingsdelen steken iets buiten de nominale 0,90 m uit.

## Opnieuw bouwen

```bash
python3 source/make_textures.py
blender -b -t 6 --python source/build_model.py
python3 source/check_glb.py
blender -b -t 6 --python source/render_preview.py
python3 source/make_contact_sheet.py
```

`make_textures.py` gebruikt Pillow en het DejaVu Sans-font. De al aanwezige PNGs
maken die stap optioneel. `check_glb.py` gebruikt NumPy. De scripts zijn getest
met Blender 5.2.2 LTS. In deze lokale omgeving werkt de Blender-binary rechtstreeks
via `/snap/blender/current/blender`; de Snap-launcher is beperkt in de sandbox.

## Gebruik in Godot

- glTF-assen: +Y omhoog, neus naar -Z; afmetingen zijn in meters.
- `Wheel_Rear_L` en `Wheel_Rear_R` zijn aparte groepen met de pivot op de as.
  Draai om de lokale X-as voor wielrotatie. Ook de twee kleine steunwielen
  hebben een eigen pivot.
- De thruster-emitter, lichtkernen en lampen hebben emissieve materialen.
  Glow/bloom stel je in Godot in via de omgeving.
- Textures zijn in de GLB ingebed; losse referentieafbeeldingen zijn niet nodig.
- Botsingsvormen, rijgedrag, wielanimaties, LODs en particles zijn niet toegevoegd.

## Controle en grenzen

`build-report.json` bevat de gemeten afmetingen en het aantal driehoeken.
`validation-report.json` bevat controles van de GLB-container, bufferbereiken,
indices, materialen, ingebedde afbeeldingen en wielpivots. Het render-script
importeert de GLB opnieuw en maakt acht aanzichten. Deze controles zijn geen
Khronos-validatorrapport of test binnen Godot; Godot is lokaal niet beschikbaar.

De plaatsing van de twee kleine steunwielen en details aan de onderzijde zijn
conservatieve aannames, omdat de referentie daarin niet eenduidig is. De vorm
van losse vlekken en kleine mechanische onderdelen is geïnterpreteerd.
