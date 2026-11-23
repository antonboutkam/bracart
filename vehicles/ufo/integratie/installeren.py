"""Install the reviewed UFO changes only if all original files still match."""
from pathlib import Path
import hashlib,json,shutil,sys
here=Path(__file__).resolve().parent
game=here.parents[2]/'game'
expected=json.loads((here/'verwachte-bestanden.json').read_text())
for name,digest in expected.items():
 target=game/name
 if not target.is_file() or hashlib.sha256(target.read_bytes()).hexdigest()!=digest:
  sys.exit('Gestopt: bestaand bestand is veranderd: '+str(target))
for name in ['assets/models/ufo.glb','tests/ufo_integration.gd']:
 if (game/name).exists():sys.exit('Gestopt: doel bestaat al: '+str(game/name))
for source in (here/'game').rglob('*'):
 if source.is_file():
  dest=game/source.relative_to(here/'game');dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,dest);print(dest)
