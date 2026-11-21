# Geselecteerde Kenney-assets

Drie gratis CC0-pakketten, opgehaald op 17 oktober 2026. Alleen vier gebruikte
natuurmodellen, twee transparante particles en vier korte impactgeluiden zijn
geïnstalleerd. De oorspronkelijke ZIP's blijven buiten de repository, onder `/tmp`.

`manifest.json` registreert officiële bron- en download-URL, archive-SHA-256,
oorspronkelijk memberpad, bronhash, outputhash en wijzigingen. De drie bestanden
onder `licenses/` zijn byte-identieke originele licentieteksten. Gebruik en
bewerking zijn ook commercieel toegestaan; credits aan Kenney worden gewaardeerd
maar zijn niet verplicht. Kenney's logo is niet onderdeel van deze selectie.

Nature-GLB's en particle-PNG's hebben originele bytes. OGG-impactbronnen zijn
gedecodeerd naar PCM16 mono 44,1 kHz WAV zonder EQ/gain/trim. `soft_medium.wav`
is een zachte impact voor mogelijke plasticlandingen, geen bronopname die
de maker als plastic labelt. Geen voertuiggeluid uit raviracer.mp3 vervangen.

Herhalen met de drie oorspronkelijke archives als
`/tmp/boracer-kenney-{nature,particles,impacts}.zip`:

```bash
python3 /home/anton/Documents/sites/boracart/public_html/boracer/game/tools/import_kenney_assets.py --archive-dir /tmp
python3 /home/anton/Documents/sites/boracart/public_html/boracer/game/tools/import_kenney_assets.py --verify
```

De importer controleert vooraf gepinde archivehashes en installeert alleen
expliciet genoemde bestanden; geen algemene ZIP-extractie. Een andere packrevisie
vereist bewuste herbeoordeling. WAV-hashes gelden voor de huidige ffmpeg-decoder;
opnieuw genereren met een andere decoder kan afrondingsverschillen geven.
