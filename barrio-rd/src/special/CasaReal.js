import * as THREE from 'three';
import { Builder, Frame } from '../core/Builder.js';
import { Flora } from '../world/Flora.js';
import { Tex } from '../core/Textures.js';
import { createVehicle } from '../vehicles/VehicleCatalog.js';
import { COLORS } from '../config.js';

// ============================================================================
//  CASA REAL — réplica 3D de la casa de las fotografías de referencia.
//  Coordenadas LOCALES (metros): +z = hacia la calle (fachada/patio), -z = fondo.
//  Compuesto: x∈[0,40], z∈[-42,0]. El portón de entrada está en z=0.
//
//  Planta baja : arcada de columnas turquesa + arcos verdes, porche con comedor,
//                sala interior accesible (dos puertas).
//  Planta alta : balcón corrido con balaustres verdes/turquesa, habitación
//                con ventanal y cortinas, puerta de acceso.
//  Exterior    : escalera CURVA de ladrillo rojizo con baranda de balaustres,
//                piscina con borde de ladrillo y baranda de acero, palmeras
//                de coco, plantas ti, jengibre, plumeros, croton, macetas,
//                columna de concreto con varillas, tumbonas turquesa, muro.
// ============================================================================

const C = {
  wall: COLORS.casaVerde, wallMid: COLORS.casaVerdeMedio, teal: COLORS.turquesa, tealLight: COLORS.turquesaClaro,
  brick: COLORS.ladrillo, white: COLORS.blanco, rail: 0x7fd0d8, balGreen: 0x68b97b, balBlue: 0x3a9fc4,
};

// Plano de la casa (local)
const HX0 = 8, HX1 = 24;          // ancho de la casa (16 m)
const ZF = -30;                   // cara frontal de la arcada
const ZW = -33.5;                 // pared trasera del porche / frente de las habitaciones
const ZB = -38;                   // fondo de la casa
const H0 = 3.2;                   // altura planta baja
const SLAB = 0.3;
const YD = H0 + SLAB;             // 3.5  -> nivel del balcón / piso alto
const H1 = 3.0;                   // altura planta alta
const ZDECK = -29.5;              // borde delantero del balcón
const NSTEPS = 18;

export function buildCasaReal(world, group, ox, oz) {
  const f = new Frame(ox, 0, oz, 0);
  const b = new Builder(world, f, group);
  const flora = new Flora();
  const lights = [];

  compoundWalls(b);
  ground(b);
  houseGround(b);
  houseUpper(b);
  balconyAndRails(b);
  curvedStair(b);
  pool(b, world);
  furniture(b);
  garden(b, flora, world, f);
  const meshes = flora.build(group);
  meshes.forEach((m) => m.position.set(ox, 0, oz)); // la vegetación se definió en coordenadas locales del compuesto

  // luces interiores (baratas, sin sombra)
  const l1 = new THREE.PointLight(0xffe2b8, 18, 11, 1.6); l1.position.set(ox + 16, 2.5, oz - 35.7); group.add(l1);
  const l2 = new THREE.PointLight(0xffe2b8, 14, 9, 1.6); l2.position.set(ox + 16, YD + 2.4, oz - 35.7); group.add(l2);
  lights.push(l1, l2);

  // Puntos de interacción
  const P = (lx, lz) => ({ x: f.wx(lx, lz), z: f.wz(lx, lz) });
  world.interactions.add({ ...P(20, -1), y: 0, radius: 3.2, label: 'Portón de la casa', icon: '🏡', action: (g) => g.ui.dialog('Mi casa real', 'Bienvenido a casa. Piscina, palmeras de coco, balcón y escalera curva. Explora todo el patio y sube al segundo nivel.') });
  world.interactions.add({ ...P(12.75, -20.25), y: 0.3, radius: 5.5, label: 'Mirar la piscina', icon: '🏊', action: (g) => g.ui.toast('El agua está tranquila… pronto podrás nadar 🏊') });
  world.interactions.add({ ...P(16, -35.5), y: 0, radius: 3.5, label: 'Sala de la casa', icon: '🛋️', action: (g) => g.ui.toast('Sala: aquí podrás guardar tu partida y cambiarte de ropa (próximamente).') });
  world.interactions.add({ ...P(16, -31.5), y: YD, radius: 3.5, label: 'Balcón', icon: '🌴', action: (g) => g.ui.toast('Desde el balcón se ve todo el patio y las palmeras.') });
  world.interactions.add({ ...P(16, -35.5), y: YD, radius: 3, label: 'Habitación', icon: '🛏️', action: (g) => g.ui.toast('Tu habitación. Aquí podrás dormir para pasar la noche (próximamente).') });

  return { meshes, lights, spawn: P(20, -4) };
}

// ----------------------------------------------------------------- muro y portón
function compoundWalls(b) {
  const T = 0.28, Hh = 2.3, cap = 0.12;
  const wallLine = (x0, z0, x1, z1) => {
    b.wall('stucco', x0, z0, x1, z1, 0, Hh, T, C.wall);
    const alongX = Math.abs(x1 - x0) > Math.abs(z1 - z0);
    if (alongX) b.block('concrete', Math.min(x0, x1) - 0.04, Hh, z0 - T / 2 - 0.05, Math.max(x0, x1) + 0.04, Hh + cap, z0 + T / 2 + 0.05, 0xd8d6cf);
    else b.block('concrete', x0 - T / 2 - 0.05, Hh, Math.min(z0, z1) - 0.04, x0 + T / 2 + 0.05, Hh + cap, Math.max(z0, z1) + 0.04, 0xd8d6cf);
  };
  // frente con portón (hueco x 17..23)
  wallLine(0, 0, 17, 0); wallLine(23, 0, 40, 0);
  wallLine(0, -42, 40, -42); wallLine(0, 0, 0, -42); wallLine(40, 0, 40, -42);
  // pilares del portón + portón de hierro abierto
  for (const x of [17, 23]) {
    b.block('stucco', x - 0.3, 0, -0.35, x + 0.3, 2.6, 0.35, C.wallMid, true);
    b.block('plain', x - 0.38, 2.6, -0.43, x + 0.38, 2.72, 0.43, C.teal);
    b.sph('lamp', x, 2.95, 0, 0.17, 0.17, 0.17, 0xfff1c8, 8);
    b.cyl('plain', x, 2.72, 0, 0.1, 0.15, 0.14, C.teal, 8);
  }
  for (let i = 0; i < 9; i++) { // hoja abierta del portón
    b.box('metal', 17.4 + 0.02, 0.85, 0.9 - i * 0.1 - 0.05 + 0.1, 0.03, 1.6, 0.03, 0x22262a);
  }
  b.box('metal', 17.42, 1.5, 0.45, 0.04, 0.06, 0.95, 0x22262a);
  b.box('metal', 17.42, 0.25, 0.45, 0.04, 0.06, 0.95, 0x22262a);
  // acera de entrada (ladrillo)
  b.block('brick', 18.5, 0, -29.8, 21.5, 0.04, 0.2, 0xffffff);
  b.floorBox(18.5, -29.8, 21.5, 0.2, 0.04);
  b.block('brick', 21.5, 0, -25.6, 29.8, 0.04, -23.2, 0xffffff); // ramal hacia la escalera
  b.floorBox(21.5, -25.6, 29.8, -23.2, 0.04);
  // franja pintada del muro (turquesa a media altura, como en la casa)
  b.fine(() => {
    for (const [x0, z0, x1, z1] of [[0, -42, 40, -42], [0, 0, 0, -42], [40, 0, 40, -42]]) {
      const alongX = Math.abs(x1 - x0) > Math.abs(z1 - z0);
      if (alongX) b.block('plain', x0, 0, z0 - 0.15, x1, 0.45, z0 + 0.15, C.teal);
      else b.block('plain', x0 - 0.15, 0, z0, x0 + 0.15, 0.45, z1, C.teal);
    }
  });
}

function ground(b) {
  // patio de césped + zona de tierra/piedra cerca de la casa, caminos de ladrillo
  b.block('grass', 0.3, -0.03, -41.8, 39.7, 0.0, -0.2, 0x7fa84a);
  // zona de piedra/tierra del patio (como en la foto 3)
  b.block('dirt', 1, 0.0, -29, 15.5, 0.02, -3, 0xd0c4b0);
  // terraza de ladrillo: porche + paso alrededor de la casa
  b.block('brick', HX0 - 0.6, 0, ZF + 0.2, HX1 + 0.6, 0.08, ZW, 0xffffff);
  b.floorBox(HX0 - 0.6, ZW, HX1 + 0.6, ZF + 0.2, 0.08);
}

// ----------------------------------------------------------------- planta baja
function houseGround(b) {
  const w = HX1 - HX0, bay = w / 5; // 5 vanos de 3.2 m
  // zócalo
  b.block('concrete', HX0 - 0.15, 0, ZB - 0.15, HX1 + 0.15, 0.12, ZW + 0.1, 0xcfcdc5);
  // Columnas (turquesa) y arcos de la arcada
  for (let i = 0; i <= 5; i++) {
    const x = HX0 + i * bay;
    const cx = Math.min(Math.max(x, HX0 + 0.25), HX1 - 0.25);
    b.block('stucco', cx - 0.25, 0, ZF - 0.25, cx + 0.25, 1.7, ZF + 0.25, C.teal, true);        // fuste turquesa
    b.block('stucco', cx - 0.25, 1.7, ZF - 0.25, cx + 0.25, H0, ZF + 0.25, C.wall);              // parte alta verde (como foto 1)
    b.block('plain', cx - 0.31, 0.0, ZF - 0.31, cx + 0.31, 0.2, ZF + 0.31, C.tealLight);          // base
  }
  // arcos: panel (tímpano) con hueco semicircular, extruido
  for (let i = 0; i < 5; i++) {
    const x0 = HX0 + i * bay + 0.25, x1 = HX0 + (i + 1) * bay - 0.25, wd = x1 - x0, cx = (x0 + x1) / 2, r = wd / 2;
    const springY = H0 - 0.35 - r;
    const sp = new THREE.Shape();
    sp.moveTo(-wd / 2, 0); sp.lineTo(-r, 0); sp.absarc(0, 0, r, Math.PI, 0, true); sp.lineTo(wd / 2, 0);
    sp.lineTo(wd / 2, r + 0.35); sp.lineTo(-wd / 2, r + 0.35); sp.lineTo(-wd / 2, 0);
    const g = new THREE.ExtrudeGeometry(sp, { depth: 0.4, bevelEnabled: false, curveSegments: 10 });
    b.geo('stucco', g, cx, springY, ZF - 0.2, {}, C.wall);
    const ring = new THREE.RingGeometry(r - 0.02, r + 0.09, 14, 1, 0, Math.PI); // moldura blanca del arco
    b.geo('plain', ring, cx, springY, ZF + 0.21, {}, C.white);
    b.geo('plain', ring, cx, springY, ZF - 0.21, { ry: Math.PI }, C.white);
  }
  // Pared trasera del porche y habitación (sala) con dos puertas abiertas + ventana
  b.wall('stucco', HX0, ZW, HX1, ZW, 0, H0, 0.3, C.wall, [
    { t0: 1.4, t1: 2.5, y0: 0, y1: 2.15, kind: 'door', open: true, trim: C.teal },
    { t0: 4.0, t1: 6.2, y0: 0.9, y1: 2.15, kind: 'window', trim: C.teal, reja: 0x2a2e33 },
    { t0: 7.3, t1: 8.7, y0: 0, y1: 2.15, kind: 'door', open: true, trim: C.teal },
    { t0: 10.4, t1: 12.8, y0: 0.9, y1: 2.15, kind: 'window', trim: C.teal, reja: 0x2a2e33 },
    { t0: 13.6, t1: 14.9, y0: 0, y1: 2.15, kind: 'door', open: true, trim: C.teal },
  ]);
  // paredes laterales y fondo de la sala (planta baja cerrada, accesible solo por las puertas)
  b.wall('stucco', HX0, ZW, HX0, ZB, 0, H0, 0.3, C.wall);
  b.wall('stucco', HX1, ZW, HX1, ZB, 0, H0, 0.3, C.wall);
  b.wall('stucco', HX0, ZB, HX1, ZB, 0, H0, 0.3, C.wall);
  b.wall('stucco', HX0 + 5.6, ZB, HX0 + 5.6, ZW - 1.8, 0, H0, 0.2, C.wall, [{ t0: 0.5, t1: 1.6, y0: 0, y1: 2.1, kind: 'gap' }]);
  // piso interior (tile) + techo
  b.block('tile', HX0 + 0.15, 0.0, ZB + 0.15, HX1 - 0.15, 0.1, ZW, 0xffffff);
  b.floorBox(HX0 + 0.15, ZB + 0.15, HX1 - 0.15, ZW, 0.1);
  // techo del porche y sala = losa del balcón (ver balconyAndRails)
  // pintura del lado interior (techo blanco)
  b.block('plain', HX0, H0 - 0.02, ZB, HX1, H0, ZF, 0xeeece4);
}

// ----------------------------------------------------------------- planta alta
function houseUpper(b) {
  const x0 = HX0 + 1, x1 = HX1 - 1, y0 = YD, y1 = YD + H1;
  // frente de la habitación (con puerta y ventanal) mirando al balcón
  b.wall('stucco', x0, ZW, x1, ZW, y0, y1, 0.3, C.wall, [
    { t0: 1.2, t1: 4.4, y0: y0 + 0.5, y1: y0 + 2.3, kind: 'window', trim: C.teal },
    { t0: 6.0, t1: 7.4, y0: y0, y1: y0 + 2.2, kind: 'door', open: true, trim: C.teal },
    { t0: 9.6, t1: 12.4, y0: y0 + 0.5, y1: y0 + 2.3, kind: 'window', trim: C.teal },
  ]);
  b.wall('stucco', x0, ZW, x0, ZB, y0, y1, 0.3, C.wall);
  b.wall('stucco', x1, ZW, x1, ZB, y0, y1, 0.3, C.wall, [{ t0: 1.2, t1: 3.0, y0: y0 + 1.0, y1: y0 + 2.2, kind: 'window', trim: C.teal }]);
  b.wall('stucco', x0, ZB, x1, ZB, y0, y1, 0.3, C.wall);
  // cortinas (color vino, como en la foto)
  b.box('plain', x0 + 1.5, y0 + 1.4, ZW - 0.22, 0.5, 1.9, 0.08, 0x5a3a4e);
  b.box('plain', x0 + 4.3, y0 + 1.4, ZW - 0.22, 0.5, 1.9, 0.08, 0x5a3a4e);
  // franja turquesa (moldura) alrededor de la planta alta
  b.block('plain', x0 - 0.12, y1 - 0.3, ZB - 0.12, x1 + 0.12, y1, ZW + 0.15, C.teal);
  // losa de techo con parapeto
  b.block('concrete', x0 - 0.3, y1, ZB - 0.3, x1 + 0.3, y1 + 0.25, ZW + 0.5, 0xc9c7bf);
  for (const [a, c, d, e] of [[x0 - 0.3, ZB - 0.3, x1 + 0.3, ZB - 0.15], [x0 - 0.3, ZW + 0.35, x1 + 0.3, ZW + 0.5], [x0 - 0.3, ZB - 0.3, x0 - 0.15, ZW + 0.5], [x1 + 0.15, ZB - 0.3, x1 + 0.3, ZW + 0.5]])
    b.block('stucco', a, y1 + 0.25, c, d, y1 + 0.75, e, C.wall);
  // tinaco (tanque de agua) en el techo
  b.cyl('plain', 12, y1 + 0.25, -36, 0.55, 0.62, 1.2, 0x222428, 14);
  // piso interior alto
  b.block('tile', x0 + 0.15, y0, ZB + 0.15, x1 - 0.15, y0 + 0.05, ZW - 0.15, 0xffffff);
  b.floorBox(x0 + 0.15, ZB + 0.15, x1 - 0.15, ZW - 0.15, y0 + 0.05);
}

// ----------------------------------------------------------------- balcón + barandas
function balconyAndRails(b) {
  // losa del balcón (sobre la arcada): x 8..24 (+aleros), z ZW..ZDECK
  b.block('concrete', HX0 - 0.3, H0 - 0.02 + 0.0, ZW - 0.2, HX1 + 0.3, YD, ZDECK, 0xd3d1c9);
  b.block('plain', HX0 - 0.35, H0 - 0.15, ZDECK - 0.15, HX1 + 0.35, YD - 0.0, ZDECK, C.teal); // canto frontal turquesa
  b.block('tile', HX0 - 0.3, YD, ZW, HX1 + 0.3, YD + 0.04, ZDECK, 0xffffff);
  b.floorBox(HX0 - 0.3, ZW + 0.1, HX1 + 0.3, ZDECK, YD + 0.04);
  // ---- baranda frontal del balcón
  straightRail(b, HX0 - 0.3, ZDECK - 0.08, HX1 + 0.3, ZDECK - 0.08, YD + 0.04);
  // lateral oeste
  straightRail(b, HX0 - 0.3, ZDECK - 0.08, HX0 - 0.3, ZW - 0.1, YD + 0.04);
  // lateral este (parcialmente cubierto por la escalera: hueco al final de la escalera)
  straightRail(b, HX1 + 0.3, ZW - 0.1, HX1 + 0.3, -31.85, YD + 0.04);
  straightRail(b, HX1 + 0.3, -29.85, HX1 + 0.3, ZDECK - 0.08, YD + 0.04);
}

// Baranda recta con balaustres alternados verde/turquesa, pasamanos y colisión
export function straightRail(b, x0, z0, x1, z1, baseY, { H = 1.05, skipStart = 0, skipEnd = 0 } = {}) {
  const dx = x1 - x0, dz = z1 - z0, len = Math.hypot(dx, dz);
  if (len < 0.05) return;
  const ang = Math.atan2(-dz, dx);   // rotación Y
  const ux = dx / len, uz = dz / len;
  const mx = (x0 + x1) / 2, mz = (z0 + z1) / 2;
  // pasamanos y zócalo
  b.box('plain', mx, baseY + H, mz, len, 0.09, 0.2, C.rail, ang);
  b.box('plain', mx, baseY + 0.1, mz, len, 0.2, 0.18, C.teal, ang);
  b.box('plain', mx, baseY + H - 0.16, mz, len, 0.06, 0.13, C.balGreen, ang);
  // balaustres
  const n = Math.max(2, Math.round(len / 0.22));
  const bal = baluster();
  for (let i = 0; i <= n; i++) {
    const t = (i / n) * len;
    const px = x0 + ux * t, pz = z0 + uz * t;
    b.geo('plain', bal, px, baseY + 0.2, pz, {}, i % 2 === 0 ? C.balGreen : C.balBlue);
  }
  // postes
  for (const [px, pz] of [[x0, z0], [x1, z1]]) b.box('plain', px, baseY + H / 2, pz, 0.2, H + 0.05, 0.2, C.teal);
  b.colBox(mx, mz, len / 2 + 0.1, 0.13, baseY, baseY + H, ang);
}

let _bal = null;
function baluster() { // balaustre torneado (perfil de lathe)
  if (_bal) return _bal;
  const pts = [[0.045, 0], [0.05, 0.03], [0.035, 0.07], [0.06, 0.16], [0.07, 0.24], [0.04, 0.34], [0.03, 0.46], [0.05, 0.58], [0.065, 0.66], [0.04, 0.74], [0.04, 0.78], [0.05, 0.82]].map(([x, y]) => new THREE.Vector2(x, y));
  _bal = new THREE.LatheGeometry(pts, 7);
  return _bal;
}

// ----------------------------------------------------------------- escalera curva de ladrillo
function curvedStair(b) {
  const CX = HX1, CZ = -26.4, RI = 3.6, RO = 5.2, A0 = (25 * Math.PI) / 180, A1 = -Math.PI / 2;
  const rise = YD / NSTEPS, span = A1 - A0;
  const poly = (ri, ro, a0, a1, h) => {
    const s = new THREE.Shape(), seg = 6;
    for (let i = 0; i <= seg; i++) { const a = a0 + ((a1 - a0) * i) / seg; i === 0 ? s.moveTo(ro * Math.cos(a), -ro * Math.sin(a)) : s.lineTo(ro * Math.cos(a), -ro * Math.sin(a)); }
    for (let i = seg; i >= 0; i--) { const a = a0 + ((a1 - a0) * i) / seg; s.lineTo(ri * Math.cos(a), -ri * Math.sin(a)); }
    const g = new THREE.ExtrudeGeometry(s, { depth: h, bevelEnabled: false });
    g.rotateX(-Math.PI / 2);
    return g;
  };
  for (let k = 0; k < NSTEPS; k++) {
    const a0 = A0 + (span * k) / NSTEPS, a1 = A0 + (span * (k + 1)) / NSTEPS;
    // cuerpo macizo pintado (verde, base turquesa) + huella de ladrillo rojizo con borde de la pared
    const h = rise * (k + 1);
    b.geo('stucco', poly(RI, RO, a0, a1, h), CX, 0, CZ, {}, k < 3 ? C.teal : C.wallMid);
    b.geo('brick', poly(RI + 0.14, RO - 0.14, a0, a1, 0.04), CX, h - 0.005, CZ, {}, 0xffffff);
  }
  b.floorSector(CX, CZ, RI, RO, A0, A1, rise, NSTEPS, 0);
  // colisión de la masa maciza bajo la escalera: una caja por peldaño (se sube escalón a escalón)
  for (let k = 0; k < NSTEPS; k++) {
    const am = A0 + (span * (k + 0.5)) / NSTEPS, rm = (RI + RO) / 2, arc = (Math.abs(span) / NSTEPS) * rm;
    b.colBox(CX + rm * Math.cos(am), CZ + rm * Math.sin(am), (RO - RI) / 2, arc / 2 + 0.03, 0, rise * (k + 1), -am);
  }
  // barandas curvas con balaustres (interior e exterior)
  const helixRail = (r, skipTop) => {
    const total = Math.abs(span) * r, n = Math.round(total / 0.22);
    const bal = baluster();
    let prev = null;
    for (let i = 0; i <= n; i++) {
      const t = i / n, a = A0 + span * t;
      const x = CX + r * Math.cos(a), z = CZ + r * Math.sin(a);
      const k = Math.min(NSTEPS - 1, Math.floor(t * NSTEPS)), base = (k + 1) * rise;
      b.geo('plain', bal, x, base + 0.02, z, {}, i % 2 === 0 ? C.balGreen : C.balBlue);
      if (i % 2 === 0) b.colCircle(x, z, 0.2, base - 0.05, base + 1.0);
      // pasamanos: tramo entre puntos consecutivos
      const hy = base + 0.02 + 0.82 + 0.02;
      if (prev) {
        const dx = x - prev.x, dz = z - prev.z, dy = hy - prev.y, len = Math.hypot(dx, dy, dz);
        const mx = (x + prev.x) / 2, my = (hy + prev.y) / 2, mz = (z + prev.z) / 2;
        const yaw = Math.atan2(-dz, dx), pitch = Math.atan2(dy, Math.hypot(dx, dz));
        b.box('plain', mx, my, mz, len + 0.03, 0.09, 0.2, C.rail, yaw, 0, pitch);
      }
      prev = { x, z, y: hy };
    }
  };
  helixRail(RO + 0.1, false);
  helixRail(RI - 0.1, false);
  // postes (pilares) al inicio y al final
  for (const [r, a] of [[RO + 0.1, A0], [RI - 0.1, A0]]) {
    const x = CX + r * Math.cos(a), z = CZ + r * Math.sin(a);
    b.block('plain', x - 0.13, 0, z - 0.13, x + 0.13, 1.15, z + 0.13, C.teal);
    b.sph('plain', x, 1.22, z, 0.13, 0.13, 0.13, C.tealLight, 8);
    b.colCircle(x, z, 0.2, 0, 1.4);
  }
}

// ----------------------------------------------------------------- piscina
export const POOL = { x0: 9.5, x1: 16, z0: -26.5, z1: -14, level: 0.34 };
function roundRect(s, x0, z0, x1, z1, r) { // en espacio Shape: y = -z
  const ya = -z0, yb = -z1; // ya > yb
  s.moveTo(x0 + r, yb);
  s.lineTo(x1 - r, yb); s.quadraticCurveTo(x1, yb, x1, yb + r);
  s.lineTo(x1, ya - r); s.quadraticCurveTo(x1, ya, x1 - r, ya);
  s.lineTo(x0 + r, ya); s.quadraticCurveTo(x0, ya, x0, ya - r);
  s.lineTo(x0, yb + r); s.quadraticCurveTo(x0, yb, x0 + r, yb);
}
function pool(b, world) {
  const { x0, x1, z0, z1 } = POOL, cope = 0.55, wallH = 0.46;
  // borde de ladrillo (anillo elevado)
  const outer = new THREE.Shape(); roundRect(outer, x0 - cope, z0 - cope, x1 + cope, z1 + cope, 1.3);
  const hole = new THREE.Path(); roundRect(hole, x0, z0, x1, z1, 0.9);
  outer.holes.push(hole);
  const g = new THREE.ExtrudeGeometry(outer, { depth: wallH, bevelEnabled: false, curveSegments: 6 });
  g.rotateX(-Math.PI / 2);
  b.geo('brick', g, 0, 0, 0, {}, 0xffffff);
  // paredes interiores (azulejo celeste) y fondo
  const inner = new THREE.Shape(); roundRect(inner, x0, z0, x1, z1, 0.9);
  const gi = new THREE.ExtrudeGeometry(inner, { depth: 0.3, bevelEnabled: false, curveSegments: 6 });
  gi.rotateX(-Math.PI / 2);
  b.geo('plain', gi, 0, 0.0, 0, {}, 0x4fa9a8);
  // escalones dentro de la piscina (extremo cercano a la casa)
  // colisión: el agua no se puede caminar; el borde sí (se camina alrededor)
  b.colBox((x0 + x1) / 2, (z0 + z1) / 2, (x1 - x0) / 2 + cope - 0.05, (z1 - z0) / 2 + cope - 0.05, 0, wallH + 0.1);
  // baranda de acero (escalera) en el lado cercano a la casa
  const rx = x0 + 1.2, zr = z0 - 0.1;
  const steel = (x, y, z, len, rx_, rz_) => b.geo('metal', new THREE.CylinderGeometry(0.025, 0.025, 1, 6), x, y, z, { rx: rx_, rz: rz_, sy: len }, 0xd2d6da);
  steel(rx, wallH + 0.5, z0 - 0.35, 1.0, 0, 0); steel(rx + 0.6, wallH + 0.5, z0 - 0.35, 1.0, 0, 0);
  steel(rx + 0.3, wallH + 1.0, z0 - 0.35, 0.6, 0, Math.PI / 2);
  // tubería/limpiapiscinas junto al borde
  b.fine(() => {
    b.geo('metal', new THREE.CylinderGeometry(0.03, 0.03, 1, 6), x1 + 0.2, 0.45, z1 + 0.5, { rx: Math.PI / 2, sy: 2.4 }, 0x3b7bbf);
  });
  // chorritos de agua (decorativo): conos blancos
  for (const px of [x0 + 1.6, x1 - 1.6]) b.cyl('plain', px, 0.3, z0 + 0.25, 0.05, 0.12, 0.25, 0xdff6ff, 6);
  // agua (malla propia animada)
  const water = new THREE.Shape(); roundRect(water, x0 + 0.04, z0 + 0.04, x1 - 0.04, z1 - 0.04, 0.88);
  const wg = new THREE.ShapeGeometry(water, 10); wg.rotateX(-Math.PI / 2);
  const uv = wg.attributes.uv, pos = wg.attributes.position;
  for (let i = 0; i < uv.count; i++) uv.setXY(i, pos.getX(i) / 3, pos.getZ(i) / 3);
  const bump = Tex.waterBump(); bump.repeat.set(1, 1);
  const mat = new THREE.MeshStandardMaterial({ color: 0x2a9e8f, roughness: 0.12, metalness: 0.25, bumpMap: bump, bumpScale: 2.2, transparent: true, opacity: 0.88 });
  const mesh = new THREE.Mesh(wg, mat);
  mesh.position.set(b.f.x, POOL.level, b.f.z);
  mesh.receiveShadow = true; mesh.name = 'poolWater';
  b.group.add(mesh);
  world.animated.push({ update: (t) => { bump.offset.set(t * 0.03, t * 0.02); } });
}

// ----------------------------------------------------------------- mobiliario
function furniture(b) {
  // Porche: mesa de comedor con sillas (foto 3)
  const tx = 12, tz = -31.6;
  b.box('plain', tx, 0.78, tz, 1.8, 0.06, 0.9, 0x6d4a2f);
  b.block('plain', tx - 0.85, 0.08, tz - 0.4, tx - 0.78, 0.78, tz - 0.33, 0x4a3320); b.block('plain', tx + 0.78, 0.08, tz - 0.4, tx + 0.85, 0.78, tz - 0.33, 0x4a3320);
  b.block('plain', tx - 0.85, 0.08, tz + 0.33, tx - 0.78, 0.78, tz + 0.4, 0x4a3320); b.block('plain', tx + 0.78, 0.08, tz + 0.33, tx + 0.85, 0.78, tz + 0.4, 0x4a3320);
  b.colBox(tx, tz, 0.95, 0.5, 0, 0.9);
  for (const [dx, dz] of [[-0.5, 0.75], [0.5, 0.75], [-0.5, -0.75], [0.5, -0.75]]) { b.box('plain', tx + dx, 0.48, tz + dz, 0.42, 0.06, 0.42, 0xf3f0e6); b.box('plain', tx + dx, 0.75, tz + dz + (dz > 0 ? 0.2 : -0.2), 0.42, 0.5, 0.05, 0xf3f0e6); b.block('plain', tx + dx - 0.18, 0.08, tz + dz - 0.18, tx + dx - 0.14, 0.48, tz + dz - 0.14, 0x888); b.block('plain', tx + dx + 0.14, 0.08, tz + dz + 0.14, tx + dx + 0.18, 0.48, tz + dz + 0.18, 0x888); }
  // banco de hierro y barra
  b.box('metal', 17.5, 0.42, -31.4, 1.5, 0.08, 0.5, 0x23262a); b.box('metal', 17.5, 0.75, -31.65, 1.5, 0.5, 0.06, 0x23262a);
  b.colBox(17.5, -31.4, 0.78, 0.28, 0, 0.9);
  // Sala interior (planta baja)
  b.block('plain', 9, 0.1, -37.5, 11.5, 0.55, -36.2, 0x6a4a58, true); // sofá
  b.block('plain', 9, 0.55, -37.5, 11.5, 1.0, -37.2, 0x6a4a58);
  b.block('plain', 18.5, 0.1, -37.6, 22, 0.7, -36.8, 0x3a2a22, true);   // mueble TV
  b.box('plain', 20.2, 1.2, -37.7, 1.3, 0.8, 0.06, 0x101010);
  b.block('plain', 12.0, 0.1, -37.2, 13.6, 0.45, -36.2, 0x5a4030, true);   // mesita
  // Habitación (planta alta): cama, mesita, ropero
  const y = YD + 0.05;
  b.block('plain', 18, y, -37.7, 21.5, y + 0.45, -35.7, 0xf0e8de, true);
  b.block('plain', 18, y + 0.45, -37.7, 21.5, y + 1.0, -37.45, 0x7a5a40);
  b.block('plain', 10.2, y, -37.7, 12.4, y + 2.0, -36.8, 0x6d4a2f, true); // ropero
  b.block('plain', 21.7, y, -37.5, 22.5, y + 0.5, -36.8, 0x6d4a2f, true);
  // macetas en la esquina del balcón (como en la foto)
  for (const [x, z, s] of [[HX0 - 0.1, ZDECK - 0.2, 1], [HX0 + 3.2, ZDECK - 0.2, 1.1], [HX1 - 0.1, ZDECK - 0.2, 1], [HX1 - 3.5, ZDECK - 0.2, 0.9]]) {
    b.cyl('plain', x, YD + 1.12, z, 0.2 * s, 0.14 * s, 0.34 * s, 0xb4553a, 10);
    b.sph('plain', x, YD + 1.58, z, 0.3 * s, 0.26 * s, 0.3 * s, 0x4a8f35, 7);
  }
  // tumbonas turquesa
  for (const [x, z, r] of [[31, -9.5, 0.3], [33.4, -11.8, -0.2]]) {
    b.box('plain', x, 0.28, z, 0.7, 0.07, 1.9, 0x39c6c8, r);
    b.box('plain', x - Math.sin(r) * 0.8, 0.58, z - Math.cos(r) * 0.8, 0.7, 0.07, 0.8, 0x39c6c8, r, 0.8);
    b.colBox(x, z, 0.4, 1.0, 0, 0.5, r);
  }
  // columna de concreto con varillas (foto 3)
  b.block('concrete', 26.7, 0, -17.3, 27.3, 4.0, -16.7, 0xb9b7b0, true);
  for (const [dx, dz] of [[-0.18, -0.18], [0.18, -0.18], [0.18, 0.18], [-0.18, 0.18]]) b.cyl('metal', 27 + dx, 4.0, -17 + dz, 0.013, 0.013, 0.8, 0x6b5a50, 5);
}

// ----------------------------------------------------------------- jardín
function garden(b, flora, world, f) {
  const W = (lx, lz) => [f.wx(lx, lz), f.wz(lx, lz)];
  // Palmeras de coco altas (foto 2 y 3)
  const palms = [[10.4, -28.6, 'palm0', 1.15, 0.0], [22.2, -27.4, 'palm1', 1.1, 0.0], [31, -15, 'palm2', 0.95, 0], [4.5, -11, 'palm0', 0.9, 2], [35.5, -34, 'palm1', 1.0, 1], [6, -34, 'palm2', 1.05, 3], [27, -39, 'palm0', 1.1, 4], [3, -22, 'palm1', 0.85, 5]];
  for (const [x, z, k, s, r] of palms) { flora.add(k, x, 0, z, { s, ry: r }); b.colCircle(x, z, 0.4 * s, 0, 9); }
  // árboles de fondo (mango) + banano
  for (const [x, z, k, s] of [[34, -29, 'tree', 1.1], [3.5, -37, 'tree2', 1.2], [37, -9, 'tree', 0.95], [33, -38.5, 'tree2', 1.0]]) { flora.add(k, x, 0, z, { s }); b.colCircle(x, z, 0.38 * s, 0, 5); }
  for (const [x, z] of [[2.5, -30], [2.2, -28.2], [38, -20], [37.4, -22]]) flora.add('banana', x, 0, z, { s: 1, ry: x });
  // zonas donde NO crece vegetación: huella de la casa, piscina, masa de la escalera y camino de entrada
  const bad = (x, z) => (x > 6.5 && x < 25.5 && z > -39 && z < -29) || (x > 8.4 && x < 17 && z > -27.6 && z < -13.4)
    || Math.hypot(x - 24, z + 26.4) < 5.8 || (x > 18.2 && x < 21.8 && z > -30) || (x > 21.5 && x < 30 && z > -26 && z < -22.8);
  // Cercanía de la arcada (como foto 1): jengibre rosado + ti rojo + plumeros, dentro de la curva de la escalera
  const near = [[25.0, -29.0, 'ginger', 1.3], [26.3, -28.1, 'ginger', 1.1], [24.2, -28.4, 'ginger', 1.0], [7.2, -29.2, 'ti', 1.2], [6.8, -28, 'ti', 1.0], [7.6, -26.9, 'celosia', 1.2], [25.6, -26.9, 'ti', 1.1]];
  for (const [x, z, k, s] of near) flora.add(k, x, 0, z, { s, ry: x * 2 });
  // arriates a lo largo de los muros y del camino
  const rng = (i) => { const s = Math.sin(i * 12.9898) * 43758.5453; return s - Math.floor(s); };
  const kindsB = ['croton', 'ti', 'celosia', 'ginger', 'croton'];
  for (let i = 0; i < 38; i++) { // franja izquierda y derecha
    const side = i % 2 ? 1.6 : 38.4, z = -3 - (i * 1.0) % 36, x = side + (rng(i) - 0.5) * 0.8;
    if (!bad(x, z)) flora.add(kindsB[i % 5], x, 0, z, { s: 0.75 + rng(i + 3) * 0.4, ry: i });
  }
  for (let i = 0; i < 12; i++) { // junto a la entrada
    if (!bad(14.8, -2 - i * 1.7)) flora.add(kindsB[i % 5], 14.8 - (i % 3) * 0.1, 0, -2 - i * 1.7, { s: 0.8 + rng(i) * 0.3 });
    if (!bad(24.6, -2 - i * 1.7)) flora.add(kindsB[(i + 2) % 5], 24.6 + (i % 3) * 0.1, 0, -2 - i * 1.7, { s: 0.8 + rng(i + 5) * 0.3 });
  }
  for (let i = 0; i < 40; i++) { const x = 1 + rng(i) * 38, z = -2 - rng(i + 9) * 39; if (!bad(x, z)) flora.add('tuft', x, 0, z, { s: 1 + rng(i + 2), ry: i }); }
  // seto bajo en el muro del fondo
  flora.add('hedge', 20, 0, -41.2, { sx: 38, sy: 1.1, sz: 0.9 });
  // plantas alrededor de la piscina (ti rojo, como la foto 2)
  for (const [x, z] of [[8.2, -16], [17.6, -14.4], [8.3, -25.5], [17.7, -26.4], [12, -12.4]]) flora.add('ti', x, 0, z, { s: 1.3, ry: x });
  // motos estacionadas junto al portón (identidad dominicana)
  const v = createVehicle('cg150', world.mats, { color: 0xc0262d });
  v.group.position.set(f.wx(30, -4), 0, f.wz(30, -4)); v.group.rotation.y = -0.4; b.group.add(v.group);
  b.colBox(30, -4, 0.45, 1.0, 0, 1.2, -0.4);
  world.interactions.add({ x: f.wx(30, -4), z: f.wz(30, -4), y: 0, radius: 2.2, label: 'Honda CG 150', icon: '🏍️', action: (g) => g.ui.toast('Honda CG 150 — próximamente podrás subirte y conducirla.') });
}
