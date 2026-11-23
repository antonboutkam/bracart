# Van kermisontwerp naar speelbaar voertuig

De brandweerauto v2 is een technisch prototype. De Godot-import en benoemde wiel- en stoelonderdelen zijn een begin, maar de eenvoudige basisvormen en losse details benaderen het concept nog niet goed genoeg. Bouw de andere drie niet automatisch op dezelfde manier: hun silhouet bepaalt of ze herkenbaar zijn.

## Werkwijze per voertuig

1. Gebruik het concept en het technische referentieblad samen. Gegenereerde aanzichten zijn richtinggevend en kunnen elkaar tegenspreken. Leg keuzes voor voor- en achterkant, wielen, zitplaats en onderkant vast voordat je modelleert.
2. Maak eerst een eenvoudige, bewerkbare volumestudie met de volledige carrosserievorm en een echte cockpit. Vergelijk front, zij-, achter- en bovenaanzicht met de referentie. Controleer schaal en bestuurdersruimte in Godot voordat kleine details worden uitgewerkt.
3. Werk de buitenvorm en cockpit uit met passende mesh-topologie, afgeronde overgangen en materialen. Voeg dan herkenbare details toe: manen en paardenvorm, rotoren of schotelvorm. Gebruik losse onderdelen alleen waar ze visueel en technisch zin hebben.
4. Lever een bewerkbare `.blend` en een zelfstandige `.glb`. Gebruik meters, +Y omhoog en voorkant -Z in glTF; controleer grondcontact en naamgeving `Seat_Cushion` en `Wheel_...` tegen de gamecode. Rotoren krijgen een eigen draaipunt. Vermijd een exacte maatclaim op basis van gegenereerde tekeningen.
5. Importeer de GLB opnieuw en render ten minste voor-, achter-, zij-, boven- en onderaanzicht. Controleer met de twee bestaande bestuurders, hun zitpositie en de camera. Controleer draaiende wielen, afmetingen, materialen en botsingen in de echte game voordat het voertuig in de garage beschikbaar wordt gemaakt.

## Aandachtspunten bij deze batch

- **Hobbelpaard:** maak een herkenbaar paardenhoofd en hals, met voldoende zicht vanuit de camera en ruimte voor de bestuurder; voorkom dat de sierlijke onderkant de weg raakt.
- **Helikopter:** controleer breedte en hoogte van de hoofdrotor, de staartrotor en de ruimte boven de bestuurder; de auto blijft een voertuig op de weg.
- **Ufo:** maak voor- en achterkant herkenbaar en beperk de schotelbreedte voor de baan. Werk onderkant en zitplaats uit.
- **Brandweerauto:** gebruik v2 voor technische experimenten en werk de carrosserie, zitkuip, wielen en versiering verder uit voordat deze als definitieve versie geldt.

Een concept of technische tekening is geen gevalideerd 3D-model. Een geïmporteerde GLB is ook nog geen geteste spelintegratie.
