#!/usr/bin/env python3
"""
Builds every track in audio/ from scratch.

Nothing here is sampled or licensed from anyone. The melodies marked
"traditional" are public domain (all published before 1929 or never under
copyright); the rest are original. The arrangements are synthesized: a
bell voice for carols, a chip voice for the lively ones, a bass line on
the chord roots, and a light percussion tick where it suits.

Usage:  python tools/build-audio.py            # writes audio/*.ogg
        python tools/build-audio.py jingle_bells  # one track
Needs:  numpy, and ffmpeg on PATH (for the ogg encode).
"""
import math
import os
import subprocess
import sys
import wave
import tempfile

import numpy as np

SR = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), 'audio')

NOTE_INDEX = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}


def midi(name):
    """'C#4' -> midi number."""
    i = 0
    n = NOTE_INDEX[name[0].upper()]
    i = 1
    if i < len(name) and name[i] in '#b':
        n += 1 if name[i] == '#' else -1
        i += 1
    octave = int(name[i:])
    return 12 * (octave + 1) + n


def freq(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


# ---------------------------------------------------------------------
# Voices
# ---------------------------------------------------------------------
def env_pluck(n, attack=0.004, tau=0.35):
    t = np.arange(n) / SR
    a = np.minimum(1.0, t / attack)
    return a * np.exp(-t / tau)


def env_adsr(n, a=0.01, d=0.08, s=0.7, r=0.08):
    t = np.arange(n) / SR
    total = n / SR
    out = np.ones(n) * s
    out[t < a] = t[t < a] / a
    dm = (t >= a) & (t < a + d)
    out[dm] = 1.0 - (1.0 - s) * (t[dm] - a) / d
    rm = t > total - r
    out[rm] *= np.maximum(0.0, (total - t[rm]) / r)
    return out


def voice_bell(f, dur):
    n = int(SR * (dur + 0.6))
    t = np.arange(n) / SR
    w = (np.sin(2 * np.pi * f * t) * 1.0
         + np.sin(2 * np.pi * f * 2.0 * t) * 0.45
         + np.sin(2 * np.pi * f * 3.0 * t) * 0.2
         + np.sin(2 * np.pi * f * 5.4 * t) * 0.08)
    return w * env_pluck(n, tau=min(0.9, 0.25 + dur * 0.5)) * 0.5


def voice_chip(f, dur):
    n = int(SR * dur)
    t = np.arange(n) / SR
    sq = np.sign(np.sin(2 * np.pi * f * t))
    tri = 2.0 * np.abs(2.0 * ((f * t) % 1.0) - 1.0) - 1.0
    return (sq * 0.35 + tri * 0.65) * env_adsr(n, a=0.005, d=0.05, s=0.75, r=0.04) * 0.45


def voice_organ(f, dur):
    n = int(SR * dur)
    t = np.arange(n) / SR
    w = (np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * 2 * f * t)
         + 0.3 * np.sin(2 * np.pi * 3 * f * t) + 0.15 * np.sin(2 * np.pi * 4 * f * t))
    return w * env_adsr(n, a=0.03, d=0.1, s=0.8, r=0.1) * 0.3


def voice_bass(f, dur):
    n = int(SR * dur)
    t = np.arange(n) / SR
    w = np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * 2 * f * t)
    return w * env_pluck(n, attack=0.006, tau=min(0.5, dur * 0.8)) * 0.6


def voice_pad(fs, dur):
    n = int(SR * dur)
    t = np.arange(n) / SR
    w = np.zeros(n)
    for f in fs:
        w += np.sin(2 * np.pi * f * t) + 0.2 * np.sin(2 * np.pi * 2.01 * f * t)
    return w / max(1, len(fs)) * env_adsr(n, a=0.15, d=0.1, s=0.9, r=0.2) * 0.16


def noise_tick(dur=0.03, amp=0.12):
    n = int(SR * dur)
    return np.random.default_rng(1).standard_normal(n) * env_pluck(n, 0.001, 0.008) * amp


def kick(dur=0.25, amp=0.9):
    n = int(SR * dur)
    t = np.arange(n) / SR
    f = 120 * np.exp(-t * 18) + 40
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env_pluck(n, 0.001, 0.09) * amp


VOICES = {'bell': voice_bell, 'chip': voice_chip, 'organ': voice_organ}


# ---------------------------------------------------------------------
# Chords
# ---------------------------------------------------------------------
def chord_notes(sym, octave=3):
    """'Am7' -> midi numbers of root triad (+7th) at the octave."""
    root = sym[0]
    i = 1
    if i < len(sym) and sym[i] in '#b':
        root += sym[i]
        i += 1
    rest = sym[i:]
    r = midi(root + str(octave))
    minor = rest.startswith('m') and not rest.startswith('maj')
    notes = [r, r + (3 if minor else 4), r + 7]
    if '7' in rest:
        notes.append(r + 10)
    if 'dim' in rest:
        notes = [r, r + 3, r + 6]
    return notes


# ---------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------
def mix(buf, start, sample):
    end = start + len(sample)
    if end > len(buf):
        sample = sample[:len(buf) - start]
        end = len(buf)
    if start < 0 or start >= len(buf):
        return
    buf[start:end] += sample


def parse_melody(s):
    out = []
    for tok in s.replace('|', ' ').split():
        name, dur = tok.split('/')
        out.append((None if name.upper() == 'R' else midi(name), float(dur)))
    return out


def render_tune(spec):
    bpm = spec['bpm']
    beat = 60.0 / bpm
    target = spec['target']
    voice = VOICES[spec.get('voice', 'bell')]
    bar = spec.get('bar', 4)
    perc = spec.get('perc', False)
    bass_every = spec.get('bass_every', 2 if bar == 4 else bar)
    pad = spec.get('pad', True)
    melody = parse_melody(spec['melody'])
    chords = spec['chords']
    transpose = spec.get('transpose', 0)
    buf = np.zeros(int(SR * (target + 2.0)))

    t = 0.0
    while t < target:
        # One pass of the melody.
        tt = t
        for m, d in melody:
            if m is not None:
                mix(buf, int(tt * SR), voice(freq(m + transpose), d * beat))
            tt += d * beat
        passlen = tt - t
        bars = int(math.ceil(passlen / (bar * beat)))
        # Chords/bass/percussion under it, one chord per bar, cycling.
        for b in range(bars):
            sym = chords[b % len(chords)]
            bt = t + b * bar * beat
            if bt >= target:
                break
            notes = chord_notes(sym, 3)
            if pad:
                mix(buf, int(bt * SR), voice_pad([freq(n + transpose) for n in notes[:3]], bar * beat))
            root = freq(notes[0] - 12 + transpose)
            fifth = freq(notes[2] - 12 + transpose)
            for k in range(0, bar, bass_every):
                f = root if (k == 0 or bar == 3) else fifth
                mix(buf, int((bt + k * beat) * SR), voice_bass(f, min(bass_every * beat, 0.6)))
            if perc:
                for k in range(bar):
                    amp = 0.16 if k == 0 else 0.08
                    mix(buf, int((bt + k * beat) * SR), noise_tick(amp=amp))
                    mix(buf, int((bt + (k + 0.5) * beat) * SR), noise_tick(amp=0.04))
        t += passlen
    return buf


# ---------------------------------------------------------------------
# Procedural pieces
# ---------------------------------------------------------------------
def render_midnight_chimes(target):
    buf = np.zeros(int(SR * (target + 2)))
    # Westminster quarters (four phrases), then twelve strikes.
    q = [['E5', 'C5', 'D5', 'G4'], ['G4', 'D5', 'E5', 'C5'], ['E5', 'D5', 'C5', 'G4'], ['G4', 'C5', 'D5', 'E5']]
    t = 0.5
    for phrase in q:
        for n in phrase:
            mix(buf, int(t * SR), voice_bell(freq(midi(n) - 12), 1.3) * 1.3)
            t += 0.75
        t += 0.9
    t += 1.5
    for i in range(12):
        n = int(SR * 3.5)
        tt = np.arange(n) / SR
        f = freq(midi('C3'))
        w = (np.sin(2 * np.pi * f * tt) + 0.6 * np.sin(2 * np.pi * f * 2.0 * tt)
             + 0.35 * np.sin(2 * np.pi * f * 2.4 * tt) + 0.2 * np.sin(2 * np.pi * f * 3.0 * tt)
             + 0.1 * np.sin(2 * np.pi * f * 4.2 * tt))
        mix(buf, int(t * SR), w * env_pluck(n, 0.003, 1.4) * 0.6)
        t += 2.2
    return buf


def render_easter_bells(target):
    buf = np.zeros(int(SR * (target + 2)))
    rng = np.random.default_rng(7)
    scale = [midi(n) for n in ['C5', 'D5', 'E5', 'G5', 'A5', 'C6', 'D6', 'E6']]
    t = 0.0
    beat = 60.0 / 90
    pad_chords = ['C', 'F', 'G', 'C', 'Am', 'F', 'G', 'C']
    b = 0
    while t < target:
        if b % 4 == 0:
            sym = pad_chords[(b // 4) % len(pad_chords)]
            mix(buf, int(t * SR), voice_pad([freq(n) for n in chord_notes(sym, 3)], 4 * beat))
        for k in range(4):
            n = scale[int(rng.integers(0, len(scale)))]
            mix(buf, int((t + k * beat * 0.5) * SR), voice_bell(freq(n), 0.5) * 0.7)
        if b % 8 == 7:
            mix(buf, int(t * SR), voice_bell(freq(midi('C4')), 2.0) * 1.2)
        t += beat
        b += 1
    return buf


def render_spooky_drone(target):
    buf = np.zeros(int(SR * (target + 2)))
    n = len(buf)
    t = np.arange(n) / SR
    f = freq(midi('D2'))
    drone = (np.sin(2 * np.pi * f * t) * 0.5 + np.sin(2 * np.pi * f * 1.5 * t) * 0.25
             + np.sin(2 * np.pi * f * 2.0 * t + 0.3 * np.sin(2 * np.pi * 0.11 * t)) * 0.3)
    lfo = 0.6 + 0.4 * np.sin(2 * np.pi * 0.07 * t)
    buf += drone * lfo * 0.35
    # Wind: filtered noise swelling in and out.
    rng = np.random.default_rng(13)
    noise = rng.standard_normal(n)
    kernel = np.ones(400) / 400.0
    wind = np.convolve(noise, kernel, mode='same')
    buf += wind * (0.5 + 0.5 * np.sin(2 * np.pi * 0.05 * t + 1.0)) * 0.6
    # Organ stabs in D minor every so often.
    stabs = [(4, 'Dm'), (12, 'Bb'), (20, 'Dm'), (28, 'A'), (36, 'Dm'), (44, 'Gm'), (52, 'Dm')]
    for at, sym in stabs:
        if at < target:
            for m in chord_notes(sym, 3):
                mix(buf, int(at * SR), voice_organ(freq(m), 2.5) * 0.6)
    # A distant bell.
    for at in (9, 25, 41, 57):
        if at < target:
            mix(buf, int(at * SR), voice_bell(freq(midi('A3')), 3.0) * 0.5)
    return buf


def render_party_loop(target):
    bpm = 124
    beat = 60.0 / bpm
    buf = np.zeros(int(SR * (target + 2)))
    bassline = ['C2', 'C2', 'G2', 'C2', 'F2', 'F2', 'G2', 'G2']
    lead = parse_melody(
        'E5/0.5 G5/0.5 C6/0.5 G5/0.5 E5/0.5 D5/0.5 C5/1 | R/0.5 E5/0.5 G5/0.5 A5/0.5 G5/1 E5/1 | '
        'F5/0.5 A5/0.5 C6/0.5 A5/0.5 F5/0.5 E5/0.5 D5/1 | G5/0.5 B5/0.5 D6/0.5 B5/0.5 G5/1 R/1')
    t = 0.0
    bar_i = 0
    while t < target:
        # Drums.
        for k in range(4):
            mix(buf, int((t + k * beat) * SR), kick())
            mix(buf, int((t + (k + 0.5) * beat) * SR), noise_tick(0.04, 0.18))
            if k in (1, 3):
                mix(buf, int((t + k * beat) * SR), noise_tick(0.12, 0.25))
        # Bass: eighths on the root.
        root = midi(bassline[bar_i % len(bassline)])
        for k in range(8):
            mix(buf, int((t + k * beat * 0.5) * SR), voice_chip(freq(root), beat * 0.45) * 0.9)
        # Lead every other bar after the first four.
        if bar_i >= 4:
            tt = t
            for m, d in lead:
                if m is not None:
                    mix(buf, int(tt * SR), voice_chip(freq(m), d * beat * 0.9) * 0.7)
                tt += d * beat
        # Pad on the chord.
        sym = ['C', 'C', 'G', 'C', 'F', 'F', 'G', 'G'][bar_i % 8]
        mix(buf, int(t * SR), voice_pad([freq(m) for m in chord_notes(sym, 4)], 4 * beat) * 1.3)
        t += 4 * beat
        bar_i += 1
    return buf


# ---------------------------------------------------------------------
# The tunes
# ---------------------------------------------------------------------
# Melody notation: NAME/BEATS, R = rest, | is ignored. Chords: one per bar.
TUNES = {
    # ---- Christmas (traditional, public domain) ----
    'jingle_bells': dict(bpm=132, voice='bell', perc=True, target=62, chords=[
        'G', 'G', 'G', 'G', 'C', 'G', 'A7', 'D7', 'G', 'G', 'G', 'G', 'C', 'G', 'D7', 'G',
        'G', 'G', 'C', 'G', 'A7', 'A7', 'D7', 'D7', 'G', 'G', 'C', 'G', 'A7', 'D7', 'G', 'G'],
        melody=(
            'B4/1 B4/1 B4/2 | B4/1 B4/1 B4/2 | B4/1 D5/1 G4/1.5 A4/0.5 | B4/4 | '
            'C5/1 C5/1 C5/1.5 C5/0.5 | C5/1 B4/1 B4/1 B4/0.5 B4/0.5 | B4/1 A4/1 A4/1 B4/1 | A4/2 D5/2 | '
            'B4/1 B4/1 B4/2 | B4/1 B4/1 B4/2 | B4/1 D5/1 G4/1.5 A4/0.5 | B4/4 | '
            'C5/1 C5/1 C5/1.5 C5/0.5 | C5/1 B4/1 B4/1 B4/0.5 B4/0.5 | D5/1 D5/1 C5/1 A4/1 | G4/4 | '
            'D5/1 B4/1 A4/1 G4/1 | D4/3 D4/0.5 D4/0.5 | D5/1 B4/1 A4/1 G4/1 | E4/4 | '
            'E4/1 C5/1 B4/1 A4/1 | F#4/4 | D5/1 D5/1 C5/1 A4/1 | B4/4 | '
            'D5/1 B4/1 A4/1 G4/1 | D4/4 | D5/1 B4/1 A4/1 G4/1 | E4/4 | '
            'E4/1 C5/1 B4/1 A4/1 | D5/1 D5/1 D5/1 D5/1 | E5/1 D5/1 C5/1 A4/1 | G4/2 D5/2')),

    'deck_the_halls': dict(bpm=126, voice='bell', perc=True, target=58, chords=[
        'C', 'C', 'G7', 'C', 'C', 'C', 'G7', 'C', 'C', 'G', 'C', 'D7', 'C', 'C', 'G7', 'C'],
        melody=(
            'G5/1.5 F5/0.5 E5/1 D5/1 | C5/1 D5/1 E5/1 C5/1 | D5/0.5 E5/0.5 F5/0.5 D5/0.5 E5/1.5 D5/0.5 | C5/1 B4/1 C5/2 | '
            'G5/1.5 F5/0.5 E5/1 D5/1 | C5/1 D5/1 E5/1 C5/1 | D5/0.5 E5/0.5 F5/0.5 D5/0.5 E5/1.5 D5/0.5 | C5/1 B4/1 C5/2 | '
            'D5/1.5 E5/0.5 F5/1 D5/1 | E5/1.5 F5/0.5 G5/1 D5/1 | E5/0.5 F#5/0.5 G5/1 A5/0.5 B5/0.5 C6/0.5 B5/0.5 | A5/1 G5/1 G5/2 | '
            'G5/1.5 F5/0.5 E5/1 D5/1 | C5/1 D5/1 E5/1 C5/1 | A5/0.5 A5/0.5 A5/0.5 A5/0.5 G5/1.5 F5/0.5 | E5/1 D5/1 C5/2')),

    'we_wish_you': dict(bpm=150, bar=3, voice='bell', perc=True, target=54, chords=[
        'C', 'F', 'D7', 'G', 'E7', 'Am', 'F', 'G', 'C', 'C', 'F', 'D7', 'G', 'E7', 'Am', 'F', 'G', 'C'],
        melody=(
            'G4/1 C5/1 C5/0.5 D5/0.5 | C5/0.5 B4/0.5 A4/1 A4/1 | A4/1 D5/1 D5/0.5 E5/0.5 | D5/0.5 C5/0.5 B4/1 G4/1 | '
            'G4/1 E5/1 E5/0.5 F5/0.5 | E5/0.5 D5/0.5 C5/1 A4/1 | G4/0.5 G4/0.5 A4/1 D5/1 | B4/1 C5/2 | '
            'G4/1 C5/1 C5/1 | C5/1 B4/2 | B4/1 C5/1 B4/1 | A4/1 G4/2 | '
            'D5/1 E5/1 D5/1 | C5/1 G5/2 | G4/0.5 G4/0.5 A4/1 D5/1 | B4/1 C5/2')),

    'carol_of_the_bells': dict(bpm=160, bar=3, voice='bell', perc=False, pad=True, target=66, bass_every=3, chords=[
        'Am', 'Am', 'Am', 'Am', 'Am', 'Am', 'Am', 'Am', 'F', 'F', 'G', 'G', 'Am', 'Am', 'E', 'Am'],
        melody=(
            'E5/1 D5/0.5 E5/0.5 C5/1 | E5/1 D5/0.5 E5/0.5 C5/1 | E5/1 D5/0.5 E5/0.5 C5/1 | E5/1 D5/0.5 E5/0.5 C5/1 | '
            'G5/1 F5/0.5 G5/0.5 E5/1 | G5/1 F5/0.5 G5/0.5 E5/1 | A5/1 G5/0.5 A5/0.5 F5/1 | A5/1 G5/0.5 A5/0.5 F5/1 | '
            'C6/1 B5/0.5 C6/0.5 A5/1 | C6/1 B5/0.5 C6/0.5 A5/1 | B5/1 A5/0.5 B5/0.5 G5/1 | B5/1 A5/0.5 B5/0.5 G5/1 | '
            'A5/0.5 G5/0.5 F5/0.5 E5/0.5 D5/0.5 C5/0.5 | B4/0.5 A4/0.5 B4/0.5 C5/0.5 D5/0.5 E5/0.5 | '
            'E5/1 D5/0.5 E5/0.5 C5/1 | E5/1 D5/0.5 E5/0.5 C5/1')),

    'up_on_the_housetop': dict(bpm=130, voice='chip', perc=True, target=56, chords=[
        'C', 'C', 'F', 'C', 'G7', 'G7', 'G7', 'C', 'C', 'C', 'F', 'C', 'G7', 'G7', 'C', 'C',
        'C', 'C', 'G7', 'G7', 'C', 'C', 'F', 'G7', 'C'],
        melody=(
            'E5/1 E5/1 E5/1 E5/1 | E5/1 C5/1 E5/2 | G5/1 G5/1 G5/1 E5/1 | D5/4 | '
            'D5/1 D5/1 D5/1 D5/1 | E5/1 D5/1 C5/2 | B4/1 G4/1 A4/1 B4/1 | C5/4 | '
            'E5/1 C5/1 G4/2 | E5/1 C5/1 G4/2 | G5/1 G5/1 G5/1 G5/1 | G5/1 F5/1 E5/1 D5/1 | '
            'C5/1 C5/1 E5/2 | D5/1 D5/1 F5/2 | E5/1 C5/1 G4/1 B4/1 | C5/4')),

    'joy_to_the_world': dict(bpm=104, voice='bell', perc=False, target=60, chords=[
        'C', 'G7', 'C', 'G7', 'C', 'C', 'C', 'C', 'C', 'C', 'G7', 'G7', 'C', 'F', 'C', 'C'],
        melody=(
            'C6/1.5 B5/0.5 A5/1 G5/1.5 | F5/0.5 E5/1 D5/1 C5/1.5 | G4/0.5 A5/1.5 A5/0.5 B5/1.5 | B5/0.5 C6/3 | '
            'C6/0.5 C6/0.5 B5/0.5 A5/0.5 G5/0.5 G5/0.5 F5/0.5 E5/0.5 | C6/0.5 C6/0.5 B5/0.5 A5/0.5 G5/0.5 G5/0.5 F5/0.5 E5/0.5 | '
            'E5/1 E5/1 E5/1 E5/1 | E5/0.5 F5/0.5 G5/2 F5/0.5 E5/0.5 | D5/1 D5/1 D5/0.5 E5/0.5 F5/2 | E5/0.5 D5/0.5 C5/1 C6/2 | '
            'A5/1 G5/1.5 F5/0.5 E5/1 | F5/1 E5/1 D5/1 C5/1 | C5/4')),

    'o_christmas_tree': dict(bpm=96, bar=3, voice='bell', perc=False, target=60, chords=[
        'C', 'C', 'G7', 'C', 'C', 'C', 'G7', 'C', 'G7', 'C', 'G7', 'C', 'C', 'F', 'G7', 'C'],
        melody=(
            'G4/1 C5/1.5 C5/0.5 | C5/2 D5/1 | E5/1.5 E5/0.5 E5/1 | E5/1 D5/1 E5/1 | F5/1 B4/1 D5/1 | C5/2 G4/1 | '
            'C5/1.5 C5/0.5 C5/2 | D5/1 E5/1.5 E5/0.5 | E5/2 E5/0.5 D5/0.5 | E5/1 F5/1 B4/1 | D5/2 C5/1 | '
            'G5/1 G5/1 E5/1 | A5/2 G5/1 | G5/1 F5/1 F5/1 | D5/2 G5/1 | G5/1 F5/1 F5/1 | D5/2 G5/1 | '
            'C5/1.5 C5/0.5 C5/2 | D5/1 E5/1.5 E5/0.5 | E5/1 D5/1 E5/1 | F5/1 B4/1 D5/1 | C5/2 R/1')),

    'silent_night': dict(bpm=72, bar=3, voice='bell', perc=False, target=72, bass_every=3, chords=[
        'C', 'C', 'C', 'C', 'G7', 'G7', 'C', 'C', 'F', 'F', 'C', 'C', 'F', 'F', 'C', 'C',
        'G7', 'G7', 'C', 'C', 'C', 'G7', 'C', 'C'],
        melody=(
            'G4/1.5 A4/0.5 G4/1 | E4/3 | G4/1.5 A4/0.5 G4/1 | E4/3 | D5/2 D5/1 | B4/3 | C5/2 C5/1 | G4/3 | '
            'A4/2 A4/1 | C5/1.5 B4/0.5 A4/1 | G4/1.5 A4/0.5 G4/1 | E4/3 | A4/2 A4/1 | C5/1.5 B4/0.5 A4/1 | G4/1.5 A4/0.5 G4/1 | E4/3 | '
            'D5/2 D5/1 | F5/1.5 D5/0.5 B4/1 | C5/3 | E5/3 | C5/1 G4/1 E4/1 | G4/1.5 F4/0.5 D4/1 | C4/3 | C4/3')),

    # ---- Hanukkah (traditional) ----
    'maoz_tzur': dict(bpm=108, voice='bell', perc=False, target=60, chords=[
        'G', 'G', 'D7', 'G', 'G', 'G', 'D7', 'G', 'C', 'G', 'D7', 'G', 'C', 'G', 'D7', 'G'],
        melody=(
            'D5/1 G5/1 G5/1 A5/1 | B5/1 B5/1 A5/1 G5/1 | A5/1 B5/1 C6/1 B5/1 | A5/2 G5/2 | '
            'D5/1 G5/1 G5/1 A5/1 | B5/1 B5/1 A5/1 G5/1 | A5/1 B5/1 C6/1 A5/1 | G5/4 | '
            'G5/1 A5/1 B5/1 C6/1 | D6/2 B5/2 | C6/1 B5/1 A5/1 G5/1 | A5/4 | '
            'G5/1 A5/1 B5/1 C6/1 | D6/2 B5/2 | C6/1 B5/1 A5/1 A5/1 | G5/4')),

    'dreidel': dict(bpm=126, voice='chip', perc=True, target=54, chords=[
        'C', 'C', 'G7', 'C', 'F', 'F', 'G7', 'C', 'C', 'C', 'G7', 'C', 'F', 'G7', 'C', 'C'],
        melody=(
            'C5/0.5 E5/0.5 G5/0.5 G5/0.5 G5/0.5 A5/0.5 G5/0.5 E5/0.5 | C5/0.5 E5/0.5 G5/0.5 G5/0.5 F5/0.5 E5/0.5 D5/1 | '
            'D5/0.5 F5/0.5 F5/0.5 F5/0.5 G5/0.5 F5/0.5 E5/0.5 D5/0.5 | E5/0.5 E5/0.5 F5/0.5 D5/0.5 C5/2 | '
            'G5/0.5 G5/0.5 G5/0.5 G5/0.5 A5/0.5 G5/0.5 E5/1 | C5/0.5 E5/0.5 G5/0.5 G5/0.5 F5/0.5 E5/0.5 D5/1 | '
            'D5/0.5 F5/0.5 F5/0.5 F5/0.5 G5/0.5 F5/0.5 E5/0.5 D5/0.5 | E5/0.5 E5/0.5 F5/0.5 D5/0.5 C5/2')),

    'hava_nagila': dict(bpm=140, voice='chip', perc=True, target=60, chords=[
        'E', 'E', 'E', 'E', 'F', 'F', 'E', 'E', 'Am', 'Am', 'E', 'E', 'F', 'F', 'E', 'E'],
        melody=(
            'E5/1 G#5/1 G#5/1 G#5/1 | A5/1 G#5/1 F5/1 E5/1 | E5/1 G#5/1 G#5/1 G#5/1 | A5/1 G#5/1 F5/1 E5/1 | '
            'F5/1 F5/1 F5/1 F5/1 | G5/1 F5/1 E5/1 D5/1 | E5/1 F5/1 E5/1 D5/1 | E5/4 | '
            'A4/1 A4/1 A4/1 A4/1 | B4/1 B4/1 C5/1 C5/1 | B4/1 B4/1 A4/1 A4/1 | G#4/4 | '
            'A4/0.5 A4/0.5 A4/0.5 A4/0.5 B4/0.5 B4/0.5 C5/0.5 C5/0.5 | B4/0.5 B4/0.5 A4/0.5 A4/0.5 G#4/1 E5/1 | '
            'F5/1 F5/1 F5/1 F5/1 | G5/1 F5/1 E5/1 D5/1 | E5/4')),

    # ---- New Year (traditional) ----
    'auld_lang_syne': dict(bpm=84, voice='bell', perc=False, target=62, chords=[
        'C', 'C', 'G7', 'C', 'F', 'C', 'G7', 'C', 'C', 'C', 'G7', 'C', 'F', 'C', 'G7', 'C'],
        melody=(
            'G4/1 | C5/1.5 B4/0.5 C5/1 E5/1 | D5/1.5 C5/0.5 D5/1 E5/1 | C5/1.5 C5/0.5 E5/1 G5/1 | A5/3 A5/1 | '
            'G5/1.5 E5/0.5 E5/1 C5/1 | D5/1.5 C5/0.5 D5/1 E5/1 | C5/1.5 A4/0.5 A4/1 G4/1 | C5/3 A5/1 | '
            'G5/1.5 E5/0.5 E5/1 C5/1 | D5/1.5 C5/0.5 D5/1 A5/1 | G5/1.5 E5/0.5 E5/1 G5/1 | A5/3 A5/1 | '
            'G5/1.5 E5/0.5 E5/1 C5/1 | D5/1.5 C5/0.5 D5/1 E5/1 | C5/1.5 A4/0.5 A4/1 G4/1 | C5/3')),

    # ---- 0.3.0: Kwanzaa (original), Memorial Day, Labor Day, wedding, birthday, funeral (all traditional) ----
    'harambee': dict(bpm=100, voice='chip', perc=True, target=60, chords=[
        'C', 'Am', 'F', 'G', 'C', 'Am', 'F', 'C'],
        melody=(
            'C5/1 E5/1 G5/1 E5/1 | D5/1 C5/2 R/1 | E5/0.5 G5/0.5 A5/1 G5/1 E5/1 | D5/1 C5/3 | '
            'G4/1 C5/1 E5/1 D5/1 | C5/1 A4/1 G4/2 | A4/1 C5/1 D5/1 E5/1 | C5/4')),
    'taps': dict(bpm=56, voice='organ', perc=False, target=48, pad=True, chords=['C', 'C', 'C', 'C', 'C', 'C', 'C', 'C'],
        melody=(
            'G3/0.5 G3/0.5 C4/3 | G3/0.5 C4/0.5 E4/3 | G3/0.5 C4/0.5 E4/1 G3/0.5 C4/0.5 E4/1 | G3/0.5 C4/0.5 E4/1 C4/0.5 E4/0.5 G4/1 | '
            'G4/3 E4/1 | C4/1 G3/3 | G3/0.5 G3/0.5 C4/4')),
    'battle_hymn': dict(bpm=112, voice='chip', perc=True, target=60, chords=[
        'C', 'C', 'F', 'C', 'C', 'C', 'G7', 'C', 'C', 'F', 'C', 'G7', 'C', 'F', 'C', 'C'],
        melody=(
            'G4/0.75 G4/0.25 G4/0.75 F4/0.25 E4/0.75 G4/0.25 C5/0.75 C5/0.25 | C5/0.75 B4/0.25 A4/0.75 A4/0.25 A4/0.75 G4/0.25 E4/1 | '
            'E4/0.75 E4/0.25 E4/0.75 F4/0.25 G4/0.75 G4/0.25 F4/0.75 E4/0.25 | D4/0.75 E4/0.25 D4/0.75 C4/0.25 D4/2 | '
            'G4/0.75 G4/0.25 G4/0.75 F4/0.25 E4/0.75 G4/0.25 C5/0.75 C5/0.25 | C5/0.75 B4/0.25 A4/0.75 A4/0.25 A4/0.75 G4/0.25 E4/1 | '
            'E4/0.75 E4/0.25 E4/0.75 F4/0.25 G4/0.75 G4/0.25 F4/0.75 E4/0.25 | D4/1 D4/0.75 D4/0.25 C4/2 | '
            'E4/1.5 E4/0.5 E4/1 D4/1 | C4/1 C4/1 C4/2 | A4/1.5 A4/0.5 A4/1 G4/1 | E4/1 E4/1 E4/2 | '
            'G4/1.5 G4/0.5 G4/1 F4/1 | E4/1 E4/1 E4/2 | D4/1 D4/1 D4/0.75 D4/0.25 | C4/4')),
    'bridal_chorus': dict(bpm=92, voice='organ', perc=False, target=60, chords=[
        'C', 'G7', 'C', 'G7', 'C', 'F', 'C', 'G7', 'C', 'G7', 'C', 'G7', 'C', 'F', 'G7', 'C'],
        melody=(
            'G4/1 C5/1.5 C5/0.5 C5/2 | G4/1 D5/1.5 B4/0.5 C5/2 | G4/1 C5/1 F5/1 E5/1 | C5/1 D5/1 C5/0.5 D5/0.5 B4/1 | '
            'G4/1 C5/1.5 C5/0.5 C5/2 | G4/1 D5/1.5 B4/0.5 C5/2 | G4/1 C5/1 F5/1 E5/1 | C5/1 D5/1 C5/2 | '
            'E5/1 E5/1 D5/1 C5/1 | B4/1 C5/1 D5/2 | E5/1 F5/1 E5/1 D5/1 | C5/2 G4/2 | '
            'G4/1 C5/1.5 C5/0.5 C5/2 | G4/1 D5/1.5 B4/0.5 C5/2 | G4/1 C5/1 F5/1 E5/1 | C5/1 D5/1 C5/2')),
    'wedding_march': dict(bpm=112, voice='organ', perc=False, target=58, chords=[
        'C', 'C', 'G7', 'C', 'C', 'G7', 'C', 'C', 'F', 'C', 'G7', 'C', 'F', 'G7', 'C', 'C'],
        melody=(
            'G4/0.5 G4/0.5 G4/0.5 G4/0.5 C5/1 E5/1 | D5/0.5 C5/0.5 B4/0.5 A4/0.5 G4/1 C5/1 | E5/0.5 E5/0.5 E5/0.5 E5/0.5 G5/1 E5/1 | '
            'D5/0.5 C5/0.5 B4/0.5 A4/0.5 G4/2 | C5/1 E5/1 G5/1 E5/1 | F5/1 D5/1 B4/1 D5/1 | C5/1 E5/1 G5/1 E5/1 | C5/4 | '
            'A4/1 B4/1 C5/1 D5/1 | E5/1 D5/1 C5/1 B4/1 | C5/1 D5/1 E5/1 F5/1 | G5/2 E5/2 | '
            'F5/1 E5/1 D5/1 C5/1 | D5/1 B4/1 D5/1 B4/1 | C5/2 G4/2 | C5/4')),
    'happy_birthday': dict(bpm=120, bar=3, voice='bell', perc=False, target=42, bass_every=3, chords=[
        'C', 'C', 'G7', 'G7', 'C', 'C', 'F', 'G7', 'C'],
        melody=(
            'R/2 G4/0.75 G4/0.25 | A4/1 G4/1 C5/1 | B4/2 G4/0.75 G4/0.25 | A4/1 G4/1 D5/1 | C5/2 G4/0.75 G4/0.25 | '
            'G5/1 E5/1 C5/1 | B4/1 A4/1 F5/0.75 F5/0.25 | E5/1 C5/1 D5/1 | C5/3')),
    'amazing_grace': dict(bpm=66, bar=3, voice='organ', perc=False, target=64, bass_every=3, chords=[
        'C', 'C', 'F', 'C', 'C', 'C', 'G7', 'G7', 'C', 'C', 'F', 'C', 'C', 'G7', 'C', 'C'],
        melody=(
            'R/2 G4/1 | C5/2 E5/0.5 C5/0.5 | E5/2 D5/1 | C5/2 A4/1 | G4/2 G4/1 | '
            'C5/2 E5/0.5 C5/0.5 | E5/2 D5/1 | G5/3 | G5/2 E5/1 | G5/2 E5/0.5 C5/0.5 | E5/2 D5/1 | C5/2 A4/1 | G4/2 G4/1 | '
            'C5/2 E5/0.5 C5/0.5 | E5/2 D5/1 | C5/3 | C5/2')),
    'nearer_my_god': dict(bpm=72, voice='organ', perc=False, target=60, chords=[
        'C', 'G7', 'C', 'F', 'C', 'G7', 'C', 'C', 'C', 'G7', 'C', 'F', 'C', 'G7', 'C', 'C'],
        melody=(
            'E5/1.5 E5/0.5 C5/1 C5/1 | G4/2 E5/2 | E5/1.5 E5/0.5 D5/1 D5/1 | C5/4 | '
            'E5/1.5 E5/0.5 C5/1 C5/1 | G4/2 E5/2 | E5/1.5 E5/0.5 D5/1 D5/1 | C5/4 | '
            'G5/2 G5/1 A5/1 | G5/2 E5/2 | G5/2 G5/1 A5/1 | G5/4 | '
            'E5/1.5 E5/0.5 C5/1 C5/1 | G4/2 E5/2 | E5/1.5 E5/0.5 D5/1 D5/1 | C5/4')),

    # ---- Valentine's (original) ----
    'valentine_waltz': dict(bpm=90, bar=3, voice='bell', perc=False, target=60, bass_every=3, chords=[
        'C', 'Am', 'F', 'G', 'C', 'Am', 'Dm', 'G', 'E7', 'Am', 'F', 'G', 'C', 'F', 'G', 'C'],
        melody=(
            'E5/2 G5/1 | A5/2 G5/1 | F5/1 E5/1 D5/1 | D5/3 | E5/2 G5/1 | C6/2 B5/1 | A5/1 G5/1 F5/1 | G5/3 | '
            'G#5/2 A5/1 | C6/2 B5/1 | A5/1 F5/1 A5/1 | B5/3 | C6/1 G5/1 E5/1 | F5/1 A5/1 F5/1 | E5/1 D5/1 B4/1 | C5/3')),

    # ---- St. Patrick's ----
    'irish_washerwoman': dict(bpm=140, bar=2, voice='chip', perc=True, target=56, bass_every=1, chords=[
        'G', 'G', 'D7', 'G', 'G', 'G', 'D7', 'G', 'G', 'C', 'G', 'D7', 'G', 'C', 'D7', 'G'],
        # 6/8: each beat is a dotted quarter, written as three thirds.
        melody=(
            'D5/0.333 B4/0.333 B4/0.333 G4/0.333 B4/0.333 B4/0.333 | D5/0.333 B4/0.333 B4/0.333 G4/0.333 B4/0.333 D5/0.333 | '
            'C5/0.333 A4/0.333 A4/0.333 F#4/0.333 A4/0.333 A4/0.333 | C5/0.333 A4/0.333 A4/0.333 F#4/0.333 A4/0.333 C5/0.333 | '
            'D5/0.333 B4/0.333 B4/0.333 G4/0.333 B4/0.333 B4/0.333 | D5/0.333 B4/0.333 B4/0.333 G4/0.333 B4/0.333 D5/0.333 | '
            'E5/0.333 F#5/0.333 G5/0.333 F#5/0.333 E5/0.333 D5/0.333 | B4/0.333 C5/0.333 A4/0.333 G4/0.667 R/0.333 | '
            'G5/0.333 G5/0.333 F#5/0.333 G5/0.333 D5/0.333 B4/0.333 | G5/0.333 G5/0.333 F#5/0.333 G5/0.333 D5/0.333 B4/0.333 | '
            'C5/0.333 D5/0.333 E5/0.333 F#5/0.333 G5/0.333 A5/0.333 | B5/0.333 A5/0.333 G5/0.333 F#5/0.333 E5/0.333 D5/0.333 | '
            'G5/0.333 G5/0.333 F#5/0.333 G5/0.333 D5/0.333 B4/0.333 | G5/0.333 G5/0.333 F#5/0.333 G5/0.333 D5/0.333 B4/0.333 | '
            'E5/0.333 F#5/0.333 G5/0.333 F#5/0.333 E5/0.333 D5/0.333 | B4/0.333 C5/0.333 A4/0.333 G4/0.667 R/0.333')),

    'shamrock_reel': dict(bpm=120, voice='chip', perc=True, target=60, bass_every=1, chords=[
        'D', 'D', 'G', 'A', 'D', 'D', 'G', 'A', 'Bm', 'G', 'D', 'A', 'Bm', 'G', 'A', 'D'],
        melody=(
            'D5/0.5 E5/0.5 F#5/0.5 D5/0.5 A5/0.5 D5/0.5 F#5/0.5 D5/0.5 | G5/0.5 F#5/0.5 E5/0.5 D5/0.5 E5/1 A4/1 | '
            'D5/0.5 E5/0.5 F#5/0.5 D5/0.5 A5/0.5 D5/0.5 F#5/0.5 A5/0.5 | B5/0.5 A5/0.5 F#5/0.5 E5/0.5 D5/2 | '
            'F#5/0.5 F#5/0.5 D5/0.5 F#5/0.5 B5/0.5 A5/0.5 F#5/0.5 E5/0.5 | G5/0.5 G5/0.5 B5/0.5 G5/0.5 E5/1 D5/1 | '
            'F#5/0.5 A5/0.5 D6/0.5 A5/0.5 F#5/0.5 D5/0.5 A4/0.5 D5/0.5 | E5/0.5 F#5/0.5 E5/0.5 C#5/0.5 D5/2')),

    # ---- Easter ----
    'morning_mood': dict(bpm=80, voice='bell', perc=False, target=62, chords=[
        'E', 'E', 'E', 'E', 'E', 'B7', 'E', 'E', 'E', 'E', 'G#m', 'C#m', 'A', 'B7', 'E', 'E'],
        melody=(
            'B4/1 G#4/1 F#4/1 E4/1 | F#4/1 G#4/1 B4/1 G#4/1 | F#4/1 E4/1 F#4/1 G#4/1 | B4/1 G#4/1 B4/1 E5/1 | '
            'D#5/1 B4/1 D#5/1 E5/1 | D#5/1 B4/1 G#4/1 B4/1 | D#5/1 B4/1 D#5/1 E5/1 | D#5/1 B4/1 G#4/1 B4/1 | '
            'B4/1 G#4/1 F#4/1 E4/1 | F#4/1 G#4/1 B4/1 G#4/1 | F#4/1 E4/1 F#4/1 G#4/1 | B4/1 G#4/1 B4/1 E5/1 | '
            'G#5/1 E5/1 B4/1 G#4/1 | A4/1 F#4/1 B4/1 A4/1 | G#4/2 E4/2 | E4/4')),

    # ---- Independence Day (traditional) ----
    'yankee_doodle': dict(bpm=126, voice='chip', perc=True, target=52, chords=[
        'C', 'G7', 'C', 'G7', 'C', 'G7', 'C', 'G7', 'F', 'C', 'F', 'C', 'F', 'C', 'G7', 'C'],
        melody=(
            'C5/1 C5/1 D5/1 E5/1 | C5/1 E5/1 D5/1 G4/1 | C5/1 C5/1 D5/1 E5/1 | C5/2 B4/2 | '
            'C5/1 C5/1 D5/1 E5/1 | F5/1 E5/1 D5/1 C5/1 | B4/1 G4/1 A4/1 B4/1 | C5/2 C5/2 | '
            'A4/1.5 B4/0.5 A4/1 G4/1 | A4/1 B4/1 C5/2 | G4/1.5 A4/0.5 G4/1 F4/1 | E4/2 G4/2 | '
            'A4/1.5 B4/0.5 A4/1 G4/1 | A4/1 B4/1 C5/1 A4/1 | G4/1 C5/1 B4/1 D5/1 | C5/2 C5/2')),

    'america_the_beautiful': dict(bpm=84, voice='bell', perc=False, target=62, chords=[
        'C', 'G7', 'G7', 'C', 'C', 'G7', 'C', 'C', 'C', 'G7', 'G7', 'C', 'F', 'C', 'G7', 'C'],
        melody=(
            'G4/1.5 G4/0.5 E4/1 E4/1 | G4/1.5 G4/0.5 D4/1 D4/1 | E4/1 F4/1 G4/1 A4/1 | B4/3 G4/1 | '
            'G4/1.5 G4/0.5 E4/1 E4/1 | G4/1.5 G4/0.5 D4/1 D4/1 | D5/1 C#5/1 D5/1 E5/1 | D5/3 G4/1 | '
            'E5/1.5 E5/0.5 D5/1 C5/1 | C5/1.5 B4/0.5 C5/1 D5/1 | G4/1 A4/1 B4/1 C5/1 | D5/3 C5/1 | '
            'C5/1.5 C5/0.5 A4/1 A4/1 | C5/1.5 C5/0.5 G4/1 G4/1 | C5/1 D5/1 E5/1 D5/1 | C5/4')),

    'star_spangled_banner': dict(bpm=76, bar=3, voice='bell', perc=False, target=60, bass_every=3, chords=[
        'C', 'C', 'G7', 'G7', 'C', 'C', 'F', 'G7', 'C', 'C', 'G7', 'G7', 'C', 'C', 'F', 'G7', 'C',
        'G7', 'G7', 'C', 'C', 'F', 'C', 'G7', 'C', 'F', 'C', 'G7', 'C', 'C', 'F', 'C', 'G7', 'C'],
        melody=(
            'G4/0.75 E4/0.25 C4/1 | E4/1 G4/1 C5/2 | E5/0.75 D5/0.25 C5/1 | E4/1 F#4/1 G4/2 | '
            'G4/0.5 G4/0.5 E5/1.5 D5/0.5 | C5/1 B4/2 | A4/0.5 B4/0.5 C5/1 C5/1 | G4/1 E4/1 C4/1 | '
            'G4/0.75 E4/0.25 C4/1 | E4/1 G4/1 C5/2 | E5/0.75 D5/0.25 C5/1 | E4/1 F#4/1 G4/2 | '
            'G4/0.5 G4/0.5 E5/1.5 D5/0.5 | C5/1 B4/2 | A4/0.5 B4/0.5 C5/1 C5/1 | G4/1 E4/1 C4/1 | '
            'E5/0.5 E5/0.5 E5/1 F5/1 | G5/2 G5/1 | F5/0.5 E5/0.5 D5/1 E5/1 | F5/2 F5/1 | F5/1 E5/1.5 D5/0.5 | C5/1 B4/2 | '
            'A4/0.5 B4/0.5 C5/1 E4/1 | F#4/1 G4/2 | G4/1 C5/1 C5/1 | C5/1 B4/1 A4/1 | A4/1 A4/1 D5/1 | F5/0.5 E5/0.5 D5/0.5 C5/0.5 C5/1 | '
            'B4/1 G4/0.5 G4/0.5 C5/1 | D5/1 E5/1 F5/1 | G5/2 C5/0.5 D5/0.5 | E5/1.5 F5/0.5 D5/1 | C5/3')),

    # ---- Halloween ----
    'mountain_king': dict(bpm=120, voice='chip', perc=True, target=64, bass_every=1, chords=[
        'Bm', 'Bm', 'Bm', 'Bm', 'Bm', 'Bm', 'Bm', 'Bm', 'F#', 'F#', 'F#', 'F#', 'F#', 'F#', 'F#', 'Bm'],
        melody=(
            'B3/0.5 C#4/0.5 D4/0.5 E4/0.5 F#4/0.5 D4/0.5 F#4/1 | F4/0.5 C#4/0.5 F4/1 E4/0.5 C4/0.5 E4/1 | '
            'B3/0.5 C#4/0.5 D4/0.5 E4/0.5 F#4/0.5 D4/0.5 F#4/0.5 B4/0.5 | A4/0.5 F#4/0.5 D4/0.5 F#4/0.5 A4/2 | '
            'B3/0.5 C#4/0.5 D4/0.5 E4/0.5 F#4/0.5 D4/0.5 F#4/1 | F4/0.5 C#4/0.5 F4/1 E4/0.5 C4/0.5 E4/1 | '
            'B3/0.5 C#4/0.5 D4/0.5 E4/0.5 F#4/0.5 D4/0.5 F#4/0.5 B4/0.5 | A4/0.5 F#4/0.5 D4/0.5 F#4/0.5 A4/2 | '
            'F#4/0.5 G#4/0.5 A4/0.5 B4/0.5 C#5/0.5 A4/0.5 C#5/1 | D5/0.5 A#4/0.5 D5/1 C#5/0.5 A4/0.5 C#5/1 | '
            'F#4/0.5 G#4/0.5 A4/0.5 B4/0.5 C#5/0.5 A4/0.5 C#5/0.5 F#5/0.5 | E5/0.5 C#5/0.5 A4/0.5 C#5/0.5 E5/2 | '
            'B4/0.5 C#5/0.5 D5/0.5 E5/0.5 F#5/0.5 D5/0.5 F#5/1 | F5/0.5 C#5/0.5 F5/1 E5/0.5 C5/0.5 E5/1 | '
            'B4/0.5 C#5/0.5 D5/0.5 E5/0.5 F#5/0.5 D5/0.5 F#5/0.5 B5/0.5 | A5/0.5 F#5/0.5 D5/0.5 F#5/0.5 A5/2')),

    'graveyard_waltz': dict(bpm=120, bar=3, voice='organ', perc=False, target=60, bass_every=3, chords=[
        'Dm', 'Dm', 'Gm', 'A7', 'Dm', 'Dm', 'Bb', 'A7', 'Dm', 'Gm', 'Dm', 'A7', 'Dm', 'Bb', 'A7', 'Dm'],
        melody=(
            'D5/1 F5/1 A5/1 | D6/2 C#6/1 | D6/1 Bb5/1 G5/1 | A5/3 | D5/1 F5/1 A5/1 | D6/2 C#6/1 | D6/1 F6/1 D6/1 | C#6/3 | '
            'F5/1 A5/1 D6/1 | F6/2 E6/1 | D6/1 C#6/1 Bb5/1 | A5/3 | D6/1 A5/1 F5/1 | Bb5/1 G5/1 E5/1 | A5/1 C#5/1 E5/1 | D5/3')),

    # ---- Thanksgiving ----
    'over_the_river': dict(bpm=120, voice='bell', perc=True, target=56, chords=[
        'C', 'C', 'F', 'C', 'G7', 'G7', 'C', 'C', 'C', 'C', 'F', 'C', 'G7', 'G7', 'C', 'C'],
        melody=(
            'E5/1 E5/1 E5/0.5 D5/0.5 C5/1 | E5/1 G5/1 G5/2 | A5/1 A5/1 A5/0.5 G5/0.5 F5/1 | A5/1 C6/1 C6/2 | '
            'G5/1 G5/1 G5/0.5 F5/0.5 E5/1 | G5/1 C5/1 C5/2 | D5/1 D5/1 D5/0.5 E5/0.5 F5/1 | E5/1 D5/1 C5/2 | '
            'E5/1 E5/1 E5/0.5 D5/0.5 C5/1 | E5/1 G5/1 G5/2 | A5/1 A5/1 A5/0.5 G5/0.5 F5/1 | A5/1 C6/1 C6/2 | '
            'G5/1 G5/1 G5/0.5 F5/0.5 E5/1 | G5/1 C5/1 C5/2 | D5/1 D5/1 D5/0.5 E5/0.5 F5/1 | E5/1 D5/1 C5/2')),

    'harvest_home': dict(bpm=92, voice='bell', perc=False, target=60, chords=[
        'G', 'C', 'G', 'D', 'Em', 'C', 'G', 'D', 'G', 'C', 'G', 'D', 'Em', 'C', 'D', 'G'],
        melody=(
            'G4/1 B4/1 D5/2 | E5/1 D5/1 B4/2 | A4/1 B4/1 D5/1 B4/1 | A4/4 | G4/1 B4/1 D5/2 | E5/1 G5/1 E5/2 | D5/1 B4/1 A4/1 B4/1 | G4/4 | '
            'B4/1 D5/1 G5/2 | F#5/1 E5/1 D5/2 | E5/1 D5/1 B4/1 D5/1 | A4/4 | G4/1 B4/1 D5/2 | E5/1 G5/1 E5/2 | D5/1 B4/1 A4/1 B4/1 | G4/4')),
}

PROCEDURAL = {
    'midnight_chimes': (render_midnight_chimes, 48),
    'easter_bells': (render_easter_bells, 50),
    'spooky_drone': (render_spooky_drone, 60),
    'party_loop': (render_party_loop, 60),
}


# ---------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------
def finish(buf, target):
    buf = buf[:int(SR * target)]
    # Fade the last 1.5 s so a loop that ends mid-phrase is not a cut.
    n = int(SR * 1.5)
    buf[-n:] *= np.linspace(1.0, 0.0, n)
    # A short fade in: the first frame of anything should not be a click.
    m = int(SR * 0.02)
    buf[:m] *= np.linspace(0.0, 1.0, m)
    peak = np.max(np.abs(buf)) or 1.0
    buf = buf / peak * 0.85
    return buf


def write_wav(path, buf):
    data = (buf * 32767).astype('<i2').tobytes()
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)


def to_ogg(wav, ogg):
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav,
                    '-c:a', 'libvorbis', '-q:a', '3', ogg], check=True)


def build(name):
    if name in TUNES:
        spec = TUNES[name]
        buf = render_tune(spec)
        target = spec['target']
    elif name in PROCEDURAL:
        fn, target = PROCEDURAL[name]
        buf = fn(target)
    else:
        raise SystemExit('unknown track: ' + name)
    buf = finish(buf, target)
    os.makedirs(OUT, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, name + '.wav')
        write_wav(wav, buf)
        to_ogg(wav, os.path.join(OUT, name + '.ogg'))
    return target


def main():
    names = sys.argv[1:] or (list(TUNES) + list(PROCEDURAL))
    for name in names:
        secs = build(name)
        size = os.path.getsize(os.path.join(OUT, name + '.ogg')) // 1024
        print(f'{name:28s} {secs:3d}s  {size:4d} KB')


if __name__ == '__main__':
    main()
