# Straatbeeld — aangeleverde fotoreferenties

Ruben van Dalen GD-015; GAME-10001, 17 oktober 2026.
Alleen de directe jpg/jpeg/webp-bestanden in `assets/straatbeeld/haarlem/` en
`assets/straatbeeld/uithoorn/` bekeken: 9 Haarlembeelden en 13 Uithoornbeelden,
als twee contactbladen via werkelijke beeldinspectie. Google-zoekpagina's en
`_files`-mappen zijn niet als bron gebruikt. Foto's dienen uitsluitend als
vorm-/kleurreferentie; ze zijn niet gekopieerd naar game-textures. Herkomst en
rechten van deze klantbeelden zijn niet vastgesteld; er wordt niets gepubliceerd
als een vrij herbruikbare foto. De bestaande CC0-fototexturen blijven gebruikt.

## Wat zichtbaar is en hoe het is vertaald

| Lokale foto | Zichtbare observatie | Uitwerking |
|---|---|---|
| Haarlem `images.jpeg`, `images (1).jpeg` | Aaneengesloten, smalle gevelwand; herhaalde hoge ramen; verschillende dakranden | Smalle huizen van 5,4m breed op ca5,65m ritme langs beide straatzijden, witte kozijnen |
| Haarlem `fb5df39be12d61739295cc33d395975a.jpg`, `WhatsApp-Image-2025-07-04-at-13.37.47-1.jpeg` | Historische straat-/pleinbeelden met winkelplinten en wisselende gevelhoogte | Baksteenvariatie, hogere plint, winkelruit en luifel-/boeibordaccenten |
| Haarlem `images (4).jpeg` | Trap- en puntgevel naast elkaar, donkere baksteen en witte horizontale lijsten | Afwisselend getrapte gevel, rechte lijstgevel en puntgevel; gesloten kap behouden |
| Haarlem `images (2).jpeg`, `images (3).jpeg` | Hoog raamritme, lichte omlijstingen, winkelpuien op de begane grond | Drie mogelijke raamlagen, stenen plint en omlijste winkel-/entreezone |
| Haarlem `Haarlem-Hofje.webp`, `images (5).jpeg` | Lage geschakelde gevels, korte stoepen, plantenbakken/groen in smalle voetgangersruimte | Stoepen, plantenbakken en groenaccenten tussen gevelritme; geen reconstructie van een specifiek hofje |
| Uithoorn `id_833279_981751995876_thumb.jpg`, `images (3).jpeg` | Roodbruine grondgebonden rijwoningen; donkere pannen; witte raam-/deurkozijnen, voortuintjes | Rijtjes op grondniveau met fotografische rode baksteen, donkere kap, witte kozijnen, hagen en tuinpad |
| Uithoorn `Amstel-Makelaardij-ogAmstelveenAmsterdam-4661-1.jpg`, `images (2).jpeg`, `images (6).jpeg` | Dakkapellen, schuine pannendaken, laag dorpslint en straatplint | Gesloten dakkapel op voorste dakhelft en compact woningritme |
| Uithoorn `images.jpeg`, `hetspoorhuis.jpg` | Herkenbare lichte hoge kopgevel met ornamentvorm, lage roodgedekte baksteenvleugel | Vrij geïnterpreteerd Het Spoorhuis: lichte puntgevel, donkere ramen en lagere vleugel, naamplaat |
| Uithoorn `Spoorbrugoveramstel.jpg` | Lage staalvakwerkbrug boven breed water | Bestaand water/brugmotief behouden; spoor/tram is Sems afzonderlijke module |
| Uithoorn `images (7).jpeg` | Moderne lage tram onder bovenleiding | Visuele afstemming met Sems grondtram; geen verzonnen historische claim |
| Uithoorn `images (1).jpeg`, `images (4).jpeg`, `images (5).jpeg`, `Amstelplein-1.jpg` | Afwisseling winkelstraat, horeca, smalle oude gevel en moderner winkelplein | Dorpsschaal en gemengd gevelritme als richting; geen exacte kopieën van winkelmerken |

De beelden zijn van uiteenlopende tijden. Moderne foto's zijn geen bewijs van
Haarlem in 1888; ook het sepia-beeld met circa1900 in de afbeelding is geen exacte
1888-bron. Uithoorn2056 blijft een vrije toekomstinterpretatie met grondgebonden
woningen en verhoogd raceparcours, geen voorspelling of stadsplattegrond.

## Implementatie en bewijsgrens

`street_districts.gd` vervangt de eerdere 48 verspreide grote huizen per wereld
met een instanced straat-/wijklaag. Eén MultiMesh per combinatie van materiaal
vorm en kleur bundelt duizenden onderdelen in circa20drawnodes per wereld.
De gesloten kap is dezelfde gecontroleerde prismageometrie als `architecture.gd`.
Alleen Haarlem en Uithoorn krijgen deze laag; overige werelden blijven gelijk.

Haarlem volgt de bestaande racehoogte met gemetselde funderingen naar het oude
terrein. Dat blijft een gestileerde verhoogde stad, geen aardrijkskundige kopie.
Uithoornwoningen staan op y=-21,8, ook daadwerkelijk onder het verhoogde parcours.
Oude kerk-/aanleg-/tuindecors zijn naar grond/water verplaatst. Sem verhoogde de
Uithoornroute16m en levert de pauzeerbare grondtram op de oostelijke oever; de
wijk houdt haar afstand van diens elliptische spoorcorridor.

De dakkapel staat op de voorste dakhelft, met de achterzijde in het dakvolume.
De bovenkant ligt over de gehele diepte boven het dakvlak; zo snijdt het
hoofddak niet door de bovenzijde van de dakkapel. Het huis- en kapvolume blijven
gesloten achter de dakkapel. Voor raamneggen blijft dit visueel reliëf, geen
werkelijk interieur.

Gerichte geometrie-/corridorcontroles: `tests/street_districts.gd` en
`tests/architecture.gd`; logs in `validation/street-district-checks.txt` en
`validation/architecture-checks.txt`. Onafhankelijke Eva-review is afzonderlijk.
Native X11 blijft geblokkeerd. Geen echte enginebeelden gemaakt of visuele
kwaliteit bewezen: straatwandcompositie, materiaalschaal, schaduwen, dakkapellen,
landmarkherkenning en kijkgevoel vanuit racercamera vragen nog beeldreview.
