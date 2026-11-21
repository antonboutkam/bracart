# BoRacer — vijf opeenvolgende Codex-opdrachten voor Boaz en Ravi

Dit document is opgesteld na inspectie van `build_characters.py`, `refine_first_pass.py`, `render_characters.py`, `make_overviews.py`, `validate_glb.py` en `check_blender_import.py`.

## Overdracht — actuele stand op 17 oktober 2026

**Stap 1, 2 en 3 zijn uitgevoerd voor zowel Boaz als Ravi en staan ook in de game. Stap 3 wacht op visuele klantbeoordeling.** Voer deze opdrachten niet opnieuw vanaf de oorspronkelijke modellen uit. De oorspronkelijke opdrachten hieronder blijven als ontwerpafspraken en geschiedenis bewaard.

| Stap | Boaz | Ravi | Nog te doen |
| --- | --- | --- | --- |
| 1 — Anatomie en gezicht | Uitgevoerd; visueel goedgekeurd door gebruiker | Uitgevoerd met eigen karakterparameters; gebruiker vroeg direct aansluitend stap 2 | Alleen gerichte correcties als de gebruiker daarom vraagt |
| 2 — Sculpturaal haar | Uitgevoerd, gecontroleerd en geïntegreerd | Uitgevoerd, gecontroleerd en geïntegreerd | Visuele beoordeling vóór de volgende fase |
| 3 — Kleding en accessoires | Uitgevoerd en geïmporteerd | Uitgevoerd met eigen outfit en geïmporteerd | Visuele beoordeling; LOD en knienaad blijven aandachtspunten |
| 4 — UV's en PBR-textures | Open | Open | Na de kledingfase |
| 5 — Expressies, skinning en animaties | Open | Open | Na de materiaal-/UV-fase |

De gebruiker keurde Boaz stap 1 goed en gaf expliciet opdracht Ravi stap 1 en direct stap 2 uit te voeren. Daarom zijn die stappen in dezelfde ronde voor beide personages gedaan. **Een expliciete visuele goedkeuring van het eindresultaat van stap 2 is nog niet vastgelegd.** De klant gaf vervolgens expliciet opdracht vanaf stap 3 verder te werken. Stap 3 is daarom uitgevoerd; stap 4/5 wachten op de bestaande visuele fasegate.

### Wat is veranderd

- **Anatomie/gezicht:** doorlopend gevormde wangen en kin, kleinere dieper liggende bruine ogen zonder dikke roze randen, subtielere neus en bredere glimlach. `ANATOMY` en `child_face()` in de generator bevatten eigen Boaz/Ravi-parameters; kostuumidentiteiten zijn behouden.
- **Haar:** nieuwe module `persons/tools/character_hair.py`, aangeroepen vanuit `make_head()`. Per personage een gesloten ondermassa en 25 brede asymmetrische lokken, met eigen pony. De oude regelmatige buisjesrijen worden niet meer gebruikt. Alle nieuwe haargeometrie is aan `head` gewogen. Het Boaz-hoogteanker blijft exact 1,125 m in de modelleerruimte zodat de overige anatomie niet herschaalt.
- **Game-integratie:** beide huidige GLB's zijn gekopieerd naar `game/assets/models/`. `game/assets/manifest.json` verwijst nu naar bevroren stap-3-snapshots en bevat de bijbehorende SHA-256. Het stoelanker in `game/scripts/kart.gd` gebruikt nu de werkelijke `hips`-restpositie in plaats van een vaste hoogte van 0,44 m.

### Bronnen en reviewbestanden

Permanente modelleerbron: `persons/tools/build_characters.py` en `persons/tools/character_hair.py`, met `character_clothes.py` voor stap 3. Lees ook [de lokale characterskill](../persons/skills/boracer-characters/SKILL.md) en per personage de originele `character-sheet.png` en stijlbeschrijving. Actiebladen blijven secundaire posebronnen; meng de afwijkende outfits niet.

| Dossier | Boaz | Ravi |
| --- | --- | --- |
| Stap 1 | [Verslag](../persons/boaz/STEP1-REVIEW.md) | [Verslag](../persons/ravi/STEP1-REVIEW.md) |
| Stap 2 | [Verslag](../persons/boaz/STEP2-REVIEW.md) | [Verslag](../persons/ravi/STEP2-REVIEW.md) |
| Haar voor/na, gezicht | [Vergelijking](../persons/boaz/review-step2/05-face-comparison.jpg) | [Vergelijking](../persons/ravi/review-step2/05-face-comparison.jpg) |
| Haar voor/na, achterzijde | [Vergelijking](../persons/boaz/review-step2/04-back-comparison.jpg) | [Vergelijking](../persons/ravi/review-step2/04-back-comparison.jpg) |
| Werkelijke Godot-beelden | `persons/boaz/review-step2/godot/` | `persons/ravi/review-step2/godot/` |

Ook voor-, driekwart-, zij- en kartzitvergelijkingen staan in `review-step2/`. Voor/na tonen echte opgeslagen meshes bij dezelfde camera en belichting. De actuele `.blend`, `.glb`, zes renders en validatierapporten staan onder `persons/<naam>/`.

### Uitgevoerde controles en grenzen

- GLB-structuurcontrole en fresh Blender-import slagen voor beide modellen: 51 bones/joints, zes bestaande clips, 20 neutrale morph targets, twee ingebedde textures en circa 1,15 m hoogte met voeten op Y=0.
- Beide exports zijn werkelijk in Godot geïmporteerd: **75/75 controles per personage**, inclusief afspelen van `Kart_Sit`. Rapporten: `persons/<naam>/godot-step2-validation.json`. Native voor-, driekwart-, achter-, volledig en zitbeelden zijn bekeken. Dit is geen volledige clipvrije animatie- of gameplayverklaring.
- De onafhankelijke haar-scopecontrole bevestigt bij Boaz exact behoud van alle 33.886 niet-haartriangles, rig, animaties en textures. Bij Ravi matchen alle 31.006 niet-haartriangles numeriek; op handschoenpatches zijn minimale exportfloatverschillen gemeten: maximaal 1,86 nanometer in positie en 0,00003785 per normalcomponent. Zijn strikte hashcontrole blijft zichtbaar afgekeurd; de aanvullende gemeten tolerantietest slaagt. UV's, gewichten, morphs, rig en animaties zijn behouden. Zie `review-step2/scope-audit.json`, bij Ravi ook `float-drift-audit.json`.
- Nieuw haar: 26 gesloten componenten per personage; geen open randen, degeneraties of foute head-gewichten gevonden. Topologiecontrole bewijst geen afwezigheid van alle doorsnijdingen.
- Gerichte gamecontroles slagen: **888** voertuig/coureurcontroles, **56** garagecontroles en **415.480** cameracompositiesamples. De cameracontrole draaide na de anatomie-update; de haarvergelijking bevestigt behoud van de lichaamsvorm/bounds. Na integratie van het haar zijn voertuig- en garagecontroles herhaald. [Testuitvoer](../game/validation/character-step2-checks.txt), [assetcontrole](../game/validation/character-assets.json).
- GLB-triangles: Boaz oorspronkelijk **33.306**, na stap 1 **41.782**, na stap 2 **40.524**. Ravi oorspronkelijk **30.417**, na stap 1 **38.902**, na stap 2 **37.644**. Beide overschrijden de richtwaarde van 25.000; optimalisatie/LOD is nog open. Gebruik GLB-counts: Blender-evaluatie kan bij Ravi acht triangles lager uitvallen door exporttriangulatie.
- Nog open: unieke UV/PBR-atlas, ruisarme presentatierenders, echt verschillende expressies en animatieverfijning. De bestaande renders gebruiken 16 samples zonder denoising; het haar is minder repetitief maar nog vrij rond/verzorgd. Dunne uitstekende naden bij Ravi's gebogen jeansknieën zijn bekend en horen bij de latere kleding-/skinningfase. De eerdere gamebenchmark is niet opnieuw uitgevoerd na de personage-update.

### Backups en reproduceerbaar vervolg

- Oorspronkelijke Boaz en tools: `persons/backups/2026-10-17-step1/`.
- Oorspronkelijke Ravi en tools: `persons/backups/2026-10-17-ravi-step1/`.
- Goedgekeurde Boaz stap 1: `persons/backups/2026-10-17-step2/boaz/`.
- Ravi stap 1: `persons/ravi/review-step1/after/`.
- Generator na beide anatomiestappen, vóór haarwijzigingen: `persons/backups/2026-10-17-step2/build_characters-before-hair.py`.
- Stap-2-broncode: `persons/backups/2026-10-17-step2/sources-after/`.
- Bevroren stap-2-GLB's: `persons/<naam>/review-step2/after/<naam>.glb`; dit zijn de bewaarde baselines; de huidige manifestbronnen staan in `review-step3/after/`.

De huidige generator bouwt **stap 3**. Complete stap-2-baselines en code staan in
`persons/backups/2026-10-17-step3/`; stap-3-snapshots in `persons/<naam>/review-step3/after/`.
De nieuwe `check_character_clothes_scope.py` controleert behoud van hoofd, haar,
huid, rig, animaties en textures: beide 9/9, inclusief exact behouden posities.

Actuele stap-3-review: [centrale Blenderbeelden](../renders/GAME-10001/blender-stap-03/index.html),
[Boaz-verslag](../persons/boaz/STEP3-REVIEW.md), [Ravi-verslag](../persons/ravi/STEP3-REVIEW.md).
Boaz heeft 65.518 triangles, Ravi 46.304; de richtwaarde 25.000 blijft overschreden.
Ravi's zijnaad bij de gebogen knie vraagt nog aandacht. De bronbladen blijven leidend.
Drie Boaz-beelden zijn uit de voorafgaande kledingbuild; hun afwijkende bronhash
staat per beeld vermeld. Geen claim dat deze opnieuw met de definitieve cape zijn gerenderd.

Godot stap 3: beide 75/75 kandidaatcontroles, voertuig888, garage56 en
followcamera1464 zonder fouten na integratie. Bewijs: `game/validation/character-step3-checks.txt`
en `persons/<naam>/godot-step3-validation.json`. De eerdere cameracompositietest
van 415.480 samples is stap-2-bewijs en is niet opnieuw uitgevoerd voor stap 3.
Nieuwe native beelden konden niet worden gemaakt: displaysockets zijn geblokkeerd.
De centrale Blenderbeelden zijn geen Godot-gameplaybewijs. Stap 4/5 blijven open.

Draai één Blenderproces tegelijk, met bijvoorbeeld:

```bash
BORACER_FAST_EXIT=1 /snap/blender/current/blender --background -noaudio --factory-startup --threads 4 --python persons/tools/build_characters.py -- boaz ravi
python3 persons/tools/validate_glb.py persons/boaz/boaz.glb persons/ravi/ravi.glb
BORACER_FAST_EXIT=1 /snap/blender/current/blender --background -noaudio --factory-startup --threads 4 --python persons/tools/check_blender_import.py -- persons/boaz/boaz.glb persons/ravi/ravi.glb
```

Godot-kandidaatcontrole vanuit de projectroot: `godot --headless --path game --script tests/character_review.gd -- boaz` en hetzelfde met `-- ravi`. Native beelden: `godot --path game --script tests/character_review_visual.gd`. Gebruik een tijdelijke `XDG_DATA_HOME` voor gametests. `sync_assets.py` kopieert ook personages: voer dat niet blind uit tijdens een nieuwe reviewbuild. De repository bevat uitgebreide bestaande wijzigingen. Bewaar fasebackups; overschrijf of commit geen ander werk.

### Startpunt voor de volgende agent

1. Lees bovenstaande status en bekijk de stap-3-beelden; registreer visuele klantbeoordeling voordat de materiaal-/UV-fase begint.
2. Voer na fasegoedkeuring **stap 4** uit, eerst Boaz, dan Ravi; houd anatomie, haar en gecontroleerde kledinggeometrie intact.
3. Laat stap 5 open tot na de materiaal-/UV-fase. De oorspronkelijke gedetailleerde opdrachten hieronder blijven daarvoor de specificatie.

---

## Voor je begint

- Gebruik de **originele character sheets** en `boaz-stijl.md` (en later de overeenkomstige Ravi-referenties) als visuele bron van waarheid. De al gegenereerde renders zijn alleen een *technische beginsituatie*, niet het artistieke doel.
- Het huidige model is procedureel opgebouwd in `build_characters.py`. **Alle blijvende verbeteringen moeten in de generator/code komen**, niet uitsluitend in een handmatig aangepaste `.blend`.
- Houd de karakters consistent: Boaz heeft **rode cape, gouden leeuwen, bruine ogen en bruin-gouden laarzen**, niet het afwijkende blauwe-cape/sneaker-ontwerp uit de pose-sheet.
- Voer de stappen **op volgorde, één per Codex-sessie/opdracht** uit. Ga pas verder als de renders van de huidige stap goedgekeurd zijn.
- Bewaar bestaande outputs voor iedere build (bijvoorbeeld met versiebeheer en/of backups). Start elke keer met een **schone build** zodat tijdelijke `refine_first_pass.py`-bewerkingen niet dubbel op de mesh worden toegepast.
- De bestaande interface blijft geldig: `build_characters.py` accepteert `-- boaz` of `-- ravi`, levert `.blend`, `.glb`, renders en validatierapporten. Bestaande zes animatienamen en circa 1,15 m hoogte blijven intact.
- Voor de nog open stappen: werk eerst aan **Boaz** en pas de aanpak vervolgens op Ravi toe met eigen karakterparameters. Stap 1 en 2 zijn voor beiden al uitgevoerd; zie de overdracht hierboven.

---

## Stap 1/5 — Silhouet, lichaamsverhoudingen en gezicht — uitgevoerd

**Status: afgerond voor Boaz en Ravi. Onderstaande opdracht is de historische specificatie; niet opnieuw uitvoeren zonder gerichte wijzigingsopdracht.**

> Analyseer het oorspronkelijke Boaz-character sheet en de bestaande renders. Verbeter uitsluitend **lichaamsproporties en gezichtsgeometrie** in `build_characters.py` (met name `make_head`, `ringbody`, `ell`, anatomie en waar nodig de posities in `build_skeleton`, `limbs` en `outfit`). Het resultaat moet veel beter overeenkomen met het originele gestileerde kinderpersonage: compactere kinderlijke verhouding, volumineuzer hoofd ten opzichte van romp/benen, volle ronde wangen, zachtere kin, kleine subtiele neus, natuurlijke brede glimlach en relatief kleinere, dieper in het gezicht liggende warme bruine ogen. Verwijder het effect van twee bolle, opgeplakte ogen met dikke roze oogranden. Behoud oogleden, aparte irissen en expressiemogelijkheden. **Verander in deze stap niets aan haarvorm, kledingdetails, textures of animatieontwerp**, behalve minimale verplaatsingen die nodig zijn om de nieuwe anatomie correct te laten aansluiten.
>
> Maak configuratieparameters voor hoofdmaat, oogbreedte, oogdiepte, wangvolume, mondbreedte, romp-/beenlengte en een eventuele aparte Boaz/Ravi-variant. Gebruik het character sheet als visuele maatstaf; neem de illustraties niet als metrisch perfecte orthografische afbeeldingen. Totale hoogte blijft ~1,15 m; voeten blijven op grondniveau. Alle anatomische onderdelen, bones en vertex weights moeten blijven aansluiten. Verbeter desnoods de onderliggende mesh-topologie zodat zachte gezichtscontouren ontstaan; puur vergroten van bestaande ellipsoïden is niet voldoende.
>
 **Oplevering:** codewijzigingen, schone Boaz-build, `01-front.png`, `02-three-quarter.png`, `03-side.png`, `05-face.png` en een korte opsomming van geometrische wijzigingen. Voer de bestaande GLB- en Blender-importcontroles uit. Vraag expliciet om visuele goedkeuring voordat je naar een volgende fase gaat.
>
 **Acceptatie:** gezicht leest onmiddellijk als het personage uit het bronblad; geen uitpuilende 'googly eyes'; zachte kinderwangen; frontaal en driekwart kloppen; skeleton en GLB blijven bruikbaar. Geen verschuiving naar het blauwe-cape/sneaker-ontwerp.

---

## Stap 2/5 — Haar als sculpturaal volume — uitgevoerd

**Status: afgerond voor Boaz en Ravi, gecontroleerd en in de game geïntegreerd. Visuele beoordeling vóór de volgende fase blijft open. Onderstaande opdracht is de historische specificatie.**

> Verbeter **uitsluitend het haar** van Boaz in `build_characters.py`, met name `back_hair` en de haarsectie van `make_head`. Het bestaande systeem van drie regelmatige cirkelrijen met vrijwel identieke `tube()`-lokken geeft een herhalend, gevlochten/helm-achtig effect. Vervang dit door een duidelijk asymmetrisch, handgesculpteerd aandoend kapsel: grotere en kleinere overlappende clusters, verschillende diktes, richtingvariatie, natuurlijke kruin, rommelige goudblonde pony en verzorgde haargrens bij oren en voorhoofd. Het haar moet rondom een geloofwaardige massa hebben, zonder zichtbare kale gaten of repetitieve horizontale rijen. Gebruik een beperkt aantal bewust ontworpen groepen met seeded subtiele variatie; vermijd duizenden losse haren of fotorealisme.
>
 Behoud positie van oren, ogen en gezicht uit stap 1. Verander verder geen anatomie, kleding, UV-systeem, rig of animaties. Zorg dat elke haarlok gekoppeld blijft aan de head bone en niet door het gezicht of door aangrenzende plukken op een storende manier snijdt. De achterkant moet even verzorgd zijn als de voorkant. Ontwerp een generieke hair-clump-helper die later Ravi's eigen kapsel kan krijgen.
>
 **Oplevering:** codewijzigingen en renders van voor, driekwart, zij en achter én een close-up van het hoofd. Rapporteer het aantal triangles vóór/na. Controleer GLB en fresh Blender import.
>
 **Acceptatie:** één overtuigend, warrig asymmetrisch kapsel met herkenbare haarlok-richtingen, geen buisjespatroon en geen haarhelm.

---

## Stap 3/5 — Kleding, cape, accessoires en silhouetdetails — uitgevoerd; visuele beoordeling open

> Verbeter **uitsluitend de geometrie van Boaz' kostuum** in `build_characters.py`, met name `outfit`, de Boaz-tak van `limbs`, de `lion`-helper en cape-opbouw. Houd de in stap 1–2 goedgekeurde anatomie en het haar exact intact. Gebruik het originele sheet en `boaz-stijl.md` als bron: koningsblauwe riddertuniek met **duidelijke gouden heraldische leeuw**, zilverachtige bolle schouderstukken met fijne gouden accenten, bruine riem met geloofwaardige gesp/tasjes, gelaagde onderarmbeschermers, goudkleurige knieplaten, forse maar afgeronde bruine ridderlaarzen met gouden teenbescherming en een **rode cape tot ongeveer de knieën met groot gouden leeuwenembleem**. Geen sneakers en geen blauwe cape.
>
 Vermijd vlakke opgeplakte decoratie, door elkaar stekende onderdelen en platte doosvormige laarzen. Geef stofpanden en cape een zichtbare subtiele dikte en vloeiende geplooide volumes; laat metaal aanvoelen als gevormde beschermplaten en leer als meerdere lagen. Maak bij voorkeur logische submodules binnen de procedurele generator om revisie eenvoudiger te maken. Bewaak de rigging en capebones; tijdens kart-zitten mogen de cape en kleding niet fors doorsnijden. Laat bestaande texturing voorlopig met rust: deze stap gaat om **geometrische volumes en correcte vormen**, niet om textuurdetails.
>
 **Oplevering:** renders van voor, driekwart, zij, achter en kartzitpose. Een korte checklist van de herkenbare outfit-elementen. Draai GLB-validatie en Blender-importtest.
>
 **Acceptatie:** volledig karaktergetrouwe outfit met goede leesbaarheid vanuit racecamera-afstand; geen zichtbaar zwevende leeuwenornamenten; cape, riem en laarzen functioneren in rust en kartpose.

---

## Stap 4/5 — Productiegeschikte UV's en hoogwaardige PBR-textures — open

> Voer een **volledige UV- en materiaalupgrade** door in `build_characters.py`, specifiek `atlas()` en `mesh()` plus eventuele nieuwe texturebake-/UV-modules. De huidige `atlas()` maakt slechts een 8×8 raster van egale kleuren op 1024×1024. `mesh()` projecteert elk los deel in een gedeelde palettile; veel onderdelen overlappen bewust. Daardoor zijn unieke gezichtsschaduwen, kledingnaden, metalen ornamenten en slijtagedetails niet betrouwbaar schilderbaar. **Vervang dit palettile-systeem door een echte gebakene UV-atlas of logische materiaalsets met unieke UV-eilanden** voor onderdelen die plaatsgebonden details nodig hebben. Houd voldoende gutter/padding voor mipmaps en minimale vervorming; hergebruik UV-ruimte uitsluitend waar spiegelen of delen bewust gewenst is.
>
 Maak glTF/Godot-compatibele PBR-materialen (base color in sRGB, ORM/roughness/metallic in Non-Color, en waar nuttig normal map in tangent space). Mik op 2048×2048 voor primaire character-textures, met de mogelijkheid een lagere resolutie voor mobiele build te genereren. Geef huid subtiele warme kleurnuances, wangen natuurlijke zachte blos, haar 2–3 goudblonde toonlagen, tuniek subtiele stoffen weving en naden, leer zachte nerf en stiknaden, en goud/staal gecontroleerde metallic- en roughnesswaarden. Details mogen niet ogen als willekeurige ruis. Ornamenten (gouden leeuw op borst en cape) moeten scherp en leesbaar blijven. **Gebruik de kleuren en details van het originele Boaz-sheet; voorkom een herontwerp.**
>
 Zorg voor reproduceerbare automatische generatie/baking en werkende GLB-export met ingebedde textures. Houd het aantal materialen en texture-memory passend bij een game. **Pas de geometrie, animaties en anatomie uit eerdere stappen niet meer aan**, afgezien van noodzakelijke UV-seams. Verbeter ook het preview-renderen: zet denoising aan, verhoog samples (bijvoorbeeld 64–128 voor review), en gebruik consistente studioverlichting. Dat is alleen een presentatieverbetering, niet een vervanging voor de juiste shading.
>
 **Oplevering:** afzonderlijke controleafbeeldingen van alle texturemaps, een UV-layout, minimaal vooraanzicht/driekwart/close-up renders, GLB met embedded textures, materiaal-/texture-overzicht met resoluties en verificatie dat alle UV-eilanden correct zijn.
>
 **Acceptatie:** nergens kleurlekkage, zichtbare onverwachte seams, ontbrekende textures of verkeerd metallic effect; zichtbaar rijkere maar nog steeds gestileerde materialen; het GLB oogt in Godot vergelijkbaar met Blender.

---

## Stap 5/5 — Echte expressies, skinning, animaties en regressietests — open

> Verbeter nu uitsluitend **rigging, facial shape keys, animatiekwaliteit en technische validatie**. In `face_shapes()` hebben meerdere vormsleutels dezelfde vervorming: `smile/happy/cheer/celebrate`, `laugh/mouth_open`, `sad/frown` en `confident/cheeky/playful` zijn momenteel functioneel grotendeels duplicaten. Maak ten minste de kernexpressies (`neutral`, `smile`, `laugh`, `surprised`, `angry`, `sad`, `wink_left`, `wink_right`, `mouth_open`, `blink`) visueel onderscheiden en geloofwaardig. Controleer dat ogen, oogleden, wenkbrauwen, wangen en mondhoeken logisch samen bewegen. Voeg zo nodig gezichtstopologie of helperdeformatie toe, maar behoud het in stappen 1–4 goedgekeurde uiterlijk in de neutrale pose.
>
 Controleer de 51-bones-rig, vertex weights en alle bestaande animatienamen: `Idle`, `Run`, `Jump`, `Cheer`, `Kart_Sit`, `Kart_Steer`. Besteed extra aandacht aan natuurlijke knieën, ellebogen, vingers aan het stuur, billen in het zitje, cape tijdens draaien en doorprikken van pantser bij schouderbewegingen. Vervang technisch 'geslaagde' maar visueel onjuiste poses door bruikbare poses. Behoud juiste schaal, oriëntatie en in-game opstelling.
>
 Breid `validate_glb.py` en `check_blender_import.py` uit met controles op echte morphverschillen (niet alleen aantallen), niet-nul oppervlaktes, hoofdrichtingen en assetintegriteit. Test de GLB expliciet in **Godot 4**, omdat de bestaande scripts alleen Blender- en glTF-structuurtests uitvoeren. Het ontbreken van een actieve Godot-runtime moet duidelijk als niet-getest worden gerapporteerd en mag niet worden voorgesteld als een geslaagde test. Leg triangle count en eventuele performance-tradeoffs vast. Zorg dat de clean rebuild, export en renders deterministisch zijn.
>
 **Oplevering:** front/driekwart en 10 expressie-crops, statische kartpose en stuuranimatie-previews, alle zes animation clips, bijgewerkte validatierapporten, plus verslag van werkelijk uitgevoerde Godot-test (of expliciete beperking).
>
 **Acceptatie:** verschillende expressies zijn zichtbaar verschillend; geen ernstige doorsnijding/vervorming; alle zes animaties blijven bestaan; `.blend` en `.glb` openen correct; een nieuwe build reproduceert het resultaat.

---

## Observaties en resterende aandachtspunten

1. **`build_characters.py` is de bron van waarheid.** `refine_first_pass.py` voert eenmalige meshbewerkingen uit en is geen vervanging voor blijvende wijzigingen in de generator.
2. De huidige `atlas()` maakt een herhalend palet, geen unieke gedetailleerde texture. Bij de UV's wordt elk onderdeel per lokaal vlak in één kleurvakje geprojecteerd; details kunnen niet zomaar uit een rijkere afbeelding ontstaan.
3. **Opgelost in stap 2:** de regelmatig verdeelde `tube()`-haarrijen zijn vervangen door `character_hair.py` met gesloten sculpturale volumes. Het oude `back_hair()` is niet meer het actieve pad; verander de nieuwe module bij haarcorrecties.
4. **Aangepast in stap 1:** de actieve `child_face()` vormt doorlopende wangen/kin en verzonken kleinere ogen. Ogen/irissen blijven afzonderlijke onderdelen voor expressies. De oude gezichtscode is geen uitgangspunt voor het vervolg.
5. `face_shapes()` koppelt meerdere expressions aan identieke bewerkingen; check daarom visuele verscheidenheid, niet alleen de lijst morphnamen.
6. `setup_stage()` en `render_characters.py` renderen met **16 samples, denoising uit**. Dat verklaart een aanzienlijk deel van de ruis in de aangeleverde beelden.
7. `validate_glb.py` meldt bij overschrijding van 12.000–25.000 triangles alleen `triangle_target_met=false`. De actuele GLB-counts zijn **40.524 voor Boaz** en **37.644 voor Ravi**. Dit is geen absolute bovengrens, maar optimalisatie blijft nodig; structureel geslaagd betekent niet dat het budget gehaald is.
8. `check_blender_import.py` controleert import, aanwezige animaties en eindige meshcoördinaten, **niet** herkenbaarheid, expressiekwaliteit of Godot-runtime.
9. Houd Boaz en Ravi niet gelijk in gezicht, haar en outfit: deel helpers, maar gebruik expliciete karakterparameters.

## Praktisch werkproces

Na elke stap:

1. Laat Codex precies één stap uitvoeren en een **voor/na-vergelijking** renderen vanuit dezelfde camerapositie.
2. Bekijk zelf het resultaat voordat je de volgende stap geeft. Vraag om gerichte bijsturing als iets visueel niet klopt.
3. Bewaar broncode en de goedgekeurde outputs. Gebruik commits als er versiebeheer is; in deze workspace zijn lokale backups gebruikt en is geen Git-repository aanwezig.
4. Pas de goedgekeurde aanpak later op Ravi toe met diens eigen referenties en karakterparameters.

**Texture-samenwerking:** zodra stap 3 goedgekeurd is, kun je de door Codex gegenereerde nieuwe UV-layout en bake-/kleurtextures laten beoordelen en verfijnen. Zonder nieuwe UV-layout kan ik vooral de materiaalkarakteristiek per kleurvakje veranderen, geen nauwkeurig geplaatste gezichtsdetaillering of naden toevoegen.
