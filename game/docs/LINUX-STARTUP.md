# Linux-opstartonderzoek — GAME-10001

Datum: 5 november 2026. Aanleiding: klantlog van `./start.sh` met een mislukte
GLX-context, terugval naar OpenGLES/llvmpipe, een ontbrekende PulseAudio-sink
en een X11 `BadMatch` bij request 42.

## Opdracht en verantwoordelijkheden

Doel: een beperkte, controleerbare verbetering van de launcher en concrete
herstelstappen. Behoud de assetimport, `GODOT_BIN`, doorgifte van Godot- en
spelargumenten en bestaande spel-/profieldata. Geen installatie of aanpassing
van systeemdrivers, audioservices of desktopconfiguratie.

Werkelijk gevoerde afstemming in deze sessie:

- Daan (GD-001, hoofdagent) droeg de coördinatie over aan Milan (GD-003,
  afzonderlijke agent), met behoud van bestaande wijzigingen en onafhankelijke QA.
- Milan controleerde vóór delegatie de technische integratie/verificatie-expertise
  van Sem (GD-005), de reviewexpertise van Eva (GD-006) en de capaciteit:
  vier uitvoerders inclusief Daan en Milan.
- Sem kreeg uitsluitend de launcher, beperkte startdocumentatie en gerichte
  controles. Eva kreeg een onafhankelijke review zonder eigenaarschap over
  de launcher. Milan beheert dit sessieverslag; Daan beoordeelt de oplevering.
- Daan wees erop dat het project al GL Compatibility gebruikt. De GLX-fout
  en de focusfout mogen niet zonder bewijs als één driverprobleem worden behandeld.
  Dit is aan Sem en Eva doorgegeven.
- Eva vond een primaire X.org-bron die `BadMatch` bij `XSetInputFocus` beschrijft
  voor een niet-zichtbaar venster. Dit is aan Sem doorgegeven. Een oorzaak op
  de klantmachine is daarmee nog niet vastgesteld.

## Besluiten en bewijsgrenzen

Gezonde werkstations behouden hun normale grafische en audioselectie.
Het uitschakelen van audio is uitsluitend een expliciete herstelkeuze.
De melding `llvmpipe` toont CPU-rendering in het aangeleverde log;
deze sessie bewijst geen defect aan een fysieke GPU.

## Tijdelijke herstelstart

```bash
./start.sh --safe-mode
```

Deze expliciete launcheroptie kiest `--rendering-driver opengl3_es` en
`--audio-driver Dummy`: de mislukte GLX-poging wordt overgeslagen en geluid
staat tijdelijk uit. Software-rendering wordt niet geforceerd. De gewone
`./start.sh` behoudt de bestaande driverselectie. De optie wordt alleen vóór
de Godot-spelargumentscheiding `--` verwerkt:

```bash
./start.sh --safe-mode -- --demo
```

Wie alleen de grafische route wil testen en geluid wil behouden kan de
Godot-optie rechtstreeks doorgeven: `./start.sh --rendering-driver opengl3_es`.
Herstelmodus repareert geen systeemdriver, audioapparaat of X11-focusprobleem.
GLES-ondersteuning is gecontroleerd met `godot --help` in deze lokale 4.7.2-build.

Als er ook in herstelmodus geen speelvenster verschijnt, controleer eerst of
de terminal in de lokale desktop of via een remote sessie draait:
`printf '%s\n' "$DISPLAY" "$XDG_SESSION_TYPE"`. Test de grafische context met
`glxinfo -B` en de audio-uitgang met `pactl get-default-sink` en
`pactl list short sinks`. Een opnieuw optredende X11-`BadMatch` bij request 42
vraagt afzonderlijke controle van vensterzichtbaarheid/focus en de sessie;
deze wijziging is daarvoor geen bewezen reparatie.

Een ingestelde `DISPLAY` bewijst geen lokale desktopsessie. Werk je via SSH,
probeer de start dan vanuit een terminal op de fysieke desktop en vergelijk
of daar hetzelfde venster-/focusprobleem optreedt.

## Technische controles door Sem

- `bash -n start.sh`: geslaagd.
- Tijdelijke Godot-stub: normale start, hersteloptie, scheiding `--`, argumenten
  met spaties, starten vanuit andere werkmap, `GODOT_BIN` met spaties,
  importfout en ontbrekende engine gecontroleerd; geslaagd. Een importfout
  stopt vóór het speelproces. Geen stub of extra testbestand toegevoegd.
- Lokale `glxinfo -B` faalt bij GLX-contextcreatie met `BadValue`.
  `pactl get-default-sink` levert letterlijk `@DEFAULT_SINK@`, terwijl
  `pactl list short sinks` één `auto_null`-sink toont.
- Normale native start en GLES-only start met `--quit-after 2` zijn elk na
  20 seconden afgebroken (`timeout`, status 124). Normale start reproduceert
  de GLX-fout en terugval naar GLES; beide melden de PulseAudio-sinkfout.
- Expliciete GLES/Dummy-proef met `--windowed --quit-after 2` meldt de
  GLES 3.2/llvmpipe-renderer, zonder GLX- of PulseAudio-fout in de vastgelegde
  uitvoer, maar bereikt binnen 60 seconden geen schone afsluiting (status 124).
  `--windowed` is niet opgenomen in de launcher: het project start al in een
  venster en deze proef bewijst geen noodzaak voor die extra optie.
- De EGL-waarschuwing `DRI2: failed to authenticate` blijft in de native proeven
  aanwezig. De X11-focusfout is tijdens deze proeven niet gereproduceerd.
  Geen geslaagde speelbare native start of opgelost focusprobleem aangetoond.
- De echte launcher `./start.sh --headless --quit-after 2` voltooit import en
  twee headless-iteraties met status 0. Daarbij meldt Godot dat de
  editorinstellingen buiten de schrijfbare sandbox niet opgeslagen kunnen
  worden en waarschuwt de runtime voor twee gelekte ObjectDB-instanties bij
  afsluiting. Headless bewijst geen werkend venster, rendering of audio.

Sem heeft code en bewijs aan Eva overgedragen voor onafhankelijke review.

## Onafhankelijke QA door Eva

Eva keurt de launcherwijziging technisch goed als expliciete herstelroute.
Zij controleerde zelf `bash -n` en acht tijdelijke-stubscenario's: normale
argumentdoorgifte met spaties vanuit een andere werkmap, veilige GLES/Dummy-keuze,
behoud van `--safe-mode` na de spelargumentscheiding, expliciete driver/audioopties,
stoppen bij importfout (status 23), doorgeven van runtime-exitstatus 37,
`GODOT_BIN` met spaties/ontbrekende engine en herhaalde hersteloptie. Alle controles
slaagden. De controles zijn tijdelijk uitgevoerd, zonder extra tests in de repo.

Een onafhankelijk minimaal tijdelijk Godotproject met geïsoleerde XDG-mappen,
GLES/Dummy en `--quit-after 2` eindigde met status 0 op Godot 4.7.2 en GLES 3.2
llvmpipe. Twee EGL/DRI2-authenticatiewaarschuwingen bleven zichtbaar; geen GLX-,
PulseAudio- of BadMatch-fout. Dit toetst de beschikbare herstelinstellingen,
maar bewijst geen volledig speelbare BoRacer-start of herstel op de klantdesktop.
De volledige native gameproeven bleven onvoltooid; de focusfout is niet gereproduceerd.

Status: technische uitvoering en onafhankelijke QA gereed; overdracht aan Daan
voor oplevering. De klantdesktop en klantacceptatie blijven open.

## Studio Credits en acceptatie

Dit verslag wijzigt geen begroting, verplichtingen of transacties. De gelezen
projectbegroting is 79.500 fictieve SC; deze sessie voegt geen budget of betaling
toe. Nieuwe uitbetalingen: **0 SC**. Klantacceptatie: **open**. Een geslaagde
lokale controle geldt niet als klantacceptatie of bewezen herstel op diens desktop.

Organisatiebestanden buiten deze schrijfbare werkmap blijven ongewijzigd;
daarom staat dit werkelijke sessieverslag bij de game.

Bron voor het onderscheid met X11-focus:
[X.org XSetInputFocus](https://xorg.freedesktop.org/archive/X11R7.5/doc/man/man3/XGetInputFocus.3.html).
