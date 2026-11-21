# Buitenleven — geometrische overdracht

Ruben GD-015; GAME-10001, 17 oktober 2026. Sem GD-005 bezit de afzonderlijke
wandelaars-/hondjesmodule. Eva GD-006 verricht onafhankelijke review.

## Inhoud en bouwcontract

Alle vijf buitenwerelden krijgen24gedragen park-/promenadeclusters met elk een
geparkeerd voertuig, boom, bank, afvalbak, bloembak, lantaarn en soms fietsrek.
Sunset heeft warme kleuren en palmvormen; Neon koele stadsbomen en lichtaccenten;
Regenbogenrijk zachte kleuren en ondersteunde wolkeneilanden; Haarlem een fictief
stoomautootje met messingpijp en periodepassende kleuren; Uithoorn geparkeerde
auto's en groen op het bestaande wijkgrondniveau. Dit zijn originele eenvoudige
primitieve modellen, geen nieuwe fotorealistische of historisch exacte assets.

`scripts/worlds/outdoor_life.gd` heeft een enkele aanroephaak in Scenery, na wijk
plus tram en vóór WorldArt-afwerking. World5keukentafel slaat de hook over.
Geen keukengeometrie, huisjes, circuit, botsingen of dashboard zijn aangepast.
Statische onderdelen delen vorm-/kleurmeshes via MultiMeshes. Sem bouwt vier
bewegende wandelgezelschappen per wereld, elk met aangelijnd hondje; dat gedrag
is apart getest en blijft eigendom van `street_walkers.gd`.

De promenade is een gesloten22x12m-dek met bovenkant op lokaleY0. De lokaleX-as
volgt de horizontale rijrichting. De wandelstrook is verschoven naarZ=-1,2;
gezelschappen blijven binnen de afgesproken swept-envelopeX±9,Z±1,5,Y0..3 van
hun eigen strookframe. Meubilair en voertuigen staan naast de strook. Boomkronen
en alle uitsteeksels blijven binnen de conservatieve gehele-clustercirkelR14,5.

Werelden0/1/3hebben massieve steunvolumes tot grondY=-22; wereld2drie echte
wolkvolumes onder ieder dek; wereld4gedragen platform opY=-20,85 boven de zichtbare grasbank (topY=-20,9). Er staan
geen auto's of personen zonder gedragen oppervlak in lege wolkenruimte.

Plaatsing controleert de volledige cirkel, inclusief kronen en sweptactors,
tegen de hele rijbaan met4,5m extra cameraguard bij0,8m samples. Beide zijden
worden eerst op dezelfde afstand onderzocht vóór een verder gelegen kandidaat.
Verder worden uitgesloten: bestaande scenic_sites, bestaande directe
skyline-/decorgrenzen, huis-/tuin-/stoepstempels, waterX±24,5 en de volledige
Uithoorntramlus met6m corridor. Clusters houden onderling minstens2m extra marge.

## Metadata voor capture en onafhankelijke QA

`Track/OutdoorLife.clusters` is een Array van dictionaries met `id`, `label`,
`center`, `radius`, `transform`, `static_aabb`, `floor_y`, `height`, `vehicle`,
`supported`, `support_kind`, `progress` en `walkspec`. De eerste cluster heeft
altijd een wandelroute; `progress` is de corresponderende echte Trackafstand.
`walker_specs` bevat alle vier routes en hun `dynamic_aabb`. Details van de
bewegende actors staan op `Track/StreetWalkers` in Sems module.

MultiMesh-batchnodes bewaren `instance_transforms`: precies dezelfde matrices
als bij `set_instance_transform()` ingediend. Dit is nodig omdat de headless
RenderingServerDummy hier voor `get_instance_transform()` identiteit teruggeeft
en `get_aabb()` geen betrouwbare gerenderde instantiebounds levert. Structurele
controle gebruikt daarom de echte gegenereerde ingediende CPUmatrices plus
meshvertices; dat bewijst geen GPU-/native-renderresultaat.

## Uitgevoerd bewijs

`tests/outdoor_life.gd`:157043checks,0fouten. Log:
`validation/outdoor-life-checks.txt`. Alle vijf werelden24clusters en4routes;
respectievelijk254/256/258/254/255nieuwe nodes inclusief wandelgezelschappen,
ruim onder600. Statische instance-aantallen993/936/1032/912/921; deze zijn via
slechts enkele tientallen batchnodes ingediend. De test controleert ieder
getransformeerd meshboundingboxhoekpunt tegen de gedeclareerde footprint,
werkelijke dekmeshhoogte, ondersteunende wolkvolumes, rij-/cameraguard, water,
tramlus, periodekeuze en behoud van de11keukengroepen zonder buitenlevenhook.

Afstand van clustercentrum tot dichtstbijzijnde routepunt, inclusief hoogte:

| Wereld | Mediaan | Maximum |
|---|---:|---:|
| Sunset |57m|101m|
| Neon |45m|77m|
| Regenbogenrijk |73m|129m|
| Haarlem |52m|106m|
| Uithoorn |77m|142m|

Deze afstanden zijn bewust transparant: bestaande huizen, water en tramlus
beperken nabije ruimte. Hoofdloos testen bewijst geen leesbaarheid, blikvangers,
gevelocclusie, schaalgevoel of aantrekkelijke compositie vanuit de racecamera.
Native X11 blijft geblokkeerd; er zijn geen enginebeelden gemaakt. De centrale
captureworkflow en Eva's onafhankelijke controle zijn aanvullend; visuele gate,
klantacceptatie en SC-uitbetaling blijven open.


## Native bevinding en correctie

Directie bekeek een daadwerkelijk op de gedeelde desktop gemaakte Uithoorncapture
(stap11/20261017T081807-879995Z/uithoorn-2056-straatinterieur.png). Daarin waren
wielen en benen deels begraven: de WorldArt-grasbank heeft een zichtbare top op
Y=-20,9, hoger dan het oorspronkelijke outdoorvloerniveauY=-21,8. OutdoorLife
plaatst Uithoornplatforms daarom nu uniform opY=-20,85, vijf centimeter boven de
hoogste grasbank. De fysieke voetplaat en steunbox lopen door tot de baseline-
grond, zodat ook buiten de bank geen zwevend platform ontstaat. Wandelrouteframes,
actorhoogtes, static/dynamicAABBmetadata en captureankers volgen hetzelfde niveau.
Dit is een echte visuele bevinding van directie, geen door Ruben gemaakte capture;
nieuwe native beelden moeten de correctie nog bevestigen. Bestaande woonwijken,
tram en ander decor zijn niet door deze correctie gewijzigd.

### Native wolkplatformbevinding

Directie bekeek vervolgens de echte native Regenbogenrijk-straatinterieurcapture:
een wolkbol stak door het dek naast de auto. De eerdere supportcontrole bewees
wel intersectie met het dek, maar miste de eis dat de wolk volledig onder de
beloopbare bovenkant blijft. CloudcenterY is daarom uitsluitend voor deze
ondersteunende volumes van lokaal-3,1 naar-4,0 verplaatst. Bij hoogte7,5 ligt de
bovenkant nu op-0,25: midden in het dekvolume[-0,6;0], geheel onder de wandelvloer.
De gerichte test controleert beide grenzen op de daadwerkelijk ingediende
meshtransformaties. Actoren, honden, platforms en Keukentafel zijn ongewijzigd.
Nieuwe native beelden moeten ook deze gerichte correctie nog bevestigen.
