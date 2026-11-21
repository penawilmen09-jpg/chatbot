#!/usr/bin/env python3
"""Efectos de sonido de la expansión (cofres, secretos, poderes temporales, vehículos, logros). Solo escribe los nuevos."""
import os

import numpy as np

import gen_audio as A

SR = A.SR


def e(n, a=0.002, d=0.1, s=0.5, r=0.05):
    return A.env(int(n * SR), a, d, s, r)


def main():
    S = {}
    S["chest_open"] = np.concatenate([A.seq([60, 64], 0.08, "tri"), A.seq([72, 76, 79, 84, 88], 0.07, "square", 0.25)])
    S["chest_rare"] = np.concatenate([A.seq([64, 67, 72], 0.07, "tri"), A.seq([76, 79, 84, 88, 91, 96], 0.06, "square", 0.125)])
    S["chest_special"] = np.concatenate([A.seq([60, 67, 72, 76], 0.08, "tri"), A.seq([79, 84, 88, 91, 96, 100, 103], 0.065, "square", 0.25),
                                         A.sweep(900, 2400, 0.3, "tri") * e(0.3)])
    S["chest_secret"] = np.concatenate([A.seq([55, 58, 62, 67], 0.1, "tri"), A.seq([70, 74, 79, 82, 86, 91, 94, 98, 103], 0.07, "square", 0.125),
                                        A.sweep(500, 3000, 0.4, "tri") * e(0.4)])
    S["secret_found"] = A.seq([67, 71, 74, 79, 83, 86, 91], 0.08, "square", 0.25)
    S["powerup"] = np.concatenate([A.sweep(300, 900, 0.14, "square", 0.25), A.seq([79, 84, 88, 91], 0.05, "square", 0.125)])
    S["fire"] = (A.noise(int(0.22 * SR), 11) * np.linspace(1, 0, int(0.22 * SR)) * 0.8 + A.sweep(180, 520, 0.22, "tri") * 0.5)
    S["thunder"] = (A.noise(int(0.32 * SR), 12) * np.linspace(1, 0, int(0.32 * SR)) ** 0.7 + A.sweep(1800, 200, 0.32, "square", 0.125) * 0.7)
    S["giant"] = np.concatenate([A.sweep(90, 260, 0.28, "tri"), A.sweep(260, 120, 0.18, "square", 0.5) * 0.6]) * e(0.46, 0.01, 0.3, 0.6, 0.08)
    S["giant_stomp"] = (A.sweep(100, 35, 0.28, "tri") + 0.8 * A.noise(int(0.28 * SR), 13) * np.linspace(1, 0, int(0.28 * SR))) * e(0.28, 0.001, 0.2, 0.3, 0.05)
    S["barrier_break"] = (A.sweep(1500, 400, 0.18, "square", 0.25) + 0.5 * A.noise(int(0.18 * SR), 14)) * e(0.18, 0.001, 0.12, 0.3, 0.04)
    S["vehicle_on"] = A.seq([48, 55, 60, 67], 0.06, "square", 0.5)
    S["engine"] = A.sweep(70, 110, 0.18, "square", 0.5) * e(0.18, 0.005, 0.1, 0.7, 0.04) * 0.6
    S["cart_rumble"] = (A.noise(int(0.2 * SR), 15) * 0.5 + A.sweep(60, 90, 0.2, "tri")) * e(0.2, 0.005, 0.1, 0.7, 0.04)
    S["splash"] = (A.noise(int(0.25 * SR), 16) * np.linspace(1, 0, int(0.25 * SR)) ** 1.5 + A.sweep(600, 200, 0.25, "tri") * 0.4)
    S["achievement"] = np.concatenate([A.seq([72, 79, 84], 0.08, "square", 0.25), A.seq([88, 91, 96, 100], 0.07, "square", 0.125), A.seq([103], 0.3, "tri")])
    S["reward"] = A.seq([76, 79, 84, 88, 84, 88, 91], 0.07, "square", 0.25)
    S["medal"] = A.seq([84, 88, 91, 96], 0.09, "tri")
    S["countdown"] = A.seq([72], 0.12, "square", 0.5)
    S["tick"] = A.seq([88], 0.03, "square", 0.5) * 0.6
    S["wave"] = A.seq([60, 64, 67, 72, 76], 0.07, "square", 0.25)
    S["rock_roll"] = (A.noise(int(0.3 * SR), 17) * 0.6 + A.sweep(45, 70, 0.3, "tri")) * e(0.3, 0.01, 0.2, 0.7, 0.05)
    for k, v in S.items():
        A.write_wav(os.path.join(A.OUT_SFX, k + ".wav"), A.finish(v, 0.7))
    print("sfx nuevos:", len(S))


if __name__ == "__main__":
    main()
