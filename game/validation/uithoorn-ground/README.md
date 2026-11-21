# Uithoorn grondtracé — lokale controle, 8 november 2026

Geslaagde gerichte controles (Godot 4.7.2, geïsoleerde XDG-profielen):

| Suite | Controles | Fouten |
| --- | ---: | ---: |
| UithoornGround | 7.125 | 0 |
| UithoornLandmarks | 55.499 | 0 |
| StreetDistricts | 312.708 | 0 |
| CameraComposition | 524.420 | 0 |
| OutdoorLife | 190.499 | 0 |
| WorldGeometry | 50.603 | 0 |
| RaceBehavior | 34 | 0 |
| TracksV2 | 87.045 | 0 |

De eerste vijf staan in `final-checks.txt`; algemene geometrie in
`geometry.txt`, race- en stuntregressies in `race-and-stunts.txt`.
In de eerste uitvoering had de nieuwe vlakke route een instabiele vrijwel
parallelle camera-upinterpolatie. Die is hersteld. De horizoncorrectie neemt
vóór de heuvel af; ook de bewegende camera met alle geteste rijstroken,
sprongen en bewegingsinstellingen blijft nu binnen de bestaande HUD-grenzen.

`visibility.txt` bevat de laatste headless zichtcontrole: acht cameraopstellingen,
nul fouten. `subjects.json` bewaart de echte cameraposities en scores.
Alle zes landmarks hebben minimaal vijf opeenvolgende leesbare naderingspunten
in de middelste rijstrook, met zichtbare echte gevelvlakken. De camera kijkt
langs de normale rijrichting, zonder een landmark automatisch te volgen.

Dit zijn geometrische en geautomatiseerde controles, geen visuele beeldacceptatie.
Native screenshots zijn niet voltooid: de Mesa-softwareweergave bleef hangen
bij het tekenen; de OpenGL ES-poging meldde `EGL version is too old! 1.0 < 1.4`.
Deze pogingen zijn beëindigd. Er zijn geen systeemdrivers aangepast en er is
geen GPU-prestatiemeting gedaan. De capture-scripts blijven beschikbaar voor
herhaling op een werkende renderer. Er is geen volledige historische suite gedraaid.
