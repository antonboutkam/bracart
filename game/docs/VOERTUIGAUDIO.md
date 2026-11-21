# Voertuigaudio uit raviracer.mp3

Uitvoering: Joris van Rijn (GD-016). Godot-integratie: Sem (GD-005).
Onafhankelijke reviewer: Eva (GD-006). Klantbron blijft ongewijzigd;
geen upload, transcriptiedienst of vervangende gegenereerde stem gebruikt.

## Bron en selectie

`../../assets/audio/raviracer.mp3` is een mono MP3 van 44.100 Hz.
SHA256: `68139b40edbe7521dad77eb773a662eac31a6694442f3c2009c9b686f52f252e`.
ffprobe rapporteert 19,5765 s. ffmpeg decodeert 19,539592 s en meldt een
ontbrekende MP3-header bij een frame. De oorspronkelijke bron is behouden;
de volledige decoderwaarschuwing staat in het manifest. De gekozen stukken
liggen ruim voor het bestandseinde en worden daadwerkelijk als PCM gedecodeerd.

Golfvorm en STFT tonen een lange harmonische passage tussen circa 1,5 en
6,2 seconden, gevolgd door pauzes en onregelmatiger korte passages. De loops
gebruiken uitsluitend die lange passage. Dit is selectie op zichtbare
harmonischen en dynamiek; geen semantische garantie dat alle spraak of
omgevingsgeluiden verwijderd zijn. Deze agent had geen rechtstreeks
luisterkanaal en claimt geen gehoorreview.

| Loop | Broninterval | Afspeelfactor | Lengte / samples | Samplepeak | RMS |
|---|---|---|---|---|---|
| Stationair | 3,60–4,45 s | 0,80 | 0,982517 s / 43.329 | -2,5431 dBFS | -14,4252 dBFS |
| Rijden | 1,85–2,85 s | 1,00 | 0,920000 s / 40.572 | -4,4674 dBFS | -14,4252 dBFS |
| Boost | 5,18–6,13 s | 1,12 | 0,768231 s / 33.879 | -4,3136 dBFS | -14,4252 dBFS |

## Recept en overdracht

Bouw opnieuw met:

```bash
python3 game/tools/build_vehicle_audio.py
```

Het script gebruikt lokale ffmpeg/ffprobe, NumPy, SciPy en Pillow. Het verwijdert
DC, past zero-phase Butterworth-filters toe (90 Hz highpass orde 3 en 4.500 Hz
lowpass orde 4), resamplet mild voor het toonhoogteverschil en overlapt de eerste
en laatste 80 ms met complementaire raised-cosine-gewichten. Die gewichten
sommeren tot één om een piek door coherente menging te vermijden. De overlap
wordt uit de looptijd verwijderd; de herhaalgrens is een paar oorspronkelijk
aangrenzende samples. Daarna volgt DC-correctie en RMS-doel 0,19, begrensd op
-2 dBFS samplepeak. Uitvoer: mono PCM16 WAV, 44.100 Hz, zonder lossy hercodering.

Godot-assets: `res://assets/audio/vehicles/{idle,drive,boost}.wav`.
Loop begin op sample 0, einde op de hierboven genoemde sampleaantallen,
voorwaarts. Runtimepitch bij voorkeur 0,8–1,2 om het bronkarakter te behouden.
De bron is vocaal en varieert in toonhoogte; autocorrelatie geeft alleen een
fundamentaalkandidaat, geen stabiel fysisch motortoerental. Voor ai en meerdere
stemmen is apart mixbudget nodig; assetheadroom garandeert geen headroom van
de volledige mix. Sem beheert snelheid, mix, afstand, pauze en opruimen.

## Werkelijk gemeten en resterend

- Alle drie bestanden hebben nul geclipte samples; DC-offset maximaal 6,4e-8.
- De samplesprong op elke loopgrens is kleiner dan het 99e percentiel van gewone
  opeenvolgende samples in diezelfde loop. Dit meet geen volledige perceptie.
- Een 4x polyphase-oversampling schat pieken op -2,52 / -4,45 / -4,29 dBFS.
  Dit is een schatting, geen gecertificeerde true-peakmeting.
- Alle zeven gebouwde outputs waren byte-identiek na een tweede uitvoering:
  drie WAV's, manifest, bronanalyse-PNG, offline voorbeeld-WAV en HTML.
- Het manifest bevat exacte bronmonsters, gain, filterketen, toolversies,
  builderhash, WAV-hashes en metingen.
- Nog nodig: menselijk beluisteren en echte hoorbare enginecontrole. De
  technische controles vervangen die beoordeling niet.

De [audio-review](../../renders/GAME-10001/audio/index.html) bevat de originele
MP3, de drie loops, een 12 seconden lange offline acceleratie-/boostdemo en
het spectrogram. De demo is met het bouwscript gemengd en is uitdrukkelijk geen
opname van Godot. Browser-looping is evenmin een sample-nauwkeurige engineproef.

## Runtime-integratie en importinstellingen

`scripts/effects/vehicle_audio.gd` gebruikt vier lagen per kart: stationair,
cruise, belasting en boost; cruise/belasting delen `drive.wav`. Drie gedeelde
AudioStreamWAV-resources voeden twintig AudioStreamPlayer3D-stemmen. Ieder
voertuig heeft een pitch-/gain-/afstandsfilterprofiel. Snelheid, gas en de
werkelijke booststatus sturen vloeiende mixovergangen. Alleen races starten
de stemmen; mute, effectvolume nul en pauze zetten de output op -80 dB en
pauzeren de streams. Finish, menu en racewissel stoppen/verwijderen stemmen.

De drie `.wav.import`-bestanden zetten **compress/mode=0**. Godot 4.7 koos bij de
eerste import QOA-compressie; dat past niet bij de PCM16-loopgrenzen op basis van
monsteraantallen. De bron-WAVs zijn onveranderd, alleen de importinstellingen
zijn hersteld en opnieuw geïmporteerd. Bewaar de sidecars bij de assets.
Fouten bij laden/formaat verschijnen in het log en als melding in de game.

Gezamenlijke enginegain vóór afstandsafzwakking blijft onder0,35; dit is een
controle van de motorlagen, geen perceptuele beoordeling van de hele mix.
Pitch is begrensd op0,8–1,2. Bestaande muziek en korte spelcues blijven apart.

Bewijs: `validation/vehicle-audio-engine-test.txt` (1.638 controles met fixtures)
en `validation/vehicle-audio-qa-checks.txt` (829 onafhankelijke controles met
echte WAVs, Main en alle zes profielen). Metingen wachten op echte physicsframes
voor de uitgestelde AudioStreamPlayer3D-start/pauzestatus. Een synchrone
testlus is hiervoor ongeschikt. Er is geen hardware-/gehoorbeoordeling gedaan.
