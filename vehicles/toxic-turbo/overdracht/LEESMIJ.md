# Installatie van voertuig-pimper en de centrale werkplek

Doel: `~/Documents/sites/boracart`.

Dit pakket voegt toe:

- `.agents/skills/voertuig-pimper/`: de herbruikbare projectskill en generieke tools.
- `public_html/boracert/`: centrale scripts, instructies en de complete Toxic Turbo-werkmap.

De oorspronkelijke spelbestanden onder `public_html/boracer/vehicles/` worden
niet verwijderd of overschreven. Het pakket stopt bij conflicterende bestanden
en controleert de gekopieerde bestanden met SHA-256.

Vanuit deze map:

```bash
python3 install.py --dry-run
python3 install.py
```

Open daarna `~/Documents/sites/boracart/public_html/boracert` als werkplek.
De projectskill staat in de bovenliggende repository en wordt tevens expliciet
verwezen vanuit het lokale `AGENTS.md`.

De oorspronkelijke sessie kon deze doelmap niet rechtstreeks aanmaken door haar
beperkte schrijfrechten. Daarom is de gehele overdracht hier eerst voorbereid.
