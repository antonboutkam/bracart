# Twee fysieke Haarlem-landmarks

Amsterdamse Poort vervangt het bord bij sectie1 Gouden Straatjes; Teylers Museum
vervangt sectie5 Spaarnekade. Bavo en De Adriaan blijven behouden. De route,
sectienamen in de HUD, botsingen en overige vijf werelden zijn behouden.

Het zijn herkenbare primitieve3D-interpretaties, geen exacte reconstructies.
De Poort heeft een werkelijk open boog, hoge vierkante poorttoren, twee lagere
ronde voortorens, rood metselwerk en gesloten puntdaken. Teylers heeft een hoge
smalle natuursteengevel, dubbele zuilen, loggia/boogvensters, fronton en een
vereenvoudigde beeldengroep; achteraan staat de glazen vestibulekoepel.

## Bronnen en tijdsgrens

- Amsterdamse Poort volgt de bestaande onderzoeksselectie van Fenne in
  [LANDMARKS-EN-MATERIALEN.md](LANDMARKS-EN-MATERIALEN.md), met daarin de
  gemeentelijke historische bron en voorgestelde ligging bij Gouden Straatjes.
- Teylers eigen [19e-eeuwse uitbreidingen](https://teylersmuseum.nl/en/discover/building/19th-century-expansions)
  noemt opening van het Nieuwe Museum in1885 en Christian Ulrichs Spaarnegevel.
  Dit past bij de spelwereld1888. De museumbron beschrijft het interieur van
  Van der Steur en de allegorische geveldecoraties; het spelmodel vereenvoudigt
  deze bewust.
- Bekeken gevelreferentie: [foto Teylers entree](https://www.radiomuseum.org/museum/nl/teylers-museum-ch-haarlem/images/nl_teylers_museum_eingang.jpg).
  Alleen vorm-/verhoudingsreferentie; geen afbeelding in assets gekopieerd.
  De moderne reclame, vlag en fietsen zijn niet overgenomen.

## Makkelijker uitbreiden

`haarlem_landmarks.gd: ENTRIES` is de enige plaatsingsregistratie: id, sectie,
zijde, horizontale reserveringsradius en volledig lokaal modelvolume. Dezelfde
sectie bepaalt de fractie langs de baan en welk bord wordt vervangen. Een nieuw
model krijgt één entry en een modelbuilder/match in dezelfde module. De bestaande
`_root/_site` kiest een veilig grondvlak; het komt vóór gevelrijen en straatleven
in `scenic_sites`. Beide monumenten staan buiten de bocht; de voorkant kijkt schuin naar de
aankomende racer en de baan. Een gesloten stenen
kade verbindt de plint met de stadsgrond.

Alleen werkelijk geplaatste geldige modellen vervangen een bord. Onbekende
modellen, ongeldige secties en mislukte veilige sites behouden hun bord;
dubbele ids/secties worden overgeslagen. De gevelrijgenerator laat uitsluitend
rond deze geregistreerde fysieke landmarks een opening, inclusief kijkruimte
vanaf de weg. Zo verdwijnt een nieuw landmark niet achter een rij huizen.

Controleer bij uitbreiding de modelhoekpunten tegen radius/volume, volledige
baancorridor en zicht vanaf de echte racecamera. Een decoratief label alleen is
geen landmark. Voor volledige assetgedreven authoring zou later een PackedScene
per entry de builder-match kunnen vervangen; voor deze twee compacte procedurele
modellen blijft alle geometrie direct controleerbaar zonder importketen.

## Controle en beelden

- Gerichte regressie: `godot --headless --path game --script tests/haarlem_landmarks.gd`.
- Bestaande wijkcontrole: `godot --headless --path game --script tests/street_districts.gd`.
- Native capture: `python3 game/tools/capture_step.py --step stap-19-haarlem-landmarks`.
- Centrale renderpagina: `renders/GAME-10001/stap-19-haarlem-landmarks/index.html`.

De capture gebruikt de echte wereld3-instanties, per gebouw een voor-/achterzicht
en de gewone racecamera op een passend naderingspunt. Het zijn geënsceneerde
stilstaande racemomenten, geen bewijs van een volledige gespeelde race.
