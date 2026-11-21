#!/usr/bin/env python3
"""Rebuild source-derived vehicle loops, measurement evidence and offline review.
Requires local ffmpeg/ffprobe, numpy, scipy and Pillow. No network or source writes.
"""
import argparse
import hashlib
import json
import math
import re
from pathlib import Path
import subprocess
import wave
from render_commands import add_commands

import numpy as np
import scipy
from scipy import signal
from PIL import Image, ImageDraw

GAME = Path(__file__).resolve().parents[1]
ROOT = GAME.parent
SOURCE = ROOT / 'assets/audio/raviracer.mp3'
OUT = GAME / 'assets/audio/vehicles'
REVIEW = ROOT / 'renders/GAME-10001/audio'
RATE = 44100
# Segments are inside the long, continuous harmonic source passage. Avoid the
# opening transient, silences and later irregular/voice-like passages.
RECIPES = {
    'idle': {'start_seconds': 3.60, 'end_seconds': 4.45, 'playback_rate': 0.80},
    'drive': {'start_seconds': 1.85, 'end_seconds': 2.85, 'playback_rate': 1.00},
    'boost': {'start_seconds': 5.18, 'end_seconds': 6.13, 'playback_rate': 1.12},
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def db(value):
    return round(20 * math.log10(max(float(value), 1e-12)), 4)


def write_wav(path, samples):
    pcm = np.round(np.clip(samples, -1, 1) * 32767).astype('<i2')
    with wave.open(str(path), 'wb') as handle:
        handle.setparams((1, 2, RATE, len(pcm), 'NONE', 'not compressed'))
        handle.writeframes(pcm.tobytes())
    return pcm.astype(np.float64) / 32768


def measure(samples):
    derivative = np.abs(np.diff(samples))
    upsampled = signal.resample_poly(np.tile(samples, 3), 4, 1)
    central = upsampled[4*len(samples):8*len(samples)]
    corr = signal.correlate(samples[:min(len(samples), RATE//4)], samples[:min(len(samples), RATE//4)], mode='full', method='fft')
    corr = corr[len(corr)//2:]
    lo, hi = RATE//750, RATE//65
    peaks, _ = signal.find_peaks(corr[lo:hi])
    lag = lo + int(peaks[np.argmax(corr[lo:hi][peaks])]) if len(peaks) else lo
    jump = abs(samples[-1] - samples[0])
    return {
        'samples': len(samples), 'seconds': round(len(samples)/RATE, 6),
        'sample_peak_dbfs': db(np.max(np.abs(samples))),
        'estimated_4x_true_peak_dbfs': db(np.max(np.abs(central))),
        'rms_dbfs': db(np.sqrt(np.mean(samples**2))),
        'dc_offset': float(np.mean(samples)),
        'clipped_samples': int(np.count_nonzero(np.abs(samples) >= 32767/32768)),
        'boundary_jump_linear': float(jump),
        'interior_derivative_p99_linear': float(np.quantile(derivative, .99)),
        'boundary_below_interior_p99': bool(jump <= np.quantile(derivative, .99)),
        'autocorrelation_fundamental_candidate_hz': round(RATE / lag, 3),
        'fundamental_note': 'Autocorrelation candidate only; changing vocal harmonics are not a fixed engine RPM.',
    }


def make_loop(source, recipe):
    start, end = round(recipe['start_seconds']*RATE), round(recipe['end_seconds']*RATE)
    x = source[start:end].astype(np.float64)
    x -= np.mean(x)
    # Zero-phase filters avoid shifting the source attacks into the cut seam.
    x = signal.sosfiltfilt(signal.butter(3, 90, 'highpass', fs=RATE, output='sos'), x)
    x = signal.sosfiltfilt(signal.butter(4, 4500, 'lowpass', fs=RATE, output='sos'), x)
    rate = recipe['playback_rate']
    x = signal.resample_poly(x, 100, round(rate*100))
    fade = round(.080*RATE)
    phase = np.linspace(0, math.pi, fade)
    head_weight = .5-.5*np.cos(phase)
    # Complementary raised-cosine weights sum to one: no equal-power coherent
    # signal gain bump. The output wrap is an unmodified adjacent source pair.
    join = x[-fade:]*(1-head_weight)+x[:fade]*head_weight
    x = np.concatenate((x[fade:-fade], join))
    x -= np.mean(x)
    gain = min(.19 / np.sqrt(np.mean(x*x)), 10**(-2/20)/max(abs(x)))
    x *= gain
    return x, {'source_first_sample': start, 'source_end_sample_exclusive': end,
               'crossfade_samples': fade, 'crossfade_seconds': .080,
               'crossfade_shape': 'complementary raised cosine; overlap removed',
               'gain_linear': float(gain), 'pitch_semitones': round(12*math.log2(rate), 4)}


def draw_analysis(source, path):
    width, height = 1500, 860
    picture = Image.new('RGB', (width, height), '#101824')
    draw = ImageDraw.Draw(picture)
    duration = len(source)/RATE
    draw.text((20, 12), 'raviracer.mp3: decoded waveform + linear-frequency STFT 50-5000 Hz', fill='white')
    colors = {'idle':'#a3c7fa', 'drive':'#efc356', 'boost':'#f597b2'}
    for name, recipe in RECIPES.items():
        xa, xb = [20+int(recipe[k]/duration*1460) for k in ['start_seconds', 'end_seconds']]
        draw.rectangle((xa, 45, xb, 325), fill=colors[name])
        draw.text((xa, 46), name, fill='black')
    for col in range(1460):
        part = source[int(col*len(source)/1460):int((col+1)*len(source)/1460)]
        draw.line((20+col,190-int(max(part)*150),20+col,190-int(min(part)*150)),fill='#1771a1')
    f, _, z = signal.stft(source, RATE, nperseg=2048, noverlap=1536)
    z = 20*np.log10(np.abs(z[(f>=50)&(f<=5000)])+1e-7)
    z = np.clip((z+80)/65,0,1)
    rgb = np.stack([255*z,255*z*z,255*np.sqrt(z)],axis=-1).astype('uint8')
    picture.paste(Image.fromarray(rgb[::-1]).resize((1460,400)), (20,350))
    for second in range(math.ceil(duration)):
        draw.text((20+int(second/duration*1460),770),str(second)+'s', fill='white')
    draw.text((20,805),'Numerical/visual analysis only. No auditory review performed in this environment.', fill='white')
    picture.save(path)


def make_demo(loops):
    n = RATE*12
    t = np.arange(n)/RATE
    speed = np.clip((t-1)/5,0,1)*np.clip((11-t)/3,0,1)
    boost = np.minimum(np.clip((t-6)/.3,0,1),np.clip((8.2-t)/.3,0,1))
    idle_weight = (1-speed)*(1-boost)
    drive_weight = speed*(1-boost)
    weights = {'idle': idle_weight, 'drive': drive_weight, 'boost': boost}
    demo = np.zeros(n)
    for name, loop in loops.items():
        pitch = .9+.22*speed
        positions = np.cumsum(pitch)
        indices = np.mod(positions,len(loop))
        samples = np.interp(indices,np.arange(len(loop)+1),np.r_[loop,loop[0]])
        demo += samples*weights[name]
    ramp = np.minimum(np.clip(t/.1,0,1),np.clip((12-t)/.1,0,1))
    return demo*ramp*.85


def main():
    argparse.ArgumentParser(description=__doc__).parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    source_hash = sha(SOURCE)
    probe = json.loads(subprocess.check_output(['ffprobe','-v','error','-show_format','-show_streams','-of','json',str(SOURCE)]))
    decoded = subprocess.run(['ffmpeg','-v','warning','-i',str(SOURCE),'-f','f32le','-ac','1','-ar',str(RATE),'-'], capture_output=True, check=True)
    source = np.frombuffer(decoded.stdout,dtype='<f4').astype(np.float64)
    loops, assets = {}, {}
    for name, recipe in RECIPES.items():
        samples, processing = make_loop(source,recipe)
        path = OUT/(name+'.wav')
        loops[name] = write_wav(path,samples)
        metrics = measure(loops[name])
        assert metrics['sample_peak_dbfs'] <= -1
        assert metrics['estimated_4x_true_peak_dbfs'] <= -1
        assert metrics['clipped_samples'] == 0
        assert metrics['boundary_below_interior_p99']
        assets[name] = {'file':name+'.wav','sha256':sha(path),'recipe':recipe,'processing':processing,'measurements':metrics,
                        'godot':{'loop_begin':0,'loop_end':len(samples),'loop_mode':'forward'}}
    draw_analysis(source, REVIEW/'source-analysis.png')
    write_wav(REVIEW/'acceleration-preview.wav',make_demo(loops))
    manifest = {
        'source':{'path':'../../../../assets/audio/raviracer.mp3','sha256':source_hash,
                  'probe':probe,'decoded_samples':len(source),'decoded_seconds':len(source)/RATE,
                  'decode_warnings':re.sub(r'0x[0-9a-fA-F]+', 'DECODER', decoded.stderr.decode()).replace(str(SOURCE),'raviracer.mp3'),
                  'original_bytes_unchanged':sha(SOURCE)==source_hash,
                  'sample_peak_dbfs':db(max(abs(source))),
                  'rms_dbfs':db(np.sqrt(np.mean(source**2))),
                  'dc_offset':float(np.mean(source)),
                  'near_silent_samples_below_minus50db_percent':float(np.mean(abs(source)<10**(-50/20))*100)},
        'format':{'channels':1,'sample_rate_hz':RATE,'pcm_bits':16},
        'filter_chain':['source segment','remove DC','zero-phase Butterworth highpass90Hz order3',
                        'zero-phase Butterworth lowpass4500Hz order4','polyphase resampling for mild pitch/rate',
                        '80ms complementary raised-cosine periodic overlap','remove DC','RMS target0.19 capped at -2dBFS peak','PCM16 quantization'],
        'assets':assets,
        'tools':{'ffmpeg':subprocess.check_output(['ffmpeg','-version']).decode().splitlines()[0],
                 'numpy':np.__version__,'scipy':scipy.__version__,'builder_sha256':sha(Path(__file__))},
        'review':{'auditory_review_performed':False,'reason':'No direct audio listening channel available to this agent.',
                  'preview':'Offline acceleration/crossfade illustration; not captured game audio.',
                  'estimated_true_peak_note':'4x polyphase estimate, not a certified intersample peak meter.',
                  'selection_note':'Selected continuous harmonic portions using waveform and STFT; no semantic speech-removal guarantee without listening.',
                  'engine_pitch_recommendation':[.8,1.2],'engine_headroom_note':'Keep player engine below cues; attenuate spatial AI and limit voices. Assets alone do not guarantee mix headroom.'}
    }
    assert sha(SOURCE) == source_hash, 'Original source changed during build'
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    html = '''<!doctype html><html lang="nl"><meta charset="utf-8"><title>RaviRacer voertuiggeluid</title><style>body{font:18px system-ui;background:#101824;color:#ecf4ff;max-width:1000px;margin:40px auto;padding:20px}audio{display:block;width:100%;margin:12px 0 28px}img{width:100%}a{color:#80d7ff}</style><h1>Voertuiggeluid uit RaviRacer</h1><p>Bronbestand ongewijzigd. Drie gefilterde bronfragmenten met vloeiende loopovergangen. Dit zijn vooraf gemaakte audiovoorbeelden, geen geluidsopname uit de game. Technisch gecontroleerd; nog geen gehoorreview door een mens.</p><h2>Origineel</h2><audio controls preload="none" src="../../../assets/audio/raviracer.mp3"></audio>'''
    for name, label in [('idle','Stationair'),('drive','Rijden'),('boost','Boost')]:
        html += f'<h2>{label}</h2><p>Herhaald afspelen staat aan; browserovergangen zijn niet de sample-nauwkeurige Godot-loop.</p><audio controls loop preload="none" src="../../../game/assets/audio/vehicles/{name}.wav"></audio>'
    html += '<h2>Optrekken en boost — offline voorbeeld, 12 seconden</h2><audio controls preload="none" src="acceleration-preview.wav"></audio><h2>Bronanalyse en gebruikte intervallen</h2><img src="source-analysis.png" alt="Golfvorm en spectrogram met gekozen bronintervallen"><p><a href="../../../game/assets/audio/vehicles/manifest.json">Kniprecepten, meetwaarden en bronhash</a></p></html>'
    (REVIEW/'index.html').write_text(add_commands(html, project='GAME-10001', audio=True))
    print(json.dumps({name:data['measurements'] for name,data in assets.items()},indent=2))


if __name__ == '__main__':
    main()
