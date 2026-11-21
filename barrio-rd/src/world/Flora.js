import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { Rng } from '../core/Rng.js';
import { Tex } from '../core/Textures.js';

// Vegetación tropical con InstancedMesh: miles de plantas con muy pocos draw calls.

const col = new THREE.Color();
const hash3 = (x, y, z) => { const s = Math.sin(x * 127.1 + y * 311.7 + z * 74.7) * 43758.5453; return s - Math.floor(s); };

function colorize(geo, fn) {
  const p = geo.attributes.position, n = p.count, c = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { fn(col, p.getX(i), p.getY(i), p.getZ(i), i); c[i * 3] = col.r; c[i * 3 + 1] = col.g; c[i * 3 + 2] = col.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(c, 3));
  return geo;
}
function stripAttrs(g, keep) { for (const k of Object.keys(g.attributes)) if (!keep.includes(k)) g.deleteAttribute(k); return g; }

// Blob de follaje (icosfera deformada) con color degradado
function blob(base, cx, cy, cz, sx, sy, sz, seed = 1, jitter = 0.18) {
  const g = new THREE.IcosahedronGeometry(1, 1);
  const p = g.attributes.position;
  for (let i = 0; i < p.count; i++) {
    const x = p.getX(i), y = p.getY(i), z = p.getZ(i);
    const k = 1 + (hash3(x * 3 + seed, y * 3, z * 3) - 0.5) * jitter * 2;
    p.setXYZ(i, cx + x * sx * k, cy + y * sy * k, cz + z * sz * k);
  }
  colorize(g, (c, x, y, z) => {
    const t = THREE.MathUtils.clamp((y - cy) / sy * 0.5 + 0.5, 0, 1);
    c.set(base).multiplyScalar(0.62 + 0.55 * t).offsetHSL(0, 0, (hash3(x, y, z) - 0.5) * 0.05);
  });
  return stripAttrs(g, ['position', 'normal', 'color']);
}

// Hoja alargada curva (hoja de ti / banana): parámetros en ángulos
function blade(len, wid, color, yaw, pitch, droop, cx = 0, cy = 0, cz = 0, seg = 5, tint = 0.12) {
  const pos = [], idx = [];
  let px = 0, py = 0, th = pitch;
  const dl = len / seg;
  for (let i = 0; i <= seg; i++) {
    const t = i / seg, w = wid * (Math.sin(Math.PI * Math.min(1, t * 0.9 + 0.1)) * 0.8 + 0.2) * (i === seg ? 0.15 : 1);
    pos.push(px, py, -w / 2, px, py - w * 0.12, w / 2);
    px += Math.cos(th) * dl; py += Math.sin(th) * dl; th -= droop / seg;
  }
  for (let i = 0; i < seg; i++) { const a = i * 2; idx.push(a, a + 1, a + 2, a + 1, a + 3, a + 2); }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  g.setIndex(idx);
  g.computeVertexNormals();
  g.rotateY(yaw); g.translate(cx, cy, cz);
  colorize(g, (c, x, y, z, i) => { c.set(color).multiplyScalar(0.8 + 0.3 * (i / g.attributes.position.count) + (hash3(x, y, z) - 0.5) * tint); });
  return g.toNonIndexed();
}

function cone(r, h, base, cx, cy, cz, seg = 6, tilt = 0) {
  const g = new THREE.ConeGeometry(r, h, seg, 1);
  g.translate(0, h / 2, 0); g.rotateZ(tilt); g.translate(cx, cy, cz);
  colorize(g, (c, x, y) => c.set(base).multiplyScalar(0.8 + (y - cy) / h * 0.4));
  return stripAttrs(g.toNonIndexed(), ['position', 'normal', 'color']);
}

function cylG(r0, r1, h, base, cx, cy, cz, seg = 7) {
  const g = new THREE.CylinderGeometry(r1, r0, h, seg, 1);
  g.translate(cx, cy + h / 2, cz);
  colorize(g, (c, x, y) => c.set(base).multiplyScalar(0.8 + 0.3 * ((y - cy) / h)));
  return stripAttrs(g.toNonIndexed(), ['position', 'normal', 'color']);
}

// -------- Geometrías de cada tipo --------
function makePalm(seed) {
  const rng = new Rng(seed);
  const H = 8.2, J = 22, N = 9, lean = rng.range(-0.9, 0.9), leanZ = rng.range(-0.4, 0.4);
  const pos = [], cols = [], idx = [];
  const center = (t) => [lean * t * t, t * H, leanZ * t * t];
  for (let j = 0; j <= J; j++) {
    const t = j / J, [cx, cy, cz] = center(t);
    const r = 0.17 * (1 - 0.3 * t) + 0.16 * Math.exp(-t * 14);
    const ring = (j % 2 === 0) ? 0x8f8070 : 0x6c5d4d;
    col.set(ring).multiplyScalar(0.85 + (hash3(j, seed, 1) - 0.5) * 0.2);
    for (let k = 0; k < N; k++) {
      const a = (k / N) * Math.PI * 2;
      pos.push(cx + Math.cos(a) * r, cy, cz + Math.sin(a) * r);
      cols.push(col.r, col.g, col.b);
    }
  }
  for (let j = 0; j < J; j++) for (let k = 0; k < N; k++) {
    const a = j * N + k, b = j * N + ((k + 1) % N), c = (j + 1) * N + k, d = (j + 1) * N + ((k + 1) % N);
    idx.push(a, c, b, b, c, d);
  }
  let trunk = new THREE.BufferGeometry();
  trunk.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  trunk.setAttribute('color', new THREE.Float32BufferAttribute(cols, 3));
  trunk.setIndex(idx); trunk.computeVertexNormals();
  trunk = trunk.toNonIndexed();
  const [tx, ty, tz] = center(1);
  // cocos bajo la corona
  const cocos = [];
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * 6.28, g = new THREE.SphereGeometry(0.15, 6, 5);
    g.translate(tx + Math.cos(a) * 0.28, ty - 0.2 - (i % 2) * 0.12, tz + Math.sin(a) * 0.28);
    colorize(g, (c) => c.set(i % 2 ? 0x6f8a2a : 0x4f7a2a));
    cocos.push(g.toNonIndexed());
  }
  trunk = mergeGeometries([trunk, ...cocos.map((g) => stripAttrs(g, ['position', 'normal', 'color']))]);

  // fronds
  const parts = [];
  const NF = 15;
  for (let i = 0; i < NF; i++) {
    const phi = (i / NF) * Math.PI * 2 + rng.range(-0.15, 0.15);
    const pitch = i % 3 === 0 ? rng.range(0.9, 1.15) : i % 3 === 1 ? rng.range(0.3, 0.6) : rng.range(-0.05, 0.25);
    const len = rng.range(3.4, 4.3), droop = rng.range(1.2, 1.9);
    const S = 9, pp = [], uu = [], ii = [];
    let px = 0, py = 0, th = pitch;
    const W = 1.5;
    for (let s = 0; s <= S; s++) {
      const t = s / S;
      pp.push(px, py, -W / 2, px, py - 0.22, W / 2); // forma de V
      uu.push(t, 0, t, 1);
      px += Math.cos(th) * (len / S); py += Math.sin(th) * (len / S); th -= droop / S * (0.4 + t);
    }
    for (let s = 0; s < S; s++) { const a = s * 2; ii.push(a, a + 1, a + 2, a + 1, a + 3, a + 2); }
    const g = new THREE.BufferGeometry();
    g.setAttribute('position', new THREE.Float32BufferAttribute(pp, 3));
    g.setAttribute('uv', new THREE.Float32BufferAttribute(uu, 2));
    g.setIndex(ii); g.computeVertexNormals();
    g.rotateY(phi); g.translate(tx, ty + 0.05, tz);
    const dry = i === 4;
    colorize(g, (c) => (dry ? c.set(0xb9753a) : c.setScalar(rng.range(0.85, 1.12))));
    parts.push(g.toNonIndexed());
  }
  const fronds = mergeGeometries(parts);
  return { trunk, fronds };
}

function makeTree(seed) { // mango / almendro: tronco + copa de blobs
  const rng = new Rng(seed), parts = [];
  parts.push(cylG(0.32, 0.2, 2.6, 0x6a5240, 0, 0, 0, 8));
  parts.push(cylG(0.14, 0.08, 1.8, 0x6a5240, 0.5, 2.0, 0.1, 6));
  const base = rng.pick([0x3f7a2e, 0x4a8a30, 0x356b2a]);
  parts.push(blob(base, 0, 4.6, 0, 2.6, 1.9, 2.6, seed));
  for (let i = 0; i < 5; i++) {
    const a = (i / 5) * 6.28 + rng.range(-0.3, 0.3), r = rng.range(1.4, 2.1);
    parts.push(blob(base, Math.cos(a) * r, 3.9 + rng.range(0, 1.3), Math.sin(a) * r, rng.range(1.2, 1.8), rng.range(1.0, 1.4), rng.range(1.2, 1.8), seed + i + 1));
  }
  return mergeGeometries(parts);
}

function makeCroton(seed) { // croton: arbusto multicolor
  const rng = new Rng(seed), parts = [];
  const cs = [0xe3b82a, 0xd9791f, 0xc2412a, 0x5a8c2b, 0xe9d24a];
  for (let i = 0; i < 6; i++) {
    parts.push(blob(rng.pick(cs), rng.range(-0.45, 0.45), 0.5 + rng.range(0, 0.4), rng.range(-0.45, 0.45), rng.range(0.28, 0.4), rng.range(0.3, 0.45), rng.range(0.28, 0.4), seed + i, 0.25));
  }
  return mergeGeometries(parts);
}
function makeTi(seed) { // planta ti (hojas rojas, como en las fotos)
  const rng = new Rng(seed), parts = [];
  for (let i = 0; i < 12; i++) {
    const c = rng.chance(0.7) ? rng.pick([0xb5233f, 0xd23a55, 0x9a1d3a]) : 0x5a8a3a;
    parts.push(blade(rng.range(0.9, 1.4), 0.2, c, rng.range(0, 6.28), rng.range(0.9, 1.25), rng.range(0.6, 1.1), 0, 0.05, 0, 4));
  }
  return mergeGeometries(parts);
}
function makeGinger(seed) { // jengibre rojo/rosado (antorcha)
  const rng = new Rng(seed), parts = [];
  for (let i = 0; i < 9; i++) parts.push(blade(rng.range(1.0, 1.5), 0.32, 0x4e9a3a, (i / 9) * 6.28 + rng.range(-0.3, 0.3), rng.range(0.9, 1.25), rng.range(0.5, 0.9), 0, 0.05, 0, 4));
  for (let i = 0; i < 3; i++) parts.push(cone(0.09, 0.26, rng.pick([0xd9486a, 0xe56b86, 0xc23358]), rng.range(-0.25, 0.25), 1.05 + i * 0.12, rng.range(-0.25, 0.25), 6));
  return mergeGeometries(parts);
}
function makeBanana(seed) {
  const rng = new Rng(seed), parts = [];
  parts.push(cylG(0.13, 0.1, 2.0, 0x7c9a4a, 0, 0, 0, 7));
  for (let i = 0; i < 8; i++) parts.push(blade(rng.range(1.7, 2.3), 0.7, rng.pick([0x5aa832, 0x4e9a2e, 0x6bb43c]), (i / 8) * 6.28 + rng.range(-0.3, 0.3), rng.range(0.5, 0.9), rng.range(1.0, 1.6), 0, 2.0, 0, 5, 0.06));
  return mergeGeometries(parts);
}
function makeCelosia(seed) { // plumero rojo
  const rng = new Rng(seed), parts = [];
  parts.push(blob(0x3f8a34, 0, 0.55, 0, 0.55, 0.5, 0.55, seed, 0.2));
  for (let i = 0; i < 9; i++) {
    const a = rng.range(0, 6.28), r = rng.range(0.1, 0.45);
    parts.push(cone(0.08, rng.range(0.3, 0.5), rng.pick([0xd92b3a, 0xe24a4a, 0xc81f38]), Math.cos(a) * r, 0.75 + rng.range(0, 0.4), Math.sin(a) * r, 6));
  }
  return mergeGeometries(parts);
}
function makeHedge() {
  const g = new THREE.BoxGeometry(1, 1, 1, 1, 1, 1).toNonIndexed();
  g.translate(0, 0.5, 0);
  colorize(g, (c, x, y) => c.set(0x3f7d2c).multiplyScalar(0.7 + y * 0.45));
  return g;
}
function makeTuft(seed) { // matas de hierba alta
  const rng = new Rng(seed), parts = [];
  for (let i = 0; i < 7; i++) parts.push(blade(rng.range(0.35, 0.7), 0.07, rng.pick([0x6fa03e, 0x5c9234, 0x86b04a]), rng.range(0, 6.28), rng.range(1.0, 1.35), rng.range(0.3, 0.9), 0, 0, 0, 3, 0.2));
  return mergeGeometries(parts);
}

let kinds = null;
export const timeUniform = { value: 0 };
function swayMat(m, amp) {
  m.onBeforeCompile = (sh) => {
    sh.uniforms.uTime = timeUniform;
    sh.vertexShader = sh.vertexShader
      .replace('#include <common>', '#include <common>\nuniform float uTime;')
      .replace('#include <begin_vertex>', `#include <begin_vertex>
        #ifdef USE_INSTANCING
          float ph = instanceMatrix[3].x * 0.35 + instanceMatrix[3].z * 0.27;
        #else
          float ph = 0.0;
        #endif
        float amp = length(position.xz) * ${amp.toFixed(3)};
        transformed.x += sin(uTime * 1.3 + ph + position.x * 0.5) * amp;
        transformed.z += cos(uTime * 1.1 + ph + position.z * 0.5) * amp * 0.7;
        transformed.y += sin(uTime * 1.7 + ph) * amp * 0.35;`);
  };
  m.customProgramCacheKey = () => 'sway' + amp;
  return m;
}

function initKinds() {
  if (kinds) return kinds;
  const plant = new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.85, side: THREE.DoubleSide });
  const solid = new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.9 });
  const plantSway = swayMat(plant.clone(), 0.025);
  const frond = swayMat(new THREE.MeshStandardMaterial({
    vertexColors: true, map: Tex.palmFrond(), alphaTest: 0.4, alphaToCoverage: true, side: THREE.DoubleSide, roughness: 0.75, emissive: 0x1d3a10, emissiveIntensity: 0.55,
  }), 0.02);
  const palms = [1, 2, 3].map((s) => makePalm(s * 17));
  kinds = {
    palm0: { parts: [{ g: palms[0].trunk, m: solid }, { g: palms[0].fronds, m: frond }], shadow: true },
    palm1: { parts: [{ g: palms[1].trunk, m: solid }, { g: palms[1].fronds, m: frond }], shadow: true },
    palm2: { parts: [{ g: palms[2].trunk, m: solid }, { g: palms[2].fronds, m: frond }], shadow: true },
    tree: { parts: [{ g: makeTree(5), m: solid }], shadow: true },
    tree2: { parts: [{ g: makeTree(9), m: solid }], shadow: true },
    croton: { parts: [{ g: makeCroton(3), m: solid }], shadow: false },
    ti: { parts: [{ g: makeTi(4), m: plantSway }], shadow: false },
    ginger: { parts: [{ g: makeGinger(6), m: plantSway }], shadow: false },
    banana: { parts: [{ g: makeBanana(7), m: plantSway }], shadow: true },
    celosia: { parts: [{ g: makeCelosia(8), m: solid }], shadow: false },
    hedge: { parts: [{ g: makeHedge(), m: solid }], shadow: false },
    tuft: { parts: [{ g: makeTuft(2), m: plantSway }], shadow: false },
  };
  return kinds;
}

const _o = new THREE.Object3D();
export class Flora {
  constructor() { initKinds(); this.items = {}; }
  // sx,sy,sz opcionales para setos
  add(kind, x, y, z, { s = 1, ry = 0, tilt = 0, sx, sy, sz } = {}) {
    _o.position.set(x, y, z); _o.rotation.set(tilt, ry, tilt * 0.5);
    _o.scale.set(sx ?? s, sy ?? s, sz ?? s); _o.updateMatrix();
    (this.items[kind] ||= []).push(_o.matrix.clone());
  }
  // Devuelve las mallas instanciadas (palma = 2: tronco + hojas)
  build(parent) {
    const meshes = [];
    for (const [k, mats] of Object.entries(this.items)) {
      const def = kinds[k];
      for (const part of def.parts) {
        const im = new THREE.InstancedMesh(part.g, part.m, mats.length);
        mats.forEach((m, i) => im.setMatrixAt(i, m));
        im.instanceMatrix.needsUpdate = true;
        im.castShadow = def.shadow; im.receiveShadow = true;
        im.computeBoundingSphere();
        parent.add(im); meshes.push(im);
      }
    }
    this.items = {};
    return meshes;
  }
}
