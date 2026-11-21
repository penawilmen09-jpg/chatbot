// Mundo de colisiones 2D (plano XZ) con rangos verticales + superficies caminables.
// - Colisionadores: círculos y cajas orientadas (OBB) con rango [y0,y1].
// - Superficies: dan la altura del suelo (aceras, escalones, balcones, pisos interiores).

const TAU = Math.PI * 2;

export class Colliders {
  constructor() { this.list = []; this.surfaces = []; }

  addBox(group, cx, cz, hw, hd, rot, y0, y1) {
    this.list.push({ t: 'b', g: group, cx, cz, hw, hd, c: Math.cos(rot), s: Math.sin(rot), y0, y1, ext: Math.hypot(hw, hd) });
  }
  addCircle(group, cx, cz, r, y0, y1) {
    this.list.push({ t: 'c', g: group, cx, cz, r, y0, y1, ext: r });
  }
  // Suelo plano (caja, opcionalmente rotada)
  addFloor(group, cx, cz, hw, hd, rot, y) {
    this.surfaces.push({ t: 'b', g: group, cx, cz, hw, hd, c: Math.cos(rot), s: Math.sin(rot), y, ext: Math.hypot(hw, hd) });
  }
  // Escalera curva: sector anular; el ángulo va de a0 a a1 (puede decrecer)
  addSector(group, cx, cz, ri, ro, a0, a1, rise, n, baseY) {
    this.surfaces.push({ t: 's', g: group, cx, cz, ri, ro, a0, a1, rise, n, baseY, ext: ro });
  }
  removeGroup(group) {
    this.list = this.list.filter((c) => c.g !== group);
    this.surfaces = this.surfaces.filter((c) => c.g !== group);
  }

  // Empuja al jugador (círculo radio r, pies en y, altura h) fuera de los obstáculos.
  resolve(p, y, r, h) {
    let hit = false;
    for (let it = 0; it < 3; it++) {
      let moved = false;
      for (const c of this.list) {
        if (Math.abs(p.x - c.cx) > c.ext + r || Math.abs(p.z - c.cz) > c.ext + r) continue;
        if (!(y + 0.32 < c.y1 && y + h > c.y0)) continue;
        if (c.t === 'c') {
          const dx = p.x - c.cx, dz = p.z - c.cz, d = Math.hypot(dx, dz), m = r + c.r;
          if (d < m) {
            const nx = d > 1e-5 ? dx / d : 1, nz = d > 1e-5 ? dz / d : 0;
            p.x = c.cx + nx * m; p.z = c.cz + nz * m; moved = true;
          }
        } else {
          const dx = p.x - c.cx, dz = p.z - c.cz;
          const lx = dx * c.c - dz * c.s, lz = dx * c.s + dz * c.c;
          const qx = Math.max(-c.hw, Math.min(c.hw, lx)), qz = Math.max(-c.hd, Math.min(c.hd, lz));
          let ex = lx - qx, ez = lz - qz;
          const d2 = ex * ex + ez * ez;
          let px = 0, pz = 0;
          if (d2 > 1e-8) {
            if (d2 < r * r) { const d = Math.sqrt(d2); px = (ex / d) * (r - d); pz = (ez / d) * (r - d); } else continue;
          } else { // centro dentro de la caja: salir por la cara más cercana
            const ox = c.hw - Math.abs(lx), oz = c.hd - Math.abs(lz);
            if (ox < oz) px = (lx >= 0 ? 1 : -1) * (ox + r); else pz = (lz >= 0 ? 1 : -1) * (oz + r);
          }
          p.x += px * c.c + pz * c.s;
          p.z += -px * c.s + pz * c.c;
          moved = true;
        }
      }
      if (!moved) break;
      hit = true;
    }
    return hit;
  }

  // ¿Hay un sólido alto en este punto? (para que la cámara no atraviese paredes)
  blockedPoint(x, z, y) {
    for (const c of this.list) {
      if (Math.abs(x - c.cx) > c.ext || Math.abs(z - c.cz) > c.ext) continue;
      if (y < c.y0 || y > c.y1 || c.y1 - c.y0 < 1.6) continue;
      if (c.t === 'c') { if (Math.hypot(x - c.cx, z - c.cz) < c.r) return true; } else {
        const dx = x - c.cx, dz = z - c.cz;
        const lx = dx * c.c - dz * c.s, lz = dx * c.s + dz * c.c;
        if (Math.abs(lx) < c.hw && Math.abs(lz) < c.hd) return true;
      }
    }
    return false;
  }

  // Altura del suelo en (x,z) alcanzable desde la altura y (sube como máximo stepUp).
  groundAt(x, z, y, stepUp) {
    let best = 0;
    for (const s of this.surfaces) {
      if (Math.abs(x - s.cx) > s.ext || Math.abs(z - s.cz) > s.ext) continue;
      let h = null;
      if (s.t === 'b') {
        const dx = x - s.cx, dz = z - s.cz;
        const lx = dx * s.c - dz * s.s, lz = dx * s.s + dz * s.c;
        if (Math.abs(lx) <= s.hw && Math.abs(lz) <= s.hd) h = s.y;
      } else {
        const dx = x - s.cx, dz = z - s.cz, r = Math.hypot(dx, dz);
        if (r >= s.ri && r <= s.ro) {
          const span = s.a1 - s.a0;
          let a = Math.atan2(dz, dx) - s.a0;
          a = ((a % TAU) + TAU) % TAU; // 0..2π
          const sgn = Math.sign(span), total = Math.abs(span);
          const along = sgn >= 0 ? a : (TAU - a) % TAU;
          if (along <= total + 1e-6) {
            const k = Math.min(s.n - 1, Math.floor((along / total) * s.n));
            h = s.baseY + (k + 1) * s.rise;
          }
        }
      }
      if (h !== null && h <= y + stepUp && h > best) best = h;
    }
    return best;
  }
}
