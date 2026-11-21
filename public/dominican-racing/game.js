/* DOMINICAN RACING — juego 2D de conducción con física, HTML5 Canvas.
 * Organización: Config · Storage · Input · Terrain · World · Car · Renderer · Game (UI y bucle). */
(() => {
  'use strict';

  /* ------------------------------ Configuración ------------------------------ */
  const CFG = {
    gravity: 1300,
    step: 1 / 120,            // paso fijo de la física
    px2m: 50,                 // 50 px = 1 metro
    viewH: 520,               // alto visible del mundo (px de mundo)
    viewW: 760,
    fuelBase: 1.0,            // % por segundo en reposo
    fuelGas: 1.3,             // % extra por segundo acelerando
    fuelCan: 40,
    coinValue: 1,
    car: {
      wheelR: 22, rest: 16, k: 95, c: 12, maxTravel: 20, kHard: 700,
      engine: 760, vmax: 640, brake: 900, reverse: 520, vmaxRev: 330,
      grip: 1.5, roll: 1.5, inertia: 3600, airTorque: 3.6,
      wheelsX: [-46, 46], anchorY: 12,
    },
  };

  /* ------------------------------ Almacenamiento ------------------------------ */
  const Store = {
    get(k, d) { try { const v = localStorage.getItem('domracing.' + k); return v === null ? d : JSON.parse(v); } catch (e) { return d; } },
    set(k, v) { try { localStorage.setItem('domracing.' + k, JSON.stringify(v)); } catch (e) { /* sin almacenamiento */ } },
  };

  /* ------------------------------ Utilidades ------------------------------ */
  const clamp = (v, a, b) => (v < a ? a : v > b ? b : v);
  const rand = (a, b) => a + Math.random() * (b - a);
  const hash = (n) => { const s = Math.sin(n * 127.1 + 311.7) * 43758.5453; return s - Math.floor(s); };
  const $ = (id) => document.getElementById(id);

  /* ------------------------------ Entrada ------------------------------ */
  const Input = { gas: false, brake: false, _t: { gas: new Set(), brake: new Set() }, _k: { gas: false, brake: false } };
  Input.refresh = () => {
    Input.gas = Input._t.gas.size > 0 || Input._k.gas;
    Input.brake = Input._t.brake.size > 0 || Input._k.brake;
    $('btnGas').classList.toggle('active', Input.gas);
    $('btnBrake').classList.toggle('active', Input.brake);
  };
  Input.clear = () => { Input._t.gas.clear(); Input._t.brake.clear(); Input._k.gas = Input._k.brake = false; Input.refresh(); };
  function bindHold(el, name) {
    const set = Input._t[name];
    const down = (e) => { e.preventDefault(); set.add(e.pointerId); try { el.setPointerCapture(e.pointerId); } catch (_) { /* */ } Input.refresh(); };
    const up = (e) => { e.preventDefault(); set.delete(e.pointerId); Input.refresh(); };
    el.addEventListener('pointerdown', down);
    el.addEventListener('pointerup', up);
    el.addEventListener('pointercancel', up);
    el.addEventListener('lostpointercapture', up);
    el.addEventListener('contextmenu', (e) => e.preventDefault());
  }

  /* ------------------------------ Terreno infinito ------------------------------ */
  class Terrain {
    constructor() { this.step = 16; this.reset(); }
    reset() {
      this.h = [0];
      this.queue = [];
      this.seg = { x0: 0, y0: 0, x1: 900, y1: 0 };
      this.lastY = 0;
      this.ramps = 0;
    }
    get genX() { return (this.h.length - 1) * this.step; }
    _nextSeg() {
      if (!this.queue.length) {
        const x = this.seg.x1, d = Math.min(1, x / 30000);
        if (x > 1800 && Math.random() < 0.22) {
          // rampa: subida empinada corta y caída posterior (salto)
          const rise = rand(50, 70) + d * 20;
          this.queue.push({ span: rand(110, 140), dy: -rise });
          this.queue.push({ span: rand(280, 380), dy: rise + rand(40, 110) });
        } else {
          const span = rand(200, 420);
          const amp = (60 + 170 * d) * (span / 300);
          let dy = rand(-1, 1) * amp;
          dy += (0 - this.seg.y1) * 0.12;               // vuelve poco a poco a la altura base
          dy = clamp(dy, -span * 0.3, span * 0.3);
          this.queue.push({ span, dy });
        }
      }
      const n = this.queue.shift();
      const y1 = clamp(this.seg.y1 + n.dy, -900, 700);
      this.seg = { x0: this.seg.x1, y0: this.seg.y1, x1: this.seg.x1 + n.span, y1 };
    }
    ensure(x) {
      while (this.genX < x) {
        const i = this.h.length, px = i * this.step;
        while (px >= this.seg.x1) this._nextSeg();
        const s = this.seg, t = (px - s.x0) / (s.x1 - s.x0);
        this.h.push(s.y0 + (s.y1 - s.y0) * (1 - Math.cos(Math.PI * t)) / 2);
      }
    }
    at(x) {
      if (x < 0) x = 0;
      this.ensure(x + this.step * 2);
      const f = x / this.step, i = Math.floor(f), t = f - i;
      return this.h[i] + (this.h[i + 1] - this.h[i]) * t;
    }
    slope(x) { return (this.at(x + 4) - this.at(x - 4)) / 8; }
  }

  /* ------------------------------ Monedas y combustible ------------------------------ */
  class World {
    constructor(terrain) { this.t = terrain; this.reset(); }
    reset() { this.items = []; this.cursor = 450; this.nextFuel = 4200; }
    update(camRight) {
      this.t.ensure(camRight + 1500);
      while (this.cursor < camRight + 1000) {
        const x = this.cursor;
        if (x >= this.nextFuel) {
          this.items.push({ type: 'fuel', x, y: this.t.at(x) - 52, taken: false });
          this.nextFuel = x + rand(4600, 7600);
          this.cursor = x + 180;
          continue;
        }
        const n = Math.floor(rand(4, 9)), arch = Math.random() < 0.4 ? rand(30, 90) : 0;
        for (let i = 0; i < n; i++) {
          const cx = x + i * 44;
          this.items.push({ type: 'coin', x: cx, y: this.t.at(cx) - 50 - Math.sin((i / (n - 1)) * Math.PI) * arch, taken: false });
        }
        this.cursor = x + n * 44 + rand(250, 700);
      }
    }
    prune(camLeft) { let i = 0; while (i < this.items.length && this.items[i].x < camLeft - 200) i++; if (i) this.items.splice(0, i); }
  }

  /* ------------------------------ Jeep (física de vehículo) ------------------------------ */
  class Car {
    constructor() { this.reset(); }
    reset() {
      const P = CFG.car;
      this.x = 120; this.y = -45; this.vx = 0; this.vy = 0; this.a = 0; this.w = 0;
      this.wheels = P.wheelsX.map((lx) => ({ lx, ly: P.anchorY, contact: false, pen: 0, ext: 0, rot: 0 }));
      this.airTime = 0; this.maxAir = 0; this.grounded = false; this.headHit = false; this.speed = 0;
    }
    // Puntos de la carrocería que no deben atravesar el suelo
    static get body() {
      return [
        { lx: -64, ly: 6, head: false }, { lx: 64, ly: 6, head: false },
        { lx: -52, ly: -32, head: false }, { lx: 40, ly: -32, head: false },
        { lx: -12, ly: -46, head: true },
      ];
    }
    step(dt, gas, brake, terrain) {
      const P = CFG.car, g = CFG.gravity, s = Math.sin(this.a), c = Math.cos(this.a);
      let fx = 0, fy = g, tq = 0, contacts = 0;
      for (const wh of this.wheels) {
        const ax = this.x + wh.lx * c - wh.ly * s, ay = this.y + wh.lx * s + wh.ly * c;
        const cx = ax - s * P.rest, cy = ay + c * P.rest;
        const gy = terrain.at(cx), sl = terrain.slope(cx), len = Math.sqrt(1 + sl * sl);
        const nx = sl / len, ny = -1 / len, tx = 1 / len, ty = sl / len;
        const pen = (cy + P.wheelR - gy) / len;
        wh.pen = pen; wh.contact = pen > 0;
        if (pen > 0) {
          contacts++;
          const rx = ax - this.x, ry = ay - this.y;
          const pvx = this.vx - this.w * ry, pvy = this.vy + this.w * rx;
          const vn = pvx * nx + pvy * ny, vt = pvx * tx + pvy * ty;
          let Fn = P.k * pen - P.c * vn;
          if (pen > P.maxTravel) Fn += P.kHard * (pen - P.maxTravel);
          if (Fn < 0) Fn = 0;
          let Ft;
          if (gas) Ft = P.engine * (1 - clamp(vt / P.vmax, 0, 1.4));
          else if (brake) Ft = vt > 40 ? -P.brake : -P.reverse * (1 - clamp(-vt / P.vmaxRev, 0, 1.4));
          else Ft = -vt * P.roll;
          const lim = P.grip * Fn;
          Ft = clamp(Ft, -lim, lim);
          const Fx = nx * Fn + tx * Ft, Fy = ny * Fn + ty * Ft;
          fx += Fx; fy += Fy; tq += rx * Fy - ry * Fx;
          wh.rot += (vt / P.wheelR) * dt;
        } else {
          wh.rot += (gas ? 22 : brake ? 0 : 8) * dt * (gas ? 1 : 0.5);
          if (brake) wh.rot *= 0.97;
        }
      }
      // Control en el aire: acelerar inclina el morro hacia arriba, frenar hacia abajo
      if (contacts === 0) {
        if (gas) this.w -= P.airTorque * dt;
        if (brake) this.w += P.airTorque * dt;
      }
      // Carrocería contra el suelo (volcar / no atravesar)
      this.headHit = false;
      for (const b of Car.body) {
        const px = this.x + b.lx * c - b.ly * s, py = this.y + b.lx * s + b.ly * c;
        const pen = py - terrain.at(px);
        if (pen > 0) {
          const rx = px - this.x, ry = py - this.y;
          const pvx = this.vx - this.w * ry, pvy = this.vy + this.w * rx;
          let Fy = -(500 * pen + 14 * Math.max(pvy, 0));
          if (Fy > 0) Fy = 0;
          const Fx = clamp(-pvx * 3, -400, 400);
          fx += Fx; fy += Fy; tq += rx * Fy - ry * Fx;
          if (b.head) this.headHit = true;
        }
      }
      this.vx += fx * dt; this.vy += fy * dt; this.w += (tq / P.inertia) * dt;
      this.w = clamp(this.w * (1 - 0.35 * dt), -9, 9);
      this.vx = clamp(this.vx, -1400, 1400); this.vy = clamp(this.vy, -1800, 1800);
      this.x += this.vx * dt; this.y += this.vy * dt; this.a += this.w * dt;
      if (this.x < -120) { this.x = -120; if (this.vx < 0) this.vx = 0; }
      this.grounded = contacts > 0;
      if (this.grounded) { this.airTime = 0; } else { this.airTime += dt; if (this.airTime > this.maxAir) this.maxAir = this.airTime; }
      this.speed = Math.hypot(this.vx, this.vy);
      // Extensión visual de las ruedas (suavizada)
      for (const wh of this.wheels) {
        const target = wh.contact ? -clamp(wh.pen, 0, P.maxTravel + 6) : 5;
        wh.ext += (target - wh.ext) * Math.min(1, dt * 18);
      }
    }
  }

  /* ------------------------------ Dibujo ------------------------------ */
  const Palette = { red: '#ce1126', blue: '#002d62', white: '#ffffff' };

  class Renderer {
    constructor(canvas) {
      this.cv = canvas; this.ctx = canvas.getContext('2d', { alpha: false });
      this.W = 0; this.H = 0; this.scale = 1; this.sky = null;
      this.resize();
    }
    resize() {
      const dpr = Math.min(window.devicePixelRatio || 1, 1.5);
      this.W = window.innerWidth; this.H = window.innerHeight;
      this.cv.width = Math.round(this.W * dpr); this.cv.height = Math.round(this.H * dpr);
      this.dpr = dpr;
      this.scale = Math.min(this.H / CFG.viewH, this.W / CFG.viewW);
      this.sky = this.ctx.createLinearGradient(0, 0, 0, this.cv.height);
      this.sky.addColorStop(0, '#1e88e5'); this.sky.addColorStop(0.55, '#6ec6ff'); this.sky.addColorStop(1, '#d6f1ff');
    }
    get viewW() { return this.W / this.scale; }
    get viewH() { return this.H / this.scale; }

    draw(game, cam) {
      const ctx = this.ctx, k = this.scale * this.dpr, t = game.terrain, car = game.car;
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.fillStyle = this.sky; ctx.fillRect(0, 0, this.cv.width, this.cv.height);
      ctx.setTransform(k, 0, 0, k, 0, 0);
      this.drawBackground(ctx, cam, game.time);
      ctx.setTransform(k, 0, 0, k, -cam.x * k, -cam.y * k);
      const left = cam.x - 40, right = cam.x + this.viewW + 40;
      this.drawTerrain(ctx, t, left, right, cam);
      this.drawPalms(ctx, t, left, right);
      this.drawItems(ctx, game, left, right);
      this.drawCar(ctx, car);
    }

    drawBackground(ctx, cam, time) {
      const W = this.viewW, H = this.viewH;
      // Sol
      ctx.fillStyle = 'rgba(255,240,150,.35)'; ctx.beginPath(); ctx.arc(W * 0.82, H * 0.2, 52, 0, 6.3); ctx.fill();
      ctx.fillStyle = '#fff6a8'; ctx.beginPath(); ctx.arc(W * 0.82, H * 0.2, 34, 0, 6.3); ctx.fill();
      // Nubes
      ctx.fillStyle = 'rgba(255,255,255,.9)';
      for (let i = 0; i < 6; i++) {
        const span = W + 300, x = ((i * 260 - cam.x * 0.06 - time * 6) % span + span) % span - 150, y = 30 + (i * 53) % 110;
        ctx.beginPath(); ctx.ellipse(x, y, 46, 16, 0, 0, 6.3); ctx.ellipse(x + 28, y - 10, 30, 16, 0, 0, 6.3); ctx.ellipse(x - 26, y - 5, 26, 12, 0, 0, 6.3); ctx.fill();
      }
      // Montañas (cordillera Central) con dos capas de parallax
      const layers = [{ f: 0.1, c: '#6aa0b8', base: 0.58, amp: 90, w: 520 }, { f: 0.22, c: '#3f8a63', base: 0.68, amp: 70, w: 340 }];
      for (const L of layers) {
        ctx.fillStyle = L.c; ctx.beginPath(); ctx.moveTo(0, H);
        const off = cam.x * L.f;
        for (let x = 0; x <= W + 20; x += 20) {
          const u = (x + off) / L.w;
          const y = H * L.base - L.amp * (0.55 * Math.sin(u) + 0.3 * Math.sin(u * 2.3 + 1.7) + 0.15 * Math.sin(u * 5.1)) - L.amp * 0.5 - (cam.y * 0.04);
          ctx.lineTo(x, y);
        }
        ctx.lineTo(W, H); ctx.closePath(); ctx.fill();
      }
    }

    drawTerrain(ctx, t, left, right, cam) {
      const st = t.step, i0 = Math.floor(left / st), i1 = Math.ceil(right / st);
      t.ensure(right + 200);
      const bottom = cam.y + this.viewH + 40;
      ctx.beginPath(); ctx.moveTo(i0 * st, bottom);
      for (let i = i0; i <= i1; i++) ctx.lineTo(i * st, t.at(i * st));
      ctx.lineTo(i1 * st, bottom); ctx.closePath();
      ctx.fillStyle = '#7a4b22'; ctx.fill();
      // Franja de tierra oscura
      ctx.beginPath(); ctx.moveTo(i0 * st, bottom);
      for (let i = i0; i <= i1; i++) ctx.lineTo(i * st, t.at(i * st) + 46);
      ctx.lineTo(i1 * st, bottom); ctx.closePath();
      ctx.fillStyle = '#5e3716'; ctx.fill();
      // Césped
      ctx.lineJoin = 'round'; ctx.lineCap = 'round';
      ctx.beginPath(); for (let i = i0; i <= i1; i++) (i === i0 ? ctx.moveTo : ctx.lineTo).call(ctx, i * st, t.at(i * st) + 6);
      ctx.strokeStyle = '#2f9a34'; ctx.lineWidth = 20; ctx.stroke();
      ctx.beginPath(); for (let i = i0; i <= i1; i++) (i === i0 ? ctx.moveTo : ctx.lineTo).call(ctx, i * st, t.at(i * st) + 1);
      ctx.strokeStyle = '#6fd34a'; ctx.lineWidth = 7; ctx.stroke();
    }

    drawPalms(ctx, t, left, right) {
      const sp = 150, k0 = Math.floor(left / sp) - 1, k1 = Math.ceil(right / sp);
      for (let k = k0; k <= k1; k++) {
        if (k < 3 || hash(k) > 0.55) continue;
        const x = k * sp + hash(k + 9) * 80, y = t.at(x), sl = t.slope(x);
        if (Math.abs(sl) > 0.45) continue;
        const hgt = 70 + hash(k + 3) * 50, lean = (hash(k + 5) - 0.5) * 36;
        ctx.strokeStyle = '#7a5230'; ctx.lineWidth = 7; ctx.lineCap = 'round';
        ctx.beginPath(); ctx.moveTo(x, y + 4); ctx.quadraticCurveTo(x + lean * 0.2, y - hgt * 0.5, x + lean, y - hgt); ctx.stroke();
        const tx = x + lean, ty = y - hgt;
        ctx.strokeStyle = '#1f8a2c'; ctx.lineWidth = 6;
        for (let f = 0; f < 6; f++) {
          const ang = -Math.PI + (f / 5) * Math.PI, dx = Math.cos(ang) * 46, dy = Math.sin(ang) * 22;
          ctx.beginPath(); ctx.moveTo(tx, ty); ctx.quadraticCurveTo(tx + dx * 0.6, ty + dy - 14, tx + dx, ty + dy + 16); ctx.stroke();
        }
        ctx.fillStyle = '#5a3a1a'; ctx.beginPath(); ctx.arc(tx - 3, ty + 3, 4, 0, 6.3); ctx.arc(tx + 4, ty + 4, 4, 0, 6.3); ctx.fill();
      }
    }

    drawItems(ctx, game, left, right) {
      const bob = Math.sin(game.time * 5) * 3;
      for (const it of game.world.items) {
        if (it.taken || it.x < left - 30 || it.x > right + 30) continue;
        if (it.type === 'coin') {
          const sx = Math.abs(Math.cos(game.time * 4 + it.x * 0.01)) * 0.7 + 0.3;
          ctx.save(); ctx.translate(it.x, it.y + bob); ctx.scale(sx, 1);
          ctx.fillStyle = '#c98a00'; ctx.beginPath(); ctx.arc(0, 0, 13, 0, 6.3); ctx.fill();
          ctx.fillStyle = '#ffd21f'; ctx.beginPath(); ctx.arc(0, 0, 10.5, 0, 6.3); ctx.fill();
          ctx.fillStyle = '#fff4a0'; ctx.fillRect(-2, -6, 4, 12);
          ctx.restore();
        } else {
          ctx.save(); ctx.translate(it.x, it.y + bob);
          ctx.fillStyle = '#b3141a'; ctx.fillRect(-14, -18, 28, 36);
          ctx.fillStyle = '#fff'; ctx.fillRect(-14, -4, 28, 8);
          ctx.fillStyle = '#7a0a10'; ctx.fillRect(-8, -24, 16, 7);
          ctx.fillStyle = '#fff'; ctx.font = 'bold 14px sans-serif'; ctx.textAlign = 'center'; ctx.fillText('⛽', 0, 14);
          ctx.restore();
        }
      }
    }

    drawWheel(ctx, x, y, rot) {
      const r = CFG.car.wheelR;
      ctx.fillStyle = '#1b1b1b'; ctx.beginPath(); ctx.arc(x, y, r, 0, 6.3); ctx.fill();
      ctx.fillStyle = '#c9c9c9'; ctx.beginPath(); ctx.arc(x, y, r * 0.58, 0, 6.3); ctx.fill();
      ctx.save(); ctx.translate(x, y); ctx.rotate(rot);
      ctx.fillStyle = '#2a2a2a';
      for (let i = 0; i < 8; i++) { ctx.rotate(Math.PI / 4); ctx.fillRect(r - 3, -2.5, 6, 5); }   // tacos del neumático
      ctx.fillStyle = Palette.red; ctx.fillRect(-r * 0.5, -3, r, 6); ctx.fillStyle = Palette.blue; ctx.fillRect(-3, -r * 0.5, 6, r);
      ctx.restore();
      ctx.fillStyle = '#666'; ctx.beginPath(); ctx.arc(x, y, 4, 0, 6.3); ctx.fill();
    }

    drawCar(ctx, car) {
      ctx.save(); ctx.translate(car.x, car.y); ctx.rotate(car.a);
      const P = CFG.car;
      // Suspensión y ruedas
      for (const wh of car.wheels) {
        const wy = wh.ly + P.rest + wh.ext;
        ctx.strokeStyle = '#444'; ctx.lineWidth = 6; ctx.beginPath(); ctx.moveTo(wh.lx, wh.ly - 4); ctx.lineTo(wh.lx, wy); ctx.stroke();
        this.drawWheel(ctx, wh.lx, wy, wh.rot);
      }
      // Rueda de repuesto
      ctx.fillStyle = '#222'; ctx.beginPath(); ctx.arc(-68, -6, 14, 0, 6.3); ctx.fill();
      ctx.fillStyle = '#999'; ctx.beginPath(); ctx.arc(-68, -6, 6, 0, 6.3); ctx.fill();
      // Carrocería
      const rr = (x, y, w, h, r) => { ctx.beginPath(); ctx.moveTo(x + r, y); ctx.arcTo(x + w, y, x + w, y + h, r); ctx.arcTo(x + w, y + h, x, y + h, r); ctx.arcTo(x, y + h, x, y, r); ctx.arcTo(x, y, x + w, y, r); ctx.closePath(); };
      ctx.fillStyle = Palette.red; rr(-62, -18, 124, 34, 9); ctx.fill();
      ctx.fillStyle = '#9d0c1c'; ctx.fillRect(-62, 8, 124, 8);
      ctx.fillStyle = Palette.white; ctx.fillRect(-58, -4, 116, 6);       // franja blanca (cruz de la bandera)
      ctx.fillStyle = Palette.blue; ctx.fillRect(-58, 2, 116, 4);
      // Capó y parabrisas
      ctx.fillStyle = Palette.red; ctx.beginPath(); ctx.moveTo(14, -18); ctx.lineTo(44, -18); ctx.lineTo(62, -8); ctx.lineTo(62, -18); ctx.closePath();
      ctx.fillStyle = '#7fd3ff'; ctx.beginPath(); ctx.moveTo(12, -18); ctx.lineTo(24, -36); ctx.lineTo(30, -36); ctx.lineTo(30, -18); ctx.closePath(); ctx.fill();
      // Piloto
      ctx.fillStyle = '#f0b27a'; ctx.beginPath(); ctx.arc(-12, -32, 10, 0, 6.3); ctx.fill();
      ctx.fillStyle = Palette.blue; ctx.beginPath(); ctx.arc(-12, -35, 10.5, Math.PI, 0); ctx.fill(); ctx.fillRect(-4, -36, 14, 3);
      ctx.fillStyle = '#fff'; ctx.fillRect(-17, -31, 3, 3);
      // Jaula antivuelco
      ctx.strokeStyle = '#222'; ctx.lineWidth = 4; ctx.lineJoin = 'round';
      ctx.beginPath(); ctx.moveTo(-50, -16); ctx.lineTo(-48, -44); ctx.lineTo(8, -44); ctx.lineTo(14, -18); ctx.stroke();
      ctx.fillStyle = Palette.blue; ctx.fillRect(-52, -47, 62, 5);
      // Faro y parachoques
      ctx.fillStyle = '#fff59a'; ctx.beginPath(); ctx.arc(58, -9, 5, 0, 6.3); ctx.fill();
      ctx.fillStyle = '#333'; ctx.fillRect(58, 4, 8, 6);
      // Antena con bandera
      ctx.strokeStyle = '#333'; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(-54, -18); ctx.lineTo(-58, -70); ctx.stroke();
      const fl = Math.sin(performance.now() / 120) * 3;
      ctx.fillStyle = Palette.red; ctx.fillRect(-58, -70, 12, 5 + fl * 0.2);
      ctx.fillStyle = Palette.blue; ctx.fillRect(-58, -65 + fl * 0.2, 12, 5);
      ctx.restore();
    }
  }

  /* ------------------------------ Juego (estados, HUD, bucle) ------------------------------ */
  class Game {
    constructor() {
      this.cv = $('game'); this.r = new Renderer(this.cv);
      this.terrain = new Terrain(); this.world = new World(this.terrain); this.car = new Car();
      this.state = 'menu';
      this.best = Store.get('best', 0); this.totalCoins = Store.get('coins', 0);
      this.cam = { x: 0, y: -300 };
      this.time = 0; this.acc = 0; this.last = 0;
      this.hud = { coins: -1, dist: -1, fuel: -1, best: -1 };
      this.bindUI();
      this.reset(); this.updateMenu();
      this.cam.x = this.car.x - this.r.viewW * 0.3; this.cam.y = this.car.y - this.r.viewH * 0.6;
      requestAnimationFrame((t) => { this.last = t; this.loop(t); });
    }
    reset() {
      this.terrain.reset(); this.world.reset(); this.car.reset();
      this.fuel = 100; this.runCoins = 0; this.dist = 0; this.stuck = 0; this.endReason = '';
      this.world.update(this.car.x + this.r.viewW);
      Input.clear();
    }
    bindUI() {
      bindHold($('btnGas'), 'gas'); bindHold($('btnBrake'), 'brake');
      const on = (id, fn) => $(id).addEventListener('click', fn);
      on('btnPlay', () => this.start()); on('btnAgain', () => this.start());
      on('btnPause', () => this.pause()); on('btnResume', () => this.resume());
      on('btnRestart', () => this.start());
      on('btnToMenu', () => this.toMenu()); on('btnOverMenu', () => this.toMenu());
      on('btnFull', () => {
        const el = document.documentElement;
        try { (el.requestFullscreen || el.webkitRequestFullscreen).call(el); } catch (e) { /* no soportado */ }
        try { screen.orientation.lock('landscape').catch(() => {}); } catch (e) { /* */ }
      });
      window.addEventListener('resize', () => this.r.resize());
      window.addEventListener('orientationchange', () => setTimeout(() => this.r.resize(), 200));
      document.addEventListener('visibilitychange', () => { if (document.hidden) { this.pause(); this.save(); } });
      window.addEventListener('pagehide', () => this.save());
      const keyMap = { ArrowRight: 'gas', KeyD: 'gas', ArrowUp: 'gas', ArrowLeft: 'brake', KeyA: 'brake', ArrowDown: 'brake' };
      window.addEventListener('keydown', (e) => {
        if (keyMap[e.code]) { Input._k[keyMap[e.code]] = true; Input.refresh(); e.preventDefault(); }
        else if (e.code === 'KeyP' || e.code === 'Escape') { this.state === 'play' ? this.pause() : this.state === 'pause' && this.resume(); }
        else if ((e.code === 'Enter' || e.code === 'Space') && (this.state === 'menu' || this.state === 'over')) this.start();
      });
      window.addEventListener('keyup', (e) => { if (keyMap[e.code]) { Input._k[keyMap[e.code]] = false; Input.refresh(); } });
    }
    show(id, on) { $(id).hidden = !on; }
    setScreens(state) {
      this.state = state;
      this.show('menu', state === 'menu'); this.show('pause', state === 'pause'); this.show('over', state === 'over');
      const playing = state === 'play' || state === 'pause';
      this.show('hud', playing); this.show('controls', state === 'play' || state === 'pause' || state === 'over');
      this.show('controls', playing);
    }
    updateMenu() { $('menuBest').textContent = this.best; $('menuCoins').textContent = this.totalCoins; }
    start() { this.reset(); this.setScreens('play'); this.last = performance.now(); this.acc = 0; this.hud = { coins: -1, dist: -1, fuel: -1, best: -1 }; this.updateHud(); }
    pause() { if (this.state !== 'play') return; Input.clear(); this.setScreens('pause'); this.save(); }
    resume() { if (this.state !== 'pause') return; this.setScreens('play'); this.last = performance.now(); }
    toMenu() { this.reset(); this.setScreens('menu'); this.updateMenu(); }
    save() { Store.set('best', this.best); Store.set('coins', this.totalCoins); }
    gameOver(reason) {
      if (this.state !== 'play') return;
      this.endReason = reason; Input.clear();
      const isRecord = this.dist > this.best;
      if (isRecord) this.best = this.dist;
      this.save();
      $('overTitle').textContent = reason === 'fuel' ? '¡SIN COMBUSTIBLE!' : '¡TE VOLCASTE!';
      $('overReason').textContent = reason === 'fuel' ? 'Se te acabó la gasolina.' : 'Tu piloto se golpeó la cabeza.';
      $('overDist').textContent = this.dist + ' m'; $('overCoins').textContent = '+' + this.runCoins; $('overBest').textContent = this.best + ' m';
      this.show('overRecord', isRecord);
      this.setScreens('over'); this.show('hud', true); this.updateHud(true);
    }

    update(dt) {
      const car = this.car, gas = Input.gas && this.fuel > 0, brake = Input.brake;
      car.step(dt, gas, brake, this.terrain);
      this.time += dt;
      // Combustible
      this.fuel = Math.max(0, this.fuel - (CFG.fuelBase + (gas ? CFG.fuelGas : 0)) * dt);
      // Recolección (radio generoso)
      const cx = car.x, cy = car.y;
      for (const it of this.world.items) {
        if (it.taken || it.x < cx - 90) continue;
        if (it.x > cx + 90) break;
        const dx = it.x - cx, dy = it.y - cy;
        if (dx * dx + dy * dy < 62 * 62) {
          it.taken = true;
          if (it.type === 'coin') { this.runCoins += CFG.coinValue; this.totalCoins += CFG.coinValue; } else this.fuel = Math.min(100, this.fuel + CFG.fuelCan);
        }
      }
      this.dist = Math.max(this.dist, Math.floor((car.x - 120) / CFG.px2m));
      // Condiciones de derrota
      if (car.headHit) { this.headT = (this.headT || 0) + dt; if (this.headT > 0.25) this.gameOver('crash'); } else this.headT = 0;
      // Volcado: sin ninguna rueda apoyada y casi inmóvil (de techo, de lado)
      if (!car.grounded && car.speed < 40) { this.flipT = (this.flipT || 0) + dt; if (this.flipT > 1.5) this.gameOver('crash'); } else this.flipT = 0;
      if (this.fuel <= 0) { this.stuck = car.speed < 25 ? this.stuck + dt : 0; if (this.stuck > 1.2) this.gameOver('fuel'); }
    }

    updateHud(force) {
      const h = this.hud;
      if (h.coins !== this.totalCoins) { h.coins = this.totalCoins; $('hudCoins').textContent = this.totalCoins; }
      if (h.dist !== this.dist) { h.dist = this.dist; $('hudDist').textContent = this.dist; }
      const bst = Math.max(this.best, this.dist);
      if (h.best !== bst) { h.best = bst; $('hudBest').textContent = bst; }
      const f = Math.round(this.fuel);
      if (h.fuel !== f || force) { h.fuel = f; $('fuelFill').style.width = f + '%'; $('fuelFill').classList.toggle('low', f < 20); }
    }

    camera(dt) {
      const car = this.car, r = this.r;
      const tx = car.x - r.viewW * 0.3 + clamp(car.vx, -300, 700) * 0.12;
      const ty = car.y - r.viewH * 0.62;
      const kx = 1 - Math.exp(-dt * 8), ky = 1 - Math.exp(-dt * 4);
      this.cam.x += (tx - this.cam.x) * kx; this.cam.y += (ty - this.cam.y) * ky;
    }

    loop(now) {
      let frame = (now - this.last) / 1000; this.last = now;
      if (frame > 0.1) frame = 0.1;
      if (this.state === 'play') {
        this.acc += frame;
        while (this.acc >= CFG.step && this.state === 'play') { this.update(CFG.step); this.acc -= CFG.step; }
        this.world.update(this.cam.x + this.r.viewW);
        this.world.prune(this.cam.x);
        this.updateHud();
      } else if (this.state === 'menu') {
        this.time += frame;     // animación de fondo en el menú
      }
      this.camera(frame);
      this.r.draw(this, this.cam);
      requestAnimationFrame((t) => this.loop(t));
    }
  }

  window.addEventListener('error', (e) => { try { console.error('Error del juego:', e.message); } catch (_) { /* */ } });
  window.__game = new Game();   // expuesto para pruebas y depuración
})();
