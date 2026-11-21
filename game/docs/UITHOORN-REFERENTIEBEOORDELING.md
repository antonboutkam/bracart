# Uithoorn — beoordeling aangeleverde landmarkpakketten

Fenne Bos (GD-011), 18 oktober 2026. Opdracht via Milan; onafhankelijke review: Eva.

De zes pakketten zijn voldoende voor herkenbare, vrij geïnterpreteerde game-objecten en zelfstandige modellen met materialen. De bronfoto's en referentiebladen zijn daadwerkelijk visueel bekeken, inclusief de vier materiaalpanelen per pakket. Dit is een beoordeling van aangeleverde bestanden, geen nieuwe monumentenstudie of bouwkundige opmeting. Er is niets gedownload en geen bronbestand gewijzigd.

## Bronnen en modelkeuzes

| Landmark | Bekeken bronnen | Herkenbare vorm en materiaal | Grens / prioriteit |
|---|---|---|---|
| Het Rechthuis | Vijf foto's in `fotos/`, AI-sheet, aanzichten en detailpanelen | Roodbruine baksteen, groot grijs schilddak met dakkapellen, twee bouwlagen, donkere luifels, bordeauxrode/witte geometrische luiken, balkon en glazen terras aan het water | Goed gedekte straat- en waterzijde. AI-zij- en bovenaanzichten zijn interpretaties; 22 × 14 × 12 m is uitsluitend gameschatting. Geef luiken/luifels daadwerkelijk reliëf. |
| Schanskerk | Vijf items in `fotos/` en vijf grotendeels overeenkomstige `source_photos/`, AI-sheet | Lang schip, twee vierkante fronttorens met klokken en spitsen; baksteen, rondboogopeningen en donker dak | Echte foto's gaan voor de sterk neogotische AI-details. `lijnenschets.jpg` toont volgens pakket Clermont-Ferrand en wordt uitgesloten als Schanskerkbewijs. Een luchtfoto toont footprint; geen volledige metrische tekening. Torenhoogte 38 m is pakketclaim, overige maten gameschatting. |
| Fort aan de Drecht | Zeven foto's/luchtbeeld in `fotos/`, AI-sheet en details | Lage langgerekte vergrijsde betonnen bouw, groen dak/aarden dek, donker groene deuren, uitstekende ronde geschutsvorm, watergracht en toegangsbrug met hek | De luchtfoto ondersteunt eiland/gracht; artistieke ringvorm en alle afmetingen blijven interpretatie. Ondergrond en dak zijn onderdeel van herkenbaarheid. Geen hoog kasteel modelleren. |
| Irenebrug | Vijf items in `fotos/` (waaronder computertekening), AI-sheet | Lage overspanning met pijlers, blauw-witte relingen, rood-witte slagbomen, lichten en bakstenen bedienhuisje met groen schilddak | Geometrie echte foto's leidend; luchtbeeld ondersteunt brugligging. 4 openingen van 10,5 m en 2,8 m doorvaarthoogte zijn aangeleverde pakketclaims, niet hier opnieuw gemeten/gecontroleerd. Model als decoratieve brug, zonder impliciete berijdbare aansluiting. |
| Thamerkerk | Vijf foto's in `fotos/`, dezelfde vijf tevens als `source_01..05.jpg`, AI-sheet | Compacte bakstenen zaalkerk met afgeschuinde koppen, donker schilddak, witte open achthoekige dakruiter met koepeltje, witte entreepartij en hoge witomrande rondboogramen | Goed genoeg voor silhouet en materiaal. Niet alle achtergeveldetails gedekt; AI-aanzichten reconstrueren die. Maten 22 × 17 m / 23 m totaalhoogte zijn visuele gameschattingen. |
| De Hoeksteen | Vijf foto's/luchtbeeld in `fotos/`, atlas en AI-sheet | Vierkant modern hoofdblok, bruingrijze baksteenvakken in witte betonnen rasterstructuur, grote verticale glaspartijen aan waterzijde, lage aanbouw, glazen trappenhuis en rode deuren/element | Hoofdblok 25 × 25 × 12,5 m heeft bronverwijzing in pakket; hier niet onafhankelijk geverifieerd. Back/left/right zijn reconstructies; front is de afgesproken watergevel, geen geografische oriëntatieclaim. Raamreflecties niet verwarren met transparant interieur. |

## Textuurtoepassing

Gebruik gesloten driedimensionale massa's en los gemodelleerde uitstekende delen. Behang de volledige gebouwen niet met de samengestelde aanzichtbeelden: daarin staan hemel, planten, belichting, perspectief en soms onderling strijdige reconstructies.

De 24 detailpanelen zijn kleur-/detailbronnen, geen volledige PBR-set. Veel bevatten witte of transparante canvasranden en bovenlabels. Rechthuis bevat bijvoorbeeld smalle luifel- en dakstroken; Fort/Irenebrug/Thamerkerk hebben relatief kleine inhoud in 512 px canvas. Schanskerk heeft transparante padding. Hoeksteen heeft beeldvullende patches; de pakketclaim 'seamless' is geen enginebewijs. Voor gebruik inhoud uitsnijden, labels/randen verwijderen en de resulterende materiaalvlakken bekijken. Geen bron overschrijven.

Baksteen/beton/dak als herhalende kleurpatch met passende schaal en matte roughness toepassen. Ramen/deuren/luiken gericht UV-mappen op afzonderlijke detailvlakken. Glas krijgt eigen materiaal, staal passend metallic; schilderwerk, metselwerk en dakpannen niet metallic. Geen onjuiste gotische Schanskerkraam-/deurpanelen klakkeloos overnemen: echte rondboogvormen modelleren. Irenebrug huis-, reling- en slagboompaneel bevatten perspectief of witte achtergrond; gebruik voor detailaccenten of vorm/kleur, niet als hele geveltextuur. Geen normal/roughness-gegevens uit foto's claimen. Een zelfstandige GLB kan standaard glTF metallic/roughness-materialen en ingebedde textures bevatten; Godot gebruikt die als PBR-shaders.

## Herkomst, bewijs en open controles

De foto's zijn door de klant aangeleverd; daarmee zijn maker/licentie van alle individuele beelden nog niet vastgesteld. AI-sheets en geresamplede uitsneden zijn als zodanig in README/manifest benoemd; 1024 px uitvoer betekent geen 1024 px oorspronkelijk detail. Deze beoordeling doet geen nieuwe historische of licentieclaims.

De startinventaris staat in `validation/uithoorn-reference-inventory.json`: 144 aanwezige bron-/pakketbestanden, exacte bytes en SHA-256, afbeeldingsmaten waar decodeerbaar. Ze bevat de zes aangeleverde pakketten vóór nieuw gegenereerde modellen; ZIP's zijn alleen gehasht, niet uitgepakt. Schanskerk en Thamerkerk bevatten duplicaten van bronbeelden; aantallen zijn geen unieke camerastandpunten.

Ruben bezit geometrie, materiaalafleiding en GLB's. Godot-import, standalone weergave, bronbehoud na productie en werkelijke race-/detailbeelden worden vervolgens door implementatie en Eva gecontroleerd. Deze bronnenbeoordeling bewijst die nog niet. Uithoorn 2056 blijft een ontwerpinterpretatie; brongebouwen worden herkenbaar gebruikt zonder een toekomstvoorspelling te claimen.
