import * as THREE from 'three';
import { Builder, Frame } from '../core/Builder.js';
import { Rng } from '../core/Rng.js';
import { Flora } from './Flora.js';
import { buildHouse } from '../buildings/HouseBuilder.js';
import { buildColmado } from '../buildings/Colmado.js';
import { buildCasaReal } from '../special/CasaReal.js';
import { mainStreet, crossStreet, crosswalk, speedBump, pole, wirePoles, cable, CROSS } from './Streets.js';
import { createVehicle } from '../vehicles/VehicleCatalog.js';
import { trashBin, crateStack } from './Props.js';

// ===== Definición de ZONAS (carga progresiva) =====
// Cada zona se construye de forma asíncrona (cediendo el hilo entre pasos) y puede descargarse.
// Para añadir un barrio nuevo: crea otra entrada en ZONES con su caja y su función build().

const tick = () => new Promise((r) => requestAnimationFrame(() => r()));
const HOUSE_Z = 9.9;   // plano de fachada: |z|
const CROSS_GAPS = [[-30.5, -19.5]];

function houseRow(ctx, flora, rng, { xa, xb, side, reserved = [], twoFloorP = 0.35, poles = [] }) {
  const N = side === 'N';
  let x = xa + rng.range(0, 1.5);
  const houses = [];
  while (x < xb - 7.5) {
    const w = rng.range(7.5, 10.5), x1 = x + w;
    const hit = reserved.find(([a, c]) => x1 > a && x < c);
    if (hit) { x = hit[1] + 0.6; continue; }
    const d = rng.range(8, 11.5), xc = x + w / 2;
    const frame = N ? new Frame(xc, 0, -HOUSE_Z, 0) : new Frame(xc, 0, HOUSE_Z, Math.PI);
    const floors = rng.chance(twoFloorP) ? 2 : 1;
    const info = buildHouse(ctx, ctx.group, frame, { w, d, floors, seed: rng.int(1, 1e6) });
    houses.push({ xc, w, d, floors, frame });
    // acometida eléctrica desde el poste más cercano
    const np = poles.reduce((m, p) => (!m || Math.abs(p.x - xc) < Math.abs(m.x - xc) ? p : m), null);
    if (np && Math.abs(np.x - xc) < 16) cable(ctx, [np.x, 7.8, np.z], [xc + 0.5, floors === 2 ? 6.3 : 3.5, (N ? -1 : 1) * (HOUSE_Z - 0.1)], 0.8, 0x151515, 0.02);
    // árbol/palma en el patio trasero o lateral
    const back = (N ? -1 : 1) * (HOUSE_Z + d + rng.range(1.5, 5));
    if (rng.chance(0.6)) { const k = rng.pick(['palm0', 'palm1', 'palm2', 'tree', 'tree2']); flora.add(k, xc + rng.range(-w / 2, w / 2), 0, back, { s: rng.range(0.85, 1.2), ry: rng.next() * 6 }); ctx.__cols.push([xc, back]); }
    const gap = rng.range(0.7, 3.8);
    if (gap > 2.4 && rng.chance(0.8)) { // lote entre casas: palma o mango
      const gx = x1 + gap / 2, gz = (N ? -1 : 1) * (HOUSE_Z + rng.range(2, 5));
      flora.add(rng.pick(['palm0', 'palm1', 'tree']), gx, 0, gz, { s: rng.range(0.9, 1.15), ry: rng.next() * 6 }); ctx.__cols.push([gx, gz]);
    }
    x = x1 + gap;
  }
  return houses;
}

function poleRow(ctx, xa, xb, z, yawLamp, skip = []) {
  const out = [];
  for (let x = Math.ceil(xa / 24) * 24; x < xb; x += 24) {
    if (skip.some(([a, b]) => x > a && x < b)) continue;
    pole(ctx, x, z, { lamp: out.length % 2 === 0, transformer: out.length % 4 === 1, yaw: Math.PI / 2, lampSide: yawLamp });
    out.push({ x, z });
  }
  return out;
}

async function commonStrip(ctx, xa, xb, seed, opts = {}) {
  const rng = new Rng(seed);
  const flora = new Flora();
  ctx.__cols = [];
  mainStreet(ctx, xa, xb, CROSS_GAPS);
  await tick();
  // postes: norte (z=-5.2) lámpara hacia +x local invertida
  const pn = poleRow(ctx, xa, xb, -5.2, -1, [[-30, -20]]);
  const ps = poleRow(ctx, xa + 12, xb, 5.2, 1, [[-30, -20]]);
  wirePoles(ctx, pn); wirePoles(ctx, ps);
  for (const p of pn) { const q = ps.find((s) => Math.abs(s.x - p.x) < 13); if (q && rng.chance(0.5)) for (const dz of [-0.5, 0.5]) cable(ctx, [p.x, 8.4, p.z + dz * 0], [q.x, 8.2, q.z + dz * 0], 0.9, 0x151515, 0.02); }
  await tick();
  const hn = houseRow(ctx, flora, rng, { xa, xb, side: 'N', reserved: [...(opts.reservedN || []), [-30.8, -19.2]], poles: pn });
  await tick();
  const hs = houseRow(ctx, flora, rng, { xa, xb, side: 'S', reserved: [...(opts.reservedS || []), [-30.8, -19.2]], poles: ps });
  await tick();
  // motos y detalles de la calle
  const motos = ['cg150', 'cg150', 'cg300', 'motoconcho', 'cg150'];
  for (let i = 0; i < 6; i++) {
    const h = rng.pick([...hn, ...hs]); if (!h) continue;
    const id = rng.pick(motos), col = rng.pick([0xc0262d, 0x1c1c1f, 0x2060c0, 0xf2f2f2, 0x2a8f4a, 0xf2c94c]);
    const v = createVehicle(id, ctx.mats, { color: col });
    const north = h.frame.z < 0, z = (north ? -1 : 1) * (HOUSE_Z - 0.2 + 1.2);
    const x = h.xc + rng.range(-h.w / 2 + 0.8, h.w / 2 - 0.8);
    v.group.position.set(x, 0.05, z); v.group.rotation.y = north ? Math.PI : 0; ctx.group.add(v.group);
    const f = new Frame(x, 0, z, v.group.rotation.y);
    new Builder(ctx, f, ctx.group).colBox(0, 0, 0.4, 0.95, 0, 1.2);
    if (i < 2) ctx.interactions.add({ x, z, y: 0, radius: 2.0, label: v.spec.name, icon: '🏍️', action: (g) => g.ui.toast(`${v.spec.name} — próximamente podrás subirte y conducir.`) });
  }
  const bins = new Builder(ctx, new Frame(0, 0, 0), ctx.group);
  for (let i = 0; i < 5; i++) {
    const h = rng.pick([...hn, ...hs]); if (!h) continue;
    const north = h.frame.z < 0;
    trashBin(bins, h.xc + h.w / 2 - 0.3, (north ? -1 : 1) * 6.6, rng.pick([0x2a6fb8, 0x2a8f4a, 0x555a60]));
  }
  // matas altas y árboles de la acera (flora)
  for (let x = Math.ceil(xa / 6) * 6; x < xb; x += 6) for (const z of [-6.35, 6.35]) if (rng.chance(0.35) && !(x > -31 && x < -19)) flora.add(rng.pick(['tuft', 'croton', 'ti']), x + rng.range(-1, 1), 0, z, { s: rng.range(0.8, 1.3) });
  // vegetación de fondo
  for (let i = 0; i < Math.round((xb - xa) / 5); i++) {
    const x = xa + rng.next() * (xb - xa), z = (rng.chance(0.5) ? -1 : 1) * rng.range(24, 46);
    if (opts.noBackNorth && z < 0 && x > opts.noBackNorth[0] && x < opts.noBackNorth[1]) continue;
    flora.add(rng.pick(['palm0', 'palm1', 'palm2', 'tree', 'tree2', 'banana']), x, 0, z, { s: rng.range(0.8, 1.3), ry: rng.next() * 6 }); ctx.__cols.push([x, z]);
  }
  for (const [x, z] of ctx.__cols) new Builder(ctx, new Frame(x, 0, z), ctx.group).colCircle(0, 0, 0.4, 0, 8);
  flora.build(ctx.group);
  return { hn, hs, rng };
}

// ---------------- cancha de baloncesto del barrio ----------------
function cancha(ctx, cx, cz) {
  const b = new Builder(ctx, new Frame(cx, 0, cz), ctx.group);
  b.block('concrete', -14, 0, -7.5, 14, 0.06, 7.5, 0x8a9fb5); b.floorBox(-14, -7.5, 14, 7.5, 0.06);
  b.fine(() => {
    const L = 0xf2f2f2;
    b.block('plain', -13, 0.06, -6.5, 13, 0.07, -6.42, L); b.block('plain', -13, 0.06, 6.42, 13, 0.07, 6.5, L);
    b.block('plain', -13, 0.06, -6.5, -12.92, 0.07, 6.5, L); b.block('plain', 12.92, 0.06, -6.5, 13, 0.07, 6.5, L); b.block('plain', -0.04, 0.06, -6.5, 0.04, 0.07, 6.5, L);
    for (const sx of [-1, 1]) { b.block('plain', sx * 13 - sx * 5.8, 0.06, -2.4, sx * 13, 0.07, -2.32, L); b.block('plain', sx * 13 - sx * 5.8, 0.06, 2.32, sx * 13, 0.07, 2.4, L); b.block('plain', sx * 13 - sx * 5.8, 0.06, -2.4, sx * 13 - sx * 5.72, 0.07, 2.4, L); }
  });
  for (const sx of [-1, 1]) {
    b.cyl('metal', sx * 13.6, 0, 0, 0.09, 0.11, 3.2, 0x44484c, 8);
    b.box('plain', sx * 13.0, 3.1, 0, 0.08, 1.05, 1.8, 0xf2f2f2);
    b.geo('metal', new THREE.TorusGeometry(0.23, 0.02, 6, 14), sx * 12.65, 2.85, 0, { rx: Math.PI / 2 }, 0xe0561e);
    b.colCircle(sx * 13.6, 0, 0.2, 0, 3.3);
  }
  // muro bajo alrededor
  b.block('stucco', -14.2, 0, -7.8, 14.2, 0.9, -7.6, 0xe9c46a, true);
  b.block('stucco', -14.2, 0, 7.6, 14.2, 0.9, 7.8, 0xe9c46a, false);
  b.colBox(0, 7.7, 14.2, 0.1, 0, 0.9);
}

export const ZONES = [
  {
    id: 'centro', box: [-34, -64, 6, 64], preload: true, loadDist: 400, unloadDist: 9999,
    async build(ctx) {
      const { rng } = await commonStrip(ctx, -34, 6, 101, { reservedS: [[-18.6, -7.4]] });
      // calles transversales
      crossStreet(ctx, 4, 64); crossStreet(ctx, -64, -4);
      crosswalk(ctx, -33, 0, false); crosswalk(ctx, -17, 0, false); crosswalk(ctx, CROSS.x, 7.5, true); crosswalk(ctx, CROSS.x, -7.5, true);
      speedBump(ctx, -4); speedBump(ctx, -36);
      await tick();
      // casas en la calle transversal
      const fl = new Flora(); const cols = [];
      for (const side of ['W', 'E']) for (const sgn of [-1, 1]) {
        let z = 22 + rng.range(0, 1);
        while (z < 60) {
          const w = rng.range(7.5, 10), d = rng.range(8, 11);
          const zc = sgn * (z + w / 2);
          const frame = side === 'W' ? new Frame(-34.4, 0, zc, Math.PI / 2) : new Frame(-15.6, 0, zc, -Math.PI / 2);
          buildHouse(ctx, ctx.group, frame, { w, d, floors: rng.chance(0.3) ? 2 : 1, seed: rng.int(1, 1e6) });
          z += w + rng.range(0.8, 3);
        }
      }
      for (const sgn of [-1, 1]) for (let z = 20; z < 62; z += 22) pole(ctx, CROSS.x - 5.3, sgn * z, { lamp: true, lampSide: 1, yaw: 0 });
      // colmado (esquina sur) — frente hacia la calle (-z)
      buildColmado(ctx, ctx.group, new Frame(-13, 0, 10.4, Math.PI));
      // motos del colmado (motoconchos)
      for (const [x, z, a, c] of [[-9.6, 8.1, 0.9, 0xc0262d], [-16.2, 8.3, -0.5, 0x2060c0]]) {
        const v = createVehicle('motoconcho', ctx.mats, { color: c }); v.group.position.set(x, 0.06, z); v.group.rotation.y = a; ctx.group.add(v.group);
        new Builder(ctx, new Frame(x, 0, z, a), ctx.group).colBox(0, 0, 0.4, 0.95, 0, 1.2);
      }
      const car = createVehicle('carro', ctx.mats, { color: 0x7ea1c2 }); car.group.position.set(-2.5, 0, 2.6); car.group.rotation.y = 0; ctx.group.add(car.group);
      new Builder(ctx, new Frame(-2.5, 0, 2.6), ctx.group).colBox(0, 0, 2.15, 0.9, 0, 1.6);
      ctx.interactions.add({ x: -2.5, z: 2.6, y: 0, radius: 3.4, label: 'Carro público', icon: '🚗', action: (g) => g.ui.toast('Carro público — conducción en una fase futura.') });
      fl.build(ctx.group);
    },
  },
  {
    id: 'oeste', box: [-120, -64, -34, 64], preload: false, loadDist: 70, unloadDist: 150,
    async build(ctx) {
      await commonStrip(ctx, -120, -34, 202, { twoFloor: 0.4 });
    },
  },
  {
    id: 'este', box: [6, -64, 120, 64], preload: false, loadDist: 70, unloadDist: 150,
    async build(ctx) {
      await commonStrip(ctx, 6, 120, 303, { reservedN: [[4.8, 47.4]], noBackNorth: [4, 48] });
      cancha(ctx, 86, 24);
      // algunos vehículos en la calle
      const car = createVehicle('guagua', ctx.mats, { color: 0xf3f0e6 }); car.group.position.set(60, 0, -2.4); car.group.rotation.y = Math.PI; ctx.group.add(car.group);
      new Builder(ctx, new Frame(60, 0, -2.4, Math.PI), ctx.group).colBox(0, 0, 2.8, 1.05, 0, 2.4);
      ctx.interactions.add({ x: 60, z: -2.4, y: 0, radius: 4, label: 'Guagua (voladora)', icon: '🚌', action: (g) => g.ui.toast('La guagua llevará pasajeros entre barrios (fase futura).') });
    },
  },
  {
    id: 'casaReal', box: [6, -49, 46, -7], preload: false, loadDist: 120, unloadDist: 9999,
    async build(ctx) {
      const r = buildCasaReal(ctx, ctx.group, 6, -7);
      ctx.extra = r;
    },
  },
];
