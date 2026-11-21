# Uithoorn 2056 — verhoogde race en tram

Sem Jansen (GD-005), 17 oktober 2026. Opdracht: woonwijken onder een hoger
parcours en een daadwerkelijk rijdende tram. Reviewer: directie/Eva.

Uitsluitend route 4 is zestien meter verhoogd: dezelfde x/z-punten en dezelfde
golving, met hoogtebasis 25 in plaats van 9. De andere vijf routes zijn exact
behouden. De laagste Uithoorn-controlepunten liggen boven 17 meter; wijkdaken
rond -10 blijven onder het racepad. Dit is een spelwereld, geen schaalreconstructie.

`worlds/tram.gd` biedt `Tram.build(track)`. De teruggegeven `UithoornTram` is een
kind van Track; pauze erft de bestaande track-processmodus. Wereldwissel of
verwijderen van de track ruimt de tram inclusief infrastructuur op. Er zijn geen
botsingsobjecten. Ruben integreert de aanroep in scenery; Sem wijzigt die file niet.

De tramlus ligt geheel oostelijk van de Amstel: middelpunt x83/z0,
ellipsstralen 49/100, railhoogte -21.68 boven wijkgrond -21.8. De wijkbouwer
reserveert zes meter naast het spoor. Drie afzonderlijke wagenbakken volgen
ieder dezelfde doorlopende lus met hun eigen raaklijnrichting; afgelegde meters
worden via een booglengtetabel naar de ellips vertaald. Snelheid: 8.5 m/s.
De zichtbare infrastructuur bestaat uit ballastbed, twee rails, dwarsliggers,
bovenleiding, halteperron, haltekap en bestemmingsaanduiding.

De aangeleverde `assets/straatbeeld/uithoorn/images (7).jpeg` toont een lage
wit/blauwe tram met donkere ruiten en bovenleiding. Dat bepaalt de basisvorm:
driedelige gelede wagen, lage blauwe band, lichte carrosserie, zwarte cabine,
zijruiten, koplampen, vouwbalgen, stroomafnemer en display `25 UITHOORN`.
`hetspoorhuis.jpg` en `Spoorbrugoveramstel.jpg` zijn visueel bekeken voor de
plaatselijke context. Foto's blijven referentie; er is geen foto als texture
gekopieerd. De lus, halte Spoorhuis en bediening in 2056 zijn creatieve
interpretaties, geen beweringen over toekomstig openbaar vervoer.

`tests/tram_motion.gd` controleert echte scene-objecten, eindige poses, richting,
lusnaad, verplaatsing, invoervalidatie, grondpositie, eigenaar/cleanup en een
werkelijk uitgeschakelde en hervatte processmodus. Headless Godot: 1224 checks,
0 fouten. De routes-diff bevat uitsluitend de hoogteaanpassing van index 4.
Native rendering is in deze omgeving geblokkeerd door X11-toegang; er zijn
geen beelden gemaakt of visuele goedkeuring geclaimd. Nieuwe capture van de
geïntegreerde wijk/tram blijft nodig voor schaal, zichtbaarheid en artreview.
