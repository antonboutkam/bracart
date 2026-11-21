# RAVI — 3D-stijlbeschrijving en GLB-specificatie

**Project:** BoRacer  
**Asset:** speelbaar personage Ravi  
**Beoogde uitvoer:** `ravi.glb` (glTF 2.0 / GLB, importeerbaar in Godot 4)  
**Primaire beeldreferentie:** `character-sheet(3).png` — het originele character sheet met vijf aanzichten, detailpanelen, gezichtsuitdrukkingen, kleurenpalet en silhouetten.  
**Secundaire beeldreferentie:** `ravi.png` — speelse poses, acties, gezichtsuitdrukkingen en gebruik in de kart.

> **BELANGRIJK — visuele bron van waarheid:** Het *originele character sheet* bepaalt Ravi's definitieve uiterlijk en kleding: **groene hoofdband met rood-oranje veer en groene blaadjes, groene avonturiersbodywarmer over een crèmekleurig shirt met opgerolde mouwen, oranjegroene rugzak, donkerblauwe opgerolde broek, donkere vingerloze handschoenen en groen-oranje-witte sneakers**. Het actieblad toont een **andere outfit** (groene pluizige bodywarmer, witte top, grijze veer, andere schoenen). **Meng deze kostuums niet.** Gebruik het actieblad alleen voor poses, gezichtsuitdrukkingen en karakter; behandel de afwijkende kleding hoogstens als een *afzonderlijke optionele skin* voor een latere opdracht.

## 1. Karakter en algemene stijl

Ravi is een **vrolijke, onbevreesde, nieuwsgierige jonge avonturier**, die eruitziet alsof hij elk moment op ontdekkingstocht kan gaan. Hij heeft een ondeugende, energieke uitstraling. Zijn karakter straalt speelsheid en optimisme uit, met een lichte 'jonge ontdekkingsreiziger'- of 'junior scout'-esthetiek. In BoRacer vormt hij een visueel contrast met Boaz: **Ravi is de avonturier in groen, oranje en denim; Boaz is de ridder in blauw, rood en goud.**

De vormtaal is die van een hoogwaardige animatie-/gameproductie: **zachte afgeronde vormen, levendige kleuren, sterk leesbare silhouetten en een rijke maar overzichtelijke afwerking**. Houd de stof, het leer en de schoenmaterialen overtuigend gestileerd. Het resultaat moet in realtime mooi werken, niet fotorealistisch of hoekig low-poly zijn.

**Ontwerptrefwoorden:** avontuurlijk, vrolijk, nieuwsgierig, ondeugend, jeugdig, onbevreesd, vriendelijk, energiek, speels, kleurrijk, handgemaakt, game-ready.

## 2. Silhouet en lichaamsverhoudingen

- **Totale schaal:** circa **1,15 meter**, zoals vermeld op het referentieblad; voeten op de grond.
- **Bouw:** relatief groot bol/rond kinderhoofd, korte romp, korte stevige ledematen en enigszins grote schoenen; ongeveer **3,5–4 hoofden hoog** als visuele richtlijn, ondergeschikt aan de getekende verhoudingen.
- **Neutrale modelleerhouding:** symmetrische **A-pose**, ontspannen open vingers, armen iets van de romp, voeten plat en ongeveer op schouderbreedte.
- **Kenmerkende vorm:** warrige goudblonde haarplukken die boven de groene hoofdband uitsteken, herkenbare opvallende veer en blaadjes aan één zijkant, compacte bodywarmer, rugzak met ronde hoeken, enigszins wijde spijkerbroek en dikke sportschoenen.
- Het personage moet zonder textures herkenbaar blijven aan **haar, hoofdband/veer, rugzak en sneakers**.
- Gebruik de voor-, zij- en achteraanzichten om de omtrek consistent te reconstrueren. De afbeeldingen zijn **geen gegarandeerd geometrisch exacte orthografische projecties**: los kleine inconsistenties coherent op zonder het ontwerp te veranderen.

## 3. Gezicht en haar

- **Gezicht:** zeer zachte ronde wangen, subtiele blos, kleine neus, korte kin, grote kinderlijke glimlach en licht uitstekende ronde oren.
- **Ogen:** **grote warmbruine/donkerhazelkleurige irissen**, helder met subtiele lichtreflecties. Het primaire character sheet heeft bruine ogen; kies **geen blauwe ogen** uit het alternatieve actieblad.
- **Wenkbrauwen:** goudblond tot lichtbruin, expressief; afzonderlijk te animeren.
- **Huid:** warme perzikkleurige tint met zacht kleurverloop; geen realistische poriën of harde contouren.
- **Haar:** dik, warrig **goudblond**, met veel overlappende, zorgvuldig gemodelleerde plukken die rond de kruin en pony omhoog krullen. Houd een zacht sculpted-3D-uiterlijk; geen vlakke haarhelm of losse fotorealistische haren.
- **Basismimiek:** ontspannen open glimlach; de mesh moet ook neutraal, boos, verdrietig en geschrokken overtuigend kunnen zijn.

## 4. Kleding en accessoires — originele referentie is bepalend

### Hoofdband en versiering — zeer belangrijk

Een brede **diepgroene stoffen hoofdband** die horizontaal rond het hoofd over/onder een deel van het haar loopt. Aan één zijkant is een karakteristieke combinatie bevestigd van **een rood-oranje veer en een paar groene bladvormen**, met een klein rond lichtkleurig bevestigingsembleem. Bij het achterhoofd lopen de stofuiteinden of groene bladeren zichtbaar weg. De pluim en bladeren moeten ook vanaf achteren en in zijaanzicht zichtbaar zijn. De vorm is een essentieel silhouetkenmerk.

**Niet vervangen door een grijze/witte veer uit de actieposes.** Houd plaats, formaat en helling aan zoals op het primaire blad.

### Shirt en bodywarmer

Onder de bodywarmer draagt Ravi een **crèmekleurig/lichtbeige shirt** met **lange mouwen die tot ongeveer de ellebogen zijn opgerold**. De stof heeft zachte plooien. Bovenin kan een eenvoudige halsopening/rits zichtbaar zijn zoals op de referentie.

Daarover zit een **groene utility-bodywarmer / avonturiersvest** met olijfgroene en warme lichtgroene panelen, meerdere kleine borstzakken, oranje details, zichtbare naden, patches en straps. De voorzijde draagt kleine grafische motieven (bijvoorbeeld een goudkleurig blad-/klaver-/natuurmotief); ze hoeven niet als vrij zwevende geometrie te worden uitgevoerd. De vestsluiting, kraag en zakken moeten duidelijk los leesbaar zijn van het shirt.

**Geen pluizig bontvest als standaardkostuum.** Dat hoort bij het alternatieve ontwerp in het actieblad.

### Rugzak — zeer belangrijk

Een compacte, rechthoekig afgeronde **oranjebruine rugzak** met groene vakken en oranje/groene accentvlakken. Hij hangt tegen de bovenrug en is met **twee zichtbare schouderbanden** bevestigd. De voorzijde van de rugzak (zichtbaar in het achteraanzicht van Ravi) heeft een duidelijke **groene klaverdecoratie**, kleine zakken, naden en een donker/oranje flap. Het detailbeeld toont ook een ander gekleurd **raketembleem op een rugzakpaneel**; neem dit waar passend als aanvullende patch op een zichtbaar vlak, zonder het klavermotief van het achteraanzicht te vervangen.

De rugzak is een apart 3D-object (niet in de romp vastgesmolten) en mag in Godot licht meebewegen met de romp. Geen starre zwevende geometrie of clipping met de armen.

### Armen en handen

Blote onderarmen onder de opgerolde crèmekleurige mouwen. **Donkerbruin/zwarte vingerloze handschoenen** met zichtbare naden, opgevulde knokkelpartijen en losse vingertoppen. Kleine groene/oranje accenten mogen alleen waar het primaire character sheet die toont. De hand moet open, grijpend en stuurbaar te riggen zijn.

### Broek en riem

**Donkerblauwe denim broek**, wat wijder rond bovenbenen/knieën, met zakken, stiknaden, subtiele patchdecoraties, lichte plooien en **opgerolde pijpen tot boven de schoenen**. Taille met een donkerbruine leren riem. Er hangen **kleine zandbruin/oranje utility-tasjes, riemlusjes of gereedschapshouders** aan de zijkanten. Maak ze in 3D herkenbaar zonder onnodig fijne losse onderdelen die tijdens animatie gaan zweven.

### Schoenen

Vrij forse **groene, oranje en gebroken-witte sneakers** met dikke lichte zolen en afgeronde neuzen. In de detailopname zie je groene panelen, warmoranje inzetstukken, witte veters/straps, een lichtgele zoolrand en kleine decoratieve badges. De schoenen moeten duidelijk modern en sportief zijn, niet middeleeuws of militair. Geen overname van de blauw-rood-witte sneakers uit het actieblad.

## 5. Kleuren en materiaalindruk

De HEX-waarden zijn **schattingen op basis van de stalen en ingekleurde aanzichten**, niet gemeten officiële palettewaarden. Houd de *kleurverdeling* belangrijker dan een exact getal.

| Materiaal / onderdeel | Kleur | HEX (indicatief) | Afwerking |
|---|---|---|---|
| Hoofdband en groen hoofdaccent | diep verzadigd groen | `#137D4D` | matte geweven stof |
| Vestpanelen en patches | blad-/olijfgroen | `#679747` | katoenen outdoor-textiel |
| Veer en warme accenten | rood-oranje | `#E54A24` | zachte veer / gekleurde details |
| Emblemen en zoolaccenten | warm geelgoud | `#F3B83E` | matdruk / rubber |
| Spijkerbroek | diep helder denimblauw | `#0868B3` | matte denim met lichte naden |
| Riem en handschoendetails | donker kastanjebruin | `#724627` | mat leer |
| Tasjes en rugzak | cognac-/oranjebruin | `#C5874F` | leer / stevig textiel |
| Huid | warm perzikbeige | `#EBC7A7` | gestileerde zachte huid |
| Shirt en lichte schoendelen | roomwit / crèmekleur | `#EFE9DD` | katoen / sneakertextiel |
| Handschoenen en kleine delen | antraciet/donkerbruin | `#292B2A` | leer of synthetisch |
| Haar | goudblond | *volg bronblad* | gestileerde sculpted haarplukken |

**PBR-richtlijn:** gebruik het standaard **metallic-roughness** materiaalmodel van glTF. Vrijwel alles is **niet-metallisch** (`metallic = 0`), behalve kleine metalen onderdelen zoals ritsen, gespen en studs. Het vest en shirt zijn mat, denim is ruw en enigszins geweven, leer heeft een zachte glans, rubber is mat en de huid zacht gestileerd. Geen natte plastic glans, hyperrealistische slijtage of fototexturen.

## 6. Meshopbouw en modulaire onderdelen

Modelleer logisch gescheiden of afzonderlijk identificeerbare onderdelen:

1. `Body_Head` — hoofd, oren, neus, gezicht en hals
2. `Eyes` — oogbollen, irissen, pupillen, oogleden
3. `Hair` — sculpted blonde haarplukken
4. `Headband` — brede groene stoffen band en strik-/banduiteinden
5. `Feather_Leaves` — rood-oranje veer, groene bladeren en bevestiging
6. `Shirt` — crèmekleurige romp, mouwen en kraag
7. `ExplorerVest` — groene utility-bodywarmer, panelen, zakken en patches
8. `Backpack` — oranjegroene rugzak en aparte schouderbanden
9. `Arms_Hands` — zichtbare armen en handen
10. `FingerlessGloves_L_R` — vingerloze handschoenen
11. `Belt_Pouches` — riem, lussen en hangende utility-tasjes
12. `Jeans_Legs` — blauwe broek, zichtbare benen en omslagen
13. `Sneakers_L_R` — groen-oranje-witte schoenen

Vermijd interne dubbele oppervlakken, onverklaarbare losse meshdeeltjes, destructieve overlap tussen vest en shirt of schouderbanden die niet fysiek aan de rugzak verbonden zijn. Maak ornamenten herkenbaar met textuur, beperkte reliëfgeometrie of decals; ze hoeven niet volledig driedimensionaal te zijn als dat triangles bespaart.

## 7. Rigging en animatie

- Voeg een **humanoid skeleton** toe met heup, romp, nek, hoofd, armen, handen, benen en voeten; vingers als de pipeline dat toelaat.
- Zorg dat Ravi zowel **kan rennen, springen, juichen, dansen, vallen, zwaaien als in een kart kan zitten en het stuur kan vastpakken**.
- Geef de handen een goede grijp-/stuurpose: vingerloze handschoenen mogen de vingertoppen niet onbruikbaar maken.
- **Rugzak:** volg de romp; schouderbanden mogen niet door schouders of armen clippen. Kleine ornamenten/tasjes kunnen optioneel secundaire beweging krijgen.
- **Veer, bladversiering en haar:** optioneel extra bones voor subtiele beweging; zorg dat de hoofdband bij hoofdanimaties stevig blijft zitten.
- Richt de gezichtsexpressies op de twaalf voorbeelden uit de referentie: `neutral`, `happy`, `laugh`, `surprised`, `angry`, `sad`, `confident`, `cheeky`, `playful`, `cheer`, `celebrate`, `nervous`. Maak waar mogelijk blendshapes en bruikbare basiscontrollers voor `blink`, `wink_left`, `wink_right`, `mouth_open`, `smile`, `frown`, `brows_up` en `brows_down`. Gebruik niet elke expressienaam als verplichte één-op-één blendshape; combinaties zijn toegestaan.
- Vermijd slechte vervormingen bij ellebogen, knieën, heupen, schouders en mond.
- **Basismodel:** A-pose. Voertuigpose, sprong en emotes zijn afzonderlijke animaties; geen permanente gebogen benen in het basismodel.

## 8. Technische GLB-uitvoereisen (Godot 4)

- **Bestand:** één `ravi.glb`, met alle benodigde PBR-materialen en textures ingebed.
- **Eenheden:** meters; **zichtbare hoogte circa `1.15`** bij schaal `(1,1,1)`.
- **Oriëntatie:** +Y omhoog; voeten op het grondvlak `Y=0`; documenteer de forward-as en controleer deze in Godot (bij voorkeur richting `-Z` in de Godot-scène).
- **Topologie:** animatievriendelijke vervormingsloops; geen losse defecte normals, niet-manifold problemen op zichtbare mesh of overbodige zeer hoge dichtheid.
- **UV:** bruikbare UV-unwrapping; unieke detailgraphics behouden; geen ongewenste overlap.
- **Materialen:** glTF 2.0 metallic-roughness; geen Blender-only procedural shadernodes die bij export verloren gaan.
- **Textures:** meestal `1024×1024` of `2048×2048` per atlas-/materiaalset, te kiezen naar platform en camerafstand; deel atlas waar zinvol.
- **Indicatieve performance:** **12.000–25.000 triangles** voor de hoofd-LOD; aanpassen aan doelhardware en schermgrootte. Besteed detailbudget eerst aan gezicht/haar/hoofdband, daarna vest/rugzak en schoenen.
- **Skinning:** voor brede compatibiliteit liefst maximaal vier botgewichten per vertex, zonder zichtbare vervormingsfouten.
- **Importtesten:** model laadt in Godot 4 zonder ontbrekende textures; goed georiënteerd, correct geschaald, bruikbare armature en animatie-/gezichtscontrollers waar aanwezig.
- **Niet in GLB opnemen:** voertuig, rode racevlag, beker, munt, podium, omgeving, tekstlabels, de 2D-sheet of een tweede kostuumvariant. De kart is een afzonderlijk gameobject.

## 9. Bronhiërarchie en samenhang met Boaz

**Rangorde bij conflicten:**

1. **Detailpanelen van `character-sheet(3).png`** — doorslaggevend voor gezicht, hoofdband, vest, rugzak, handschoenen en schoenen.
2. **Vooraanzicht** — verhouding, silhouettelementen en kleuropbouw.
3. **Zij- en achteraanzicht** — diepte, rugzak, hoofdband/veer en constructie van de broek.
4. **Expressierij** — gezichtsvariaties, onderliggende facial rig.
5. **Kleurenpalet** — globale kleurkeuze.
6. **`ravi.png`** — energie, gebaren, bewegingen en kartgedrag; **geen bron voor het standaardkostuum of oogkleur**.

**Onderlinge consistentie met Boaz:**

- Beide kinderen hebben **dezelfde beoogde gameschaal (ca. 1,15 m), dezelfde gestileerde rendering, vergelijkbare gezichts- en lichaamsproporties en compatibele rig-namen**.
- Gebruik zo veel mogelijk **dezelfde skeletonstructuur, basisanimaties en Godot-materiaalinstellingen**, zodat animaties kunnen worden gedeeld of geretarget.
- Laat hun identiteiten wel nadrukkelijk verschillen: Boaz is een blauwe ridder met rode cape; Ravi is een groene explorer met hoofdband, veer en rugzak.
- Leg gezichtsvorm, haarsilhouet en gelaatstrekken per personage vast; maak geen identieke hoofden met alleen andere kleding.

**Niet doen:** grijze veer toevoegen, groen bontvest uit de actieposes overnemen, shirt vervangen door een witte mouwloze top, ogen blauw maken, rugzak weglaten, sneakers wit-rood-blauw maken, outdoorvest in ridderharnas veranderen, decoratieve raceauto meeleveren, of door automatisering de identiteit van Ravi en Boaz laten samenvloeien.

## 10. Copy-paste prompt voor 3D-generator / modelleeragent (EN)

```text
Create a faithful, game-ready, riggable stylized 3D child character named RAVI for the Godot 4 kart-racing game BoRacer. Use the attached original RAVI CHARACTER SHEET (front, side, back, 3/4 views and detail panels) as the SINGLE VISUAL SOURCE OF TRUTH for costume, colors, face and silhouette. Use the separate RAVI ACTION POSE SHEET only for personality, expressions, animation references and kart poses.

CRITICAL: The two reference images depict DIFFERENT CLOTHING VARIANTS. DO NOT merge the costumes. The canonical game model must match the detailed character sheet, NOT the furry-vest action sheet.

CHARACTER: Ravi is a cheerful, energetic, mischievous young explorer boy. He has a large rounded childlike head, soft rosy cheeks, a small nose, visible rounded ears, large warm BROWN/HAZEL eyes (NOT blue), an expressive friendly smile and thick, tousled GOLDEN-BLOND sculpted hair made of layered curved hair clumps. Stylized animated-film/game proportions: approximately 3.5–4 heads tall, compact body, short sturdy limbs, oversized shoes. Target visual height approximately 1.15 meters.

HEAD ACCESSORY: A wide DEEP-GREEN cloth headband crossing the forehead, with a highly recognizable RED-ORANGE FEATHER, GREEN LEAVES and a small round ornament attached on one side. Retain the distinctive rear band/leaf shapes. Do NOT replace the feather with the gray feather from the action poses.

OUTFIT: A CREAM/LIGHT-BEIGE long-sleeved shirt with sleeves rolled to the elbows, worn underneath a GREEN/OLIVE utility explorer VEST with multiple pockets, orange trim, sewn patches, green panels and visible seams. Add a compact ORANGE-AND-GREEN BACKPACK with two real shoulder straps, small pouches, a GREEN CLOVER symbol on the rear-facing main panel, and a small rocket-themed patch where consistent with the detail image. His forearms are exposed; he wears DARK FINGERLESS GLOVES. Add DARK-BLUE loose-fitting DENIM JEANS with pockets, stitched details and ROLLED-UP CUFFS, a brown leather belt and small TAN/ORANGE utility pouches. His shoes are chunky modern GREEN, ORANGE and OFF-WHITE SNEAKERS with pale thick soles, layered panels and sporty details.

IMPORTANT NEGATIVES: Do NOT use a fuzzy green vest, white sleeveless undershirt, gray/white feather, blue-red-white sneakers or blue eyes from the secondary action sheet. Do NOT remove his backpack. Do NOT use knight armor, cape, gold lion heraldry, adult anatomy, photorealistic skin, or angular blocky low-poly geometry.

STYLE: Premium, clean, playful, high-end stylized 3D game art with soft rounded shapes, warm facial shading, layered hair clumps, bright readable colors, subtle hand-crafted details and stylized metallic-roughness PBR materials. Mostly matte fabrics and denim; soft leather and rubber; minimal metal for small buckles/zips. Preserve the reference character's identity when viewed in front, side, rear and three-quarter views.

CONSTRUCTION: Model the entire full-body character in a neutral symmetrical A-pose with open hands, arms away from torso, relaxed fingers and feet grounded. Organize head, eyes, hair, headband, feather/leaves, shirt, explorer vest, backpack/straps, arms/hands, gloves, belt/pouches, jeans, and each sneaker as clean logical mesh groups. Create proper UVs and correct texture assignments. Keep the clover emblem, orange/green backpack, vest pocket patches and sneaker color blocking readable. Where orthographic drawings are inconsistent, resolve conservatively and maintain a coherent 3D object without redesigning visible parts.

RIGGING: Include a humanoid skeleton compatible with idle, running, jumping, dancing, cheering, falling and seated kart-driving/steering animations. Avoid clipping of backpack straps, gloves and utility pouches. Optional minor bones for feather/leaves and hanging accessories. If available, implement facial expression blendshapes or equivalent controllers supporting smiling, laughing, surprised, angry, sad, cheeky, celebrating, blinking and winking.

DELIVERABLE: A single Godot 4-compatible ravi.glb containing the full character, rig, embedded PBR textures and materials. Approximately 1.15 m tall with feet at Y=0, consistent forward orientation, and import scale 1. Keep the kart/vehicle, trophy, coins, flags, environments and costume variants OUT of this GLB.

PRIORITY ORDER: Canonical character-sheet identity > reference detail fidelity > animation-ready topology > performance > creative embellishment. Invent only the minimum needed for unseen 3D construction. Do not change Ravi's eye color, green headband, red-orange feather/leaves, green utility vest, orange-green backpack, rolled denim jeans or green-orange-white sneakers.
```

## 11. Acceptatiecheck voor het gemaakte GLB

- [ ] Ravi is onmiddellijk herkenbaar als het kind op het **originele** character sheet.
- [ ] Warrig goudblond haar, warmbruine ogen en vrolijk kinderlijk gezicht.
- [ ] **Groene hoofdband met rood-oranje veer en groene blaadjes**.
- [ ] Crèmekleurig shirt met opgerolde mouwen onder **groene utility-bodywarmer**.
- [ ] **Oranjegroene rugzak** met schouderbanden en groene klaverdecoratie.
- [ ] Donkere **vingerloze handschoenen** en kleine riemtasjes.
- [ ] Donkerblauwe **denim broek met opgerolde pijpen**.
- [ ] **Groen-oranje-witte sneakers**, geen alternatief sportschoenontwerp.
- [ ] Géén bontvest, grijze veer of alternatieve actieblad-outfit in het canonieke model.
- [ ] Rugzak en headband blijven vanuit front, zijde en achteraanzicht consistent.
- [ ] Schone UVs, correct materiaalgebruik, rig en indien mogelijk facial blendshapes.
- [ ] Correcte hoogte/oriëntatie en succesvolle GLB-import in Godot 4.
- [ ] Compatibele rig-/schaalkeuzes met het Boaz-model voor BoRacer.
