# BoRacer — Golden Rocket Racer
## Game-ready 3D reconstruction specification (GLB / Godot 4)

### 1. Objective and source priority
Reconstruct the **Golden Rocket Racer** as a complete, recognizable, optimized 3D vehicle using both supplied PNG references:
- `golden-rocker-racer(2).png`: primary reference for appearance, palette, paint, highlights, and silhouette.
- `golden-rocket-racer-technical.png`: reference sheet for front/rear/left/right/top/bottom, three-quarter views, details, and approximate dimensions.

**Source precedence:** Use the multiview drawings for geometry and the primary color render for surface treatment. Where drawings conflict, favor consistent orthographic silhouettes, then perspective views. Never hallucinate major components. Model all visible sides, not a billboard or relief.

### 2. Vehicle identity
Single-seat, open-cockpit retro-futuristic rocket racing kart with a long pointed nose at the **front**, two exposed large rear side wheels, a small narrow wheel visible beneath the front center, and a large circular rear jet/thruster. Its defining visual language is polished golden-yellow bodywork, muted olive/gold military-style stripes and star insignia, black exposed pipe chassis, brown leather upholstery, and warm amber lighting.

### 3. Coordinate system and proportions
- Engine: Godot 4, glTF 2.0 / `.glb`.
- **+Y up; -Z forward (pointed nose); +Z rear**; +X vehicle's right.
- Approximate main body length **1.85 m**, width **0.90 m**. Sheet gives height annotations **0.85 m and 0.90 m** that may differ by view; prioritize visual proportions. Measure overall height including fin, not simply cockpit rim.
- Place scene origin at ground level, centered laterally and near the wheelbase center; use separate local pivots for spinning wheels and optional steerable front assembly.
- Maintain approximate bilateral symmetry for structure; mirrored insignia and small detail placement should match the respective side references.

### 4. Primary body shell
- Main body is an elongated, smooth, tapered, convex rocket hull, broadest around the cockpit/rear-midsection and narrowing into a conical rounded front tip.
- Front nose should look like a solid smoothly curved metal fairing, **not** a thin cylinder or sharp needle. Distinct seams separate nose cone from central body. Include a gold/olive metallic band with small regularly spaced rivets around the transition near the front cockpit region.
- Side panels gently bulge, with a subtle lower edge and taper toward the nose. Preserve the uninterrupted streamlined profile and cockpit cutout.
- Add visible panel seams and small metallic fasteners, without making the body faceted or excessively mechanical.
- At the nose tip: a small round amber/yellow headlamp set into a metallic gold bezel. The tip itself is rounded.

### 5. Paint, emblems, and decals
- Dominant paint: glossy **warm golden yellow**, with cream-yellow highlights caused by reflection rather than a white base coat.
- Secondary color: muted **olive-brown / antique brass**. Apply thin longitudinal stripe on both sides at mid-height; a matching transverse stripe on the upper central fin; other banding according to references.
- Large insignia on both side body panels: dark olive circular disc with a contrasting angular five-point star / layered star shape. Preserve the distinct star silhouette from the source rather than substituting a generic US military insignia. Place approximately ahead of rear wheel and behind nose seam. The circle and horizontal stripe visually overlap.
- Smaller star emblem on upper nose front; see frontal view. Avoid placing oversized star marks on the underside.
- Use UV texture/decal or carefully mapped material regions so stripes and symbols follow curved surfaces without stretching. Mirror decals carefully, maintaining correct star orientation and avoiding text-like artifacts.
- Finishes should be clean but not perfectly sterile: subtle roughness variation, thin seam darkening, controlled specular reflections. Do not bake image lighting/shadows into albedo.

### 6. Cockpit and controls
- Open top cockpit centered along the body axis, with an elongated oval/racetrack opening; raised yellow/gold rim around its perimeter.
- One deeply padded dark brown leather racing seat with separate backrest and lower cushion. Seat back is steeply inclined at the rear of the opening; segmented cushioning visible. No driver.
- Small raised instrument pod at the **front of the cockpit** with dark faceplate, small colored buttons/lights (red, green, orange), a central short joystick topped by a spherical yellow/gold knob. Position must match both top and side views.
- Black/dark inner cockpit lining. A sculpted padded gold/yellow structure supports the seatback and aft body.

### 7. Tail fins and rear upper assembly
- One tall central vertical fin above/behind seat, curved backward in a swept retro-aircraft silhouette; gold paint with an olive horizontal stripe. Its tip is rounded and not a razor edge.
- Two shorter outward-facing side fins toward the rear, one each side, triangular/swept, gold with muted olive accents. Distinct from wheel fenders.
- Structural rear seat surround has a compact raised gold body/pod, black cylindrical components, and metallic fasteners.
- Fins are actual 3D airfoil-like shells with thickness, bevels, and separate editable meshes, not flat alpha planes.

### 8. Wheels, fenders, and suspension
- Two prominent exposed rear wheels left/right. Dark rubber tires with understated tread and broad rounded shoulders.
- Wheels feature black multi-spoke metal hubs with **golden-yellow outer rim rings** and central gold/black axle caps. Use proper circular mesh, enough radial segments to remain round.
- Thin polished metal fender arch hugs the top/front edge of each rear wheel. Rear-wheel placement and silhouette should agree with side and rear views.
- A small narrow front wheel is visible beneath the center of the pointed nose in front/rear orthographic views; build it if supported by reference, rather than incorrectly assuming a conventional four-wheel chassis.
- Exposed black tubular struts, articulated diagonal bars linking wheel hubs to body, vertical shock/suspension members, cylindrical pivot joints, and small round bolts. These must be plausible and physically connected.

### 9. External pipework and frame
- Glossy black/very dark charcoal tubular rails run along both lower sides, with rounded bends and visible capped ends.
- One horizontal upper silver/brass cylinder above the lower side rail near rear wheel, with black connection pipes. Metallic fittings should have mild worn-steel sheen.
- Rear framework includes vertical and diagonal tubular elements, black crossbars, cylindrical joints and fasteners. Match source placement, not random decorative pipes.
- Keep separate mesh groups for frame and pipes to facilitate later editing.

### 10. Rear thruster and lighting
- Large circular jet engine centered at the back, wider than the small nose lamp. Metallic layered housing with dark steel rings, warm brass/gold concentric interior and a **bright amber-white luminous core**.
- Concentric rings must be true 3D geometry, not a flat glowing disk. Emissive material creates the light appearance; Godot glow/bloom is a runtime post-process effect and must not be relied on for base geometry.
- Rear engine is partly framed by the wheel/pipe assembly. Add small orange/yellow side lamps at outer rear frame edges and a small rectangular **red tail light** above the thruster.
- The front has two round amber side lights, symmetrically mounted on the tubular uprights.
- No particle flames baked into the GLB; optional runtime VFX may be added in Godot.

### 11. Underside
- Use technical bottom view: dark, flattened rectangular belly pan with panel divisions and rivets, connected to the rear engine assembly and side pipes. Build enough underside structure to look credible if the kart flips or jumps.
- Avoid leaving open holes or visibly unfinished bottom surfaces.

### 12. Suggested Blender mesh hierarchy
```text
GoldenRocketRacer_ROOT
├── Body
│   ├── MainHull
│   ├── NoseCone
│   ├── NoseTrimBand
│   ├── CockpitRim
│   ├── CockpitInterior
│   ├── BellyPan
│   └── BodyDecals
├── Cockpit
│   ├── SeatBack
│   ├── SeatCushion
│   ├── Dashboard
│   ├── Joystick
│   └── Buttons
├── Fins
│   ├── Fin_Center
│   ├── Fin_Left
│   └── Fin_Right
├── Wheels
│   ├── Wheel_Rear_L
│   ├── Wheel_Rear_R
│   └── Wheel_Front_Center
├── Suspension
│   ├── Fender_L
│   ├── Fender_R
│   ├── Struts_L
│   └── Struts_R
├── PipesAndFrame
│   ├── SideRails_L
│   ├── SideRails_R
│   ├── Cylinders_L
│   ├── Cylinders_R
│   └── RearFrame
├── Engine
│   ├── ThrusterHousing
│   ├── ThrusterRings
│   └── ThrusterCore_Emissive
└── Lights
    ├── NoseLamp
    ├── FrontSideLamps
    ├── RearSideLamps
    └── RearRedLamp
```

### 13. PBR material targets
Approximate values only; visually sample references where possible.

| Material | Base color | Metallic | Roughness | Notes |
|---|---|---:|---:|---|
| GoldYellowPaint | #EAB92E | 0.45 | 0.22 | Glossy lacquered shell |
| OliveMarkings | #746023 | 0.18 | 0.36 | Stripe and star decal |
| AntiqueGoldTrim | #C99B38 | 0.8 | 0.24 | Rim, bands, hardware |
| DarkSteel | #292C2C | 0.75 | 0.3 | Tubes, mounts |
| SilverSteel | #92918B | 0.82 | 0.24 | Wheel arch, jet rings |
| TireRubber | #19191A | 0 | 0.78 | Rubber tread |
| BrownLeather | #493024 | 0 | 0.68 | Seat upholstery |
| AmberEmission | #FFB521 | 0 | 0.2 | Emission strength > 1 in engine workflow |
| RedRearLens | #B9140C | 0.05 | 0.18 | Red taillight |

### 14. Game asset optimization
- Target **20k–40k triangles** total for hero vehicle; optimize as appropriate for on-screen size and target hardware. Avoid unnecessary unseen internals.
- Prefer 1–3 texture atlases (e.g. 2048² for body decals and trim, smaller for repeated materials) with shared PBR materials; preserve sharp star edges and paint stripes.
- Weighted normals and small bevels for hard surface highlights; smooth normals on curved shell. Use sensible UV islands and padding.
- Separate animation-worthy parts: rear wheels, front wheel, joystick, optional thruster core. Do not combine everything into a single uneditable mesh.
- Collisions should be simple Godot primitives/convex shapes, not triangle-mesh vehicle physics.

### 15. Modeling procedure for generating LLM
1. Establish axes, overall dimensions, side silhouette and nose/rear orientation.
2. Block out central shell, cockpit void, seat and front/rear engine envelopes.
3. Align front, rear, side and top silhouettes with technical reference.
4. Add rear wheels, front center wheel, fenders and suspension joints.
5. Construct central/side fins, external pipework and rear jet housing.
6. Add dashboard, upholstery, nose light and side/tail lights.
7. UV unwrap body, apply gold paint, olive stripe and star insignia at source-correct positions.
8. Add rivets, seams, trim and physically plausible material response.
9. Check eight three-quarter and orthographic views against sheet; revise mismatches.
10. Apply transforms, ensure correct normals, no loose floating components, export binary `.glb`.

### 16. Acceptance tests
- [ ] Nose points -Z; thruster points +Z; Y up.
- [ ] Recognizable golden-yellow rocket racer with correct olive star emblem and stripe.
- [ ] Full 360-degree model, including underside, not merely a front-facing prop.
- [ ] Open cockpit, brown padded seat, colorful control panel and gold joystick.
- [ ] Three swept tail fins, including tall central fin with olive stripe.
- [ ] Correct rear wheels with gold rim rings and plausible black suspension.
- [ ] Small centered front wheel as seen in reference.
- [ ] Concentric gold/steel rear jet with emissive amber core.
- [ ] Nose and side amber lamps, rear rectangular red lamp.
- [ ] Distinct meshes for key editable and potentially animated parts.
- [ ] Correct GLB scale/orientation, valid materials, no missing faces or broken UVs.
- [ ] No extra wings, weapons, exhaust flames, driver, logos or text not in references.

**Deliverable:** `golden_rocket_racer.glb`, optionally accompanying editable `.blend` and preview renders from front/rear/left/right/top/three-quarter angles. If actual geometry creation is not available, report that limitation explicitly; do not substitute an image render for the GLB.
