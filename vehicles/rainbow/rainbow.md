# BoRacer — Rainbow Racer
## Game-ready 3D asset generation specification (GLB / Godot 4)

**Reference images (both mandatory):** `rainbow(2).png` (primary color/style reference) and `rainbow-technical.png` (multi-view geometry reference).

**Deliverable:** one visually faithful, fully three-dimensional `.glb` asset, with logically separated objects and reusable PBR materials. Do not simply project the reference image onto a flat plane.

## 1. Design intent and priorities

Reconstruct a compact, single-seat retro-futuristic rocket racing kart. Its visual identity is a highly polished, saturated rainbow-painted rocket fuselage, bright white five-point stars on rear aerodynamic fins and side panels, black mechanical pipes, metallic rear engine, glowing amber lighting, and black padded cockpit. Preserve the exact overall silhouette and recognizable paint layout. The primary reference controls color, finish, and detail; the technical sheet controls geometry, placement, and symmetry. When drawings disagree, prioritize consistent orthographic proportions and use the primary rendering for appearance. Do not invent extra wings, wheels, weapons, spoilers, or decals.

## 2. Scale and coordinate system

- Reference drawing dimensions: approximately **1850 mm long**, **900 mm wide**, and **850–900 mm tall**. Treat these as approximate, not precision CAD measurements. The height depends on whether the highest fin is included; resolve against the images.
- Work in meters: nominal overall length **1.85 m**, width **0.90 m**, approximate height **0.85–0.90 m**.
- Godot convention: **+Y up**, **-Z forward (pointed nose)**, **+Z rear (jet exhaust)**, **+X vehicle's right**.
- Place root origin on the vehicle centerline near ground level; make wheel pivots independent and aligned with the axle (local X).
- Apply mesh transforms, ensure outward-facing normals, triangulate only at export as appropriate.

## 3. Overall shape and topology

The body is an elongated, rounded, enclosed rocket shell tapering toward a pointed nose. The nose has a tiny circular glowing amber/yellow headlight integrated into its tip. Body sides are smoothly convex and lower edges narrow under the cockpit. A shallow, open single-seat cockpit is cut into the upper central/rear fuselage, outlined by a rounded glossy multicolor lip. A black leather-like padded seat, high backrest, and low cushion occupy the opening. The cockpit dashboard is toward the front of the opening, featuring a miniature panel of colored push buttons and a central gold/yellow spherical joystick. Avoid a car-like windshield or enclosed canopy.

At the rear, two large black rubber wheels with intricate dark multi-spoke rims and polished metal outer rings sit left and right of the fuselage. They are mounted externally below flared silver wheel arches. The mechanical rear engine extends along the centerline behind the cockpit: stacked metallic rings around a large circular amber-orange glowing exhaust. Black tubular supports, diagonal suspension links, and polished silver cylindrical side mufflers flank the wheels and body. Front and rear views show small auxiliary amber lamps at the outer sides and a rectangular red tail lamp above the exhaust.

### Aerodynamic fins

- **One tall central dorsal fin** behind the seat, swept backward with a broad upper surface and a pointed rearward/upward tip. Its sides carry a bold rainbow gradient and a prominent **white five-point star**.
- **Two shorter outboard rear fins**, left and right, emerging around the wheel/engine area, angled outward. They also carry rainbow paint and white star markings.
- Fins are genuine thin solids with beveled edges, not floating textured quads. Maintain the asymmetric swept profiles seen in side and three-quarter references while keeping left/right pairs mirrored.
- Do not mistake the central fin for a flag, or duplicate the fin arrangement.

## 4. Paint and graphics — critical

The glossy main body uses broad, **continuous rainbow ribbons** running lengthwise and diagonally along its curved shell. Colors progress through hot red, orange, bright yellow, green, cyan, saturated blue, violet and magenta. The pointed nose appears predominantly red/orange/yellow at its upper front with cooler blue/purple on the lower sides; the side panels feature a strong red-to-yellow-to-green-to-blue-to-purple sequence from upper to lower areas. Preserve this orientation from the source rather than applying a generic repeated rainbow texture.

White five-point stars are clearly visible on both side panels and on each of the three fins. Their size, placement, and crisp contours matter. They should follow the surface curvature without visible stretching, seams, mirrored backwards distortion, or pixelation. Use a carefully UV-mapped color/albedo texture (preferred), with consistent seam placement underneath or in mechanically hidden areas. A decal method is acceptable if the exported GLB remains stable in Godot 4 and avoids z-fighting. **Do not use vertex colors alone if they blur or distort the stars and rainbow boundaries.**

Additional color cues: glossy black seat and tubing; gunmetal and chrome-like wheel/engine rings; golden joystick; small red, yellow, blue and green control buttons; yellow/amber nose light and auxiliary side lamps; orange-yellow rear thruster glow; red rectangular rear brake/tail light. Keep rainbow paint glossy and toy-like rather than photorealistic weathered metal. No rust, dirt, scratches, camouflage, flames, numbers, text, or unrelated symbols.

## 5. Component hierarchy (recommended)

```text
RainbowRacer_ROOT
├── Body
│   ├── MainFuselage
│   ├── NoseCone
│   ├── NoseLightHousing
│   ├── NoseLightEmissive
│   ├── CockpitRim
│   ├── CockpitInterior
│   ├── SeatCushion
│   ├── SeatBack
│   ├── Dashboard
│   ├── JoystickBase
│   ├── JoystickStem
│   └── JoystickBall
├── Fins
│   ├── DorsalFin
│   ├── LeftRearFin
│   └── RightRearFin
├── Wheels
│   ├── Wheel_L_Pivot
│   │   ├── Tire_L
│   │   ├── Rim_L
│   │   └── Hub_L
│   └── Wheel_R_Pivot
│       ├── Tire_R
│       ├── Rim_R
│       └── Hub_R
├── SuspensionAndPipes
│   ├── Fender_L
│   ├── Fender_R
│   ├── Suspension_L
│   ├── Suspension_R
│   ├── SidePipe_L
│   ├── SidePipe_R
│   ├── SideCylinder_L
│   └── SideCylinder_R
├── RearEngine
│   ├── EngineHousing
│   ├── ConcentricMetalRings
│   ├── ThrusterEmissive
│   └── TailLight
└── AuxiliaryLamps
    ├── Lamp_L
    └── Lamp_R
```

Individual meshes may be merged for performance when no animation is needed, but retain separate wheel pivots, cockpit details, lighting, and rear thruster where practical.

## 6. Specific geometry notes

1. **Nose:** smoothly tapered and round in cross-section; no long sharp needle or angular fighter-jet geometry. A small circular amber lamp sits at the very tip.
2. **Cockpit:** recessed open tub, with no pilot or character included. Make seat padding actual shallow volumes with seams suggested by low-cost geometry or normal maps. Keep the dashboard visible from front and top views.
3. **Wheels:** two primary wheels near the rear, one per side, with radial multi-spoke hubs, thick tires, curved metallic fenders, and external linkage. Technical drawings show additional dark mechanical/underside components; do not reinterpret these as a new pair of large front wheels.
4. **Engine:** circular concentric silver/gunmetal barrel at the rear, with a luminous central disc. Use actual layered rings, not just a flat texture. The exhaust points backward along +Z.
5. **Tubular frame:** dark bent tubes run alongside the lower fuselage, connecting around the rear assembly. Keep pipes symmetric, rounded, and visibly separate from the rainbow body.
6. **Lighting:** two small side-mounted amber/yellow lamps, a tiny bright nose lamp, red rectangular rear lamp, and large glowing exhaust. Emission textures/materials should remain visible without bloom; optional glow is an engine-level postprocess effect.
7. **Underside:** dark, relatively flat mechanical belly plate with subtle panel fasteners and engine/axle support, following the technical bottom view. Avoid unsupported complexity.

## 7. Materials / glTF 2.0 PBR

| Material | Base color / texture | Metallic | Roughness | Notes |
|---|---|---:|---:|---|
| RainbowBody | UV-mapped saturated rainbow + white stars | 0.15–0.35 | 0.16–0.25 | Clear-coated appearance, no baked studio reflections |
| BlackRubber | Near-black charcoal | 0.0 | 0.72–0.85 | Tires |
| DarkPaddedSeat | Dark graphite | 0.0 | 0.50–0.68 | Padded upholstery |
| Gunmetal | Dark neutral metallic gray | 0.75–0.95 | 0.27–0.40 | Tubes and machinery |
| PolishedMetal | Medium-light silver | 0.85–1.0 | 0.14–0.27 | Rings, wheel edges, fenders |
| Controls | Distinct bright button colors | 0.0–0.35 | 0.20–0.35 | Tiny dashboard accents |
| AmberEmission | Amber/yellow/orange | 0.0 | 0.25 | Thruster, front and side lamps |
| RedTailLight | Red translucent-looking lens | 0.0 | 0.25 | Red emissive rectangle |

Numbers are suggested starting points, not absolute constraints. Export textures with the GLB. Prefer a 2048² albedo atlas for paint/stars if needed; smaller maps for secondary parts. Use PBR emission, not external Blender shader nodes that fail to translate to glTF.

## 8. Modeling sequence for the generating agent

1. Establish axes, nominal dimensions, ground clearance, and front/back orientation.
2. Block out the fuselage, cockpit opening, nose, rear engine, and wheel positions using orthographic front/side/top views.
3. Compare silhouette against **both** left and right side images, front and rear images, and the 3/4 views; correct proportions before adding details.
4. Sculpt/model the rounded cockpit lip, padded seat, dashboard, and raised rear backrest.
5. Model dorsal fin and the two smaller side fins; validate their swept shapes in profile and rear view.
6. Add both rear wheels, multi-spoke hubs, metallic fenders, suspension, black frame tubes, and cylindrical side components.
7. Build the rear jet as concentric metallic ring meshes with a recessed emissive core; add lamps and tail light.
8. UV unwrap visible painted surfaces and create reference-faithful rainbow ribbons and star graphics. Validate from all views.
9. Assign GLB-compatible PBR materials and emission. Optimize mesh complexity without losing the recognizable curves.
10. Export to GLB, reimport in Godot 4 or a glTF viewer, and render front, rear, both sides, top, and four 3/4 views for comparison.

## 9. Game-ready constraints

- Suggested **15k–35k triangles** for the complete asset as a starting target; prioritize silhouette, rounded wheels, visible pipes, and fin shapes. The actual limit depends on platform and scene population.
- No unnecessary subdivision modifiers at export. Use bevels and weighted normals selectively.
- Avoid non-manifold shells, duplicate coplanar faces, loose vertices, inverted normals, z-fighting decals, and missing texture paths.
- Ensure body does not intersect the rotating wheels. All components must be grounded in believable attachment points.
- Use consistent texel density; mirror only where graphics stay correct. A star must not become distorted or mirrored incorrectly.
- No baked lighting, shadow, black backdrop, floor, camera, character, or environment geometry in the GLB.
- If desired, include simple collision proxies as separately named objects, but do not substitute them for the visual mesh.

## 10. Acceptance checklist

- [ ] Model is a fully enclosed 3D object with an open, recessed cockpit, not a billboard.
- [ ] Nose faces **-Z**, exhaust faces **+Z**, **+Y** is up.
- [ ] Approximate length 1.85 m and width 0.90 m; proportions match technical references.
- [ ] One tall dorsal fin plus two smaller rear side fins; all have correct rainbow/star graphics.
- [ ] Main body displays continuous, clean rainbow bands from every angle.
- [ ] Large white stars on body sides and fins are legible and correctly positioned.
- [ ] Two external rear wheels with visible spokes, fenders, and suspension.
- [ ] Black padded seat, gold joystick, multicolored buttons, and open cockpit rim are present.
- [ ] Rear concentric metallic jet glows amber; nose and auxiliary lamps glow; red tail light exists.
- [ ] Black side pipes and silver cylinders are visible on both sides.
- [ ] GLB reimports with all meshes, textures, emission, transforms, and pivots intact.
- [ ] No unintended extra components, lettering, numbers, flags, or altered graphics.

## 11. Final instruction to 3D-generation LLM

**Build and export `rainbow_racer.glb` based on BOTH attached references and this specification.** Treat the multi-view technical sheet as the geometric authority and the color artwork as the visual authority. Preserve the distinctive glossy rainbow stripes and crisp white stars rather than substituting generic procedural gradients. Model all visible elements as coherent, physically attached 3D geometry. Make the result usable in Godot 4 and visually recognizable from every angle. If a detail is hidden or ambiguous, infer the simplest symmetrical and mechanically plausible solution consistent with the other views, and report that assumption separately rather than inventing conspicuous new design features.
