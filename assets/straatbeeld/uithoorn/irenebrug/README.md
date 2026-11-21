# Irenebrug — BoRacer Asset Pack

This package contains game-ready reference assets for **Irenebrug** in Uithoorn.

## Included
- 5 view images (`front`, `back`, `left`, `right`, `top`) — 1024×1024 PNG
- 1 line-art reference — 1024×1024 PNG (+ SVG wrapper)
- 4 material/detail textures — 512×512 PNG
- `manifest.json` with file descriptions and partial scale anchors
- preview image and original AI reference sheet

## Recommended modeling approach
- Start from the **top view** to place roadway, sidewalks, water gaps and bridge edges.
- Keep the **striped barriers**, **traffic lights**, **blue-white railing** and **green-roof control house** prominent; these are the key recognizable features.
- The bridge does not need to be engineering-exact; prioritize readability and a clean silhouette for gameplay.

## Scale
Known scale anchors included in `manifest.json`:
- 4 navigable openings
- each opening width: **10.5 m**
- closed clearance height: **2.8 m**

These are partial dimensions, useful as modeling anchors rather than a full measured drawing.

## File naming
All files use the prefix `irenebrug_`.
