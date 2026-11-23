from pathlib import Path
import json,os,subprocess,tempfile
OUT=Path(__file__).resolve().parent;GAME=OUT.parents[1]/'game'
result=json.loads((OUT/'check-results.json').read_text())
with tempfile.TemporaryDirectory(prefix='boracart-finish-') as temp:
    env=dict(os.environ)
    for key in ['CACHE','CONFIG','DATA']:env['XDG_'+key+'_HOME']=str(Path(temp)/key.lower())
    cases=[('garage_current_catalog',str(OUT/'garage_current_catalog.gd')),('follow_camera','res://tests/follow_camera.gd'),('smoke','res://tests/smoke.gd')]
    for name,script in cases:
        with (OUT/(name+'.log')).open('w') as log:done=subprocess.run(['godot','--headless','--audio-driver','Dummy','--path',str(GAME),'--script',script],env=env,stdout=log,stderr=subprocess.STDOUT,timeout=240)
        result[name]={'exit_code':done.returncode,'log':name+'.log'};(OUT/'check-results.json').write_text(json.dumps(result,indent=2)+'\n')
        print(name,done.returncode,flush=True)
        if done.returncode:raise SystemExit(done.returncode)
