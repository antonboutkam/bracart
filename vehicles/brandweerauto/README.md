# Brandweerauto — concept voor Boracart

Een compacte rode kermisbrandweerauto met lichte accenten, koperen bel, kleine ladder en blauwe zwaailichten. De open zitplaats en zichtbare wielen houden het een racekart.

## Bestanden en status

- `concept.png`: gegenereerd ontwerp met meerdere aanzichten. Het is een visuele richting, geen nauwkeurige technische tekening; aanzichten kunnen onderling verschillen.
- `brandweerauto-v2.blend` en `brandweerauto-v2.glb`: tweede, bewerkbare versie en GLB-export met slanghaspels, wielspaken, sierlijnen, zijbuizen en achterlichten.
- `source/build_model_v2.py`: bouwscript voor versie 2; uitvoeren overschrijft de v2-bestanden.
- `previews/v2-front-right.png`: controlebeeld van de opnieuw geïmporteerde versie 2.
- `brandweerauto-improved.blend`: bewerkbaar eerste 3D-prototype.
- `brandweerauto-improved.glb`: zelfstandige export van het prototype.
- `previews/front-right.png`: controlebeeld van de opnieuw in Blender geïmporteerde GLB.
- `source/build_model.py`: script om het prototype opnieuw op te bouwen met Blender. Let op: opnieuw bouwen overschrijft de GLB en het Blender-bestand.

Ook versie 2 is een vereenvoudigde uitwerking: de ronde carrosserie, banden, stoel, ladder, bel en lampen zijn aanwezig, maar de verfijnde vormen en decoraties van het concept ontbreken nog. De wielen en zitplaats zijn afzonderlijk benoemd. Blender heeft de GLB opnieuw geïmporteerd; in een tijdelijk Godot 4.7.2-project is de GLB headless geladen en zijn vier wielpivots en `Seat_Cushion` gevonden. Dat bewijst nog niet dat de wielen goed draaien of de bestuurders goed zitten. Het voertuig is nog niet in Boracart opgenomen of in een race getest.

## Uitwerking naar 3D

Modelleer een korte motorkap en cabine met open bestuurdersplek; bevestig de ladder laag genoeg voor het zicht. Maak lampen, bumper en wielen afzonderlijke onderdelen.

Gebruik de bestaande voertuigen als schaalreferentie: ongeveer 1,85 m lang en 0,90 m breed als startpunt, niet als harde maat. Werk in meters, met +Y omhoog en de voorkant naar -Z in glTF/Godot; plaats de root op grondniveau. Maak een gesloten onderkant, een echte zitplaats, afzonderlijke wielen met bruikbare draaipunten en materialen die in de GLB zijn ingebed. Lever zonder bestuurder, camera of studiobelichting. Vergelijk de uiteindelijke afmetingen met de andere voertuigen en de speelcamera.

## Verbeterpunten

Werk slang, ladder en lampbevestigingen uit. Controleer dat de ladder de bestuurder en camera niet raakt; stem de lichtanimatie later af op het spel.

Controleer het model van voor, achter, beide zijkanten, boven en onder. Maak waar nodig aanvullende technische aanzichten; kies bij tegenstrijdigheden één consistente vorm. Test de materialen, wielen en zitplaats na herimport in Blender en Godot.
