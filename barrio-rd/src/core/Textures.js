import * as THREE from 'three';
import { Rng } from './Rng.js';

// Texturas 100% procedurales (canvas): cero descargas, carga instantánea.
let aniso = 4;
export function initTextures(renderer) {
  aniso = Math.min(8, renderer.capabilities.getMaxAnisotropy());
}

function canvasTex(w, h, draw, { repeat = true, srgb = true } = {}) {
  const c = document.createElement('canvas');
  c.width = w; c.height = h;
  draw(c.getContext('2d'), w, h);
  const t = new THREE.CanvasTexture(c);
  if (repeat) t.wrapS = t.wrapT = THREE.RepeatWrapping;
  if (srgb) t.colorSpace = THREE.SRGBColorSpace;
  t.anisotropy = aniso;
  return t;
}

function speckle(g, s, rng, n, base, spread, size = 1.6) {
  for (let i = 0; i < n; i++) {
    const v = base + (rng.next() - 0.5) * spread;
    g.fillStyle = `rgba(${v},${v},${v},${rng.range(0.15, 0.6)})`;
    g.fillRect(rng.next() * s, rng.next() * s, size * rng.range(0.6, 2), size * rng.range(0.6, 2));
  }
}

export const Tex = {
  // Repello de cemento / pintura (gris claro: se tiñe con el color del vértice)
  stucco() {
    return canvasTex(256, 256, (g, s) => {
      const r = new Rng(11);
      g.fillStyle = '#ececec'; g.fillRect(0, 0, s, s);
      speckle(g, s, r, 3200, 225, 60, 2);
      for (let i = 0; i < 14; i++) { // manchas de humedad
        const x = r.next() * s;
        const grd = g.createLinearGradient(x, 0, x + r.range(-10, 10), s);
        grd.addColorStop(0, 'rgba(150,150,150,0)');
        grd.addColorStop(0.4, `rgba(170,170,170,${r.range(0.05, 0.14)})`);
        grd.addColorStop(1, 'rgba(150,150,150,0)');
        g.fillStyle = grd; g.fillRect(x, 0, r.range(6, 22), s);
      }
    });
  },
  // Ladrillo / baldosa rojiza (color propio)
  brick() {
    return canvasTex(256, 256, (g, s) => {
      const r = new Rng(21);
      g.fillStyle = '#3a2a26'; g.fillRect(0, 0, s, s);
      const bw = 64, bh = 32;
      for (let row = 0; row < s / bh; row++) {
        for (let col = -1; col < s / bw + 1; col++) {
          const off = (row % 2) * bw / 2;
          const k = r.range(-18, 18);
          g.fillStyle = `rgb(${190 + k},${96 + k * 0.6},${70 + k * 0.5})`;
          g.fillRect(col * bw + off + 2, row * bh + 2, bw - 4, bh - 4);
        }
      }
      speckle(g, s, r, 1200, 120, 80, 2);
    });
  },
  asphalt() {
    return canvasTex(256, 256, (g, s) => {
      const r = new Rng(31);
      g.fillStyle = '#4a4a4d'; g.fillRect(0, 0, s, s);
      speckle(g, s, r, 5000, 100, 120, 1.6);
      g.strokeStyle = 'rgba(25,25,25,0.5)'; g.lineWidth = 1.2;
      for (let i = 0; i < 5; i++) {
        g.beginPath(); let x = r.next() * s, y = r.next() * s; g.moveTo(x, y);
        for (let j = 0; j < 6; j++) { x += r.range(-18, 18); y += r.range(-18, 18); g.lineTo(x, y); }
        g.stroke();
      }
    });
  },
  concrete() {
    return canvasTex(256, 256, (g, s) => {
      const r = new Rng(41);
      g.fillStyle = '#b9b7b0'; g.fillRect(0, 0, s, s);
      speckle(g, s, r, 3000, 170, 70, 2);
      g.strokeStyle = 'rgba(70,70,70,0.35)'; g.lineWidth = 2;
      g.strokeRect(0, 0, s, s); g.beginPath(); g.moveTo(s / 2, 0); g.lineTo(s / 2, s); g.stroke();
    });
  },
  grass() {
    return canvasTex(256, 256, (g, s) => {
      const r = new Rng(51);
      g.fillStyle = '#6fa03e'; g.fillRect(0, 0, s, s);
      for (let i = 0; i < 90; i++) {
        g.fillStyle = `rgba(${r.int(40, 90)},${r.int(110, 150)},${r.int(30, 60)},0.18)`;
        g.beginPath(); g.arc(r.next() * s, r.next() * s, r.range(8, 26), 0, 7); g.fill();
      }
      for (let i = 0; i < 2600; i++) {
        const x = r.next() * s, y = r.next() * s;
        g.strokeStyle = `rgba(${r.int(50, 110)},${r.int(120, 175)},${r.int(30, 70)},0.55)`;
        g.beginPath(); g.moveTo(x, y); g.lineTo(x + r.range(-2, 2), y - r.range(3, 8)); g.stroke();
      }
    });
  },
  dirt() {
    return canvasTex(256, 256, (g, s) => {
      const r = new Rng(61);
      g.fillStyle = '#8a6c4c'; g.fillRect(0, 0, s, s);
      speckle(g, s, r, 3500, 130, 100, 2.4);
      for (let i = 0; i < 50; i++) { // piedritas
        g.fillStyle = `rgba(${r.int(170, 215)},${r.int(160, 200)},${r.int(140, 180)},0.8)`;
        g.beginPath(); g.ellipse(r.next() * s, r.next() * s, r.range(1.5, 4), r.range(1, 3), r.next() * 3, 0, 7); g.fill();
      }
    });
  },
  zinc() { // techo de zinc acanalado
    return canvasTex(128, 128, (g, s) => {
      const r = new Rng(71);
      for (let x = 0; x < s; x += 16) {
        const grd = g.createLinearGradient(x, 0, x + 16, 0);
        grd.addColorStop(0, '#8d9094'); grd.addColorStop(0.5, '#d5d8db'); grd.addColorStop(1, '#8d9094');
        g.fillStyle = grd; g.fillRect(x, 0, 16, s);
      }
      for (let i = 0; i < 30; i++) {
        g.fillStyle = `rgba(150,80,40,${r.range(0.05, 0.2)})`;
        g.fillRect(r.next() * s, r.next() * s, r.range(2, 12), r.range(8, 40));
      }
    });
  },
  tile() { // cerámica
    return canvasTex(256, 256, (g, s) => {
      const r = new Rng(81);
      g.fillStyle = '#9b8f80'; g.fillRect(0, 0, s, s);
      for (let i = 0; i < 4; i++) for (let j = 0; j < 4; j++) {
        const k = r.range(-8, 8);
        g.fillStyle = `rgb(${225 + k},${214 + k},${196 + k})`;
        g.fillRect(i * 64 + 2, j * 64 + 2, 60, 60);
      }
    });
  },
  waterBump() {
    return canvasTex(256, 256, (g, s) => {
      const r = new Rng(91);
      g.fillStyle = '#808080'; g.fillRect(0, 0, s, s);
      for (let i = 0; i < 260; i++) {
        const x = r.next() * s, y = r.next() * s, rad = r.range(6, 22);
        const grd = g.createRadialGradient(x, y, 0, x, y, rad);
        const v = r.chance(0.5) ? 255 : 0;
        grd.addColorStop(0, `rgba(${v},${v},${v},0.35)`); grd.addColorStop(1, 'rgba(128,128,128,0)');
        g.fillStyle = grd; g.fillRect(x - rad, y - rad, rad * 2, rad * 2);
      }
    }, { srgb: false });
  },
  // Hoja de palma (alfa): raquis + foliolos
  palmFrond() {
    return canvasTex(512, 128, (g, w, h) => {
      const r = new Rng(101);
      g.clearRect(0, 0, w, h);
      g.strokeStyle = '#3f6a2a'; g.lineWidth = 7;
      g.beginPath(); g.moveTo(0, h / 2); g.lineTo(w, h / 2); g.stroke();
      const n = 56;
      for (let i = 1; i < n; i++) {
        const t = i / n, x = t * w;
        const len = Math.sin(Math.min(1, t * 1.05) * Math.PI * 0.95) ** 0.55 * (h / 2 - 2) + 4;
        for (const sgn of [-1, 1]) {
          const gr = r.int(95, 150);
          g.strokeStyle = `rgb(${r.int(60, 95)},${gr + 45},${r.int(35, 65)})`;
          g.lineWidth = 7.5 - t * 3.2;
          g.beginPath(); g.moveTo(x, h / 2);
          g.quadraticCurveTo(x + len * 0.35, h / 2 + sgn * len * 0.6, x + len * 0.75, h / 2 + sgn * len);
          g.stroke();
        }
      }
    }, { repeat: false });
  },
  // Letrero con texto
  sign(text, { bg = '#d62828', fg = '#ffffff', w = 512, h = 128, font = 'bold 64px Arial Black, Impact, sans-serif', sub = '' } = {}) {
    return canvasTex(w, h, (g) => {
      g.fillStyle = bg; g.fillRect(0, 0, w, h);
      g.strokeStyle = fg; g.lineWidth = 6; g.strokeRect(6, 6, w - 12, h - 12);
      g.fillStyle = fg; g.font = font; g.textAlign = 'center'; g.textBaseline = 'middle';
      g.fillText(text, w / 2, sub ? h * 0.40 : h / 2, w - 30);
      if (sub) { g.font = 'bold 30px Arial, sans-serif'; g.fillText(sub, w / 2, h * 0.78, w - 30); }
    }, { repeat: false });
  },
};
