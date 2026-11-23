# Monsterbreker: selectie en sfeer

De lokale spelmap toont acht breekbare monsters in het start- en pauzemenu. De oude blokmonsters en de voorlopige draak staan niet meer in de keuzes. Hun bestanden en technische ondersteuning zijn behouden voor bestaande tests en terugval; ze zijn dus niet fysiek gewist.

De voertuigenkiezer gebruikt kleine afbeeldingen en een horizontale scrollcontainer die toetsenbordfocus volgt. De afbeeldingen zijn afgeleid van de voertuigpreviews. De omgeving heeft donkerdere lucht, mist en belichting.

De tests in een tijdelijke spelkopie zijn geslaagd: `monster_breaker.gd` (175 controles), `fractured_monster.gd` (481), `fractured_collection.gd` (1064) en `monster_selection_responsive.gd`. De laatste controle is ook in de werkelijke spelmap geslaagd. Een screenshot op 640 × 400 is geprobeerd, maar de grafische driver kon geen geschikte OpenGL/EGL-context maken. De daadwerkelijke weergave op dat formaat is dus nog niet visueel beoordeeld.

`wijzigingen.diff` toont de gerichte codewijzigingen; `installeren.py` controleert de eerdere inhoud voordat het bestanden wijzigt. De oude bronnen zijn niet verwijderd.
