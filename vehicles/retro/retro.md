# BoRacer — 3D Asset Specification: Retro 8

**Output:** `retro_8.glb` (glTF 2.0), game-ready for Godot 4.
**Visual reference:** `retro(2).png` (large hero front, side, rear views).
**Technical reference:** `retro-technical.png` (orthographic, 3/4, top, bottom, details, line drawings).

## 1. Objective
Create a fully volumetric, recognizable, editable 3D recreation of the orange-and-cream **number 8 retro rocket racer**. This is a stylized, low-slung open-cockpit kart, not an aircraft or a normal car. Prioritize matching the references over creative additions. No driver.

## 2. Reference interpretation
- Primary hero image controls paint, finish, detailed shape, materials and lighting appearance.
- Technical sheet controls relative placement, silhouette, front/rear distinction, upper and lower geometry.
- Its left/right views face opposite directions because of camera viewpoint: **do not mirror the vehicle's actual nose/rear orientation**.
- Drawings may contain perspective inconsistencies; favor large clear views over tiny thumbnails. Unseen structures are inferred conservatively, not invented extravagantly.

## 3. Dimensions and coordinate system
The technical drawings label length **1850**, width **900**, height **850**; provisionally treat as millimeters, yielding 1.85 m long × 0.90 m wide × 0.85 m tall. These are approximate illustrated dimensions, not surveyed CAD. Maintain silhouette if proportions require slight adjustments. Use Godot convention **+Y up, -Z forward (pointed nose), +Z rear (round thruster), +X vehicle right**. Set root near ground under cockpit center; tire contact at Y=0. Apply transforms before GLB export.

## 4. Primary silhouette and shell
The main fuselage is a glossy elongated, rounded torpedo body with a low horizontal profile. Its front section narrows into a cream-white pointed rocket nose with orange accents and a small orange tip; the front is **not** the large thruster. A pale collar with regularly spaced metallic rivets encircles the transition between main body and nose. The main orange body has curved sides, broad enough to carry a white circular roundel with bold black **8**, plus swept flame decals. Model a truly recessed open cockpit in the top shell with thick orange rim and dark inner walls. Do not fake the opening using a black flat surface.

## 5. Cockpit and controls
Single dark charcoal/black padded seat, with separate seat base, slightly reclined back, rounded side bolsters and stitched rectangular cushion sections. The seat back projects above the cockpit rim. At the forward cockpit edge sits a small oval control cluster with a **short joystick capped by a metallic gold/yellow sphere**, red/green/blue buttons and tiny dark switches. Build prominent controls as geometry. No steering wheel, windscreen, roof, second seat or pilot. The rear seat surround includes orange painted fairing and metal cylindrical supports.

## 6. Three characteristic fins
- **One tall center tail fin**, rising behind the seat, curved and swept backward in side view, thick enough to show beveled edges. It is orange/red with ivory flame accents and a **white roundel containing a black 8** on its visible sides. Its top defines much of the vehicle's 850 mm height.
- **Two smaller outward-swept side fins** mounted symmetrically at the rear side shoulders above/behind the wheel region. Ivory/cream with orange-red flames and orange trim; broad at root, tapered at tips. Connect roots to the body with real geometry.
- Do not accidentally model two tall center fins or omit the smaller fins.

## 7. Wheels, suspension and pipework
Large exposed rear wheels sit on either side beneath the cockpit/tail region: thick black tires, subtle tread, dark many-spoke rims, chrome outer lip, bright center hub. Use separate wheel meshes with usable axle pivots. There are additional dark tire silhouettes in front/rear and bottom references, including a narrow central element; **exact small-wheel arrangement is visually ambiguous**. Reconstruct only support wheels justified by multiple views rather than forcing a conventional four-wheel layout. Build black diagonal struts with rounded joints, silver circular pivot caps above the rear wheels, a slender diagonal mechanical link from each hub, and curved chrome wheel-arch trim. Along both lower sides run long horizontal dark metallic pipes/exhausts, with silver cylindrical sections, rounded end caps and tubular rear guards. The pipes must connect sensibly and not float.

## 8. Nose lamp and rear propulsion
At the low front center, include a circular warm amber/yellow headlamp in a gold/chrome bezel, distinct from the pointed orange nose tip. The rear carries a **large centered cylindrical jet thruster**, projecting past the tail body: multiple concentric gunmetal/chrome rings surround a recessed **yellow-white glowing center with amber/orange annular glow**. Make rings, inner cavity and emissive surfaces actual separate geometry/materials. Immediately above the thruster is a small rectangular **red** rear lamp in a dark metal bezel, below the tall fin. Add circular amber lamps on the left/right rear external struts. Bloom is an engine-side postprocess effect, not a substitute for modeled rings.

## 9. Paint and decals
**Dominant palette:** saturated racing orange, warm ivory/cream white, red-orange hot-rod flames, black tires/upholstery, silver/chrome and dark gunmetal mechanical components. Use smooth glossy enamel for shell (roughness approximately 0.20–0.35), polished metal for rings (metallic approximately 0.8–1.0), and matte rubber/fabric for seat/tires (roughness approximately 0.55–0.85). These are starting points; adjust against references.

Place **black numeral 8 in clean white circular roundels** on both broad side panels, the top/front body, and center tail fin. Keep the numeral readable from intended views; no mirrored or reversed typography. The flames are elongated curved red/orange tongues with sharp tips, running across the orange/cream surfaces and fins. Reproduce their placement and direction from images; avoid generic random decals. Use UV texture or carefully fitted opaque decals; avoid z-fighting and stretched roundels. Ensure graphics survive GLB export without external texture dependencies.

## 10. Underside and hidden areas
The bottom reference shows a dark segmented longitudinal belly plate with bolts and visible rear mechanical/axle structures. Model a closed underside, sensible cross supports and attached side pipes. Infer obscured back faces with structural symmetry. Avoid making elaborate unseen mechanisms or weapons. The underside should look finished when the kart jumps or rolls.

## 11. Suggested GLB mesh hierarchy
```text
Retro8_Root
├── Body
│   ├── MainShell
│   ├── NoseCone
│   ├── NoseTip
│   ├── NoseCollarAndRivets
│   ├── CockpitRim
│   └── BellyPanels
├── Cockpit
│   ├── SeatBase
│   ├── SeatBack
│   ├── SeatBolsters
│   ├── ControlPanel
│   ├── Joystick
│   └── Buttons
├── Fins
│   ├── CenterTailFin
│   ├── SideFin_L
│   └── SideFin_R
├── Wheels
│   ├── RearWheel_L
│   ├── RearWheel_R
│   └── SupportWheels_IfSupportedByReferences
├── Mechanical
│   ├── Suspension_L
│   ├── Suspension_R
│   ├── Exhaust_L
│   ├── Exhaust_R
│   └── RearGuardPipes
├── Thruster
│   ├── EngineHousing
│   ├── ConcentricRings
│   └── EmissiveCore
├── Lights
│   ├── FrontHeadlamp
│   ├── RearRedLamp
│   ├── SideAmberLamp_L
│   └── SideAmberLamp_R
└── Decals
    ├── Number8Roundels
    └── FlameGraphics
```
`_L` and `_R` refer to vehicle-relative left/right, not image screen position. Preserve separate wheel pivots and separate emissive materials for gameplay.

## 12. Game optimization
Aim for **20,000–45,000 triangles**, preferably near 30,000 for the hero asset; fewer are acceptable if silhouette and recognizable detail remain strong. Use smooth normals, beveled visible edges, efficient cylinder segmentation and minimal invisible detail. Use one or a few packed 1024–2048 px PBR texture sets, plus emission where necessary. No loose objects, flipped normals, z-fighting, missing UVs or external asset dependencies. Optional lower-detail LOD can be produced separately.

## 13. Build procedure for the 3D-generating LLM
1. Establish metric scale and Godot axes. Block out torpedo shell, tapered nose, cockpit hole, rear wheel pair, center fin, two side fins and cylindrical rear engine.
2. Compare blockout against front, side, rear and top reference before details. Ensure nose points -Z and engine +Z.
3. Refine cockpit lip and seat, then wheel rims, suspension, arches, exhaust and rear guard tubes.
4. Build nose collar/rivets, front lamp, rear thruster rings, red tail lamp and amber side lamps.
5. Model joystick and colored buttons; make fin roots and tube junctions physically plausible.
6. UV unwrap shell and fins; apply exact orange/cream paint, red-orange flame graphics and every number-8 roundel.
7. Assign glTF-compatible PBR and emissive materials. Inspect in neutral lighting and dark game lighting.
8. Validate 360-degree appearance plus top/bottom, correct any interpenetrations and floating parts, and optimize geometry.
9. Apply transforms, set pivots, export binary `retro_8.glb` with embedded textures, and re-import into Godot 4 to verify.

## 14. Acceptance tests
- [ ] Identifiably the same **orange/ivory flame-painted number 8** kart in both PNGs.
- [ ] Approximate envelope 1.85 × 0.90 × 0.85 m and correct Godot orientation.
- [ ] Long cream pointed nose with orange tip; separate circular amber front headlamp.
- [ ] Actual open cockpit, black padded seat and colored control cluster with gold joystick.
- [ ] Exactly one tall center fin and two smaller swept side fins.
- [ ] Correct white roundels with legible black **8** and correctly flowing flame graphics.
- [ ] Rear wheels with spoked rims, suspension struts and attached longitudinal pipes.
- [ ] Rear circular jet engine with metallic concentric rings and bright orange/yellow emission.
- [ ] Small rectangular red rear lamp above thruster and two amber side lamps.
- [ ] Complete underside, no missing surfaces, floating parts or reversed normals.
- [ ] Correct material/texture rendering after standalone Godot 4 GLB import.
- [ ] Wheels and light/emissive parts can be addressed separately in the scene tree.

## 15. Explicit exclusions
Do **not** create a flat image plane or billboard; do not add a driver, windshield, roof, wings of aircraft scale, conventional steering wheel, weapons, extra logos, or new colors. Do not substitute a green biohazard design or another number. Do not put the bright circular jet nozzle at the front. Do not make the center fin paper-thin or the cockpit solid. Do not claim exact mechanical accuracy for parts obscured in the references.

## 16. Delivery contract
Return `retro_8.glb` as a **real 3D mesh asset** with embedded or GLB-contained textures, correct scale, named components, wheel pivots, physically plausible surfaces and emissive engine/lights. If a native editable Blender project is also available, it is optional; the GLB is mandatory. Report any unresolved interpretation decisions, particularly support-wheel count and underside layout, instead of silently inventing them.
