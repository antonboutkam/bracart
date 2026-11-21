# Hoog passerend vliegtuig

De vijf buitenwerelden krijgen af en toe één stil vliegtuig met herkenbare
romp, vleugels, staart en navigatielichtjes. De keuken krijgt dit niet.
Het vliegt210m boven het hoogste bemonsterde baanpunt en passeert over een
route van1.000m, vóór de startsectie en binnen de bestaande1600mfarclip.
Eerste passage na10–20s; daarna30s vliegen en55–100s wachten. De interval
gebruikt een lokale wereldseed en verandert geen race-/weerwillekeur.

Twee condenssporen gebruiken vaste wereldposities achter de motoren. Oudere
delen worden over12s breder en transparanter. Er zijn maximaal96punten per
motor, één hergebruikte ImmediateMesh en2304trailvertices; minder dan20nodes.
Er worden geen blijvende losse deeltjes toegevoegd. Nacht dimt model en spoor;
geen extra wereldlichten, geluid of botsingen.

Aircraft is eigendom van Track en gebruikt procesdelta. Echte gamepauze
bevriest zowel tijdschema, vliegtuig als spoor. Hervatten springt geen tijd
vooruit; wereldwissel verwijdert de oude groep. De DutchSky-hook behoudt
het bestaande weer-/hemelcontract en installeert niets voor keuken5.

## Renderen

```bash
python3 game/tools/capture_step.py --project GAME-10001 --step stap-14-vliegtuig
```

Vanuit een grafische desktopterminal. De eigen renderpagina heet
Vliegtuig en condensspoor en volgt dezelfde laatste-successelectie als andere
onderdelen. Drie echte Uithoorncamera's zijn voorbereid: dag met jong spoor,
zes seconden later vanuit hetzelfde standpunt en een nachtpose. Een passage
wordt voor deze review expliciet gestart; de beelden bewijzen niet de gewone
wachttijd. Headless setupvalidatie controleert de camera zonder beelden te
maken. Native zichtbaarheid, luchtcontrast en prestaties blijven een aparte
beeld-/speelcontrole.

Onafhankelijke projectiecontrole vond het model op27–33van120 normale
racecameraposes per wereld, met18–24px geprojecteerde spanwijdte. Dit bewijst
frustum/farclipbereik, geen native pixels of afwezigheid van wolkocclusie.
De volledige vliegtuiggroep bleef stabiel op14nodes. Makers8771 en
onafhankelijke75258controles groen; Mainpauze,spoorposities en cleanup getoetst.
