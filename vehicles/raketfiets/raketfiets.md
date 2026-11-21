# BoRacer — 3D Asset Specification: Raketfiets

## 1. Objective and source hierarchy
Create a fully three-dimensional, game-ready **GLB (glTF 2.0)** vehicle called `raketfiets`, suitable for Godot 4. Use both supplied PNGs throughout construction:
- `raketfiets(1).png`: authoritative reference for color, material appearance, silhouette and graphic details (front, left-side and rear render).
- `raketfiets-technical.png`: authoritative reference for spatial layout, left/right orthographic views, top, underside, 3/4 views, close-ups and line drawings.

**Do not merely extrude a side-view image or build billboard geometry.** Build a coherent vehicle visible from any camera angle. Where drawings conflict, preserve the main reference's silhouette and color; use the technical views to resolve topology. Do not invent major parts.

## 2. Identity and overall design
A whimsical retro-futuristic rocket-powered, three-wheeled racing vehicle, combining a streamlined vintage speedboat/rocket nose with motorcycle-style rear wheels, exposed black suspension tubes, a low open single-seat cockpit, and a tall waving red pennant bearing a white star. It is polished and toy-like, not photorealistic, with colorful enamel surfaces, metallic mechanical elements, rounded edges and deliberate readable details.

**Critical silhouette:** long tapered blue nose at the front; deep open red cockpit centered behind it; two large black spoked rear wheels, one on each side; upright red rear seat fairing; prominent rear-facing circular jet thruster; tall flagpole above the rear section. No conventional steering wheel or front automobile axle should be invented. A small central wheel is suggested under the nose in front/rear references: implement it only as a narrow central front wheel, consistent with the images.

## 3. Coordinates, scale and proportions
- World convention: **Y up, -Z forward, +X right** (Godot-friendly). Rear thruster faces +Z.
- Use metres; technical drawings indicate approximately **1850 mm long x 900 mm wide**. The drawing shows both **850 and 900 mm** height annotations; treat them as approximate, not guaranteed exact. The flag may extend above the nominal body height.
- Target body length 1.85 m, width across rear wheels and guard rails 0.90 m. Derive all other dimensions proportionally from the orthographic drawings rather than assigning false precision.
- Place root origin at the ground-plane centerline near the vehicle's geometric center; keep wheels, flag and thruster as separate child meshes with sensible pivots.
- The vehicle must remain symmetrical in primary mechanical structure, while decals, control panel and flag folds may be asymmetric.

## 4. Geometry — front nose and body
1. Build a smooth, rounded, elongated rocket/boat-shaped front fuselage. The tip is pointed in side view but rounded in 3D; avoid an excessively sharp needle.
2. Body color: saturated cyan/turquoise blue with a glossy painted finish. The upper nose has **three narrow parallel yellow racing stripes** running longitudinally toward the tip, clearly visible from above/front; do not replace them with one broad stripe.
3. Add small **red triangular accents** near the lower forward left/right sides and a slim white/off-white lower trim line wrapping the nose.
4. Near the nose/body junction, add paired small amber circular side lamps with a small cream rectangular lamp underneath each; integrate these into the side panel rather than projecting as enormous headlights.
5. Body sides are long and fairly straight below the cockpit, with rounded transitions to the nose. Add a narrow **pink/magenta horizontal stripe** near the bottom of both sides, with a **white strip below**. Preserve the strong blue-red-yellow-pink graphic palette.
6. Include modest rivets/panel joins and a few small dark fasteners as visible in the technical sheet. Keep silhouette clean; do not introduce unnecessary seams.

## 5. Cockpit and rider area
- Deep, open, single-person cockpit running lengthwise along the vehicle centerline, surrounded by a thick **glossy bright-red rim**. It is NOT enclosed by glass or a canopy.
- Black padded seat: recessed, elongated black cushion at the bottom and a black upright segmented backrest at the rear. Use rounded padded forms with subtle stitching/sectioning.
- At the forward right/center of the cockpit, model a small raised red control console with a compact dark panel. Include a short central **black joystick topped with a gold/yellow sphere** and several small colored buttons (blue, yellow, red, green) based on close-up. Do not add a full steering wheel.
- Behind the seat, a tall red rear backrest/fairing transitions into a **red-white-blue horizontal tricolor panel** on both sides. Keep its shape blocky-rounded and mechanically integrated.

## 6. Wheels, suspension and side structures
- Two large black rubber rear tires with dark metallic **thin multi-spoke motorcycle-style rims**, one per side, exposed outside the body. Make actual circular rim/tire geometry and legible spokes, not a solid black disk.
- Chrome/silver wheel arches curve closely above each rear tire.
- Add black tubular external supports/struts rising alongside the rear fairing, with cylindrical joints and rounded fittings. On each side a diagonal linkage extends toward the rear wheel hub.
- Low on each side, add **two black longitudinal tubular exhaust/guard rails** with rounded caps, following the blue body near ground level. They should be physically separated from the main shell where the reference shows a gap.
- Small central front wheel under the nose is visible in frontal/rear orthographic imagery. Keep narrow and partly tucked beneath the fuselage.
- Ensure mechanical parts are attached to credible mounting points; no disconnected or floating rods.

## 7. Rear thruster and lighting
- Rear-center **large cylindrical jet engine** with several concentric metallic rings, a bright warm amber/orange illuminated central opening, and a reflective silver/steel housing.
- Build the nozzle with true depth: concentric recessed rings, darker interior and a distinct emissive center. Do not use a flat orange disk on the back surface.
- The bright engine glow is orange/yellow/white, NOT green or blue. Use emissive PBR material, with optional Godot glow/bloom configured in-engine.
- Above the thruster: small rectangular red rear brake/tail lamp mounted on the rear fairing. Black protective tubes and small mechanical elements surround the engine.
- A small amber light is present on each rear-side/front-side support, as shown in the views.

## 8. Flag assembly — signature feature
- Tall dark metal flagpole at the rear, rising above the seat. It is slightly raked rather than perfectly vertical in some references. Include silver collars and a **gold spherical finial** at the top.
- Attach a vivid **red, wind-swept pennant** extending backward from the pole with a clear **white five-pointed star** on both visible sides.
- Give the flag actual thin, double-sided surface geometry with an elegant undulating silhouette; avoid making it an opaque rigid triangular plate or a single-sided decal.
- Keep pole and cloth as separate objects. Add an appropriate pivot / optional bone or deformable mesh to allow subtle wind animation in Godot. Default static pose should match the reference's wave shape.
- Preserve the star's visibility; avoid severe texture stretching across folds.

## 9. Materials and visual finish
Use glTF 2.0 metallic-roughness PBR materials; use image textures or mesh decals for sharp graphics where appropriate. Suggested values are starting points, not colorimetric measurements:

| Part | Color / finish | Approx. metallic / roughness |
|---|---|---|
| Main body | Bright turquoise blue, glossy enamel | 0.2 / 0.25 |
| Cockpit trim and rear fairing | Vivid glossy red | 0.15 / 0.24 |
| Nose racing stripes | Bright warm yellow | 0.05 / 0.35 |
| Lower accent | Hot pink stripe above white trim | 0.05 / 0.3 |
| Rear fairing band | Red, white, blue horizontal tricolor | 0.1 / 0.3 |
| Seat | Dark charcoal/black padded vinyl | 0 / 0.65 |
| Tires | Black rubber | 0 / 0.8 |
| Spokes, wheel arches, jet rings | Polished steel/chrome | 0.8 / 0.2 |
| Side tubing and struts | Black painted metal | 0.5 / 0.35 |
| Flag | Saturated red with white star, matte cloth | 0 / 0.75 |
| Jet core and lamps | Warm amber/orange emission | emissive |

The palette should resemble the source images, not a muted realistic repaint. Bake/paint the racing stripes and star cleanly. Avoid accidental black background polygons from PNG transparency.

## 10. Recommended Blender / GLB object hierarchy
```text
Raketfiets_ROOT
├── Body_MainBlue
├── Nose_TrimWhite
├── Nose_YellowStripes
├── Body_PinkSideStripes_L_R
├── Body_RedAccent_L_R
├── Cockpit_RedRim
├── Cockpit_SeatBase
├── Cockpit_Backrest
├── Cockpit_ControlPanel
├── Cockpit_Joystick
├── RearFairing_RedWhiteBlue
├── Wheel_FrontCenter
├── Wheel_Rear_L
├── Wheel_Rear_R
├── Fender_Rear_L
├── Fender_Rear_R
├── Suspension_L
├── Suspension_R
├── SideRails_L
├── SideRails_R
├── Jet_Housing
├── Jet_InnerRings
├── Jet_EmissiveCore
├── Lights_Front_L_R
├── Lights_Rear
├── Flag_Pole
└── Flag_Cloth
```
Separate meshes may be merged for draw-call efficiency once their animation and material needs are understood. Keep wheels and flag separable.

## 11. Game-ready topology and optimization
- Prefer clean manifold meshes, bevels on important edges, weighted/smooth normals where appropriate; avoid visibly faceted round bodywork.
- Aim for **roughly 15k–35k triangles for the complete primary model**, adjusted based on actual screen size and target hardware; this is a working budget, not a hard constraint.
- Use texture detail for tiny screws, panel lines and graphics; reserve geometry for major silhouettes, rims, suspension, console, flag and jet rings.
- Prefer shared 1k–2k textures/atlases when possible. Keep material count reasonable.
- Generate UVs without overlaps for baked graphics. Do not mirror UVs where asymmetric decals would reverse.
- Optional simplified LOD can reduce spokes, suspension detail and small bolts at distance.
- Add a simple convex or compound collision proxy separately in Godot rather than relying on a dense render mesh as dynamic collision.

## 12. Build sequence for a modeling LLM / Blender agent
1. Import both reference PNGs and orient their orthographic views. Set 1 unit = 1 metre, Y-up export and -Z forward.
2. Block out body, nose, cockpit cavity, rear fairing, wheel positions, thruster and flag. Compare silhouette in side, front, back and top views.
3. Refine body surfaces and cockpit opening; model seat and controls.
4. Model wheels and spokes, arches, mechanical struts, side rails and lighting.
5. Build concentric rear thruster and separate emissive core.
6. Add pole and modeled flag cloth with white star on both sides.
7. Apply materials, paint/decal graphics and small details.
8. Check all eight perspective/orthographic references, fix mismatched left/right geometry and floating parts.
9. Apply mesh transforms, set useful pivots, triangulate as needed, pack/export textures, export GLB.
10. Reimport GLB into Godot 4 and inspect lighting, normals, transparency, emission, scale and node hierarchy.

## 13. Explicit prohibitions / failure modes
- No extra conventional front wheels, windshield, roof, driver, guns, spoilers or invented weaponry.
- Do not replace the flag with a fin; do not omit the white star.
- Do not recolor the turquoise shell to red or the rear jet glow to neon green.
- Do not omit the pink side stripe, triple yellow nose stripes, or tricolor rear fairing.
- Do not turn the two spoked rear wheels into solid car wheels.
- Do not make the body a flat 2D silhouette, nor the jet a flat decal.
- Do not place the large glowing thruster at the front: the small headlamp is at the nose; the jet nozzle is at the rear.
- Do not model the technical reference sheet's white background, labels, dimension arrows or contact shadows.

## 14. Acceptance checklist
- [ ] GLB loads in Godot 4, correctly oriented (-Z forward, Y up) and scaled in metres.
- [ ] Body length/width near 1.85 m / 0.90 m; height interpreted consistently with source.
- [ ] Front nose has **three** yellow stripes and red side accents.
- [ ] Blue side body has thin pink and white lower stripes.
- [ ] Red open cockpit has visible black seat, backrest and colored control panel.
- [ ] Two exposed spoked rear wheels, chrome fenders and black structural tubes are present.
- [ ] Rear jet has metallic concentric housing and amber glowing core.
- [ ] Red flag on tall pole displays white star on both sides.
- [ ] Model looks coherent from all directions, with no holes, flipped normals or floating components.
- [ ] Wheel, flag and jet objects remain individually addressable for game animation/effects.

## 15. Final generation instruction
**Produce the actual editable 3D scene and export `raketfiets.glb`.** Treat the two provided PNGs as the visual source of truth and this specification as a geometric and technical interpretation. If any unseen area is ambiguous, infer the smallest mechanically plausible continuation consistent with the other views; report substantive assumptions. Include a brief validation report (triangle count, materials, dimensions, export status and any deliberate deviations). A textual description or a rendered 2D picture is **not** a substitute for the GLB model.
