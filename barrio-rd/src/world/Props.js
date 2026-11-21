import * as THREE from 'three';

// Utilidades para objetos de barrio. Todas trabajan sobre un Builder (coordenadas locales).

export function plasticChair(b, x, z, ry = 0, color = 0xf4f4f4) {
  const c = Math.cos(ry), s = Math.sin(ry);
  const P = (dx, dz) => [x + dx * c + dz * s, z - dx * s + dz * c];
  const [sx, sz] = P(0, 0);
  b.box('plain', sx, 0.44, sz, 0.42, 0.04, 0.42, color, ry);
  const [bx, bz] = P(0, -0.2);
  b.box('plain', bx, 0.72, bz, 0.42, 0.5, 0.04, color, ry);
  for (const [dx, dz] of [[-0.18, -0.18], [0.18, -0.18], [-0.18, 0.18], [0.18, 0.18]]) { const [lx, lz] = P(dx, dz); b.box('plain', lx, 0.22, lz, 0.04, 0.44, 0.04, color); }
  b.colCircle(x, z, 0.25, 0, 0.9);
}

export function dominoTable(b, x, z, color = 0x2a6f97) {
  b.box('plain', x, 0.74, z, 0.9, 0.05, 0.9, color);
  b.box('plain', x, 0.37, z, 0.08, 0.74, 0.08, 0x333333);
  b.box('plain', x, 0.03, z, 0.6, 0.04, 0.06, 0x333333); b.box('plain', x, 0.03, z, 0.06, 0.04, 0.6, 0x333333);
  b.fine(() => { for (let i = 0; i < 6; i++) b.box('plain', x - 0.25 + (i % 3) * 0.19, 0.78, z - 0.1 + Math.floor(i / 3) * 0.22, 0.07, 0.025, 0.14, i % 2 ? 0xf0efe8 : 0x1a1a1a, (i * 0.7)); });
  b.colCircle(x, z, 0.5, 0, 0.9);
  for (const [dx, dz, r] of [[0.85, 0, -Math.PI / 2], [-0.85, 0, Math.PI / 2], [0, 0.85, Math.PI], [0, -0.85, 0]]) plasticChair(b, x + dx, z + dz, r, 0xe83a3a);
}

export function crateStack(b, x, z, n = 3, color = 0xf2c230) {
  for (let i = 0; i < n; i++) b.block('plain', x - 0.25, i * 0.3, z - 0.18, x + 0.25, i * 0.3 + 0.28, z + 0.18, color, i === 0);
  b.colBox(x, z, 0.25, 0.18, 0, n * 0.3);
}

export function speaker(b, x, z, ry = 0) {
  b.box('plain', x, 0.85, z, 0.7, 1.4, 0.55, 0x151515, ry);
  b.geo('plain', new THREE.CylinderGeometry(0.2, 0.2, 0.04, 14), x + Math.sin(ry) * 0.28, 0.55, z + Math.cos(ry) * 0.28, { rx: Math.PI / 2, ry }, 0x333333);
  b.geo('plain', new THREE.CylinderGeometry(0.14, 0.14, 0.04, 14), x + Math.sin(ry) * 0.28, 1.15, z + Math.cos(ry) * 0.28, { rx: Math.PI / 2, ry }, 0x333333);
  b.colBox(x, z, 0.38, 0.32, 0, 1.6, ry);
}

export function trashBin(b, x, z, color = 0x2a6fb8) {
  b.cyl('plain', x, 0, z, 0.3, 0.26, 0.75, color, 10);
  b.cyl('plain', x, 0.75, z, 0.32, 0.32, 0.05, 0x1a3f6e, 10);
  b.colCircle(x, z, 0.32, 0, 0.8);
}
