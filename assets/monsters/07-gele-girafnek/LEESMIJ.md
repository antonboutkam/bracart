# Girafnek — 07-gele-girafnek

Alle aanwezige, aan dit monster gekoppelde bronnen zijn hier verzameld.
De oorspronkelijke bestanden staan ongewijzigd in `assets/monters`.

## Status

Het organische GLB is een eerste 3D-proefmodel en geen definitief afgewerkt
gamemodel. Het blokjesmodel en de blokken-JSON zijn een aparte variant.
De blokken-JSON komt byte voor byte overeen met de huidige spelkopie.
Er is nog geen afzonderlijke verfijnde breekstukkenversie voor dit monster aanwezig.

## Inhoud

- `afbeeldingen/`: eigen illustratie, drie aanzichten en aanwezige modelvoorbeelden.
- `modellen/organisch-proefmodel.glb`: bestaande organische vormstudie.
- `modellen/blokjesmodel.glb`: blokjesinterpretatie als 3D-model.
- `blokjes/blokken.json`: alle 732 blokken van dit monster.
- `blokjes/bronmanifest.json`: oorspronkelijke collectie-instellingen en alleen de vermelding van dit monster.
- `spelgegevens/catalogus-item.json`: huidige catalogusvermelding van dit monster.
- `bronnotities/`: oorspronkelijke gemeenschappelijke bronbeschrijvingen; hun importstatus kan verouderd zijn.
- `gegevens.json`: gemeten JSON-afmetingen, GLB-inventaris en beschikbaarheidsstatus.
- `TECHNISCHE-EISEN.md`: gewenste technische vorm voor een nieuwe verfijnde export.
- `OPDRACHT-CHATGPT.md`: opdracht voor het verder uitwerken van dit monster.
- `bestanden.json`: herkomst, bestandsgrootte en SHA-256 van alle overige pakketbestanden.

## Gemeten blokjesgegevens

- Aantal blokken: 732.
- Afmetingen uit de echte JSON, X/Y/Z: [12, 32, 4] roostercellen.
- Afmetingen uit het historische manifest: [12, 32, 4].

De gemeten afmetingen komen overeen met het historische manifest en de spelcatalogus.

Ontbrekende voorbeeldrenders zijn niet bijgemaakt. Zie `gegevens.json` voor
welke bestaande renders beschikbaar waren. Nieuwe afbeeldingen of modellen
zijn bij het samenstellen van dit pakket niet gegenereerd.

## Gebruiken in ChatGPT

Upload de zip van deze map en gebruik `OPDRACHT-CHATGPT.md` als opdracht.
Voor de overige monsters kan het aparte `voorbeeld-gifspuwer.zip` als werkend
technisch voorbeeld worden toegevoegd. Alleen het eerste monster heeft al
eigen verfijnde Blender-bronnen; voor de andere negen zijn die niet aanwezig.
