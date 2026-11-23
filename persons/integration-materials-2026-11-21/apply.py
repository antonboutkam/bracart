"""Integrate only the two validated character snapshots. Requires game write access."""
from pathlib import Path
import json,hashlib,shutil,datetime,os,struct,subprocess
PERSONS=Path(__file__).resolve().parents[1]
ROOT=PERSONS.parent;GAME=ROOT/'game';OUT=Path(__file__).resolve().parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    proof=json.loads((PERSONS/'materiaalcontrole.json').read_text())
    manifest_path=GAME/'assets/manifest.json'
    original=json.loads(manifest_path.read_text());updated=json.loads(json.dumps(original))
    backup=OUT/'previous-game-assets';backup.mkdir(exist_ok=False)
    shutil.copy2(manifest_path,backup/'manifest.json')
    receipt={'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'backup':str(backup),'assets':{},'protected_work':{}}
    changed=subprocess.check_output(['git','-C',str(ROOT),'diff','--name-only','-z']).decode().split('\0')
    for name in changed:
        p=ROOT/name
        if name and not name.startswith('persons/') and p.is_file() and name not in ['game/assets/manifest.json','game/assets/models/boaz.glb','game/assets/models/ravi.glb']:
            receipt['protected_work'][name]=sha(p)
    prepared={}
    for name in ['boaz','ravi']:
        source=PERSONS/name/(name+'.glb');assert sha(source)==proof[name]['source_sha256']
        frozen=PERSONS/name/'review-materials-2026-11-21/after'/(name+'.glb')
        if frozen.exists():assert sha(frozen)==sha(source)
        else:shutil.copy2(source,frozen)
        target=GAME/'assets/models'/(name+'.glb');shutil.copy2(target,backup/(name+'.glb'))
        raw=frozen.read_bytes();assert struct.unpack_from('<4sII',raw)==(b'glTF',2,len(raw))
        jsize=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+jsize])
        assert len(doc['images'])==2 and all('bufferView' in image for image in doc['images'])
        updated[name]=dict(original[name],source=str(frozen.relative_to(ROOT)),sha256=sha(frozen),materials=len(doc['materials']),integration_stage='material-refinement-2026-11-21',visual_review='zie persons/ANALYSE-PERSONAGES.md')
        prepared[name]=(frozen,target)
        receipt['assets'][name]={'previous_sha256':sha(target),'new_sha256':sha(frozen),'source':str(frozen.relative_to(ROOT)),'runtime':str(target.relative_to(ROOT))}
    assert {k:v for k,v in original.items() if k not in prepared}=={k:v for k,v in updated.items() if k not in prepared}
    (OUT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
    for frozen,target in prepared.values():
        staged=target.with_suffix('.glb.new');shutil.copy2(frozen,staged);os.replace(staged,target)
    staged=manifest_path.with_suffix('.json.new');staged.write_text(json.dumps(updated,indent=2)+'\n');os.replace(staged,manifest_path)
    for name,(source,target) in prepared.items():assert sha(source)==sha(target)==updated[name]['sha256']
    print('Both character GLBs and their manifest entries updated; all other entries preserved. Previous assets backed up.',flush=True)

if __name__=='__main__':main()
