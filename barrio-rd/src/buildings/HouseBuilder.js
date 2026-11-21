import * as THREE from 'three';
import { Builder, Frame } from '../core/Builder.js';
import { Rng } from '../core/Rng.js';

// Generador de casas dominicanas de cemento y bloques.
// Local: x∈[-w/2,w/2], z∈[-d,0], fachada hacia +z, patio delantero z∈[0,yard], verja en z=yard.
// Estilos: techo plano con varillas y tinaco, techo de zinc a dos aguas, balcón con rejas, marquesina…

export const WALL_COLORS = [0xf2b8c6, 0xf4d35e, 0xf4a259, 0x8ecae6, 0xb7e4c7, 0xe9c46a, 0xf3efe6, 0xe76f51, 0xc8b6ff, 0x90be6d, 0x62c7d8, 0xf6bd60, 0xd9e8f5];
const TRIMS = [0xffffff, 0x1d3557, 0xc1121f, 0x2a9d8f, 0xf3efe6, 0x264653];

export function buildHouse(world, group, frame, o = {}) {
  const rng = new Rng(o.seed ?? 1);
  const w = o.w ?? 9, d = o.d ?? 9, floors = o.floors ?? 1;
  const wall = o.wall ?? rng.pick(WALL_COLORS), trim = o.trim ?? rng.pick(TRIMS);
  const roof = o.roof ?? (rng.chance(0.5) ? 'flat' : 'gable');
  const yard = o.yard ?? 2.4;
  const b = new Builder(world, frame, group);
  const H = 2.85, FH = 0.18, SL = 0.22;
  const hx = w / 2;

  // zócalo
  b.block('concrete', -hx - 0.06, 0, -d - 0.06, hx + 0.06, FH, 0.1, 0xb8b4aa, false);
  // piso del patio delantero (cemento)
  b.block('concrete', -hx - 0.1, 0, 0.1, hx + 0.1, 0.05, yard, 0xcfccc2);

  // ------- planta baja: fachada con puerta + ventanas
  const doorX = o.doorX ?? rng.pick([-hx + 1.4, 0, hx - 1.4]);
  const open = [];
  const doorW = 1.0;
  open.push({ t0: hx + doorX - doorW / 2, t1: hx + doorX + doorW / 2, y0: FH, y1: FH + 2.15, kind: 'door', trim, leafColor: rng.pick([0x6b4a30, 0x2a6f97, 0x8b2e2e, 0x3a7d44]) });
  const winY0 = FH + 0.95, winY1 = FH + 2.1, winW = 1.25;
  const wx = [];
  for (const cx of [-hx + 1.4, hx - 1.4, 0]) if (Math.abs(cx - doorX) > 1.9 && wx.length < 2) wx.push(cx);
  for (const cx of wx) open.push({ t0: hx + cx - winW / 2, t1: hx + cx + winW / 2, y0: winY0, y1: winY1, kind: 'window', trim, reja: rng.chance(0.75) ? 0x25282d : undefined });
  b.wall('stucco', -hx, -0.15, hx, -0.15, FH, FH + H, 0.3, wall, open, { trim });
  b.wall('stucco', -hx + 0.15, 0, -hx + 0.15, -d, FH, FH + H, 0.3, wall);
  b.wall('stucco', hx - 0.15, 0, hx - 0.15, -d, FH, FH + H, 0.3, wall);
  b.wall('stucco', -hx, -d + 0.15, hx, -d + 0.15, FH, FH + H, 0.3, wall);
  // ventana lateral (decoración)
  b.fine(() => {
    b.box('glass', hx + 0.0, FH + 1.5, -d * 0.5, 0.04, 0.9, 1.1, 0x9cc7d6);
    b.box('plain', hx + 0.02, FH + 1.5, -d * 0.5, 0.06, 1.0, 1.2, trim);
  });
  // banda de pintura inferior
  b.fine(() => {
    b.block('plain', -hx - 0.02, FH, -0.2, hx + 0.02, FH + 0.55, 0.0, trim ^ 0x303030 & 0xffffff);
  });
  // medidor de luz + caja eléctrica
  b.fine(() => {
    const mx = hx + doorX + 0.9 > w - 0.3 ? -hx + 0.5 : doorX + 0.95;
    b.box('plain', Math.max(-hx + 0.4, Math.min(hx - 0.4, mx)), FH + 1.5, 0.08, 0.26, 0.34, 0.12, 0x6e7378);
    b.box('metal', Math.max(-hx + 0.4, Math.min(hx - 0.4, mx)), FH + 1.5, 0.15, 0.14, 0.14, 0.02, 0xcfd3d6);
  });
  let topY = FH + H;

  // ------- porche/marquesina de zinc
  if (o.porch ?? rng.chance(0.4)) {
    const px0 = doorX - 1.5, px1 = doorX + 1.5;
    b.block('concrete', px0, 0.05, 0.05, px1, 0.12, 1.8, 0xd8d4c8);
    for (const x of [px0 + 0.1, px1 - 0.1]) b.block('stucco', x - 0.1, 0.1, 1.6, x + 0.1, FH + 2.5, 1.8, wall, true);
    b.box('zinc', doorX, FH + 2.55, 0.9, 3.2, 0.06, 2.0, 0xffffff, 0, 0.1);
    b.fine(() => { // silla plástica
      b.box('plain', px1 - 0.2, 0.42, 1.0, 0.45, 0.05, 0.45, 0xf4f4f4);
      b.box('plain', px1 - 0.2, 0.7, 0.8, 0.45, 0.5, 0.05, 0xf4f4f4);
    });
  }

  // ------- segundo piso con balcón
  if (floors === 2) {
    const y0 = topY;
    b.block('concrete', -hx - 0.05, y0, -d - 0.05, hx + 0.05, y0 + SL, 0.0, 0xc9c6bd); // losa
    // balcón volado
    b.block('concrete', -hx + 0.1, y0, 0, hx - 0.1, y0 + SL, 1.3, 0xc9c6bd);
    b.block('plain', -hx + 0.1, y0 - 0.12, 1.1, hx - 0.1, y0 + SL, 1.3, trim);
    b.floorBox(-hx + 0.2, -0.3, hx - 0.2, 1.3, y0 + SL);
    const yy = y0 + SL, y1 = yy + H - 0.1;
    const open2 = [{ t0: hx - 0.5, t1: hx + 0.5, y0: yy, y1: yy + 2.15, kind: 'door', open: true, trim }];
    for (const cx of [-hx + 1.3, hx - 1.4]) if (Math.abs(cx) > 1.0) open2.push({ t0: hx + cx - 0.6, t1: hx + cx + 0.6, y0: yy + 0.95, y1: yy + 2.1, kind: 'window', trim, reja: 0x25282d });
    b.wall('stucco', -hx, -0.15, hx, -0.15, yy, y1, 0.3, wall, open2, { trim });
    b.wall('stucco', -hx + 0.15, 0, -hx + 0.15, -d, yy, y1, 0.3, wall);
    b.wall('stucco', hx - 0.15, 0, hx - 0.15, -d, yy, y1, 0.3, wall);
    b.wall('stucco', -hx, -d + 0.15, hx, -d + 0.15, yy, y1, 0.3, wall);
    ironRail(b, -hx + 0.2, 1.22, hx - 0.2, 1.22, yy, trim);
    ironRail(b, -hx + 0.2, 1.22, -hx + 0.2, 0.0, yy, trim);
    ironRail(b, hx - 0.2, 1.22, hx - 0.2, 0.0, yy, trim);
    // piso interior accesible (balcón) ya incluido; interior inaccesible
    b.colBox(0, -d / 2 - 0.1, hx - 0.05, d / 2 - 0.05, yy, y1);
    topY = y1;
  } else {
    b.colBox(0, -d / 2 - 0.05, hx, d / 2, 0, topY);
  }

  // ------- techo
  if (roof === 'flat') {
    b.block('concrete', -hx - 0.2, topY, -d - 0.2, hx + 0.2, topY + 0.2, 0.2, 0xbdbab1);
    const pH = 0.5;
    for (const [x0, z0, x1, z1] of [[-hx - 0.2, 0.0, hx + 0.2, 0.2], [-hx - 0.2, -d - 0.2, hx + 0.2, -d], [-hx - 0.2, -d, -hx, 0], [hx, -d, hx + 0.2, 0]])
      b.block('stucco', x0, topY + 0.2, z0, x1, topY + 0.2 + pH, z1, wall);
    b.block('plain', -hx - 0.22, topY + 0.2 + pH, -0.02, hx + 0.22, topY + 0.2 + pH + 0.06, 0.22, trim);
    // tinaco
    const tx = rng.range(-hx / 2, hx / 2), tz = -d * 0.5;
    b.cyl('plain', tx, topY + 0.2, tz, 0.5, 0.58, 1.15, 0x1f2326, 12);
    b.cyl('plain', tx, topY + 1.35, tz, 0.22, 0.5, 0.18, 0x1f2326, 12);
    b.fine(() => {
      // varillas de la futura ampliación
      if (rng.chance(0.7)) for (const [cx, cz] of [[-hx + 0.15, -0.15], [hx - 0.15, -0.15], [-hx + 0.15, -d + 0.15], [hx - 0.15, -d + 0.15]])
        for (let k = 0; k < 3; k++) b.cyl('metal', cx + (k - 1) * 0.07, topY + 0.2 + pH, cz, 0.012, 0.012, 0.9 + k * 0.1, 0x7a4c3a, 4);
      // antena / plato
      b.cyl('metal', hx - 0.6, topY + 0.2 + pH, -0.6, 0.02, 0.02, 1.4, 0x888888, 5);
      b.geo('plain', new THREE.SphereGeometry(0.3, 8, 4, 0, Math.PI * 2, 0, 1.0), hx - 0.6, topY + 0.2 + pH + 1.3, -0.6, { rx: 0.5, sy: 0.7 }, 0xe8e8e8);
    });
  } else {
    const rise = d * 0.2, over = 0.55, th = 0.07;
    const half = d / 2 + over;
    const L = Math.hypot(half, rise), ang = Math.atan2(rise, d / 2 + over * 0.0);
    const roofCol = o.roofColor ?? rng.pick([0xffffff, 0xb85c38, 0x9aa0a6, 0x3b6e8f]);
    const mat = 'zinc';
    // plano delantero (+z) y trasero (-z)
    b.box(mat, 0, topY + rise / 2 + 0.2, -d / 4 + over / 2, w + 0.8, th, L, roofCol, 0, ang);
    b.box(mat, 0, topY + rise / 2 + 0.2, -3 * d / 4 - over / 2, w + 0.8, th, L, roofCol, 0, -ang);
    // cumbrera
    b.box('plain', 0, topY + rise + 0.22, -d / 2, w + 0.82, 0.1, 0.5, 0x777c80);
    // frontones triangulares
    const tri = new THREE.Shape(); tri.moveTo(-d, 0); tri.lineTo(0, 0); tri.lineTo(-d / 2, rise); tri.lineTo(-d, 0);
    const gg = new THREE.ExtrudeGeometry(tri, { depth: 0.25, bevelEnabled: false }); gg.rotateY(-Math.PI / 2);
    b.geo('stucco', gg, -hx + 0.12, topY, 0, {}, wall); b.geo('stucco', gg, hx + 0.13, topY, 0, {}, wall);
    b.fine(() => { // cielo falso / losa de cierre
      b.block('concrete', -hx, topY, -d, hx, topY + 0.15, 0, 0xb8b4aa);
    });
  }

  // ------- patio delantero: verja con portón + plantas + cables
  if (o.fence !== false) fence(b, w, yard, doorX, wall, trim, rng);
  // aire acondicionado
  if (rng.chance(0.35)) b.fine(() => { b.box('plain', hx - 0.2 - 0.9, FH + 2.45, 0.12, 0.8, 0.3, 0.25, 0xe9ecef); });
  // tiestos con plantas junto a la puerta
  b.fine(() => {
    for (const s of [-1, 1]) {
      const x = doorX + s * 0.95;
      if (Math.abs(x) > hx - 0.3) continue;
      b.cyl('plain', x, 0.05, 0.7, 0.16, 0.2, 0.34, 0xb4553a, 8);
      b.sph('plain', x, 0.58, 0.7, 0.28, 0.26, 0.28, 0x3f8a34, 6);
    }
  });
  return { w, d, doorX, yard };
}

export function ironRail(b, x0, z0, x1, z1, baseY, color = 0x25282d, H = 1.0) {
  const dx = x1 - x0, dz = z1 - z0, len = Math.hypot(dx, dz), ang = Math.atan2(-dz, dx);
  const mx = (x0 + x1) / 2, mz = (z0 + z1) / 2;
  b.box('plain', mx, baseY + H, mz, len, 0.06, 0.08, color, ang);
  b.box('plain', mx, baseY + 0.08, mz, len, 0.08, 0.08, color, ang);
  const n = Math.max(2, Math.round(len / 0.13));
  b.fine(() => { for (let i = 0; i <= n; i++) { const t = (i / n) * len; b.box('metal', x0 + (dx / len) * t, baseY + H / 2, z0 + (dz / len) * t, 0.022, H, 0.022, color); } });
  b.colBox(mx, mz, len / 2 + 0.05, 0.08, baseY, baseY + H, ang);
}

function fence(b, w, yard, doorX, wall, trim, rng) {
  const hx = w / 2 + 0.1, z = yard + 0.05, H = 1.55;
  const gate = 1.3;
  const seg = (x0, x1) => {
    if (x1 - x0 < 0.1) return;
    b.block('stucco', x0, 0, z - 0.1, x1, 0.8, z + 0.1, wall);
    b.block('plain', x0, 0.8, z - 0.12, x1, 0.86, z + 0.12, trim);
    b.colBox((x0 + x1) / 2, z, (x1 - x0) / 2, 0.12, 0, H);
    b.block('metal', x0, 0.86, z - 0.02, x1, 0.92, z + 0.02, 0x25282d);
    b.block('metal', x0, H - 0.06, z - 0.02, x1, H, z + 0.02, 0x25282d);
    b.fine(() => { const n = Math.max(1, Math.round((x1 - x0) / 0.14)); for (let i = 0; i <= n; i++) b.box('metal', x0 + ((x1 - x0) * i) / n, (0.86 + H) / 2, z, 0.02, H - 0.86, 0.02, 0x25282d); });
  };
  seg(-hx, doorX - gate / 2); seg(doorX + gate / 2, hx);
  for (const x of [-hx, hx, doorX - gate / 2, doorX + gate / 2]) b.block('stucco', x - 0.12, 0, z - 0.12, x + 0.12, H + 0.1, z + 0.12, wall);
  // portón abierto
  b.fine(() => { for (let i = 0; i < 8; i++) b.box('metal', doorX - gate / 2 + 0.03, 0.8, z + 0.1 + i * 0.12, 0.02, 1.4, 0.02, 0x25282d); });
}
