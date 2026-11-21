import * as THREE from 'three';
import { CONFIG } from '../config.js';

// Cámara en tercera persona: órbita suave alrededor del jugador, zoom, colisión con paredes
// y seguimiento amortiguado.
export class ThirdPersonCamera {
  constructor(camera, colliders) {
    this.cam = camera; this.col = colliders;
    this.yaw = -Math.PI / 2; this.pitch = 0.32; this.dist = CONFIG.camera.distance;
    this.curDist = this.dist; this.pos = new THREE.Vector3(); this.look = new THREE.Vector3();
    this.targetSmoothed = new THREE.Vector3(); this.inited = false; this.sens = 1;
  }
  snap(target) { this.targetSmoothed.copy(target); this.inited = false; }

  update(dt, target, look, zoom) {
    const C = CONFIG.camera;
    this.yaw -= look.dx * 0.0052 * this.sens;
    this.pitch = THREE.MathUtils.clamp(this.pitch + look.dy * 0.0042 * this.sens, -0.12, 1.25);
    this.dist = THREE.MathUtils.clamp(this.dist + zoom * 0.7, C.minDistance + 1, C.maxDistance);

    const tp = new THREE.Vector3(target.x, target.y + C.height, target.z);
    if (!this.inited) { this.targetSmoothed.copy(tp); this.inited = true; }
    const k = 1 - Math.exp(-14 * dt);
    this.targetSmoothed.x += (tp.x - this.targetSmoothed.x) * k;
    this.targetSmoothed.z += (tp.z - this.targetSmoothed.z) * k;
    this.targetSmoothed.y += (tp.y - this.targetSmoothed.y) * (1 - Math.exp(-8 * dt));
    const t = this.targetSmoothed;

    const cp = Math.cos(this.pitch), sp = Math.sin(this.pitch);
    const dir = new THREE.Vector3(Math.sin(this.yaw) * cp, sp, Math.cos(this.yaw) * cp);
    // colisión: avanzar desde el jugador hasta la cámara y parar antes de un muro
    let free = this.dist;
    for (let d = 0.5; d <= this.dist; d += 0.25) {
      const x = t.x + dir.x * d, y = t.y + dir.y * d, z = t.z + dir.z * d;
      if (this.col.blockedPoint(x, z, y) || y < this.col.groundAt(x, z, y, 0.5) + 0.12) { free = Math.max(0.9, d - 0.35); break; }
    }
    // acercar rápido, alejar lento
    this.curDist += (free - this.curDist) * (1 - Math.exp(-(free < this.curDist ? 22 : 3.5) * dt));
    this.pos.set(t.x + dir.x * this.curDist, t.y + dir.y * this.curDist, t.z + dir.z * this.curDist);
    const gh = this.col.groundAt(this.pos.x, this.pos.z, this.pos.y, 0.5);
    if (this.pos.y < gh + 0.3) this.pos.y = gh + 0.3;
    this.cam.position.copy(this.pos);
    this.look.set(t.x, t.y - 0.25, t.z);
    this.cam.lookAt(this.look);
  }
}
