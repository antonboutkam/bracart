# Gifspuwer — 01-gifspuwer-rood

Alle aanwezige, aan dit monster gekoppelde bronnen zijn hier verzameld.
De oorspronkelijke bestanden staan ongewijzigd in `assets/monters`.

## Status

Het organische GLB is een eerste 3D-proefmodel en geen definitief afgewerkt
gamemodel. Het blokjesmodel en de blokken-JSON zijn een aparte variant.
De blokken-JSON komt byte voor byte overeen met de huidige spelkopie.
Er is ook een verfijnde fase-1-versie en de geïntegreerde versie met 76 breekstukken.

## Inhoud

- `afbeeldingen/`: eigen illustratie, drie aanzichten en aanwezige modelvoorbeelden.
- `modellen/organisch-proefmodel.glb`: bestaande organische vormstudie.
- `modellen/blokjesmodel.glb`: blokjesinterpretatie als 3D-model.
- `blokjes/blokken.json`: alle 1741 blokken van dit monster.
- `blokjes/bronmanifest.json`: oorspronkelijke collectie-instellingen en alleen de vermelding van dit monster.
- `spelgegevens/catalogus-item.json`: huidige catalogusvermelding van dit monster.
- `bronnotities/`: oorspronkelijke gemeenschappelijke bronbeschrijvingen; hun importstatus kan verouderd zijn.
- `gegevens.json`: gemeten JSON-afmetingen, GLB-inventaris en beschikbaarheidsstatus.
- `TECHNISCHE-EISEN.md`: gewenste technische vorm voor een nieuwe verfijnde export.
- `OPDRACHT-CHATGPT.md`: opdracht voor het verder uitwerken van dit monster.
- `bestanden.json`: herkomst, bestandsgrootte en SHA-256 van alle overige pakketbestanden.
- `verfijnd-fase1/`: alle fase-1-modellen, Blender-bron en vier aanzichten.
- `breekbaar/`: werkende breekbare Gifspuwer, Blender-bron, JSON, voorbeeldrender en optioneel gif-effect.
- `spelgegevens/collision-planes.json`: afgeleide botsingsvlakken uit de huidige game.
- `historische-spelcontrole/`: ongewijzigde controles en zes beelden van 14 november 2026.
  De daarin genoemde race-smokefout is inmiddels opgelost; dit verslag blijft historisch.
  Het gif-effect zit wel in dit bronpakket maar is niet actief in de game.

## Gemeten blokjesgegevens

- Aantal blokken: 1741.
- Afmetingen uit de echte JSON, X/Y/Z: [26, 30, 8] roostercellen.
- Afmetingen uit het historische manifest: [26, 30, 8].

De gemeten afmetingen komen overeen met het historische manifest en de spelcatalogus.

Ontbrekende voorbeeldrenders zijn niet bijgemaakt. Zie `gegevens.json` voor
welke bestaande renders beschikbaar waren. Nieuwe afbeeldingen of modellen
zijn bij het samenstellen van dit pakket niet gegenereerd.

## Gebruiken in ChatGPT

Upload de zip van deze map en gebruik `OPDRACHT-CHATGPT.md` als opdracht.
Voor de overige monsters kan het aparte `voorbeeld-gifspuwer.zip` als werkend
technisch voorbeeld worden toegevoegd. Alleen het eerste monster heeft al
eigen verfijnde Blender-bronnen; voor de andere negen zijn die niet aanwezig.
