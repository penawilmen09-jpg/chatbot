import * as THREE from 'three';

// Frame: sistema de coordenadas local de un edificio (posición + giro Y).
// Local: +z = fachada principal, y hacia arriba.
export class Frame {
  constructor(x = 0, y = 0, z = 0, rot = 0) {
    this.x = x; this.y = y; this.z = z; this.rot = rot;
    this.c = Math.cos(rot); this.s = Math.sin(rot);
    this.m = new THREE.Matrix4().makeRotationY(rot).setPosition(x, y, z);
  }
  wx(lx, lz) { return this.x + lx * this.c + lz * this.s; }
  wz(lx, lz) { return this.z - lx * this.s + lz * this.c; }
}

const _m = new THREE.Matrix4(), _l = new THREE.Matrix4(), _q = new THREE.Quaternion(), _e = new THREE.Euler(), _p = new THREE.Vector3(), _s = new THREE.Vector3();
const unitCache = new Map();
function unit(key, make) { let g = unitCache.get(key); if (!g) { g = make(); unitCache.set(key, g); } return g; }
const UBOX = () => unit('box', () => new THREE.BoxGeometry(1, 1, 1));

// Builder: "pincel" para construir geometría + colisiones en coordenadas locales.
export class Builder {
  constructor(world, frame, group) {
    this.w = world; this.f = frame; this.group = group;
    this.layer = 'main';
  }
  get batch() { return this.w.chunks.at(this.f.x, this.f.z, this.layer); }
  fine(fn) { const l = this.layer; this.layer = 'fine'; fn(); this.layer = l; }

  // Matriz mundo = frame * local(T * R * S)
  _mat(px, py, pz, rx, ry, rz, sx, sy, sz) {
    _q.setFromEuler(_e.set(rx, ry, rz)); _p.set(px, py, pz); _s.set(sx, sy, sz);
    _l.compose(_p, _q, _s);
    return _m.multiplyMatrices(this.f.m, _l);
  }
  geo(mat, geometry, px, py, pz, { rx = 0, ry = 0, rz = 0, sx = 1, sy = 1, sz = 1 } = {}, color = 0xffffff) {
    this.batch.add(mat, geometry, this._mat(px, py + 0, pz, rx, ry, rz, sx, sy, sz), color);
  }
  // Caja centrada
  box(mat, cx, cy, cz, w, h, d, color = 0xffffff, ry = 0, rx = 0, rz = 0) {
    this.batch.add(mat, UBOX(), this._mat(cx, cy, cz, rx, ry, rz, w, h, d), color);
  }
  // Caja por esquinas mín/máx, con colisión opcional
  block(mat, x0, y0, z0, x1, y1, z1, color = 0xffffff, collide = false) {
    this.box(mat, (x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2, x1 - x0, y1 - y0, z1 - z0, color);
    if (collide) this.colBox((x0 + x1) / 2, (z0 + z1) / 2, (x1 - x0) / 2, (z1 - z0) / 2, y0, y1);
  }
  // Cilindro con la base en y0
  cyl(mat, cx, y0, cz, rTop, rBot, h, color = 0xffffff, seg = 10) {
    const g = unit(`cyl${rTop / rBot}_${seg}`, () => new THREE.CylinderGeometry(rTop / rBot, 1, 1, seg, 1));
    this.batch.add(mat, g, this._mat(cx, y0 + h / 2, cz, 0, 0, 0, rBot, h, rBot), color);
  }
  sph(mat, cx, cy, cz, rx, ry, rz, color = 0xffffff, seg = 8) {
    const g = unit(`sph${seg}`, () => new THREE.SphereGeometry(1, seg, Math.max(4, Math.round(seg * 0.7))));
    this.batch.add(mat, g, this._mat(cx, cy, cz, 0, 0, 0, rx, ry, rz), color);
  }

  // ---- colisiones (en coordenadas locales -> mundo) ----
  colBox(cx, cz, hw, hd, y0, y1, rot = 0) {
    this.w.colliders.addBox(this.group, this.f.wx(cx, cz), this.f.wz(cx, cz), hw, hd, this.f.rot + rot, this.f.y + y0, this.f.y + y1);
  }
  colCircle(cx, cz, r, y0, y1) {
    this.w.colliders.addCircle(this.group, this.f.wx(cx, cz), this.f.wz(cx, cz), r, this.f.y + y0, this.f.y + y1);
  }
  floorBox(x0, z0, x1, z1, y) {
    this.w.colliders.addFloor(this.group, this.f.wx((x0 + x1) / 2, (z0 + z1) / 2), this.f.wz((x0 + x1) / 2, (z0 + z1) / 2), (x1 - x0) / 2, (z1 - z0) / 2, this.f.rot, this.f.y + y);
  }
  floorSector(cx, cz, ri, ro, a0, a1, rise, n, baseY = 0) {
    this.w.colliders.addSector(this.group, this.f.wx(cx, cz), this.f.wz(cx, cz), ri, ro, a0 - this.f.rot, a1 - this.f.rot, rise, n, this.f.y + baseY);
  }

  // Pared recta (a lo largo de x o z) con huecos. Cada pieza sólida genera su colisión.
  // openings: {t0,t1,y0,y1,kind:'door'|'window'|'gap', trim, color}
  wall(mat, xa, za, xb, zb, y0, y1, thick, color, openings = [], opts = {}) {
    const alongX = Math.abs(xb - xa) >= Math.abs(zb - za);
    const a = alongX ? Math.min(xa, xb) : Math.min(za, zb), b = alongX ? Math.max(xa, xb) : Math.max(za, zb);
    const fixed = alongX ? (za + zb) / 2 : (xa + xb) / 2;
    const piece = (t0, t1, yy0, yy1, collide = true, m = mat, col = color) => {
      if (t1 - t0 < 0.01 || yy1 - yy0 < 0.01) return;
      if (alongX) this.block(m, t0, yy0, fixed - thick / 2, t1, yy1, fixed + thick / 2, col, collide);
      else this.block(m, fixed - thick / 2, yy0, t0, fixed + thick / 2, yy1, t1, col, collide);
    };
    const ops = [...openings].sort((p, q) => p.t0 - q.t0);
    let cur = a;
    for (const o of ops) {
      const t0 = a + o.t0, t1 = a + o.t1;
      piece(cur, t0, y0, y1);
      piece(t0, t1, y0, o.y0);
      piece(t0, t1, o.y1, y1);
      const w = t1 - t0, mid = (t0 + t1) / 2;
      const trimCol = o.trim ?? opts.trim ?? 0xf3f0e6;
      if (o.kind === 'window') {
        // vidrio + marco + colisión (la ventana no se atraviesa)
        const gx = alongX ? mid : fixed, gz = alongX ? fixed : mid;
        this.box('glass', gx, (o.y0 + o.y1) / 2, gz, alongX ? w - 0.06 : 0.04, o.y1 - o.y0 - 0.06, alongX ? 0.04 : w - 0.06, 0x9cc7d6);
        const fr = 0.06, th = thick + 0.08;
        const bar = (c0, c1, yy0, yy1) => {
          if (alongX) this.box('plain', (c0 + c1) / 2, (yy0 + yy1) / 2, fixed, c1 - c0, yy1 - yy0, th, trimCol);
          else this.box('plain', fixed, (yy0 + yy1) / 2, (c0 + c1) / 2, th, yy1 - yy0, c1 - c0, trimCol);
        };
        bar(t0, t1, o.y0 - fr, o.y0); bar(t0, t1, o.y1, o.y1 + fr); bar(t0 - fr, t0, o.y0 - fr, o.y1 + fr); bar(t1, t1 + fr, o.y0 - fr, o.y1 + fr);
        bar(mid - 0.025, mid + 0.025, o.y0, o.y1);
        if (o.reja) { // reja de hierro típica
          const nb = Math.max(3, Math.round(w / 0.16));
          for (let i = 0; i < nb; i++) {
            const c = t0 + (w * (i + 0.5)) / nb;
            if (alongX) this.box('metal', c, (o.y0 + o.y1) / 2, fixed + thick / 2 + 0.03, 0.02, o.y1 - o.y0, 0.02, o.reja);
            else this.box('metal', fixed + thick / 2 + 0.03, (o.y0 + o.y1) / 2, c, 0.02, o.y1 - o.y0, 0.02, o.reja);
          }
        }
        if (alongX) this.colBox(mid, fixed, w / 2, thick / 2, o.y0, o.y1); else this.colBox(fixed, mid, thick / 2, w / 2, o.y0, o.y1);
      } else if (o.kind === 'door') {
        const fr = 0.07, th = thick + 0.06;
        const bar = (c0, c1, yy0, yy1) => {
          if (alongX) this.box('plain', (c0 + c1) / 2, (yy0 + yy1) / 2, fixed, c1 - c0, yy1 - yy0, th, trimCol);
          else this.box('plain', fixed, (yy0 + yy1) / 2, (c0 + c1) / 2, th, yy1 - yy0, c1 - c0, trimCol);
        };
        bar(t0 - fr, t0, o.y0, o.y1 + fr); bar(t1, t1 + fr, o.y0, o.y1 + fr); bar(t0 - fr, t1 + fr, o.y1, o.y1 + fr);
        if (o.leaf !== false && !o.open) { // puerta cerrada
          const lc = o.leafColor ?? 0x6b4a30;
          if (alongX) this.box('plain', mid, (o.y0 + o.y1) / 2, fixed, w - 0.02, o.y1 - o.y0, 0.06, lc);
          else this.box('plain', fixed, (o.y0 + o.y1) / 2, mid, 0.06, o.y1 - o.y0, w - 0.02, lc);
          if (alongX) this.colBox(mid, fixed, w / 2, thick / 2, o.y0, o.y1); else this.colBox(fixed, mid, thick / 2, w / 2, o.y0, o.y1);
        } else if (o.open) { // hoja abierta (batiente a 90°)
          const lc = o.leafColor ?? 0x6b4a30;
          if (alongX) this.box('plain', t0 + 0.04, (o.y0 + o.y1) / 2, fixed + w / 2, 0.05, o.y1 - o.y0, w - 0.05, lc);
          else this.box('plain', fixed + w / 2, (o.y0 + o.y1) / 2, t0 + 0.04, w - 0.05, o.y1 - o.y0, 0.05, lc);
        }
      }
      cur = t1;
    }
    piece(cur, b, y0, y1);
  }
}
