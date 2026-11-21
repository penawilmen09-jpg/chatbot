import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { TEX_SCALE } from './Materials.js';

// Batch: acumula geometrías (ya transformadas, con color por vértice y UV horneadas)
// y las fusiona en UNA malla por material => pocos draw calls en el móvil.

const _c = new THREE.Color();
const NO_SHADOW = new Set(['glass']);

export class Batch {
  constructor(mats) { this.mats = mats; this.parts = {}; this.count = 0; }

  add(key, geo, matrix, color = 0xffffff) {
    const g = geo.index ? geo.toNonIndexed() : geo.clone();
    g.applyMatrix4(matrix);
    const pos = g.attributes.position, nor = g.attributes.normal;
    const n = pos.count, uv = new Float32Array(n * 2), col = new Float32Array(n * 3);
    const sc = TEX_SCALE[key] || 1;
    _c.set(color);
    for (let i = 0; i < n; i++) {
      const px = pos.getX(i), py = pos.getY(i), pz = pos.getZ(i);
      const ax = Math.abs(nor.getX(i)), ay = Math.abs(nor.getY(i)), az = Math.abs(nor.getZ(i));
      let u, v;
      if (ay >= ax && ay >= az) { u = px; v = pz; } else if (ax >= az) { u = pz; v = py; } else { u = px; v = py; }
      uv[i * 2] = u / sc; uv[i * 2 + 1] = v / sc;
      col[i * 3] = _c.r; col[i * 3 + 1] = _c.g; col[i * 3 + 2] = _c.b;
    }
    g.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
    g.setAttribute('color', new THREE.BufferAttribute(col, 3));
    for (const name of Object.keys(g.attributes)) if (!['position', 'normal', 'uv', 'color'].includes(name)) g.deleteAttribute(name);
    (this.parts[key] ||= []).push(g);
    this.count++;
  }

  // Fusiona y agrega las mallas a `parent`. Devuelve las mallas creadas.
  build(parent, { cast = true, receive = true } = {}) {
    const out = [];
    for (const key of Object.keys(this.parts)) {
      const merged = mergeGeometries(this.parts[key], false);
      this.parts[key].forEach((g) => g.dispose());
      if (!merged) continue;
      merged.computeBoundingSphere();
      const mesh = new THREE.Mesh(merged, this.mats[key]);
      mesh.castShadow = cast && !NO_SHADOW.has(key);
      mesh.receiveShadow = receive;
      if (key === 'glass') mesh.renderOrder = 2;
      parent.add(mesh);
      out.push(mesh);
    }
    this.parts = {};
    return out;
  }
}

// Divide el mundo en celdas: cada celda tiene su propio Batch => frustum culling por trozo.
// Capa 'fine' = detalles pequeños que se ocultan lejos del jugador (LOD simple).
export class ChunkedBatch {
  constructor(mats, chunk = 40) { this.mats = mats; this.chunk = chunk; this.map = new Map(); }
  at(x, z, layer = 'main') {
    const cx = Math.floor(x / this.chunk), cz = Math.floor(z / this.chunk);
    const k = `${layer}:${cx},${cz}`;
    let e = this.map.get(k);
    if (!e) {
      e = { layer, cx: (cx + 0.5) * this.chunk, cz: (cz + 0.5) * this.chunk, batch: new Batch(this.mats) };
      this.map.set(k, e);
    }
    return e.batch;
  }
  build(group, fineMeshes) {
    for (const e of this.map.values()) {
      const meshes = e.batch.build(group);
      if (e.layer === 'fine') {
        for (const m of meshes) { m.userData.cx = e.cx; m.userData.cz = e.cz; m.userData.r = this.chunk * 0.75; fineMeshes.push(m); }
      }
    }
    this.map.clear();
  }
}
