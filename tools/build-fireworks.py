#!/usr/bin/env python3
"""
Builds the fireworks: a score for every shipped track, and the sounds.

SCORES (shared/fireworks_scores.lua)
Every track in audio/ is synthesized by tools/build-audio.py from note
data, so the notes are known exactly and a firework score can be written
from them instead of guessed from the audio: shells burst ON the melody's
notes. Low notes fire from the left launchers and high notes from the
right; high notes burst higher; long notes are big shells; the first note
of each pass of the melody is a salvo; phrases get cakes, sweeps and
shapes; the last seconds are a finale. Quiet tunes (Silent Night, Taps,
Amazing Grace) get a gentle score of willows and shapes.

Each cue is six numbers: burst time (s), lane (0..1, -1 = every
launcher), height (0..1), size (1..4), kind, priority (1 always, 2 at
normal and heavy intensity, 3 at heavy only). Kinds are
Fireworks.Kind in shared/fireworks.lua.

SOUNDS (audio/sfx/*.ogg)
Launch thump, whistle, rocket, three booms, pop, salute, crackle,
fountain, the countdown tick and the midnight chime. Synthesized here;
nothing is sampled or licensed.

Usage:  python tools/build-fireworks.py           # scores and sounds
        python tools/build-fireworks.py scores    # scores only
        python tools/build-fireworks.py sounds    # sounds only
Needs:  numpy, and ffmpeg on PATH (for the ogg encode).
"""
import importlib.util
import math
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SCORES = os.path.join(ROOT, 'shared', 'fireworks_scores.lua')
SFX = os.path.join(ROOT, 'audio', 'sfx')

spec = importlib.util.spec_from_file_location('build_audio', os.path.join(HERE, 'build-audio.py'))
audio = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audio)
SR = audio.SR

SHELL, SALVO, CAKE, SHAPE, FOUNTAIN, ACCENT, SWEEP = 1, 2, 3, 4, 5, 6, 7

GENTLE = {'silent_night', 'taps', 'amazing_grace', 'nearer_my_god', 'morning_mood', 'easter_bells'}
FADE = 1.6          # the tracks fade over their last 1.5 s; nothing bursts in the fade


# ---------------------------------------------------------------------
# Scores
# ---------------------------------------------------------------------
class Score:
    def __init__(self, duration):
        self.duration = duration
        self.e = []

    def add(self, t, lane, h, size, kind, p):
        if t < 0.3 or t > self.duration - FADE + 0.05:
            return
        lane = -1 if lane < 0 else min(1.0, max(0.0, lane))
        self.e.append((round(t, 3), round(lane, 2), round(min(1.0, max(0.0, h)), 2), int(min(4, max(1, size))), kind, p))


def tune_notes(spec):
    """Every melody note as the renderer lays it out: (t, midi, beats, pass, first, bar_pos)."""
    bpm = spec['bpm']
    beat = 60.0 / bpm
    target = spec['target']
    bar = spec.get('bar', 4)
    transpose = spec.get('transpose', 0)
    melody = audio.parse_melody(spec['melody'])
    out = []
    t, pas = 0.0, 0
    while t < target:
        tt, first = t, True
        for m, d in melody:
            if m is not None:
                pos = ((tt - t) / beat) % bar
                out.append(dict(t=tt, m=m + transpose, d=d, pas=pas, first=first, down=abs(pos) < 1e-6 or abs(pos - bar) < 1e-6))
                first = False
            tt += d * beat
        t = tt
        pas += 1
    return out, beat, bar


def finale_window(duration, gentle):
    secs = 8.0 if gentle else min(15.0, max(7.0, duration * 0.18))
    end = duration - FADE
    return end - secs, end


def score_tune(name, spec):
    notes, beat, bar = tune_notes(spec)
    target = spec['target']
    gentle = name in GENTLE
    s = Score(target)
    ms = [n['m'] for n in notes]
    lo, hi = min(ms), max(ms)
    span = max(1, hi - lo)
    f0, f1 = finale_window(target, gentle)
    rnd = np.random.default_rng(sum(map(ord, name)))      # the same score on every run

    last_t = -10.0
    bars_seen = set()
    for i, n in enumerate(notes):
        t, d = n['t'], n['d']
        ds = d * beat
        x = (n['m'] - lo) / span
        lane = 0.08 + 0.84 * x
        h = 0.25 + 0.7 * x
        size = 4 if ds >= 1.6 else 3 if ds >= 0.9 else 2 if ds >= 0.45 else 1
        if t >= f0:
            continue
        bar_no = int(round(t / (bar * beat), 6))

        if gentle:
            if d >= 2:
                s.add(t, lane, h, min(4, size + 1), SHELL, 1)
            elif d >= 1 and n['down']:
                s.add(t, lane, h, size + 1, SHELL, 2)
            elif d >= 1:
                s.add(t, lane, h, size, SHELL, 3)
        else:
            if ds >= 0.9 or (n['down'] and d >= 1):
                p = 1
            elif d >= 1 or n['down']:
                p = 2
            else:
                p = 3
            # Never two "always" cues closer than a quarter second: the
            # light intensity is meant to be light.
            if p == 1 and t - last_t < 0.25:
                p = 2
            if p == 1:
                last_t = t
            # The top of a phrase: the highest long note of its bar.
            kind = SHELL
            if d >= 1.5 and x >= 0.75:
                kind = ACCENT
            s.add(t, lane, h, size, kind, p)
            # Long notes get a second, lower shell from the other side.
            if ds >= 1.2:
                s.add(t, 1.0 - lane, h * 0.6, max(1, size - 1), SHELL, 2)

        if n['first']:
            if gentle:
                s.add(t, 0.5, 1.0, 4, SHAPE, 1)
            elif n['pas'] == 0:
                s.add(t, -1, 0.0, 3, FOUNTAIN, 1)
            else:
                s.add(t, -1, 0.8, 3, SALVO, 1)
                s.add(t, -1, 0.0, 2, FOUNTAIN, 2)
        if n['down'] and bar_no not in bars_seen:
            bars_seen.add(bar_no)
            if not gentle:
                if bar_no % 8 == 4:
                    s.add(t, rnd.random(), 0.5, 2, CAKE, 2)
                if bar_no % 16 == 12:
                    s.add(t, 0.5, 1.0, 4, SHAPE, 1)
                if bar_no % 8 == 6:
                    s.add(t, -1, 0.4, 2, SWEEP, 2)
                if bar_no % 16 == 2:
                    s.add(t, -1, 0.0, 2, FOUNTAIN, 3)
            elif bar_no % 8 == 4:
                s.add(t, 0.5, 0.9, 4, SHELL, 2)

    # The finale, on the melody's own notes in the window.
    fin = [n for n in notes if f0 <= n['t'] < f1 - 0.3]
    for j, n in enumerate(fin):
        x = (n['m'] - lo) / span
        if gentle:
            if n['d'] >= 1:
                s.add(n['t'], 0.1 + 0.8 * x, 0.6 + 0.4 * x, 4, SHELL, 1)
            continue
        s.add(n['t'], 0.08 + 0.84 * x, 0.4 + 0.6 * x, 3 if n['d'] >= 1 else 2, ACCENT if j % 5 == 4 else SHELL, 1)
        s.add(n['t'], 0.92 - 0.84 * x, 0.3 + 0.4 * rnd.random(), 2, SHELL, 2)
        if j % 3 == 0:
            s.add(n['t'], rnd.random(), 0.7, 3, SHELL, 3)
        if j % 6 == 0:
            s.add(n['t'], rnd.random(), 0.5, 2, CAKE, 2)
    if not gentle:
        s.add(f0, -1, 0.0, 4, FOUNTAIN, 1)
        s.add(f1 - 2 * beat, -1, 0.3, 2, SWEEP, 1)
        s.add(f1 - beat, -1, 0.5, 3, SALVO, 2)
    s.add(f1, -1, 1.0, 4, SALVO, 1)
    s.add(f1, 0.5, 1.0, 4, SHAPE, 2 if gentle else 1)
    return s, ('gentle' if gentle else 'grand')


def score_midnight_chimes(target):
    s = Score(target)
    q = [['E5', 'C5', 'D5', 'G4'], ['G4', 'D5', 'E5', 'C5'], ['E5', 'D5', 'C5', 'G4'], ['G4', 'C5', 'D5', 'E5']]
    lo, hi = audio.midi('G4'), audio.midi('E5')
    t = 0.5
    for pi, phrase in enumerate(q):
        for k, n in enumerate(phrase):
            x = (audio.midi(n) - lo) / (hi - lo)
            s.add(t, 0.1 + 0.8 * x, 0.3 + 0.6 * x, 2, SHELL, 1)
            if k == 3:
                s.add(t, 0.9 - 0.8 * x, 0.6, 3, ACCENT, 2)
            t += 0.75
        t += 0.9
    t += 1.5
    s.add(t - 1.0, -1, 0.0, 2, FOUNTAIN, 2)
    for i in range(12):
        lane = 0.15 if i % 2 == 0 else 0.85
        s.add(t, lane, 0.9, 4, SHELL, 1)
        s.add(t, 0.5, 0.6, 3, SHELL, 2)
        if i % 4 == 3 and i < 11:
            s.add(t, -1, 0.7, 3, SALVO, 1)
        if i % 3 == 1:
            s.add(t + 1.1, 1 - lane, 0.5, 2, SHELL, 3)
        if i == 11:
            # Midnight.
            s.add(t, -1, 1.0, 4, SALVO, 1)
            s.add(t, 0.5, 1.0, 4, SHAPE, 1)
            s.add(t, -1, 0.0, 4, FOUNTAIN, 1)
            end = target - FADE
            k, tt = 0, t + 0.5
            while tt < end - 0.2:
                s.add(tt, (k * 0.37) % 1.0, 0.4 + (k % 3) * 0.25, 2 + k % 3, ACCENT if k % 4 == 3 else SHELL, 1)
                s.add(tt + 0.25, 1 - (k * 0.37) % 1.0, 0.3, 2, SHELL, 2)
                k += 1
                tt += 0.5
            s.add(end, -1, 1.0, 4, SALVO, 1)
        t += 2.2
    return s, 'grand'


def score_easter_bells(target):
    s = Score(target)
    rng = np.random.default_rng(7)
    scale = [audio.midi(n) for n in ['C5', 'D5', 'E5', 'G5', 'A5', 'C6', 'D6', 'E6']]
    lo, hi = scale[0], scale[-1]
    beat = 60.0 / 90
    f0, f1 = finale_window(target, True)
    t, b = 0.0, 0
    while t < target:
        for k in range(4):
            n = scale[int(rng.integers(0, len(scale)))]
            x = (n - lo) / (hi - lo)
            if t < f0 and k == 0 and b % 2 == 0:
                s.add(t, 0.1 + 0.8 * x, 0.3 + 0.6 * x, 3, SHELL, 1)
            elif t < f0 and k == 2:
                s.add(t + k * beat * 0.5, 0.1 + 0.8 * x, 0.3 + 0.6 * x, 2, SHELL, 3)
        if b % 8 == 7 and t < f0:
            s.add(t, 0.5, 1.0, 4, SHAPE, 1)
        if b % 16 == 0 and t < f0:
            s.add(t, -1, 0.0, 2, FOUNTAIN, 2)
        t += beat
        b += 1
    k, tt = 0, f0
    while tt < f1 - 0.3:
        s.add(tt, (k * 0.29) % 1.0, 0.7, 4, SHELL, 1)
        k += 1
        tt += beat * 2
    s.add(f1, -1, 1.0, 4, SALVO, 1)
    return s, 'gentle'


def score_spooky_drone(target):
    s = Score(target)
    for at, _ in [(4, 'Dm'), (12, 'Bb'), (20, 'Dm'), (28, 'A'), (36, 'Dm'), (44, 'Gm'), (52, 'Dm')]:
        s.add(at, 0.2 if at % 8 == 4 else 0.8, 0.8, 4, ACCENT, 1)
        s.add(at + 0.4, 0.5, 0.4, 2, SHELL, 2)
    for at in (9, 25, 41):
        s.add(at, 0.5, 1.0, 4, SHAPE, 1)
    t = 2.0
    k = 0
    while t < target - 10:
        s.add(t, (k * 0.41) % 1.0, 0.5, 1, ACCENT, 2 if k % 2 == 0 else 3)
        k += 1
        t += 2.0
    f0, f1 = finale_window(target, False)
    k, tt = 0, f0
    while tt < f1 - 0.3:
        s.add(tt, (k * 0.37) % 1.0, 0.5 + (k % 2) * 0.4, 3, ACCENT if k % 2 else SHELL, 1)
        k += 1
        tt += 0.9
    s.add(f1, -1, 1.0, 4, SALVO, 1)
    return s, 'grand'


def score_party_loop(target):
    s = Score(target)
    bpm = 124
    beat = 60.0 / bpm
    lead = audio.parse_melody(
        'E5/0.5 G5/0.5 C6/0.5 G5/0.5 E5/0.5 D5/0.5 C5/1 | R/0.5 E5/0.5 G5/0.5 A5/0.5 G5/1 E5/1 | '
        'F5/0.5 A5/0.5 C6/0.5 A5/0.5 F5/0.5 E5/0.5 D5/1 | G5/0.5 B5/0.5 D6/0.5 B5/0.5 G5/1 R/1')
    lo, hi = audio.midi('C5'), audio.midi('D6')
    f0, f1 = finale_window(target, False)
    t, bar_i = 0.0, 0
    while t < f0:
        for k in range(4):
            tk = t + k * beat
            if tk >= f0:
                break
            s.add(tk, 0.15 + 0.7 * ((bar_i * 4 + k) % 5) / 4, 0.3 + 0.2 * (k % 2), 2 if k % 2 == 0 else 1, SHELL, 1 if k % 2 == 0 else 2)
        if bar_i >= 4:
            tt = t
            for m, d in lead:
                if m is not None and tt < f0:
                    x = (m - lo) / (hi - lo)
                    s.add(tt, 0.1 + 0.8 * x, 0.5 + 0.5 * x, 1, SHELL, 3)
                tt += d * beat
        if bar_i % 8 == 7:
            s.add(t, -1, 0.8, 3, SALVO, 1)
        if bar_i % 4 == 2:
            s.add(t, -1, 0.5, 2, SWEEP, 2)
        if bar_i % 4 == 1:
            s.add(t, (bar_i * 0.3) % 1.0, 0.5, 2, CAKE, 2)
        if bar_i % 8 == 4:
            s.add(t, 0.5, 1.0, 4, SHAPE, 1)
        if bar_i % 8 == 0:
            s.add(t, -1, 0.0, 2, FOUNTAIN, 2)
        t += 4 * beat
        bar_i += 1
    k, tt = 0, f0
    while tt < f1 - 0.3:
        s.add(tt, (k * 0.37) % 1.0, 0.4 + (k % 3) * 0.25, 2 + k % 3, ACCENT if k % 5 == 4 else SHELL, 1)
        s.add(tt + beat * 0.5, 1 - (k * 0.37) % 1.0, 0.3, 2, SHELL, 2)
        k += 1
        tt += beat
    s.add(f0, -1, 0.0, 4, FOUNTAIN, 1)
    s.add(f1 - beat, -1, 0.4, 3, SWEEP, 1)
    s.add(f1, -1, 1.0, 4, SALVO, 1)
    return s, 'grand'


PROCEDURAL = {
    'midnight_chimes': score_midnight_chimes,
    'easter_bells': score_easter_bells,
    'spooky_drone': score_spooky_drone,
    'party_loop': score_party_loop,
}


def build_scores():
    tracks = {}
    for name, spec in audio.TUNES.items():
        s, style = score_tune(name, spec)
        tracks[name] = (s, style, spec['bpm'])
    for name, (fn, target) in audio.PROCEDURAL.items():
        s, style = PROCEDURAL[name](target)
        bpm = {'midnight_chimes': 60, 'easter_bells': 90, 'spooky_drone': 60, 'party_loop': 124}[name]
        tracks[name] = (s, style, bpm)

    lines = [
        '-- Generated by tools/build-fireworks.py from the notes in tools/build-audio.py.',
        '-- Do not edit by hand: change the generator and run it again.',
        '-- Each cue is six numbers: burst time (s), lane (0..1, -1 every launcher),',
        '-- height (0..1), size (1..4), kind (Fireworks.Kind), priority (1..3).',
        'FireworkScores = {',
    ]
    for name in sorted(tracks):
        s, style, bpm = tracks[name]
        s.e.sort()
        lines.append(f"    {name} = {{ duration = {s.duration}, bpm = {bpm}, style = '{style}', e = {{")
        row = []
        for i, (t, lane, h, size, kind, p) in enumerate(s.e):
            row.append(f'{t:g},{lane:g},{h:g},{size},{kind},{p}')
            if len(row) == 6:
                lines.append('        ' + ', '.join(row) + ',')
                row = []
        if row:
            lines.append('        ' + ', '.join(row) + ',')
        lines.append('    } },')
        counts = [sum(1 for e in s.e if e[5] <= k) for k in (1, 2, 3)]
        print(f'{name:24s} {style:6s} light {counts[0]:4d}  normal {counts[1]:4d}  heavy {counts[2]:4d}')
    lines.append('}')
    with open(SCORES, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(lines) + '\n')
    print('wrote', os.path.relpath(SCORES, ROOT))


# ---------------------------------------------------------------------
# Sounds
# ---------------------------------------------------------------------
RNG = np.random.default_rng(2026)


def lowpass(x, cutoff):
    """One-pole low-pass; cutoff in Hz (a number or a per-sample array)."""
    cutoff = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    a = 1.0 - np.exp(-2.0 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc)
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def noise(secs):
    return RNG.standard_normal(int(round(SR * secs)))


def env_exp(n, tau, attack=0.002):
    t = np.arange(n) / SR
    return np.minimum(1.0, t / max(attack, 1e-4)) * np.exp(-t / tau)


def tail(secs, tau, cutoff):
    """A rumbling reverb tail: low-passed noise decaying away."""
    n = int(round(SR * secs))
    return lowpass(noise(secs), cutoff) * env_exp(n, tau, 0.01)


def thump(secs, f0, f1, tau):
    n = int(round(SR * secs))
    t = np.arange(n) / SR
    f = f1 + (f0 - f1) * np.exp(-t * 14)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env_exp(n, tau, 0.001)


def pad(x, secs):
    n = int(round(SR * secs))
    out = np.zeros(max(n, len(x)))
    out[:len(x)] = x
    return out


def snd_launch():
    x = pad(thump(0.5, 110, 38, 0.09), 0.7)
    x[:int(round(SR * 0.08))] += lowpass(noise(0.08), 1800) * env_exp(int(round(SR * 0.08)), 0.02) * 0.8
    x += pad(tail(0.6, 0.15, 500), 0.7) * 0.25
    return x


def snd_whistle():
    secs = 1.7
    n = int(round(SR * secs))
    t = np.arange(n) / SR
    f = 950 + 1500 * (t / secs) ** 0.8 + 25 * np.sin(2 * np.pi * 7 * t)
    w = np.sin(2 * np.pi * np.cumsum(f) / SR)
    e = np.minimum(1.0, t / 0.15) * np.minimum(1.0, (secs - t) / 0.25)
    return (w * 0.35 + highpass(noise(secs), 3000) * 0.05) * e


def snd_rocket():
    secs = 1.5
    n = int(round(SR * secs))
    t = np.arange(n) / SR
    cut = 600 + 3500 * (t / secs)
    w = lowpass(noise(secs), cut) * 1.6
    e = np.minimum(1.0, t / 0.05) * np.exp(-t * 0.6) * np.minimum(1.0, (secs - t) / 0.2)
    return w * e


def snd_boom(body=1.0, length=2.4, bright=2400, low=48):
    x = pad(thump(0.9, 120, low, 0.25 * body), length)
    crack = highpass(noise(0.05), 300) * env_exp(int(round(SR * 0.05)), 0.012, 0.0005)
    x[:len(crack)] += lowpass(crack, bright) * 1.4
    x += pad(tail(length, 0.55 * body, 380), length) * 0.9
    x += pad(tail(length * 0.7, 0.3, 1400), length) * 0.2
    return x


def snd_pop():
    x = pad(thump(0.3, 220, 90, 0.05), 0.9)
    x[:int(round(SR * 0.03))] += highpass(noise(0.03), 800) * env_exp(int(round(SR * 0.03)), 0.006, 0.0003) * 1.2
    x += pad(tail(0.9, 0.2, 900), 0.9) * 0.4
    return x


def snd_salute():
    x = pad(highpass(noise(0.04), 200) * env_exp(int(round(SR * 0.04)), 0.008, 0.0002) * 2.0, 1.6)
    x += pad(thump(0.5, 160, 60, 0.08), 1.6) * 0.9
    x += pad(tail(1.6, 0.4, 2600), 1.6) * 0.45
    return x


def snd_crackle():
    secs = 1.8
    n = int(round(SR * secs))
    x = np.zeros(n)
    t = 0.0
    while t < secs - 0.02:
        rate = 70 * math.exp(-t * 1.2)
        t += RNG.exponential(1.0 / max(rate, 4))
        i = int(t * SR)
        if i >= n - 400:
            break
        k = int(round(SR * 0.004))
        click = highpass(RNG.standard_normal(k), 1500) * env_exp(k, 0.001, 0.0001)
        x[i:i + k] += click * (0.6 + RNG.random() * 0.8) * math.exp(-t * 0.6)
    return x


def snd_fountain():
    secs = 3.2
    n = int(round(SR * secs))
    t = np.arange(n) / SR
    w = highpass(noise(secs), 1800) * (0.7 + 0.3 * np.sin(2 * np.pi * 9 * t) * RNG.random())
    w += snd_crackle_like(secs) * 0.4
    e = np.minimum(1.0, t / 0.2) * np.minimum(1.0, (secs - t) / 0.4)
    return w * e * 0.5


def snd_crackle_like(secs):
    n = int(round(SR * secs))
    x = np.zeros(n)
    for _ in range(int(secs * 40)):
        i = int(RNG.random() * (n - 200))
        x[i:i + 120] += highpass(RNG.standard_normal(120), 2500) * env_exp(120, 0.0008, 0.0001)
    return x


def snd_tick():
    n = int(round(SR * 0.12))
    t = np.arange(n) / SR
    w = np.sin(2 * np.pi * 1800 * t) * 0.6 + np.sin(2 * np.pi * 2700 * t) * 0.3
    return w * env_exp(n, 0.02, 0.0005)


def snd_chime():
    secs = 2.6
    n = int(round(SR * secs))
    t = np.arange(n) / SR
    w = np.zeros(n)
    for m in (audio.midi('C5'), audio.midi('E5'), audio.midi('G5'), audio.midi('C6')):
        f = audio.freq(m)
        w += (np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 2.0 * t) + 0.15 * np.sin(2 * np.pi * f * 3.0 * t))
    return w * env_exp(n, 0.9, 0.003) * 0.3


SOUNDS = {
    'launch': snd_launch,
    'whistle': snd_whistle,
    'rocket': snd_rocket,
    'boom': lambda: snd_boom(1.0, 2.4, 2400, 48),
    'boom_big': lambda: snd_boom(1.5, 3.2, 1800, 40),
    'boom_soft': lambda: lowpass(snd_boom(1.2, 2.8, 900, 44), 1600) * 1.2,
    'pop': snd_pop,
    'salute': snd_salute,
    'crackle': snd_crackle,
    'fountain': snd_fountain,
    'tick': snd_tick,
    'chime': snd_chime,
}


def write_ogg(name, buf):
    buf = buf / (np.max(np.abs(buf)) or 1.0) * 0.9
    m = int(round(SR * 0.004))
    buf[-m:] *= np.linspace(1.0, 0.0, m)
    os.makedirs(SFX, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, name + '.wav')
        with wave.open(wav, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes((buf * 32767).astype('<i2').tobytes())
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'libvorbis', '-q:a', '4',
                        os.path.join(SFX, name + '.ogg')], check=True)


def build_sounds():
    for name, fn in SOUNDS.items():
        buf = fn()
        write_ogg(name, buf)
        size = os.path.getsize(os.path.join(SFX, name + '.ogg')) // 1024
        print(f'sfx {name:10s} {len(buf) / SR:4.1f}s {size:4d} KB')


def main():
    what = sys.argv[1:] or ['scores', 'sounds']
    if 'scores' in what:
        build_scores()
    if 'sounds' in what:
        build_sounds()


if __name__ == '__main__':
    main()
