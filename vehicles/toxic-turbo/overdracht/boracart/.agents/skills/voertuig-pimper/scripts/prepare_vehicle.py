#!/usr/bin/env python3
"""Copy a vehicle into the central workshop without overwriting different files."""
import argparse,hashlib,json,os,shutil
from pathlib import Path

def digest(p):return hashlib.sha256(p.read_bytes()).digest()

def main():
    root=Path(__file__).resolve().parents[4]
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('vehicle');p.add_argument('--workspace',type=Path,default=root/'public_html/boracert');p.add_argument('--dry-run',action='store_true');a=p.parse_args()
    source=Path(a.vehicle).expanduser()
    if not source.is_dir():source=root/'public_html/boracer/vehicles'/a.vehicle
    source=source.resolve();dest=a.workspace.expanduser().resolve()/'vehicles'/source.name
    if not source.is_dir():p.exit(1,f'Vehicle folder not found: {source}\n')
    if source==dest or source in dest.parents:p.exit(1,'Choose a separate source and workspace folder.\n')
    ignored={'.git','__pycache__','node_modules','overdracht','.venv'}
    files=[f for f in source.rglob('*') if f.is_file() and not any(x in ignored for x in f.relative_to(source).parts)]
    if not any(f.suffix.lower()=='.glb' for f in files):p.exit(1,'No GLB found in vehicle folder.\n')
    for src in files:
        out=dest/src.relative_to(source)
        if out.exists() and (not out.is_file() or digest(src)!=digest(out)):p.exit(1,f'Different existing file; nothing copied: {out}\n')
    print(f'{source}\n-> {dest}\n{len(files)} input files')
    if a.dry_run:return
    for src in files:
        out=dest/src.relative_to(source)
        if not out.exists():out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,out)
    meta=dest/'vehicle-workspace.json'
    if not meta.exists():meta.write_text(json.dumps({'id':source.name,'input_directory':os.path.relpath(source,dest),'improved_glb':source.name+'-improved.glb'},indent=2)+'\n')
    print('Workspace ready; originals preserved.')

if __name__=='__main__':main()
