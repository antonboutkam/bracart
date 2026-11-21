#!/usr/bin/env python3
"""Central entry point for independent BoRacer vehicle workspaces."""
import argparse,os,subprocess,sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
SKILL=ROOT.parents[1]/'.agents/skills/voertuig-pimper/scripts'

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('vehicle');p.add_argument('action',choices=['prepare','audit','build','check','render']);p.add_argument('--asset',type=Path);p.add_argument('--views',default='all');a=p.parse_args()
 if Path(a.vehicle).name!=a.vehicle or a.vehicle in ('.','..'):p.error('Use a vehicle folder name, not a path')
 vehicle=ROOT/'vehicles'/a.vehicle;src=vehicle/'source'
 def run(cmd):subprocess.run([str(x) for x in cmd],check=True,cwd=ROOT)
 blender=[ROOT/'tools/blender.sh','-b','-t',os.environ.get('BORACERT_THREADS','6')]
 if a.action=='prepare':return run([sys.executable,SKILL/'prepare_vehicle.py',a.vehicle,'--workspace',ROOT])
 if not vehicle.is_dir():p.error('Create this workspace with prepare first')
 if a.action=='build':
  script=src/'build_model.py'
  if not script.is_file():p.error('Write a vehicle-specific source/build_model.py first; no default geometry is substituted')
  return run([*blender,'--python',script])
 improved=vehicle/(a.vehicle+'-improved.glb')
 if a.asset:asset=a.asset.expanduser().resolve()
 elif a.action in ['check','render']:asset=improved
 else:
  originals=[f for f in vehicle.glob('*.glb') if not f.stem.endswith('-improved')]
  if len(originals)!=1:p.error('Choose the original GLB with --asset because its filename is ambiguous')
  asset=originals[0]
 if not asset.is_file():p.error(f'GLB not found: {asset}')
 if a.action=='render':return run([*blender,'--python',SKILL/'render_glb.py','--',asset,'--out-dir',vehicle/'previews','--views',a.views])
 report=src/('original-audit.json' if a.action=='audit' else 'generic-validation-report.json')
 cmd=[sys.executable,SKILL/'audit_glb.py',asset,'--report',report]
 if a.action=='check':cmd.append('--strict')
 run(cmd)

if __name__=='__main__':main()
