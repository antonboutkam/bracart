from pathlib import Path
import os,subprocess,tempfile,json
OUT=Path(__file__).resolve().parent
GAME=OUT.parents[1]/'game'
with tempfile.TemporaryDirectory(prefix='boracart-integrated-') as temp:
    env=dict(os.environ)
    for key in ['CACHE','CONFIG','DATA']:env['XDG_'+key+'_HOME']=str(Path(temp)/key.lower())
    commands=[('import',['--headless','--path',str(GAME),'--import','--quiet']),
        ('game-materials',['--headless','--path',str(GAME),'--script',str(OUT/'check_game_materials.gd')])]
    for test in ['kart_visuals','driver_reactions','garage_presentation','follow_camera','smoke']:
        commands.append((test,['--headless','--audio-driver','Dummy','--path',str(GAME),'--script','res://tests/'+test+'.gd']))
    result={}
    for name,args in commands:
        with (OUT/(name+'.log')).open('w') as log:
            done=subprocess.run(['godot',*args],env=env,stdout=log,stderr=subprocess.STDOUT,timeout=240)
        result[name]={'exit_code':done.returncode,'log':name+'.log'}
        (OUT/'check-results.json').write_text(json.dumps(result,indent=2)+'\n')
        print(name,done.returncode,flush=True)
        if done.returncode:raise SystemExit(done.returncode)
