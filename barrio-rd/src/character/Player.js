import * as THREE from 'three';
import { createHuman } from './HumanModel.js';
import { CONFIG } from '../config.js';

// Jugador: movimiento relativo a la cámara, aceleración suave, colisiones, escaleras y caída.
export class Player {
  constructor(colliders) {
    this.col = colliders;
    this.human = createHuman({});
    this.object = this.human.root;
    this.pos = new THREE.Vector3(); this.vel = new THREE.Vector3();
    this.vy = 0; this.facing = 0; this.speed = 0; this.grounded = true; this.running = false;
    this.footTimer = 0; this.onStep = null;
  }
  teleport(x, y, z, facing = this.facing) {
    this.pos.set(x, y, z); this.vel.set(0, 0, 0); this.vy = 0; this.facing = facing;
    this.object.position.copy(this.pos); this.object.rotation.y = facing;
  }

  update(dt, input, camYaw) {
    const P = CONFIG.player;
    const mx = input.move.x, my = input.move.y, mag = Math.min(1, Math.hypot(mx, my));
    const sy = Math.sin(camYaw), cy = Math.cos(camYaw);
    // adelante = (-sin, -cos), derecha = (cos, -sin)
    let dx = mx * cy + my * -sy, dz = mx * -sy + my * -cy;
    const len = Math.hypot(dx, dz) || 1; dx /= len; dz /= len;
    this.running = input.run && mag > 0.05;
    const top = this.running ? P.runSpeed : P.walkSpeed * 1.35;
    const target = mag > 0.05 ? top * Math.min(1, mag * 1.1) : 0;
    // aceleración suave
    const tvx = dx * target, tvz = dz * target;
    const acc = 1 - Math.exp(-(target > 0 ? 14 : 18) * dt);
    this.vel.x += (tvx - this.vel.x) * acc; this.vel.z += (tvz - this.vel.z) * acc;

    // mover + colisionar (sub-pasos para no atravesar paredes finas)
    const steps = Math.max(1, Math.ceil((Math.hypot(this.vel.x, this.vel.z) * dt) / 0.2));
    for (let i = 0; i < steps; i++) {
      this.pos.x += (this.vel.x * dt) / steps; this.pos.z += (this.vel.z * dt) / steps;
      this.col.resolve(this.pos, this.pos.y, P.radius, P.height);
    }
    const H = CONFIG.world.halfSize - 2;
    this.pos.x = THREE.MathUtils.clamp(this.pos.x, -H, H); this.pos.z = THREE.MathUtils.clamp(this.pos.z, -H, H);

    // suelo: sube escalones (hasta stepUp) y cae por gravedad
    const g = this.col.groundAt(this.pos.x, this.pos.z, this.pos.y, P.stepUp);
    if (this.pos.y < g - 0.001) {
      const k = 1 - Math.exp(-26 * dt);
      this.pos.y = Math.min(g, this.pos.y + Math.max(0.0, (g - this.pos.y) * k + 0.02));
      this.vy = 0; this.grounded = true;
    } else if (this.pos.y > g + 0.001) {
      this.vy -= P.gravity * dt; this.pos.y += this.vy * dt; this.grounded = false;
      if (this.pos.y <= g) { this.pos.y = g; this.vy = 0; this.grounded = true; }
    } else { this.vy = 0; this.grounded = true; }

    this.speed = Math.hypot(this.vel.x, this.vel.z);
    if (this.speed > 0.25) {
      const want = Math.atan2(this.vel.x, this.vel.z);
      let diff = want - this.facing; diff = Math.atan2(Math.sin(diff), Math.cos(diff));
      this.facing += diff * (1 - Math.exp(-P.turnSpeed * dt));
    }
    this.object.position.copy(this.pos); this.object.rotation.y = this.facing;
    this.human.animate(dt, this.speed, this.running ? 1 : Math.max(0, (this.speed - 3.2) / 2));

    // pasos (para el audio)
    if (this.speed > 0.4 && this.grounded) {
      this.footTimer -= dt * (this.speed / 2.2);
      if (this.footTimer <= 0) { this.footTimer = 0.42; this.onStep?.(this.running); }
    } else this.footTimer = 0.1;
  }
}
