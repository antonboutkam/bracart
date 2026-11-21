# BoRacer — 3D Asset Specification: Toxic Turbo

**Asset ID:** `vehicle_toxic_turbo`  
**Deliverable:** `toxic_turbo.glb` (glTF 2.0 binary)  
**Target:** Godot 4, real-time arcade racing game  
**Reference files:** `toxic-turbo(1).png` (primary appearance), `toxic-turbo-technical.png` (multiview reference)

## 1. Mission and reference priority

Build a complete, fully three-dimensional, game-ready stylized rocket racer matching the supplied reference images. Preserve its distinctive silhouette, proportions, surface graphics and mechanically layered construction. Do not redesign it or substitute a generic rocket, car or motorcycle.

**Priority:** (1) orthographic and multi-angle reference for structure and placement; (2) primary image for finish, shape language and color; (3) reasonable symmetric reconstruction only where information is missing. Some reference panels may contain perspective distortions or small inconsistencies: resolve them by preserving the main side profile and recognizable front/rear views, rather than reproducing inconsistent details literally.

## 2. Coordinate system and dimensions

- **Target dimensions:** approximately **1.85 m long × 0.90 m wide × 0.85 m high**, interpreting the drawing's 1850/900/850 annotations as millimeters. Preserve ratios if scale is later changed.
- **Axes:** Godot convention: +Y up, vehicle front toward **-Z**, vehicle rear toward **+Z**, +X vehicle right.
- **Origin:** centered laterally at ground level, approximately midway along the vehicle length; wheels contact Y=0.
- **Transforms:** export at scale 1 with applied transforms, correct normals, no unexpected parent rotations.
- **Approximate dimensions, not exact CAD:** derive all subcomponent sizes and positions visually from reference images. Never claim unseen dimensions are measured.

## 3. Overall silhouette

A compact single-seat, open-cockpit, retro-futuristic rocket-powered racing vehicle. The long, low, torpedo-shaped body tapers toward a pointed front nose. The rear is mechanically dense, with a very large circular luminous thruster, two chunky exposed wheels, tubular rails, shock-like linkages, auxiliary cylindrical engine housings, a tall central dorsal fin, and two smaller side fins. The front and rear each carry conspicuous lights. The style is a playful, high-detail arcade racing prop, not photorealistic military hardware.

**Critical directional distinction:** the **small pointed nose and circular green nose lamp are at -Z (front)**. The **large round green-white jet exhaust and red rectangular tail lamp are at +Z (rear)**. Do not reverse them.

## 4. Geometry: build from primary volumes to secondary details

### 4.1 Main fuselage

- Create a continuous, low, streamlined body, widest around the cockpit/rear-midsection and tapering smoothly into the front cone.
- Its side walls are glossy dark charcoal / near-black with vivid toxic-lime green splash motifs.
- The forward cone is a dark metallic tapered ogive, not a flat-ended cylinder. Its point terminates in a small circular glowing neon-green lamp with a metallic green rim.
- Add a bright lime green circumferential ring immediately behind the nose cone, with regularly spaced dark bolt heads. Add subtle metal seam rings where visible.
- Body panels are smooth and moderately bevelled; maintain intentional hard seams at metal bands and mechanical joints.

### 4.2 Open cockpit and seat

- A single open cockpit is recessed into the upper body. Do not close it with a canopy or windshield.
- Shape its opening as a long rounded rectangle/oval, with a thick bright-green upper rim following the vehicle's upper contour.
- At the rear of the opening, place a black, padded bucket seat with a tall backrest, slightly reclined. The upholstery has visible stitched segmented cushions, rounded padding and side bolsters.
- In front of the driver, build a compact green-trimmed dashboard containing a yellow/gold ball-topped joystick, red and blue buttons, smaller black/yellow switches and circular indicator details. Position it toward the front of the cockpit.
- Keep the interior hollow and readable from above and 3/4 views. A seat-shaped texture on a flat deck is not acceptable.

### 4.3 Rear wheels and suspension

- Two exposed rear wheels, one on each side, are substantial black rubber tires with rounded shoulders and subtle tread grooves.
- Dark metallic multi-spoke rims have bright steel outer lips and prominent central hubs.
- Position wheels around the rear-mid body, not at the pointed nose. Their size and placement must match the side views.
- Add arched silver/black fenders above the wheels, side suspension struts, rod linkages, cylindrical shock-like components, joints, brackets and visible mounting collars.
- Wheels must be separate named mesh objects with correctly centered pivots and rotational axes, suitable for animation. Avoid baking wheels into the fuselage.
- The front elevation shows a small lower central tire-like element beneath the nose. The rear elevation also shows a lower central tire-like element beneath the thruster. The reference is ambiguous about the exact undercarriage/wheel arrangement: use the underside and line drawings to resolve it; if necessary, create simplified discrete small support wheel(s) while retaining the dominant paired rear wheels. Do not invent a large conventional front axle.

### 4.4 Rear thruster and auxiliary cylinders

- Build the rear thruster as a large, concentric cylindrical assembly with multiple steel and black rings, inset circular emitter and a bright lime-yellow/white glowing core.
- Its rear-facing emitter is much larger than the small nose light and dominates the rear view.
- Include surrounding dark turbine/housing details, metal rim highlights, stepped cylinder diameters and a luminous inner disc.
- Above and beside the rear wheel regions, model metallic cylindrical engine tanks/exhaust housings with black brackets, round caps and metal collars.
- Add low horizontal black/silver side pipes with rounded end caps and short coupling sections. Side rails and pipes must be genuine tubes, not decals.
- Include small yellow circular lamps on both sides of the rear mechanical assembly and a centered red rectangular rear light above the thruster.

### 4.5 Fins and spoilers

- A prominent tall, tapered central vertical fin rises behind the seat, widening near its base and leaning/sweeping back. Its silhouette is organic and pointed rather than a perfect triangle.
- Its surfaces are lime green with irregular dark charcoal/black spots, like a toxic camouflage pattern.
- Two smaller angled lateral fins protrude symmetrically from the rear sides. Preserve their characteristic swept, pointed profiles and spots.
- The fin thickness must be physically modeled, with rounded edges; do not use infinitely thin image planes.
- Preserve mechanical attachment collars and brackets at the base of the central fin.

### 4.6 Tubular framework and small parts

- The rear half includes an external dark metal tubular cage/rail structure, vertical struts, round joints, support rods, cylindrical braces and bolts.
- Use cylindrical or bevelled tubular meshes with consistent diameters, not isolated floating decorations.
- Retain recognizable mechanical layering while reducing subpixel details where needed for runtime performance.
- Small fasteners may be instanced or merged into static meshes after verification.

## 5. Graphics and material specification

Use physically based glTF-compatible materials. Match the reference's vivid, glossy arcade aesthetic:

| Material | Visual target | Roughness / metalness guidance |
|---|---|---|
| Toxic lime paint | High-saturation fluorescent yellow-green, approximately `#A8F000` to `#B5FF00` under neutral lighting | Roughness 0.20–0.32, metalness 0.1–0.35 |
| Charcoal body paint | Very dark graphite / near-black `#191B1C` to `#292B2D` | Roughness 0.20–0.35, metalness 0.3–0.55 |
| Polished metal | Steel/silver rims, clamps, rings and piston rods | Roughness 0.16–0.30, metalness 0.85–1.0 |
| Black mechanical metal | Tubes, joints, frames and housings | Roughness 0.24–0.42, metalness 0.6–0.9 |
| Rubber | Deep black tires, lightly satin | Roughness 0.65–0.85, metalness 0 |
| Seat upholstery | Black leather/vinyl with subtle seam relief | Roughness 0.48–0.70, metalness 0 |
| Lime lamps | Bright yellow-green emissive light | Emission enabled, intensity tuned in Godot |
| Rear red lamp | Red glowing rectangle in dark frame | Emission enabled |

**Color accuracy:** these hex values are starting estimates, not sampled authoritative palette values. Compare visually with the original PNG under neutral studio illumination. Do not use excessively blown-out bloom that destroys shape detail.

### Surface decoration

- On both side panels, include a **large circular toxic-green patch containing a black biohazard symbol**. Preserve its recognizable three-lobed form and circular structure. Mirror/position appropriately so it is legible from each side.
- Surround it with irregular neon-green splashes/blotches on the charcoal body. These are intentionally organic, asymmetrical shapes, not evenly spaced polka dots.
- Put black spots on the green dorsal and side fins.
- A black biohazard emblem is also visible on the green upper front body panel.
- Prefer UV texture decals or carefully designed mesh decals for large graphics; avoid floating planes, z-fighting and graphics that disappear at oblique angles.
- Do not replace the biohazard symbols with generic skulls, radiation symbols or unrelated lettering.

## 6. Mesh organization and pivots

Suggested hierarchy (adjust names if the implementation requires):

```text
ToxicTurbo (Node3D / root)
├── Body_Main
├── Body_NoseCone
├── Body_NoseRing
├── Light_Nose
├── Cockpit_Rim
├── Cockpit_Interior
├── Seat_Back
├── Seat_Cushion
├── Dashboard
│   ├── Joystick
│   └── Buttons_Indicators
├── Wheel_Rear_L (rotatable)
├── Wheel_Rear_R (rotatable)
├── Undercarriage_SupportWheels (if supported by reference)
├── Fenders_L_R
├── Suspension_L_R
├── Rear_Thruster_Housing
├── Rear_Thruster_Emitter
├── Rear_Light_Red
├── Rear_Lamps_Yellow_L_R
├── Engine_Cylinders_L_R
├── Side_Pipes_L_R
├── Frame_Tubes
├── Fin_Dorsal
├── Fin_Lateral_L
├── Fin_Lateral_R
└── Decals_Biohazard_Splashes
```

Use sensible object names and pivots. Keep wheel meshes separate, as well as any part likely to animate or emit light. Static mechanical details may be combined by material once verified. Do not rely on the hierarchy to replace proper geometric attachment.

## 7. Topology, textures and optimization

- Aim for a **mid-detail hero game asset**, not an unbounded cinematic sculpt. Suggested initial target: **20k–45k triangles** for the full vehicle, adjustable after in-engine performance tests; this is a production target, not a measurement from the reference.
- Concentrate triangles on the nose profile, cockpit rim, tire silhouette, fins and large thruster. Simplify small hidden fasteners.
- Avoid n-gons that triangulate unpredictably, inverted normals, self-intersections that cause visible artifacts, disconnected floating pieces and unnecessary interior surfaces.
- Prefer shared materials and one or two efficient texture atlases (e.g. 2048² for hero asset; reduce if needed). Preserve crisp logo edges with adequate UV space.
- Use smooth shading with appropriate sharp edges / weighted normals on machined components; bevel hard highlights selectively.
- UV unwrap visible textured surfaces without severe stretching. Bake graphic details into textures if needed.
- Model should look correct without reference PNGs placed as visible planes.
- Optional LOD variants are useful, but a clean base GLB takes precedence.

## 8. Rendering and lighting behavior

- Base colors should remain readable in neutral light, not depend on a specific HDRI.
- The nose lamp, rear jet emitter, yellow side lamps and red tail light should have emissive materials. Godot glow/bloom is a scene post-processing effect and must be configured in the engine; GLB alone cannot guarantee bloom.
- The rear thruster may optionally expose a separate emitter mesh/material for future acceleration effects.
- Do not add permanent smoke, particle systems, flames or environmental props to the GLB unless requested separately.

## 9. Generation procedure for the downstream modeling agent

1. Load **both** reference PNGs and identify the front/rear orientation before building anything.
2. Block out the main body, nose, cockpit cavity, rear wheels, rear thruster and fin assembly with simple primitives.
3. Compare silhouette against front, rear, both side, top and 3/4 panels. Correct proportions before detailing.
4. Build the cockpit and padded seat as genuine geometry, then dashboard and controls.
5. Model wheel assemblies, fenders, suspensions, side pipes, rear cylinders and tubular frame.
6. Add fin thickness, mounting hardware and the layered rear jet housing.
7. Apply materials and UV/decal graphics, especially both side biohazard logos and fin spots.
8. Validate from eight camera directions against the reference sheet; ensure both sides are modeled rather than one-sided image cards.
9. Optimize mesh and materials without sacrificing key silhouette features.
10. Export a real `toxic_turbo.glb`; reimport it into Godot 4 or a glTF validator and check orientation, materials, normals, hierarchy and wheel pivots.

**If the agent cannot directly create 3D files:** it must say so and produce an executable Blender Python modeling script or equivalent procedural source instead of pretending a GLB was generated. The script must build real geometry and export GLB when executed in Blender.

## 10. Acceptance criteria

- [ ] The vehicle points forward toward -Z; the small glowing lamp is in the front nose.
- [ ] The large circular thruster is rear-facing and clearly larger than the nose lamp.
- [ ] Overall proportions approximate 1.85 × 0.90 × 0.85 m.
- [ ] Both large rear tires are modeled as 3D tires with spoke rims and separate pivots.
- [ ] Open single-seat cockpit has padded seat, green rim and colored control panel.
- [ ] Central tall spotted fin and both smaller spotted lateral fins are present.
- [ ] Charcoal paint, toxic lime graphics and black biohazard logos match references.
- [ ] Metal frame, cylindrical housings, fenders and side pipes are physically present.
- [ ] Nose, rear thruster, yellow side lamps and red tail lamp use suitable emissive materials.
- [ ] All primary surfaces exist and look plausible from 360°.
- [ ] GLB imports into Godot 4 with correct scale, +Y up and -Z forward.
- [ ] No missing textures, flipped normals, obvious z-fighting or detached geometry.

## 11. Known ambiguities and conservative assumptions

- The reference image is an illustrated design sheet, not a mechanically exact CAD blueprint. Some hidden geometry, wheel layout and attachment points are ambiguous.
- The dimension labels are interpreted as millimeters and should be treated as target bounding-box dimensions, not measured engineering specifications.
- The exact underside wheel arrangement should be reconstructed conservatively from the underside/line drawings, without inventing a large front suspension.
- Surface graphics are stylized and may not align perfectly across all generated reference panels. Preserve the overall composition, not every individual splash boundary.
- Material colors are approximate; visually compare against the original reference images.

## 12. Final instruction to the modeling agent

**Produce a recognizable, polished, efficient 360-degree 3D recreation of the supplied Toxic Turbo rocket kart. Match the two reference PNGs closely, especially the nose-versus-thruster orientation, cockpit, fins, wheels, biohazard graphics, and neon green/charcoal palette. Export `toxic_turbo.glb` for Godot 4. Do not replace missing information with unrelated creative additions. Report any unresolved ambiguities and validate the resulting file rather than merely asserting completion.**
