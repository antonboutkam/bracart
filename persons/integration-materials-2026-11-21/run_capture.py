from pathlib import Path
import os,subprocess,tempfile
OUT=Path(__file__).resolve().parent;GAME=OUT.parents[1]/'game'
with tempfile.TemporaryDirectory(prefix='boracart-capture-') as temp:
    env=dict(os.environ,LIBGL_ALWAYS_SOFTWARE='1')
    for key in ['CACHE','CONFIG','DATA']:env['XDG_'+key+'_HOME']=str(Path(temp)/key.lower())
    with (OUT/'capture.log').open('w') as log:
        result=subprocess.run(['godot','--display-driver','x11','--rendering-driver','opengl3_es','--audio-driver','Dummy','--position','10000,10000','--path',str(GAME),'--script',str(OUT/'capture_game.gd')],env=env,stdout=log,stderr=subprocess.STDOUT,timeout=180)
    print('native capture exit',result.returncode,flush=True)
    raise SystemExit(result.returncode)
