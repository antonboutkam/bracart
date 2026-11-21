# Haarlem 1888 en Uithoorn 2056 — landmarks en materialen

Onderzoek en implementatie door Fenne Bos (GD-011), GAME-10001, 17 oktober 2026.

## Wat nu werkelijk in de game zit

De bestaande Bavo-, Adriaan-, Thamerkerk- en bruginterpretaties blijven staan.
Geen nieuw landmarkmodel is in deze materiaalstap gebouwd. De voorstellen
hieronder zijn een onderzoeksselectie en backlog, geen gerealiseerde gebouwen.
De bestaande universele kerk is een sterk vereenvoudigde interpretatie; een
naamplaat maakt het nog geen architectonisch getrouwe reconstructie.

Wel geïmplementeerd: CC0 fotografische albedo-, OpenGL-normal- en roughnessmaps
voor Haarlemse bakstenen gevels, natuurstenen weg/kade, Uithoornse betonnen
gevels en asfaltweg. Alleen wereld 3 en 4 krijgen deze vervanging; gameplay,
weggeometrie, slagboom- en decorposities blijven behouden.

## Onderzoeksselectie Haarlem 1888

| Prioriteit | Landmark en tijdsgrens | Herkenningsvorm | Voorstel voor veilige plaatsing |
|---|---|---|---|
| 1 | Grote of Sint-Bavokerk: toren voltooid 1518–1520, dus bestaand in 1888 | Lang gotisch schip, kruisvorm, steunberen, hoge slanke vieringtoren; geen frontale kathedraal met twee torens | Doorontwikkeling huidige startanker rond 0,035 van de ronde; zijwaarts buiten de rijcorridor |
| 1 | Molen De Adriaan: in gebruik sinds 1779, dus bestaand in 1888 | Stelling, taps toelopende romp, donkere kap en vier wieken boven het Spaarne | Huidig anker rond 0,55 verbeteren met stellingring; volledige draaicirkel van wieken buiten de baan |
| 2 | Amsterdamse Poort: middeleeuwse stadspoort | Hoge centrale poort met puntdak, lagere ronde voortorentjes, rood metselwerk en lichte natuursteendetails | Als los decor bij de Gouden Straatjes; geen nauwe poortopening als verplicht rijgat |

De [kerkgeschiedenis van de Bavo](https://www.bavo.nl/over-de-bavo-en-de-nieuwe-kerk/grote-of-st-bavokerk/geschiedenis/)
onderbouwt de datering van de toren. De [eigen geschiedenis van De Adriaan](https://www.molenadriaan.nl/nl/geschiedenis/)
onderbouwt ingebruikname in 1779; de brand en latere reconstructie horen niet
bij de situatie van 1888. De [gemeentelijke ontwikkelingsvisie Spaarnesprong](https://gemeentebestuur.haarlem.nl/bestuurlijke-stukken/2017596170-2-Bijlage-1-Ontwikkelingsvisie-Spaarnesprong-ontwerp-2.pdf)
beschrijft de oorsprong en uitbreiding van de Amsterdamse Poort.

Steampunkketels, luchtschepen en werkende tandwielgevels zijn bewust fictief.
Gebruik geen hedendaagse winkelreclame of de Nieuwe Bavo als bestaand monument
uit 1888 zonder afzonderlijk tijdsonderzoek. De gekozen natuursteenbestrating
is een plausibele artistieke materiaalkeuze, geen bewijs voor de precieze
bestrating van een bepaalde Haarlemse straat in 1888.

## Onderzoeksselectie Uithoorn 2056

| Prioriteit | Werkelijk referentiepunt | Herkenningsvorm | Voorstel in de fictieve wereld |
|---|---|---|---|
| 1 | Thamerkerk | Eenvoudig neoclassicistisch kerkvolume, houten portico en klein dakklokkentorentje; vermijd gotische spitskerk | Huidig landmark rond 0,54 herontwerpen met lage portico; zonnepanelen en groen als losse toekomstlaag ernaast |
| 1 | Dorpslint, Rechthuis en Amsteloever | Watergerichte gevelrij, laag Rechthuis, kade, bomen en terras | Compacte gevelgroep achter kade; houd horizon en bochtuitzicht vrij |
| 2 | Schanskerk / Sint-Jan de Doper | Kerkensemble aan de Schans als tweede duidelijk ander silhouet | Ver uitzichtanker, geen tweede kopie van de Thamerkerk |
| 2 | Fort aan de Drecht | Laag breed fort, aarden dekking, gracht en entree | Optioneel polderranddecor met groen dak; geen hoog kasteel of toren |
| 2 | Irenebrug en herinnering aan de Lange Brug | Rivieroversteek en bruggenhoofden | Benoem exact welke brug de referentie is; modulaire bewegende racebrug is een nieuwe fictieve variant |

De [RCE-inschrijving van de Thamerkerk](https://monumentenregister.cultureelerfgoed.nl/monumenten/35861)
beschrijft het eenvoudige bedehuis met houten onderdelen. De [gemeentelijke route door het oude dorp](https://www.uithoorn.nl/Home/Sport_en_recreatie/Wandel_en_fietsroutes/Route_oude_dorp)
onderbouwt Rechthuis, Schanskerk, oeverlint en verdwenen Lange Brug, en onderscheidt
deze van de Irenebrug. Het [gemeentelijke erfgoedregister](https://www.uithoorn.nl/Home/wonen/Erfgoed_en_monumenten/Erfgoedregister)
bevestigt het fort en het kerk/pastorie-ensemble als monumenten.

2056 is een ontwerpvisie: behoud, zonnepanelen, watertaxi's, nieuwe bruggen en
verticale tuinen zijn geen gemeentelijke prognose of vastgesteld bouwplan.
De huidige codebrug is een vrije interpretatie van het ontwerpdocument en
mag niet als exacte bestaande Uithoornse brug worden gepresenteerd.

## Ingevoerde fotomaterialen

Alle vier sets zijn van Rob Tuytel via Poly Haven onder [CC0](https://polyhaven.com/license).
Downloads, auteur, afzonderlijke kanaal-URL's, bronafmetingen, downloadmoment en
SHA-256 staan in `assets/textures/worlds/photographic/sources.json`. Alle twaalf
bestanden zijn 1024 × 1024; downloadbytes zijn ook aan de API-MD5 getoetst.

| Toepassing | Fotobron | Werkelijke spelprojectie |
|---|---|---|
| Haarlemse gevels | [Red Brick](https://polyhaven.com/a/red_brick) | 0,48 herhaling/m, circa 2,08 m/tegel; zes bakstenen per tegel geven speels vergrote steenmaat |
| Haarlemse weg en kade | [Cobblestone Floor 01](https://polyhaven.com/a/cobblestone_floor_01) | 0,4 herhaling/m, 2,5 m/tegel; rustige, leesbare stenen op racesnelheid |
| Uithoornse lichte gevels/kade | [Concrete Floor 02](https://polyhaven.com/a/concrete_floor_02) | 0,5 herhaling/m, 2 m/tegel; warme lichte tint, echte poriën/slijtagesporen |
| Uithoornse weg | [Asphalt 02](https://polyhaven.com/a/asphalt_02) | 1/3 herhaling/m, 3 m/tegel; bron vermeldt eveneens 3 m |

Projectie is world-space triplanar: gelijke schaal op naastliggende bouwdelen,
geen uitgerekte box-UV's en geen verdwenen wegtextuur doordat de wegmesh nog
geen eigen UV-attribuut heeft. Deze schaalkeuzes zijn expliciete artdirection;
de API geeft voor enkele oudere assets verschillende `scale`/`dimensions`-waarden.
Daarom claimen we geen metrisch exacte reconstructie. Gevels blijven bewust
uitvergroot naast de cartoonpersonages.

Albedo gebruikt Godots sRGB-sampling; OpenGL-normalmaps worden als normalmap
geïmporteerd en roughness wordt via het rode kanaal als lineaire data gelezen.
Normals zijn bescheiden (0,45 bestrating, 0,6 gevels/asfalt), zonder geometrische
verplaatsing of invloed op wielcontact. Mipmaps en anisotropisch filteren beperken
flikkering in schuine camerahoeken. Stoom, glas, emissie, vegetatie en bestaande
zonnepanelen behouden hun eigen materiaal.

## Reproduceren en review

`python3 tools/generate_world_textures.py --verify-photo` controleert offline
alle twaalf fotomaps. Zonder deze optie blijft de bestaande procedurele generator
werken; hij overschrijft geen fotografische bronnen. Back-up van aangepast script
staat onder `validation/backups/GAME-10001/materialen/`.

QA: Godot-import, World Art-contracttests en echte spelcaptures moeten naast de
broncontrole worden bekeken. De directeur bewaart centrale staprenders; een
headless materiaaltest bewijst op zichzelf geen fraaie cameracompositie.

## Aanvullend straatbeeldvervolg

Na dit onderzoek leverde de klant22foto’s aan. Die zijn verwerkt in dichte
Haarlemgevelrijen, Uithoornwoonwijken en een vrije Spoorhuis-interpretatie;
zie [bronkaart](STRAATBEELD-BRONKAART.md). Het Uithoornparcours is16m verhoogd
en heeft een bewegende grondtram; zie [tramdocumentatie](UITHOORN-TRAM.md).
Dit is afzonderlijke implementatie en geen realisatie van alle bovenstaande voorstellen.
