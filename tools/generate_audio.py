"""Generate original deterministic PCM ambience, motor and interface feedback."""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / 'assets'
RATE = 22050
rng = random.Random(279)

def save(name, seconds, sample):
    with wave.open(str(ROOT / name), 'wb') as f:
        f.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        data = [max(-1, min(1, sample(i / RATE))) for i in range(int(RATE * seconds))]
        f.writeframes(b''.join(struct.pack('<h', int(x * 24000)) for x in data))

save('city.wav', 8, lambda t: 0.07 * rng.uniform(-1, 1)
     + 0.12 * math.sin(2 * math.pi * 62 * t) * (0.5 + 0.5 * math.sin(2 * math.pi * t / 8))
     + 0.12 * math.sin(2 * math.pi * (1800 * t + 30 * math.sin(2 * math.pi * 4 * t)))
     * max(0, math.sin(2 * math.pi * t / 2)) ** 32)
save('engine.wav', 2, lambda t: 0.3 * math.sin(2 * math.pi * 48 * t)
     + 0.18 * math.sin(2 * math.pi * 96 * t)
     + 0.08 * math.sin(2 * math.pi * 192 * t))
save('click.wav', 0.18, lambda t: 0.4 * math.sin(2 * math.pi * 880 * t) * math.exp(-30 * t))

for name in ['city.wav', 'engine.wav']:
    path = ROOT / (name + '.import')
    # Godot generates this file on first import; loop is applied by runtime too.
print('Generated three original audio files.')
