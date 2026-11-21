import * as THREE from 'three';
import { Builder, Frame } from '../core/Builder.js';

// Calles asfaltadas, aceras con contén, líneas de tráfico, policías acostados,
// postes eléctricos, transformadores, luminarias y cables.

export const ROAD_HALF = 4;            // calle principal: z∈[-4,4]
export const SIDEWALK = [4, 6];        // aceras: |z|∈[4,6]
export const CROSS = { x: -25, half: 3.5 };

const ASPHALT = 0x6a6a6e, LINE_Y = 0xf0c419, LINE_W = 0xeeeeee;

// Un tramo de calle principal [xa,xb] (se parte en piezas de 20 m para el frustum culling)
export function mainStreet(ctx, xa, xb, gaps = []) {
  const step = 20;
  for (let x = xa; x < xb; x += step) {
    const x1 = Math.min(xb, x + step), cx = (x + x1) / 2, hw = (x1 - x) / 2;
    const b = new Builder(ctx, new Frame(cx, 0, 0), ctx.group);
    b.block('asphalt', -hw, -0.3, -ROAD_HALF, hw, 0, ROAD_HALF, ASPHALT);
    // aceras (con huecos en las intersecciones)
    for (const sgn of [-1, 1]) {
      const z0 = sgn > 0 ? 4 : -6, z1 = sgn > 0 ? 6 : -4;
      let cur = x;
      const cuts = gaps.filter(([g0, g1]) => g1 > x && g0 < x1).sort((a, c) => a[0] - c[0]);
      const runs = [];
      for (const [g0, g1] of cuts) { if (g0 > cur) runs.push([cur, g0]); cur = Math.max(cur, g1); }
      if (cur < x1) runs.push([cur, x1]);
      for (const [r0, r1] of runs) {
        const l0 = Math.max(r0, x) - cx, l1 = Math.min(r1, x1) - cx;
        if (l1 - l0 < 0.05) continue;
        b.block('concrete', l0, -0.3, z0, l1, 0.16, z1, 0xc9c6bd);
        b.floorBox(l0, z0, l1, z1, 0.16);
        // juntas de la acera
        b.fine(() => { for (let jx = Math.ceil((cx + l0) / 2) * 2; jx < cx + l1; jx += 2) b.block('plain', jx - cx - 0.015, 0.16, z0, jx - cx + 0.015, 0.162, z1, 0x8a877e); });
      }
      // línea de borde
      b.fine(() => { b.block('plain', -hw, 0.002, sgn * (ROAD_HALF - 0.35) - 0.06, hw, 0.012, sgn * (ROAD_HALF - 0.35) + 0.06, LINE_W); });
    }
    // línea central amarilla discontinua
    b.fine(() => { for (let lx = Math.ceil(x / 4) * 4; lx < x1; lx += 4) b.block('plain', lx - cx, 0.002, -0.07, lx - cx + 2, 0.012, 0.07, LINE_Y); });
  }
}

// Calle transversal (norte-sur) en x = CROSS.x
export function crossStreet(ctx, za, zb) {
  const step = 20;
  for (let z = za; z < zb; z += step) {
    const z1 = Math.min(zb, z + step), cz = (z + z1) / 2, hd = (z1 - z) / 2;
    const b = new Builder(ctx, new Frame(CROSS.x, 0, cz), ctx.group);
    const hw = CROSS.half;
    b.block('asphalt', -hw, -0.3, -hd, hw, 0, hd, ASPHALT);
    for (const sgn of [-1, 1]) {
      const x0 = sgn > 0 ? hw : -hw - 2, x1 = sgn > 0 ? hw + 2 : -hw;
      // no duplicar aceras dentro de la zona de la calle principal
      b.block('concrete', x0, -0.3, -hd, x1, 0.16, hd, 0xc9c6bd);
      b.floorBox(x0, -hd, x1, hd, 0.16);
    }
    b.fine(() => { for (let lz = Math.ceil(z / 4) * 4; lz < z1; lz += 4) if (Math.abs(lz) > ROAD_HALF + 1) b.block('plain', -0.07, 0.002, lz - cz, 0.07, 0.012, lz - cz + 2, LINE_Y); });
  }
  // el cruce: el asfalto de la calle principal ya cubre z∈[-4,4]; las aceras de la
  // principal tienen hueco en x∈[CROSS.x-5.5, CROSS.x+5.5]
}

// Paso de cebra y policías acostados (lomos de burro)
export function crosswalk(ctx, x, z, alongX = true) {
  const b = new Builder(ctx, new Frame(x, 0, z), ctx.group);
  b.fine(() => {
    for (let i = -3; i <= 3; i++) {
      if (alongX) b.block('plain', -1.2, 0.003, i * 1.0 - 0.25, 1.2, 0.014, i * 1.0 + 0.25, LINE_W);
      else b.block('plain', i * 1.0 - 0.25, 0.003, -1.2, i * 1.0 + 0.25, 0.014, 1.2, LINE_W);
    }
  });
}
export function speedBump(ctx, x) { // "policía acostado"
  const b = new Builder(ctx, new Frame(x, 0, 0), ctx.group);
  for (let i = 0; i < 8; i++) b.block('plain', -0.45, 0, -ROAD_HALF + i * 1.0, 0.45, 0.1, -ROAD_HALF + i * 1.0 + 1.0, i % 2 ? 0x1a1a1a : 0xf0c419);
}

// ---------------- postes y cables ----------------
export function pole(ctx, x, z, { lamp = false, transformer = false, yaw = Math.PI / 2, lampSide = 1 } = {}) {
  const b = new Builder(ctx, new Frame(x, 0, z, yaw), ctx.group);
  const H = 9;
  b.cyl('concrete', 0, 0, 0, 0.1, 0.17, H, 0xb4b1a8, 8);
  b.cyl('plain', 0, 0, 0, 0.19, 0.19, 0.5, 0x777469, 8);
  b.box('plain', 0, H - 0.5, 0, 2.2, 0.1, 0.1, 0x5b4630);
  b.box('plain', 0, H - 1.3, 0, 1.8, 0.1, 0.1, 0x5b4630);
  for (const dx of [-0.9, 0, 0.9]) { b.cyl('plain', dx, H - 0.45, 0, 0.04, 0.05, 0.14, 0x3b7a8a, 5); }
  for (const dx of [-0.7, 0.7]) b.cyl('plain', dx, H - 1.25, 0, 0.04, 0.05, 0.14, 0x3b7a8a, 5);
  if (transformer) { b.cyl('metal', 0.35, H - 2.5, 0.0, 0.25, 0.25, 0.8, 0x6d7378, 10); b.cyl('plain', 0.35, H - 1.7, 0, 0.05, 0.05, 0.15, 0x333, 6); }
  if (lamp) {
    b.box('plain', lampSide * 0.9, H - 0.3, 0, 1.8, 0.06, 0.06, 0x444444); b.box('metal', lampSide * 1.7, H - 0.4, 0, 0.55, 0.1, 0.3, 0x666b70);
    b.box('lamp', lampSide * 1.7, H - 0.47, 0, 0.45, 0.04, 0.24, 0xfff3c8);
  }
  b.colCircle(0, 0, 0.2, 0, H);
}

// Cable con catenaria (cajas finas). p = [x,y,z]
export function cable(ctx, p0, p1, sag = 0.4, color = 0x151515, thick = 0.025) {
  const b = new Builder(ctx, new Frame(p0[0], 0, p0[2]), ctx.group);
  const n = Math.max(4, Math.round(Math.hypot(p1[0] - p0[0], p1[2] - p0[2]) / 3));
  let prev = null;
  for (let i = 0; i <= n; i++) {
    const t = i / n;
    const x = (p1[0] - p0[0]) * t, z = (p1[2] - p0[2]) * t;
    const y = p0[1] + (p1[1] - p0[1]) * t - sag * 4 * t * (1 - t);
    if (prev) {
      const dx = x - prev[0], dy = y - prev[1], dz = z - prev[2], len = Math.hypot(dx, dy, dz);
      b.box('plain', (x + prev[0]) / 2, (y + prev[1]) / 2, (z + prev[2]) / 2, len + 0.02, thick, thick, color, Math.atan2(-dz, dx), 0, Math.atan2(dy, Math.hypot(dx, dz)));
    }
    prev = [x, y, z];
  }
}

// Cables entre postes consecutivos de la misma fila + algunos cruzando la calle
export function wirePoles(ctx, poles) {
  const H = 9;
  for (let i = 0; i < poles.length - 1; i++) {
    const a = poles[i], c = poles[i + 1];
    for (const dx of [-0.9, 0, 0.9]) cable(ctx, [a.x, H - 0.4, a.z + dx], [c.x, H - 0.4, c.z + dx], 0.6);
    for (const dx of [-0.7, 0.7]) cable(ctx, [a.x, H - 1.2, a.z + dx], [c.x, H - 1.2, c.z + dx], 0.5, 0x222222, 0.018);
  }
}
