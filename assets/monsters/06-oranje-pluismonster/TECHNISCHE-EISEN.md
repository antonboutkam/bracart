# Technische doelen voor een verfijnd Monsterbreker-model

Dit zijn ontwerpdoelen voor een nieuwe export. De aanwezige proefmodellen
voldoen hier niet automatisch aan; dit is geen gemeten prestatiegarantie.

- Bronhoogte circa 5 meter, grondcontacten op Y=0; +Y omhoog, +Z naar voren.
- Richt op maximaal 40.000 driehoeken, maximaal vier gedeelde materialen en
  60–100 afzonderlijk benoemde breekstukken met eigen pivots.
- Lever een zelfstandige GLB, een bewerkbare .blend en breekstukken.json.
- Gesloten stukken en snijvlakken; intact geen open gaten of hinderlijke naden.
- Per stuk een vereenvoudigde convexe botsingsvorm in lokale nodecoördinaten.
- Alle stukken bereikbaar via steunverbindingen vanaf grounded-stukken.
- Geen rigging of animaties nodig. Behoud herkenbaarheid en kindvriendelijke stijl.

## JSON-contract van het werkende voorbeeld

De velden op het hoogste niveau van breekstukken.json zijn:
`version`, `model`, `up`, `front`, `units`, `targetFraction`, `mouthEmit`, `pieces`.
Het voorbeeld gebruikt version=1, up="+Y", front="+Z", units="m" en targetFraction=0.7.
`model` verwijst naar de werkelijk geleverde GLB-bestandsnaam.

Elk element van `pieces` heeft `id`, `node`, `pivot`, `grounded`, `volume`,
`neighbors`, `collider` en `scoreWeight`. `id` en `node` koppelen aan een echte
GLB-node; `pivot` is een vector met drie getallen, `grounded` een boolean,
`neighbors` bevat geldige stuk-ID's. Steunverbindingen zijn wederzijds.
`collider.type` is "convexHull" en `collider.points` bevat lokale 3D-punten.
Het huidige importhulpmiddel controleert 4–64 botsingspunten per stuk.
Scoregewichten zijn positief en tellen samen op tot 1.

`mouthEmit` beschrijft bij het Gifspuwer-voorbeeld een anker via `node`, `parent`
en `position`. Bij andere monsters is een gif-effect geen verplicht ontwerpkenmerk;
stem af hoe een eventueel niet gebruikt anker in de nieuwe import wordt verwerkt.

In het spel levert een volledig gezonken stuk zijn gewogen aandeel van 10.000
punten op; vanaf 7.000 punten wordt de eindafwikkeling ingezet. Torens scoren
niet. De GLB/JSON-export bepaalt de bestaande spelregels niet opnieuw.

## Grenzen van de huidige integratie

Het blokjesmodel gebruikt een ander JSON-formaat: id, name en blocks, met per
blok gehele x/y/z en een #RRGGBB-kleur. Houd die bestanden gescheiden.
De huidige verfijnde runtime en synchronisatie richten zich specifiek op de
Gifspuwer. Een nieuwe model-export is niet automatisch in de game geïntegreerd.
Laat integratie, import, botsingen, steunverlies, score en prestaties later
apart controleren. Importeer het optionele gif-effect niet als structureel stuk.
