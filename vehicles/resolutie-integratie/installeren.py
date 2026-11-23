from pathlib import Path
import hashlib,json,shutil,sys
here=Path(__file__).resolve().parent
game=here.parents[1]/'game'
for name,digest in json.loads((here/'verwachte-bestanden.json').read_text()).items():
 target=game/name
 if not target.is_file() or hashlib.sha256(target.read_bytes()).hexdigest()!=digest:
  sys.exit('Gestopt: bestand is intussen veranderd: '+str(target))
for source in (here/'game').rglob('*'):
 if source.is_file():
  dest=game/source.relative_to(here/'game');shutil.copyfile(source,dest);print(dest)
