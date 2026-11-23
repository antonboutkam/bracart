"""Run the game's existing GLTF candidate test in an isolated temporary project.

No game assets are synchronized. The Godot test checks import and Kart_Sit;
it does not render images or prove gameplay/framerate/intersection quality.
"""
from pathlib import Path
import os,subprocess,sys,tempfile,json
ROOT=Path(__file__).resolve().parents[1]

def main(names):
    source=(ROOT.parent/'game/tests/character_review.gd').read_text()
    old='ProjectSettings.globalize_path("res://../persons/%s/%s.glb" % [character_id, character_id])'
    assert old in source, 'Game test changed; inspect its candidate path before reuse'
    source=source.replace(old,json.dumps(str(ROOT)+'/%s/%s.glb')+' % [character_id, character_id]')
    with tempfile.TemporaryDirectory(prefix='boracart-godot-') as temp:
        project=Path(temp)
        (project/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Boracart character check"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
        script=project/'character_review.gd';script.write_text(source)
        env=dict(os.environ,XDG_DATA_HOME=str(project/'data'),XDG_CONFIG_HOME=str(project/'config'),XDG_CACHE_HOME=str(project/'cache'))
        for name in names:
            assert name in ['boaz','ravi']
            report=Path('/tmp')/('boracer-'+name+'-review-godot.json')
            if report.exists():report.unlink()
            subprocess.run(['godot','--headless','--path',str(project),'--log-file',str(project/(name+'.log')),'--script',str(script),'--',name],env=env,check=True,timeout=90)
            data=json.loads(report.read_text())
            assert data['runtime_import']=='passed' and not data['failures']
            out=ROOT/name/'review-materials-2026-11-21'/'godot-validation.json'
            out.parent.mkdir(exist_ok=True);out.write_text(json.dumps(data,indent=2)+'\n')
            print(name, data['checks'], 'Godot checks passed',flush=True)

if __name__=='__main__':main(sys.argv[1:] or ['boaz','ravi'])
