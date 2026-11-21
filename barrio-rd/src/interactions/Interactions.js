// Sistema de interacciones: puntos con radio, etiqueta y acción.
// Colmados, tiendas, vehículos, puertas, misiones, etc. se registran aquí (add) y se ejecutan con E / botón.

export class Interactions {
  constructor() { this.items = []; }
  add(item) { this.items.push(item); return item; }
  forZone(zoneId) { return { add: (i) => this.add({ ...i, zone: zoneId }) }; }
  removeZone(zoneId) { this.items = this.items.filter((i) => i.zone !== zoneId); }
  // el punto utilizable más cercano al jugador
  nearest(px, py, pz) {
    let best = null, bd = Infinity;
    for (const it of this.items) {
      if (Math.abs((it.y ?? 0) - py) > 2.4) continue;
      const d = Math.hypot(it.x - px, it.z - pz);
      if (d < it.radius && d < bd) { bd = d; best = it; }
    }
    return best;
  }
}
