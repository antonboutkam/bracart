# Gifspuwer voor Monsterbreker

Dit proefmodel is afgeleid van Gifspuwer detailronde 2. Het zichtbare model heeft 76 benoemde breekstukken, 36.085 driehoeken, 27.540 geëxporteerde vertices en twee gedeelde materialen met vertexkleuren. De GLB is 1.329.624 bytes. De hoogte is 5 m. In GLB en JSON staat +Y omhoog en +Z naar voren. In Blender staat +Z omhoog en wijst de bek naar −Y.

| Bestand | Gebruik |
| --- | --- |
| gifspuwer-breekbaar.glb | Zichtbare stukken met eigen pivots en het anker mouth_emit |
| gifspuwer-breekbaar.blend | Bewerkbare stukken en verborgen COL_-objecten |
| breekstukken.json | Convexe botsingsvormen, steunverbindingen en scoregewichten |
| gif-effect.glb | Optioneel statisch effect in lokale coördinaten van mouth_emit |
| voorbeeld.png | Render van het intacte model |

## Integratie

1. Laad de GLB en koppel elk JSON-stuk aan de GLB-node met de bijbehorende naam. De punten in collider.points zijn lokaal ten opzichte van die node. Maak per stuk één convex hull uit deze punten. Pas dezelfde uniforme schaal toe op meshes, pivots en botsingsvormen.
2. Laat intacte stukken op hun beginpositie. Markeer bij een treffer het geraakte stuk als los. Zoek vanaf alle overgebleven grounded-stukken via neighbors welke stukken nog steun hebben. Sla losse stukken over tijdens die zoekactie. Activeer vervolgens dynamische botsing en zwaartekracht voor elk stuk dat steun verliest. De botsingsvormen zijn vereenvoudigd. Zet botsingen tussen aanliggende intacte stukken uit om krachten door kleine overlappingen te voorkomen.
3. Tel scoreWeight eenmaal per losgekomen stuk, inclusief stukken die instorten. Vergelijk de som met targetFraction (0,7). Dit voorstel weegt stukken naar hun kernvolume. Behandel de JSON als een eigen assetformaat naast het bestaande roosterformaat.
4. Voeg gif-effect.glb als child toe aan mouth_emit met een lokale identiteits­transformatie. De bekanker is een child van een breekstuk en beweegt daarmee mee.

## Gecontroleerd

- De Blender-meshes hebben gesloten randen. Ogen, tanden en andere details kunnen uit meerdere gesloten schillen binnen één breekstuk bestaan.
- De snijvlakken zijn gesloten en de stukken delen dezelfde snijposities. De voorbeeldrender toont lichte verschillen in shading op enkele naden.
- Alle 76 stukken zijn in de steunstructuur bereikbaar vanaf de vier voeten. Met alle vier voetstukken verwijderd is geen stuk meer ondersteund.
- Test in Monsterbreker nog de impactreactie, de combinatie van colliders en de framerate bij veel gelijktijdig vallende stukken. Het bestaande roosterformaat kan deze asset niet direct laden.
