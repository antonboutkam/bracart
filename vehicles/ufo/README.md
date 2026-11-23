# Ufo — concept voor Boracart

Een retro vliegende schotel met gekleurde lampjes, een open zitplaats en kleine wielen. De schotel rijdt op de baan en past in dezelfde kermisfamilie.

## Bestanden en status

- `concept.png`: gegenereerd ontwerp met meerdere aanzichten. Het is een visuele richting, geen nauwkeurige technische tekening; aanzichten kunnen onderling verschillen.
- `technisch-concept.png`: aanvullend gegenereerd referentieblad met boven- en onderaanzicht. De voor- en achteraanzichten tonen een extra middenwiel, terwijl de onderkant vier wielen toont. Kies bij het modelleren één wielindeling en controleer of de sierkap het zicht belemmert.
- `ufo-spel.blend` en `ufo-spel.glb`: smallere spelversie, toegevoegd aan de lokale Boracart-garage.
- `source/build_spelversie.py`: bouwscript voor de spelversie.
- `ufo-studie.blend`: bewerkbare eerste volumestudie.
- `ufo-studie.glb`: GLB-export van de volumestudie.
- `source/build_model.py`: bouwscript; opnieuw uitvoeren overschrijft de studie.
- `previews/front-right.png` en `previews/top.png`: controlebeelden van de opnieuw in Blender geïmporteerde GLB.

De studie heeft een uitgesneden cockpit, een ovale schotel, vier wielen en een kap achter de stoel. De vier wielen zijn een keuze op basis van het onderaanzicht; de referenties spreken elkaar tegen. Een headless Godot 4.7.2-import herkent vier wielpivots en `Seat_Cushion`. De smallere spelversie is lokaal toegevoegd aan de garage. In een aparte kopie van het spel zijn de twee bestuurders, wielbeweging, voertuigselectie, bewaren en laden headless getest. Een visuele controle van bestuurder, camera en botsingen tijdens een race blijft nodig. De oorspronkelijke studie blijft beschikbaar.

## Uitwerking naar 3D

Maak de voorkant herkenbaar met lampen en bediening. Houd de schotel compact genoeg voor de baan en zorg voor een echte, verdiepte zitplaats.

Gebruik de bestaande voertuigen als schaalreferentie: ongeveer 1,85 m lang en 0,90 m breed als startpunt, niet als harde maat. Werk in meters, met +Y omhoog en de voorkant naar -Z in glTF/Godot; plaats de root op grondniveau. Maak een gesloten onderkant, een echte zitplaats, afzonderlijke wielen met bruikbare draaipunten en materialen die in de GLB zijn ingebed. Lever zonder bestuurder, camera of studiobelichting. Vergelijk de uiteindelijke afmetingen met de andere voertuigen en de speelcamera.

## Verbeterpunten

Werk de onderzijde en lampjes uit, controleer de breedte en maak de rijrichting ook van achteren zichtbaar. Een lichte zweefanimatie kan later worden onderzocht.

Controleer het model van voor, achter, beide zijkanten, boven en onder. Maak waar nodig aanvullende technische aanzichten; kies bij tegenstrijdigheden één consistente vorm. Test de materialen, wielen en zitplaats na herimport in Blender en Godot.
