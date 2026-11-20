#!/usr/bin/env python3
"""Sintetiza la música y los efectos de WILMEN ADVENTURE (chiptune original).

Todo se genera con osciladores (cuadrada, triángulo, ruido); no hay muestras
externas. Uso:  python3 tools/gen_audio.py
"""
import os
import random
import wave

import numpy as np
import soundfile as sf

SR = 22050
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_SFX = os.path.join(ROOT, "audio", "sfx")
OUT_MUS = os.path.join(ROOT, "audio", "music")


def freq(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def square(f, n, duty=0.5):
    ph = (np.arange(n) * f / SR) % 1.0
    return np.where(ph < duty, 1.0, -1.0)


def tri(f, n):
    ph = (np.arange(n) * f / SR) % 1.0
    return 4 * np.abs(ph - 0.5) - 1.0


def noise(n, seed=0):
    return np.random.RandomState(seed).uniform(-1, 1, n)


def env(n, a=0.005, d=0.1, s=0.6, r=0.05):
    e = np.ones(n)
    na, nd, nr = int(a * SR), int(d * SR), int(r * SR)
    na = max(1, min(na, n))
    e[:na] = np.linspace(0, 1, na)
    nd = min(nd, n - na)
    if nd > 0:
        e[na:na + nd] = np.linspace(1, s, nd)
        e[na + nd:] = s
    nr = min(nr, n)
    if nr > 0:
        e[n - nr:] *= np.linspace(1, 0, nr)
    return e


def sweep(f0, f1, dur, kind="square", duty=0.5):
    n = int(dur * SR)
    f = np.linspace(f0, f1, n)
    ph = np.cumsum(f) / SR
    ph = ph % 1.0
    if kind == "square":
        w = np.where(ph < duty, 1.0, -1.0)
    elif kind == "tri":
        w = 4 * np.abs(ph - 0.5) - 1.0
    else:
        w = np.sin(2 * np.pi * ph)
    return w


def finish(x, gain=0.8):
    x = np.asarray(x, dtype=np.float64)
    peak = np.max(np.abs(x)) if len(x) else 1.0
    if peak > 0:
        x = x / peak * gain
    return x


def write_wav(path, x):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def write_ogg(path, x):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    sf.write(path, np.clip(x, -1, 1).astype(np.float32), SR, format="OGG", subtype="VORBIS")


# ------------------------------------------------------------- EFECTOS ----
def seq(notes, dur, kind="square", duty=0.5, vol=1.0):
    out = []
    for m in notes:
        n = int(dur * SR)
        w = square(freq(m), n, duty) if kind == "square" else tri(freq(m), n)
        out.append(w * env(n, 0.002, dur * 0.5, 0.5, dur * 0.3) * vol)
    return np.concatenate(out)


def sfx_all():
    S = {}
    S["jump"] = sweep(260, 620, 0.16, "square", 0.25) * env(int(0.16 * SR), 0.002, 0.1, 0.3, 0.05)
    S["double_jump"] = sweep(420, 900, 0.18, "square", 0.25) * env(int(0.18 * SR), 0.002, 0.1, 0.3, 0.05)
    S["coin"] = np.concatenate([square(freq(83), int(0.06 * SR), 0.5), square(freq(88), int(0.22 * SR), 0.5) * env(int(0.22 * SR), 0.002, 0.15, 0.2, 0.08)])
    S["stomp"] = (sweep(300, 70, 0.12, "tri") + 0.4 * noise(int(0.12 * SR), 1)) * env(int(0.12 * SR), 0.001, 0.08, 0.3, 0.03)
    S["hurt"] = sweep(520, 120, 0.35, "square", 0.5) * env(int(0.35 * SR), 0.002, 0.25, 0.4, 0.08)
    S["die"] = np.concatenate([seq([70, 66, 62, 58, 54, 50], 0.12, "square", 0.25)])
    S["break"] = (noise(int(0.25 * SR), 2) * env(int(0.25 * SR), 0.001, 0.2, 0.1, 0.05) + 0.4 * sweep(200, 60, 0.25, "tri"))
    S["bump"] = sweep(150, 90, 0.08, "tri") * env(int(0.08 * SR), 0.001, 0.05, 0.3, 0.02)
    S["item"] = seq([72, 76, 79, 84], 0.07, "square", 0.25)
    S["heart"] = seq([76, 80, 83, 88], 0.08, "tri")
    S["life"] = seq([72, 76, 79, 84, 79, 84, 88, 91], 0.07, "square", 0.25)
    S["gem"] = seq([84, 88, 91, 96, 91, 96, 100], 0.06, "square", 0.125)
    S["spring"] = sweep(180, 700, 0.2, "tri") * env(int(0.2 * SR), 0.002, 0.15, 0.3, 0.04)
    S["checkpoint"] = seq([67, 72, 76, 79, 84], 0.09, "square", 0.25)
    S["goal"] = np.concatenate([seq([72, 72, 72, 76, 79, 84], 0.12, "square", 0.25), seq([84, 79, 84], 0.22, "square", 0.5)])
    S["spark"] = sweep(900, 400, 0.12, "square", 0.125) * env(int(0.12 * SR), 0.001, 0.09, 0.3, 0.03)
    S["dash"] = (noise(int(0.2 * SR), 3) * np.linspace(1, 0, int(0.2 * SR)) * 0.8 + sweep(200, 600, 0.2, "tri") * 0.4)
    S["shield"] = seq([60, 64, 67, 72, 76], 0.06, "tri") * 1.0
    S["freeze"] = (sweep(1400, 2400, 0.25, "square", 0.125) * env(int(0.25 * SR), 0.002, 0.2, 0.3, 0.05))
    S["blink"] = (sweep(300, 1200, 0.1, "square", 0.25) * env(int(0.1 * SR), 0.001, 0.08, 0.3, 0.02))
    S["enemy_shoot"] = sweep(500, 220, 0.14, "square", 0.25) * env(int(0.14 * SR), 0.001, 0.1, 0.3, 0.03)
    S["boss_hit"] = (sweep(400, 90, 0.3, "square", 0.5) + 0.5 * noise(int(0.3 * SR), 4)) * env(int(0.3 * SR), 0.001, 0.2, 0.4, 0.06)
    S["boss_die"] = (noise(int(1.2 * SR), 5) * np.linspace(1, 0, int(1.2 * SR)) ** 1.5 + 0.6 * sweep(300, 40, 1.2, "tri"))
    S["boss_roar"] = (sweep(110, 70, 0.5, "square", 0.5) * 0.7 + 0.5 * noise(int(0.5 * SR), 6)) * env(int(0.5 * SR), 0.02, 0.3, 0.5, 0.1)
    S["slam"] = (sweep(120, 40, 0.3, "tri") + 0.6 * noise(int(0.3 * SR), 7) * np.linspace(1, 0, int(0.3 * SR))) * env(int(0.3 * SR), 0.001, 0.2, 0.4, 0.05)
    S["click"] = seq([84], 0.05, "square", 0.5)
    S["select"] = seq([76, 83], 0.07, "square", 0.25)
    S["back"] = seq([76, 69], 0.07, "square", 0.25)
    S["pause"] = seq([79, 72], 0.06, "tri")
    S["gameover"] = np.concatenate([seq([67, 66, 65, 64, 62, 60, 55], 0.2, "tri")])
    for k, v in S.items():
        write_wav(os.path.join(OUT_SFX, k + ".wav"), finish(v, 0.7))
    return list(S)


# --------------------------------------------------------------- MÚSICA ---
MAJ = [0, 2, 4, 5, 7, 9, 11]
MIN = [0, 2, 3, 5, 7, 8, 10]
HMIN = [0, 2, 3, 5, 7, 8, 11]
PHR = [0, 1, 4, 5, 7, 8, 10]
PENT_MAJ = [0, 2, 4, 7, 9]
PENT_MIN = [0, 3, 5, 7, 10]

# (raíz midi, escala, progresión [(grado semitono, calidad)...], bpm, semilla)
TRACKS = {
    "world1": dict(root=60, scale=MAJ, pent=PENT_MAJ, prog=[(0, "M"), (7, "M"), (9, "m"), (5, "M")], bpm=124, seed=11, lead_duty=0.25, swing=False, drums="light"),
    "world2": dict(root=57, scale=MIN, pent=PENT_MIN, prog=[(0, "m"), (8, "M"), (3, "M"), (10, "M")], bpm=104, seed=22, lead_duty=0.5, swing=False, drums="soft"),
    "world3": dict(root=62, scale=PHR, pent=PENT_MIN, prog=[(0, "m"), (1, "M"), (0, "m"), (10, "M")], bpm=112, seed=33, lead_duty=0.25, swing=False, drums="march"),
    "world4": dict(root=65, scale=MAJ, pent=PENT_MAJ, prog=[(0, "M"), (7, "M"), (2, "m"), (10, "M")], bpm=120, seed=44, lead_duty=0.125, swing=False, drums="light"),
    "world5": dict(root=52, scale=HMIN, pent=PENT_MIN, prog=[(0, "m"), (8, "M"), (7, "M"), (7, "M")], bpm=116, seed=55, lead_duty=0.5, swing=False, drums="march"),
    "boss": dict(root=55, scale=HMIN, pent=PENT_MIN, prog=[(0, "m"), (1, "M"), (0, "m"), (7, "M")], bpm=156, seed=66, lead_duty=0.5, swing=False, drums="drive"),
    "title": dict(root=67, scale=MAJ, pent=PENT_MAJ, prog=[(0, "M"), (5, "M"), (9, "m"), (7, "M")], bpm=108, seed=77, lead_duty=0.25, swing=False, drums="light"),
}


def chord_tones(root, q):
    return [root, root + (4 if q == "M" else 3), root + 7]


RHYTHMS = [
    [(0, 2), (2, 2), (4, 2), (6, 2)],
    [(0, 3), (3, 1), (4, 2), (6, 1), (7, 1)],
    [(0, 1), (1, 1), (2, 2), (4, 1), (5, 1), (6, 2)],
    [(0, 2), (2, 1), (3, 1), (4, 4)],
    [(0, 1), (1, 1), (2, 1), (3, 1), (4, 2), (6, 2)],
    [(0, 4), (4, 2), (6, 1), (7, 1)],
]


def build_phrase(rnd, cfg, bars_chords):
    """Devuelve lista de (compás, inicio_corchea, duración, nota_midi)."""
    notes = []
    last = cfg["root"] + 12 + rnd.choice([0, 2, 4])
    for bar_i, (croot, q) in enumerate(bars_chords):
        rh = rnd.choice(RHYTHMS)
        ct = chord_tones(croot, q)
        for k, (st, ln) in enumerate(rh):
            if k == 0 or rnd.random() < 0.25:  # tonos del acorde en pulsos fuertes
                cands = [t + o for t in ct for o in (0, 12, 24) if abs(t + o - last) <= 5]
                if not cands:
                    cands = [t + 12 for t in ct]
                note = min(cands, key=lambda c: (abs(c - last) + rnd.random() * 3))
            else:
                scale_notes = [cfg["root"] + o + s for o in (0, 12, 24) for s in cfg["pent"]]
                cands = [c for c in scale_notes if 1 <= abs(c - last) <= 4]
                note = rnd.choice(cands) if cands else last
            note = max(cfg["root"] + 7, min(cfg["root"] + 28, note))
            last = note
            notes.append((bar_i, st, ln, note))
    return notes


def render_track(name, cfg):
    rnd = random.Random(cfg["seed"])
    spb = 60.0 / cfg["bpm"]
    eighth = spb / 2
    bar = spb * 4
    prog = cfg["prog"]
    bars = 16
    n_total = int(bars * bar * SR)
    lead = np.zeros(n_total)
    arp = np.zeros(n_total)
    bass = np.zeros(n_total)
    drum = np.zeros(n_total)
    # progresión de 16 compases: 4 repeticiones del ciclo de 4 acordes
    chords = [(cfg["root"] + prog[i % 4][0] - 12 + 12, prog[i % 4][1]) for i in range(bars)]
    chords = [(c[0], c[1]) for c in chords]
    # frases melódicas (4 compases) A, B, A', C
    phr_a = build_phrase(rnd, cfg, chords[0:4])
    phr_b = build_phrase(rnd, cfg, chords[4:8])
    phr_c = build_phrase(rnd, cfg, chords[8:12])
    phrases = [phr_a, phr_b, phr_a, phr_c]

    def put(buf, start_s, wave_, vol=1.0):
        i0 = int(start_s * SR)
        if i0 >= len(buf):
            return
        i1 = min(len(buf), i0 + len(wave_))
        buf[i0:i1] += wave_[:i1 - i0] * vol

    for p in range(4):
        for (bi, st, ln, m) in phrases[p]:
            t0 = (p * 4 + bi) * bar + st * eighth
            n = int(ln * eighth * SR * 0.95)
            w = square(freq(m), n, cfg["lead_duty"]) * env(n, 0.004, 0.08, 0.7, 0.04)
            put(lead, t0, w, 0.5)
            if p == 3:  # eco en la última frase
                put(lead, t0 + eighth, w, 0.15)
    for b in range(bars):
        croot, q = chords[b]
        ct = chord_tones(croot, q)
        # bajo: raíz y quinta en corcheas
        for e in range(8):
            m = (croot - 12) if e % 4 != 3 else (croot - 12 + 7)
            if e % 2 == 1 and cfg["drums"] == "soft":
                continue
            n = int(eighth * SR * 0.9)
            put(bass, b * bar + e * eighth, tri(freq(m), n) * env(n, 0.003, 0.06, 0.8, 0.03), 0.8)
        # arpegio en semicorcheas
        s16 = eighth / 2
        pat = [0, 1, 2, 1, 0, 1, 2, 1, 0, 1, 2, 1, 0, 2, 1, 2]
        for k in range(16):
            m = ct[pat[k] % 3] + 12
            n = int(s16 * SR * 0.8)
            put(arp, b * bar + k * s16, square(freq(m), n, 0.125) * env(n, 0.002, 0.05, 0.4, 0.02), 0.16)
        # batería
        for beat in range(4):
            t0 = b * bar + beat * spb
            if beat in (0, 2) or cfg["drums"] == "drive":
                n = int(0.13 * SR)
                kick = np.sin(2 * np.pi * np.cumsum(np.linspace(150, 45, n)) / SR) * np.linspace(1, 0, n)
                put(drum, t0, kick, 0.9)
            if beat in (1, 3):
                n = int(0.1 * SR)
                put(drum, t0, noise(n, b * 4 + beat) * np.linspace(1, 0, n) ** 2, 0.5)
            for h in (0, 1):
                n = int(0.03 * SR)
                if cfg["drums"] == "soft" and h == 1:
                    continue
                put(drum, t0 + h * eighth, noise(n, beat + h * 9 + b) * np.linspace(1, 0, n), 0.18)
    mix = lead + arp + bass + drum * 0.6
    # fundido mínimo en el empalme para evitar clics
    f = int(0.004 * SR)
    mix[:f] *= np.linspace(0, 1, f)
    mix[-f:] *= np.linspace(1, 0, f)
    mix = np.tanh(mix * 1.1)
    write_ogg(os.path.join(OUT_MUS, name + ".ogg"), finish(mix, 0.55))


def jingle(name, notes, dur, kind="square", duty=0.25):
    x = seq(notes, dur, kind, duty)
    write_ogg(os.path.join(OUT_MUS, name + ".ogg"), finish(x, 0.6))


def main():
    names = sfx_all()
    for name, cfg in TRACKS.items():
        render_track(name, cfg)
    jingle("victory", [72, 72, 72, 76, 79, 84, 79, 84, 88, 91, 96], 0.16)
    print("sfx:", len(names), "música:", len(TRACKS) + 1)


if __name__ == "__main__":
    main()
