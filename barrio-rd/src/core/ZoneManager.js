import * as THREE from 'three';
import { ChunkedBatch } from './Batch.js';
import { CONFIG } from '../config.js';

// Carga progresiva por zonas: cada zona se construye de forma asíncrona (sin bloquear el
// dibujado), con su propio grupo de mallas y colisiones, y se descarga si el jugador se aleja.
const nextFrame = () => new Promise((r) => requestAnimationFrame(() => r()));

export class ZoneManager {
  constructor(game, defs) {
    this.game = game;
    this.zones = new Map(defs.map((def) => [def.id, { def, state: 'idle', ctx: null }]));
    this.queue = []; this.busy = false;
    this.onChange = null;
  }
  get loadedContexts() { return [...this.zones.values()].filter((z) => z.state === 'loaded').map((z) => z.ctx); }
  isLoaded(id) { return this.zones.get(id)?.state === 'loaded'; }

  dist(def, x, z) {
    const [x0, z0, x1, z1] = def.box;
    return Math.hypot(Math.max(x0 - x, 0, x - x1), Math.max(z0 - z, 0, z - z1));
  }

  async load(id) {
    const z = this.zones.get(id);
    if (!z || z.state !== 'idle') return;
    z.state = 'loading'; this.onChange?.();
    const g = this.game;
    const ctx = {
      id, group: new THREE.Group(), chunks: new ChunkedBatch(g.mats, CONFIG.world.chunk), colliders: g.colliders, mats: g.mats,
      interactions: g.interactions.forZone(id), animated: [], audioSources: [], fineMeshes: [],
    };
    ctx.group.name = `zone:${id}`;
    await z.def.build(ctx);
    ctx.chunks.build(ctx.group, ctx.fineMeshes);
    g.scene.add(ctx.group);
    z.ctx = ctx; z.state = 'loaded';
    this.onChange?.();
  }

  unload(id) {
    const z = this.zones.get(id);
    if (!z || z.state !== 'loaded') return;
    const { ctx } = z;
    this.game.scene.remove(ctx.group);
    ctx.group.traverse((o) => {
      if (o.isInstancedMesh) o.dispose(); else if (o.geometry) o.geometry.dispose();
    });
    this.game.colliders.removeGroup(ctx.group);
    this.game.interactions.removeZone(id);
    z.ctx = null; z.state = 'idle'; this.onChange?.();
  }

  async pump() {
    if (this.busy) return;
    this.busy = true;
    while (this.queue.length) { const id = this.queue.shift(); await nextFrame(); try { await this.load(id); } catch (e) { console.error('Zona', id, e); this.zones.get(id).state = 'idle'; this.zones.get(id).failed = true; } }
    this.busy = false;
  }

  update(px, pz) {
    for (const [id, z] of this.zones) {
      const d = this.dist(z.def, px, pz);
      if (z.state === 'idle' && !z.failed && d < z.def.loadDist && !this.queue.includes(id)) this.queue.push(id);
      else if (z.state === 'loaded' && d > z.def.unloadDist) this.unload(id);
    }
    if (this.queue.length) this.pump();
  }
  get loadingNow() { return [...this.zones.values()].some((z) => z.state === 'loading') || this.queue.length > 0; }
}
