# BoRacer — Game-Ready 3D Asset Specification: Purple Passion

## 1. Objective and source priority

Reconstruct **Purple Passion**, a whimsical retro-futuristic single-seat rocket racing kart, as a complete, recognizable, game-ready **GLB/glTF 2.0** asset for **Godot 4**. Use the two supplied images together:

- `purple-passion(2).png`: **primary source** for colors, glossy finish, star placement, silhouette, lighting, and detailed design.
- `purple-passion-technical.png`: **primary source** for front/rear/left/right/top/bottom proportions, three-quarter views, component layout, and construction details.

Do not reinterpret the vehicle as an aircraft, conventional automobile, motorcycle, or generic spaceship. Build true three-dimensional geometry, not intersecting picture planes or a single textured billboard. Reference drawings are stylized and may have minor inconsistencies: prioritize the main color render for appearance and the orthographic reference views for construction. Avoid inventing invisible mechanical details.

## 2. Coordinate system, dimensions and placement

- Model in meters; **length approximately 1.85 m**, **maximum body/wheel width approximately 0.90 m**. The technical drawing's vertical annotation appears to indicate roughly **0.85 m** for the main vehicle; the glowing antenna extends beyond the main hull silhouette. Treat all these as approximate, not precision-engineering dimensions.
- Godot/glTF convention: **+Y up**, **front/nose points -Z**, **rear thruster points +Z**, **vehicle left/right across X**. Check and correct Blender export axes rather than assuming an imported orientation.
- Center the main root at ground level near the horizontal center of the vehicle. Wheel contact patches lie at Y=0; model geometry stays above ground except any intentionally low pipes.
- Use symmetric mechanical structure where appropriate, but do not mirror decals blindly if references show deliberate asymmetry.
- A broad pear/torpedo-shaped fuselage: pointed front at -Z, widest and tallest around the cockpit and rear shoulders, narrowing toward the conical nose. Low and elongated stance with two substantial rear wheels visible on both sides. A small central tire appears in front/rear silhouettes under the body: include it if confirmed by the supplied orthographic views, but do not turn the design into a conventional four-wheel car.

## 3. Core silhouette and body geometry

### 3.1 Main purple fuselage

Create a continuous, rounded, aerodynamic shell with a low sweeping side profile. The body begins near the aft wheel assemblies and extends forward to a pointed nose cone. The cockpit is an open cavity recessed into the top, with a thick raised rim and a distinct front dashboard lip. Preserve a clean curved shoulder line from the rear seat toward the front instrument pod.

- Primary finish: saturated **royal/deep violet**, highly polished, with bright magenta-violet reflections. Avoid flat pastel lavender or blue.
- Large uninterrupted purple side panels provide a backdrop for scattered golden five-pointed stars of varying sizes.
- Use smooth normals, modest bevels, and enough radial geometry to avoid a faceted silhouette at normal racing camera distances.
- Build the fuselage as one or several clean closed meshes, not loose flat strips.

### 3.2 Front nose

The front is a long purple cone/ogive terminating in a small, circular **warm yellow-white illuminated headlamp** surrounded by a gold bezel. A thick **metallic gold collar** encircles the base of the nose, with evenly spaced dark fasteners. On the head-on view, a second broad gold bolted band/rim frames the nose transition. Respect these concentric bands and do not merge them into the purple shell texture.

### 3.3 Open cockpit and seat

Single seat, no windshield, no canopy. Black or very dark charcoal padded seat with visible backrest, horizontal upholstery divisions, and a slightly curved lower cushion. Cockpit opening is oval/elongated in plan view, framed by a thick **gold trim**. Interior is dark, with a rear seat surround rising behind the driver's shoulders. At the front of the cockpit is a compact angled dashboard: black inset top, gold outer border, small red, blue, green and yellow buttons, and a short joystick topped with a golden sphere. The dashboard must be visible from above and from the front three-quarter view. Keep seat and control panel as separate meshes.

## 4. Rear structure, fins and antenna

### 4.1 Three-fin arrangement

The signature arrangement is **one tall upright center fin** behind the cockpit and **two shorter outward-canted side fins** mounted over/behind the rear wheel shoulders. Use thickness, rounded leading edges, and tapered trailing edges; they are solid fins, not paper planes.

- Tall center fin: swept triangular/curved purple form rising above the seat; gold edge/tip detailing and a prominent gold five-point star on its side.
- Left and right small fins: swept, wing-like purple forms flaring outward; gold leading-edge/tip accents. Keep their placement consistent with the front, rear, top and three-quarter views.
- The reference includes star motifs on the fins; reproduce only the stars that are visibly present and place them as surface markings, not raised bulky extrusions.

### 4.2 Beacon antenna

A slender, dark metal stalk rises from the aft upper structure behind/above the center fin and terminates in a large glowing **golden-yellow orb**. The stalk leans slightly in the side view; use the orthographic reference for placement. Include gold metal collars and a base mount. Model the orb as its own mesh with emissive PBR material, so Godot can animate emission intensity. The bright halo/bloom seen in the artwork is a render effect, not physical geometry; do not bake a giant halo disk into the mesh.

### 4.3 Rear thruster

Large circular rocket thruster mounted on the centerline at the rear, approximately at wheel-hub height. Build layered cylindrical housings, dark metallic outer sections, concentric silver/gunmetal rings, and a recessed bright amber/orange luminous core with a white-hot center. Rear nozzle must have actual depth, not a flat orange disk. Separate its emissive center from housing and rings. Above it is a small rectangular **red taillight**; on either side sit warm amber round lamps in black housings. Dark support brackets and tubes frame the thruster.

## 5. Wheels, suspension, pipes

- Two dominant rear wheels, one on each side, with thick black rubber tires, shallow tread grooves, black multi-spoke wheel centers and **gold wheel-rim accent rings**. Use cylinders/tori with real tire volume; orient axles along X.
- Bright curved silver wheel arches follow the upper tire contours, attached to the body with visible mounts.
- Black metal suspension rods angle between upper rear supports and lower wheel assemblies. Include cylindrical pivots, joints, and metal collars. Keep rods symmetrical and visibly connected.
- Long, parallel **black external pipes** run low along each side below the purple panels. A shorter upper metallic cylindrical canister/pipe with silver-gold finish and dark rounded endcaps sits near the rear wheel and lower midbody. Pipes must be 3D tubes with visible end geometry, not painted lines.
- At the rear, add the characteristic black tubular bumper/frame and mechanical supports around the engine. Do not clutter with unreferenced machinery.
- Bottom view shows a dark flat-ish structural undertray with panel seams/fasteners and compact axle/engine details near the rear. Build a plausible simplified underside, not an open hollow shell.

## 6. Color and material guide

Approximate palette, to be sampled/refined from supplied PNG rather than treated as exact colorimetry:

| Part | Visual target | PBR guidance |
|---|---|---|
| Main body | Deep saturated royal purple / violet | Nonmetallic automotive paint, metallic 0.0–0.25, roughness ~0.18–0.3, optional clearcoat |
| Gold trim and star graphics | Rich warm golden yellow | Trim metallic ~0.7–1.0; star decals primarily opaque golden color |
| Wheel/tire | Near-black rubber | Metallic 0, roughness ~0.75 |
| Wheel spokes, suspension, pipes | Black chrome / gunmetal | Metallic ~0.65–0.95, roughness ~0.2–0.4 |
| Wheel arch and nozzle rings | Silver polished metal | Metallic ~0.85–1.0, roughness ~0.15–0.3 |
| Seat | Charcoal black leather/vinyl | Metallic 0, roughness ~0.55–0.8 |
| Headlamp and beacon | Warm yellow-white | Emissive material, adjustable intensity |
| Rear thruster | Orange/amber to white center | Separate emissive rings/core; bloom handled in Godot |
| Rear taillight | Saturated red | Red lens plus moderate emission |

Keep decorative **gold five-point stars** clean and sharp. On the side panels, use one large central star and several smaller stars scattered around it, consistent with each visible side view. Additional small stars decorate the nose shoulders/front and the fins. Use UV decals or a texture atlas (recommended), avoiding Z-fighting; do not create enormous floating star geometry. The original star pattern is part of the vehicle identity: do not replace it with sparkles, galaxies, dots, or gradients.

## 7. Proposed scene hierarchy

```text
PurplePassion_Root
├── Chassis
│   ├── MainBody
│   ├── NoseCone
│   ├── NoseGoldBand
│   ├── NoseFasteners
│   ├── Undercarriage
│   └── StarDecals
├── Cockpit
│   ├── CockpitGoldRim
│   ├── SeatBack
│   ├── SeatCushion
│   ├── Dashboard
│   ├── DashboardButtons
│   └── Joystick
├── RearAssembly
│   ├── ThrusterHousing
│   ├── ThrusterRings
│   ├── ThrusterEmissiveCore
│   ├── RearTaillight
│   ├── SideLamps
│   └── SupportFrame
├── Fins
│   ├── CenterFin
│   ├── LeftFin
│   └── RightFin
├── Beacon
│   ├── AntennaStalk
│   └── BeaconEmissiveOrb
├── Wheels
│   ├── WheelRearLeft
│   ├── WheelRearRight
│   └── WheelFrontCenter_if_reference_confirms
├── Suspension
│   ├── LeftSuspension
│   ├── RightSuspension
│   └── WheelArches
├── ExternalPipes
│   ├── LeftPipes
│   └── RightPipes
└── Lamps
    └── NoseEmissiveLamp
```

Keep major animatable components independently addressable: wheels, beacon, thruster core, lights. The GLB scene can contain many nodes but should avoid unnecessary individual objects for each bolt if draw calls become excessive.

## 8. Construction sequence for the modeling agent

1. Establish dimensions, axes and the primary fuselage silhouette using side, top and front orthographic references. Create a grey clay model first.
2. Shape the front nose and gold collar; check its cone curvature and the front lamp location.
3. Cut the cockpit opening into the upper body and install the raised gold rim, dark seat and dashboard.
4. Model rear wheels, hubs, tire treads and curved silver fenders; verify wheel contact and wheel-to-body spacing.
5. Add the rear central thruster, red taillight, side lamps, black structural tubing and suspension.
6. Build the three fins, ensuring their sweep, thickness and attachment points match the top and rear views.
7. Add the beacon stalk and separate glowing orb.
8. Build side pipes and upper cylindrical canisters.
9. UV unwrap body panels; apply deep purple paint, gold bands and precisely located gold star graphics.
10. Add PBR materials and emissive lamps. Test with neutral studio lighting so bright reflections do not disguise incorrect geometry.
11. Inspect front, rear, left, right, top, bottom and both three-quarter angles against the PNGs.
12. Optimize, export GLB, import into Godot 4, and check that materials, normals, node names and emission survive.

## 9. Performance and topology

- Suggested visual target: **20,000–45,000 triangles** for a hero/garage-selection asset, adjustable to the game's target hardware and camera distance. This is a target, not a hard requirement.
- Prioritize geometry at the outline, cockpit opening, wheels, fins and nozzle. Use textures/normal maps for shallow seams, bolt heads and decorative stars where appropriate.
- Avoid hidden overlapping shells, zero-area faces, inverted normals, disconnected floating components, or dense tessellation on straight pipe sections.
- Use a compact PBR texture atlas where practical (base color, metallic-roughness, normal if needed), preferably 1K–2K for this vehicle depending on on-screen size.
- Prefer physically connected-looking components, but do not merge animatable wheels, antenna orb, or thruster glow into the main body mesh.
- If adding LODs, retain distinctive gold stars, fin silhouettes, rear nozzle and beacon at every useful viewing distance.

## 10. GLB export and Godot validation

- Export **glTF 2.0 binary (.glb)**, with embedded meshes/materials/textures.
- Use meters, apply object transforms and verify orientation in Godot: front = -Z, up = +Y.
- Use stable, descriptive object names. Preserve pivots for wheels (at each axle center), thruster and antenna orb.
- Ensure double-sided settings only where needed, e.g. very thin decorative surfaces; fins should have real thickness.
- Verify color textures are interpreted as sRGB and PBR data maps use the appropriate non-color data settings.
- Emissive materials should visibly glow as colored surfaces without relying on a baked background; enable glow/bloom in the Godot environment if desired.
- Include no background plane, studio backdrop, ground shadows, reference images, labels or cameras in the final GLB unless separately requested.

## 11. Acceptance criteria

- [ ] Immediately recognizable as **Purple Passion** from the references, not a generic purple kart.
- [ ] Deep glossy purple body and clean metallic gold trim.
- [ ] Correct number and placement of gold stars, with one prominent large star on each side.
- [ ] Single open cockpit, dark padded seat, visible colorful controls and gold-topped joystick.
- [ ] Pointed purple nose with gold bolted collar and glowing front lamp.
- [ ] Two prominent black rear wheels with gold-accented rims, silver arches and visible suspension.
- [ ] Three swept rear fins, central fin taller than side fins.
- [ ] Rear antenna with a separate glowing golden sphere.
- [ ] Large recessed orange rear rocket thruster, red rectangular rear light and amber side lamps.
- [ ] External black pipes, cylindrical canisters and tubular rear supports.
- [ ] Plausible complete underside and no missing geometry from a 360-degree view.
- [ ] Proper Godot 4 scale/orientation, PBR materials, independent animated parts and successful GLB import.

## 12. Final instruction to the 3D-generating LLM

**Use both reference PNGs as ground truth. First match the silhouette and component locations from the technical sheet, then reproduce the color, material and decorative details from the full-color sheet. If a hidden surface is not depicted, infer the simplest mechanically coherent form consistent with visible orthographic views. Never add new wings, extra seats, wheels, weapons or decorative patterns. Deliver a clean, game-ready, editable-node GLB with the correct proportions and unmistakable Purple Passion identity.**
