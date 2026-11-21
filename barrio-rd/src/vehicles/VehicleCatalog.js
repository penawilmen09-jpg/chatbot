import * as THREE from 'three';
import { Batch } from '../core/Batch.js';
import { Builder, Frame } from '../core/Builder.js';

// Catálogo de vehículos dominicanos. Cada entrada describe el vehículo (para tienda,
// garaje y conducción futura) y sabe construir su modelo 3D con geometría propia.
// FASE FUTURA: subir/bajar, conducir (ver src/vehicles/README en el README del proyecto).

const cylG = new THREE.CylinderGeometry(1, 1, 1, 12);
const torus = new THREE.TorusGeometry(1, 0.28, 8, 18);

function makeBuilder(mats) {
  const batch = new Batch(mats);
  const b = new Builder({ chunks: { at: () => batch }, colliders: null }, new Frame(), 'veh');
  return { b, batch };
}

function wheel(b, x, y, z, R, tire = 0x1a1a1a, rim = 0xb8bcc2) {
  b.geo('tire', torus, x, y, z, { ry: Math.PI / 2, sx: R * 0.78, sy: R * 0.78, sz: R * 0.78 * 1.0 }, tire);
  b.geo('metal', cylG, x, y, z, { rz: Math.PI / 2, sx: R * 0.62, sy: 0.1, sz: R * 0.62 }, rim);
  b.geo('metal', cylG, x, y, z, { rz: Math.PI / 2, sx: R * 0.16, sy: 0.2, sz: R * 0.16 }, 0x555a60);
}

// ----- Motos (CG 125/150/300, motoconcho, deportiva) -----
function buildMoto(mats, o) {
  const { b, batch } = makeBuilder(mats);
  const R = o.wheel ?? 0.29, color = o.color ?? 0xc0262d, big = o.big ?? 1;
  const wz = 0.66 * big, hy = R + 0.02;
  wheel(b, 0, hy, wz, R); wheel(b, 0, hy, -wz, R);
  // guardabarros
  b.geo('plain', new THREE.CylinderGeometry(1, 1, 1, 10, 1, true, 0, Math.PI), 0, hy + R * 0.2, wz, { rz: Math.PI / 2, ry: 0, sx: R * 1.12, sy: 0.12, sz: R * 1.12 }, color);
  b.box('plain', 0, hy + R * 0.85, -wz - 0.08, 0.14, 0.04, 0.5, color, 0, -0.25);
  // motor
  b.box('metal', 0, 0.36, 0.0, 0.26, 0.3, 0.42 * big, 0x7d8288);
  b.box('metal', 0, 0.32, -0.28, 0.2, 0.2, 0.22, 0x666b72);
  for (let i = 0; i < 4; i++) b.box('metal', 0.14, 0.44 + i * 0.03, 0.12, 0.02, 0.02, 0.3, 0x9aa0a6);
  // chasis + tanque + asiento
  b.box('plain', 0, 0.62, -0.05, 0.1, 0.1, 0.9 * big, 0x1d1f22, 0, -0.18);
  b.sph('plain', 0, 0.85, 0.22 * big, 0.17, 0.14, 0.3 * big, color, 10);
  b.box('plain', 0, 0.79, -0.28 * big, 0.26, 0.1, 0.66 * big, 0x141414);
  b.box('plain', 0, 0.74, -0.28 * big, 0.2, 0.05, 0.6 * big, color);
  if (o.rack) { b.box('metal', 0, 0.88, -0.78 * big, 0.34, 0.03, 0.38, 0x2a2d30); b.box('plain', 0, 0.82, -0.62 * big, 0.28, 0.06, 0.3, 0x141414); }
  // tren delantero
  b.geo('metal', cylG, 0.09, hy + 0.34, wz - 0.1, { rx: -0.25, sx: 0.022, sy: 0.7, sz: 0.022 }, 0xc9ccd0);
  b.geo('metal', cylG, -0.09, hy + 0.34, wz - 0.1, { rx: -0.25, sx: 0.022, sy: 0.7, sz: 0.022 }, 0xc9ccd0);
  b.geo('metal', cylG, 0, 1.08, wz - 0.24, { rz: Math.PI / 2, sx: 0.02, sy: 0.7, sz: 0.02 }, 0x2a2d30);
  b.geo('plain', cylG, 0.28, 1.08, wz - 0.24, { rz: Math.PI / 2, sx: 0.03, sy: 0.1, sz: 0.03 }, 0x111111);
  b.geo('plain', cylG, -0.28, 1.08, wz - 0.24, { rz: Math.PI / 2, sx: 0.03, sy: 0.1, sz: 0.03 }, 0x111111);
  // faro, tablero, espejos
  b.sph('lamp', 0, 1.0, wz + 0.04, 0.1, 0.1, 0.07, 0xfff4d0, 8);
  b.box('plain', 0, 1.1, wz - 0.2, 0.16, 0.08, 0.1, 0x222222);
  b.box('metal', 0.26, 1.24, wz - 0.26, 0.012, 0.18, 0.012, 0x888888); b.box('metal', -0.26, 1.24, wz - 0.26, 0.012, 0.18, 0.012, 0x888888);
  b.box('metal', 0.26, 1.34, wz - 0.26, 0.09, 0.06, 0.02, 0x9ab); b.box('metal', -0.26, 1.34, wz - 0.26, 0.09, 0.06, 0.02, 0x9ab);
  // escape, pedal, luz trasera
  b.geo('metal', cylG, 0.17, 0.3, -0.3, { rx: Math.PI / 2, sx: 0.045, sy: 0.9, sz: 0.045 }, 0xcfd2d6);
  b.box('plain', 0, 0.78, -wz - 0.18, 0.1, 0.05, 0.03, 0xe21d1d);
  b.box('metal', 0.18, 0.22, 0.05, 0.1, 0.02, 0.1, 0x666b72); b.box('metal', -0.18, 0.22, 0.05, 0.1, 0.02, 0.1, 0x666b72);
  if (o.windshield) b.box('glass', 0, 1.3, wz - 0.12, 0.34, 0.3, 0.02, 0xbfe0ee, 0, -0.4);
  const group = new THREE.Group();
  batch.build(group);
  return { group, size: { w: 0.7, l: 1.9 * big } };
}

// ----- Carros y guaguas -----
function buildCar(mats, o) {
  const { b, batch } = makeBuilder(mats);
  const L = o.len ?? 4.3, W = o.wid ?? 1.75, color = o.color ?? 0x9fb3c8;
  const hy = 0.34, bodyH = o.van ? 1.4 : 0.62;
  b.box('plain', 0, hy + bodyH / 2 + 0.12, 0, W, bodyH, L, color);
  const cabL = o.van ? L * 0.78 : L * 0.5, cabH = o.van ? 0.6 : 0.55, cabZ = o.van ? -0.2 : -0.2;
  b.box('plain', 0, hy + 0.12 + bodyH + cabH / 2, cabZ, W - 0.1, cabH, cabL, color);
  // vidrios
  b.box('glass', 0, hy + 0.12 + bodyH + cabH / 2, cabZ, W - 0.04, cabH * 0.7, cabL - 0.2, 0x7aa6b8);
  b.box('glass', 0, hy + 0.12 + bodyH + cabH / 2, cabZ, W - 0.12, cabH * 0.7, cabL + 0.04, 0x7aa6b8);
  b.box('plain', 0, hy + 0.12 + bodyH + cabH + 0.02, cabZ, W - 0.1, 0.06, cabL, color);
  // parachoques, luces
  b.box('metal', 0, hy + 0.18, L / 2 + 0.03, W + 0.04, 0.14, 0.12, 0x9a9ea3); b.box('metal', 0, hy + 0.18, -L / 2 - 0.03, W + 0.04, 0.14, 0.12, 0x9a9ea3);
  for (const s of [-1, 1]) {
    b.box('lamp', s * (W / 2 - 0.22), hy + bodyH * 0.65, L / 2 + 0.01, 0.3, 0.14, 0.04, 0xfff4d0);
    b.box('plain', s * (W / 2 - 0.22), hy + bodyH * 0.65, -L / 2 - 0.01, 0.3, 0.14, 0.04, 0xd02020);
    wheel(b, s * (W / 2 - 0.06), 0.33, L * 0.32, 0.33, 0x151515, 0xc5c8cc);
    wheel(b, s * (W / 2 - 0.06), 0.33, -L * 0.32, 0.33, 0x151515, 0xc5c8cc);
  }
  if (o.sign) b.box('plain', 0, hy + 0.12 + bodyH + cabH + 0.14, L * 0.2, 0.7, 0.22, 0.05, 0xf2c94c);
  b.box('plain', 0, hy + bodyH * 0.45, 0, W + 0.02, 0.06, L * 0.98, o.stripe ?? 0xf3f0e6);
  const group = new THREE.Group();
  batch.build(group);
  return { group, size: { w: W, l: L } };
}

export const VEHICLES = {
  cg150: { id: 'cg150', name: 'Honda CG 150', kind: 'moto', seats: 2, topSpeed: 95, price: 75000, build: (m, o) => buildMoto(m, { color: 0xc0262d, ...o }) },
  cg300: { id: 'cg300', name: 'CG 300 Deportiva', kind: 'moto', seats: 2, topSpeed: 130, price: 160000, build: (m, o) => buildMoto(m, { color: 0x1c1c1f, wheel: 0.31, big: 1.1, ...o }) },
  motoconcho: { id: 'motoconcho', name: 'Motoconcho', kind: 'moto', seats: 3, topSpeed: 80, price: 55000, build: (m, o) => buildMoto(m, { color: 0x2060c0, rack: true, windshield: true, ...o }) },
  deportiva: { id: 'deportiva', name: 'Moto deportiva', kind: 'moto', seats: 2, topSpeed: 180, price: 420000, build: (m, o) => buildMoto(m, { color: 0xf2c94c, wheel: 0.3, big: 1.05, windshield: true, ...o }) },
  carro: { id: 'carro', name: 'Carro público', kind: 'car', seats: 4, topSpeed: 140, price: 350000, build: (m, o) => buildCar(m, { color: 0x9fb3c8, ...o }) },
  guagua: { id: 'guagua', name: 'Guagua (voladora)', kind: 'van', seats: 14, topSpeed: 110, price: 900000, build: (m, o) => buildCar(m, { van: true, len: 5.4, wid: 1.95, color: 0xf3f0e6, stripe: 0x2fa6c4, sign: true, ...o }) },
};

export function createVehicle(id, mats, opts = {}) {
  const spec = VEHICLES[id];
  const { group, size } = spec.build(mats, opts);
  group.userData.vehicle = { id, spec, size };
  return { group, spec, size };
}
