#!/usr/bin/env python3
"""Install this prepared boracart patch; stop before writing if existing file contents differ."""
import argparse,hashlib,json,shutil
from pathlib import Path

HERE=Path(__file__).resolve().parent

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--destination',type=Path,default=Path('~/Documents/sites/boracart'))
 p.add_argument('--dry-run',action='store_true');a=p.parse_args()
 source=HERE/'boracart';dest=a.destination.expanduser().resolve()
 manifest=json.loads((HERE/'manifest.json').read_text())
 files=[];new=0;unchanged=0
 for rel,expected in manifest['files'].items():
  src=source/rel;target=dest/rel
  if not src.is_file() or sha(src)!=expected:p.exit(1,f'Package file changed or missing: {rel}\n')
  if target.exists():
   if not target.is_file() or sha(target)!=expected:p.exit(1,f'Existing file differs; nothing copied: {target}\n')
   unchanged+=1
  else:new+=1
  parent=target.parent
  while parent!=dest.parent:
   if parent.exists() and not parent.is_dir():p.exit(1,f'Parent path is not a directory: {parent}\n')
   if parent==dest:break
   parent=parent.parent
  files.append((src,target))
 print(f'Destination: {dest}\nNew files: {new}; identical files retained: {unchanged}')
 if a.dry_run:
  print('Dry run passed; no files written.');return
 try:
  for src,target in files:
   if not target.exists():target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,target)
 except OSError as e:p.exit(1,f'Installation stopped: {e}\nRun this script from a terminal with write access to the destination.\n')
 for src,target in files:
  if sha(src)!=sha(target):p.exit(1,f'Copy verification failed: {target}\n')
 print(f'Installed and checksum-verified {len(files)} files.')
 print(f'Workspace: {dest}/public_html/boracert')
 print(f'Skill: {dest}/.agents/skills/voertuig-pimper/SKILL.md')
 print('Original game files retained; no files deleted.')

if __name__=='__main__':main()
