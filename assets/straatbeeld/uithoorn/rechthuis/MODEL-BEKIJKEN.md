# Het Rechthuis — zelfstandig 3D-model

- `model.glb`: zelfstandige glTF-binary met ingebedde kleurtexturen en standaard PBR-materialen. Open dit bestand in een glTF-viewer, Blender of Godot; geen losse texturebestanden nodig.
- `model.blend`: bewerkbare Blenderbron met de gebouwgeometrie en materialen.
- `preview.png`: vaste native Godot-controleweergave van dezelfde GLB in een studio-opstelling, geen gameplaybeeld.

De game gebruikt dezelfde GLB-bytes in `game/assets/models/uithoorn-rechthuis.glb`. De gameplaatsing kan het model uniform schalen; de zelfstandige GLB blijft in zijn oorspronkelijke modeleenschaal. Zie de centrale bouw-/integratierapporten voor bounds en definitieve schaal.

Dit is een herkenbare game-interpretatie op basis van aangeleverde foto's en gereconstrueerde referentieplaten, geen bouwkundige reconstructie. Bronfoto's en bestaande pakketbestanden blijven behouden. De materiaalkleur is afgeleid uit de meegeleverde detailpanelen; roughness/metallic zijn artistiek gekozen PBR-instellingen, geen gemeten materiaaldata.

Herbouwen: vanuit de repositoryroot voert Blender zonder previewoptie het script `public_html/boracer/game/tools/build_uithoorn_landmarks.py` uit. Werkelijke gamebeelden staan centraal onder `public_html/boracer/renders/GAME-10001/stap-25-uithoorn-landmarks/`.
