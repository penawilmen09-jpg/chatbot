// Entrada unificada: teclado + ratón + táctil (joystick flotante, cámara por arrastre, botones).
// El resto del juego solo lee: move{x,y}, run, consumeLook(), consumeInteract().

export class Input {
  constructor() {
    this.move = { x: 0, y: 0 };        // x: derecha, y: adelante (-1..1)
    this.runBtn = false;               // botón CORRER (toggle táctil)
    this.runKey = false;
    this.look = { dx: 0, dy: 0 };
    this.zoom = 0;
    this._interact = false;
    this.keys = new Set();
    this.joy = { id: null, ox: 0, oy: 0, x: 0, y: 0 };
    this.lookPtr = { id: null, x: 0, y: 0 };
    this.sens = 1;
    this.enabled = true;
    this.touchUsed = false;
    this.onToggleMenu = null;
    this._bindKeyboard();
    this._bindTouch();
  }

  get run() { return this.runBtn || this.runKey; }
  consumeLook() { const l = { dx: this.look.dx, dy: this.look.dy }; this.look.dx = this.look.dy = 0; return l; }
  consumeInteract() { const v = this._interact; this._interact = false; return v; }
  consumeZoom() { const z = this.zoom; this.zoom = 0; return z; }

  _bindKeyboard() {
    const dn = (e) => {
      if (!this.enabled) return;
      const k = e.key.toLowerCase();
      if (['arrowup', 'arrowdown', 'arrowleft', 'arrowright', ' '].includes(k)) e.preventDefault();
      if (k === 'e' || k === 'f' || k === 'enter') this._interact = true;
      if (k === 'escape' || k === 'p') this.onToggleMenu?.();
      this.keys.add(k);
      this._recalcKeys(e);
    };
    const up = (e) => { this.keys.delete(e.key.toLowerCase()); this._recalcKeys(e); };
    addEventListener('keydown', dn); addEventListener('keyup', up);
    addEventListener('blur', () => { this.keys.clear(); this._recalcKeys({}); });
  }
  _recalcKeys(e) {
    const k = this.keys;
    this.runKey = k.has('shift') || !!e.shiftKey;
    if (this.joy.id !== null) return;
    const x = (k.has('d') ? 1 : 0) - (k.has('a') ? 1 : 0);
    const y = (k.has('w') || k.has('arrowup') ? 1 : 0) - (k.has('s') || k.has('arrowdown') ? 1 : 0);
    const len = Math.hypot(x, y) || 1;
    this.move.x = x / len; this.move.y = y / len;
  }
  // rotación de cámara con flechas izquierda/derecha (por frame)
  keyLook(dt) {
    const k = this.keys;
    const r = (k.has('arrowright') ? 1 : 0) - (k.has('arrowleft') ? 1 : 0);
    if (r) this.look.dx += r * 520 * dt;
  }

  _bindTouch() {
    const $ = (id) => document.getElementById(id);
    const joyZone = $('joy-zone'), base = $('joy-base'), knob = $('joy-knob'), lookZone = $('look-zone'), runBtn = $('btn-run'), actBtn = $('btn-act');
    const R = 54;
    const homeLeft = () => base.style.left, homeBottom = () => base.style.bottom;
    const setKnob = (dx, dy) => { knob.style.transform = `translate(${dx}px, ${dy}px)`; };

    joyZone.addEventListener('pointerdown', (e) => {
      if (this.joy.id !== null) return;
      e.preventDefault(); this.touchUsed = true;
      joyZone.setPointerCapture(e.pointerId);
      const rect = joyZone.getBoundingClientRect();
      // joystick flotante: la base aparece donde se toca (limitada a la zona)
      const bw = base.offsetWidth;
      const cx = Math.min(Math.max(e.clientX, rect.left + bw / 2 + 6), rect.right - bw / 2 - 6);
      const cy = Math.min(Math.max(e.clientY, rect.top + bw / 2 + 6), rect.bottom - bw / 2 - 6);
      base.style.left = `${cx - rect.left - bw / 2}px`; base.style.bottom = `${rect.bottom - cy - bw / 2}px`;
      base.classList.add('active');
      this.joy = { id: e.pointerId, ox: cx, oy: cy, x: 0, y: 0 };
      this._joyMove(e, R, setKnob);
    });
    joyZone.addEventListener('pointermove', (e) => { if (e.pointerId === this.joy.id) this._joyMove(e, R, setKnob); });
    const end = (e) => {
      if (e.pointerId !== this.joy.id) return;
      this.joy.id = null; this.move.x = 0; this.move.y = 0; setKnob(0, 0); base.classList.remove('active');
      base.style.left = ''; base.style.bottom = '';
    };
    joyZone.addEventListener('pointerup', end); joyZone.addEventListener('pointercancel', end);

    // cámara: arrastrar en cualquier parte libre (ratón o dedo)
    lookZone.addEventListener('pointerdown', (e) => {
      if (this.lookPtr.id !== null) return;
      if (e.pointerType === 'mouse' && e.button !== 0) return;
      if (e.pointerType !== 'mouse') this.touchUsed = true;
      lookZone.setPointerCapture(e.pointerId);
      this.lookPtr = { id: e.pointerId, x: e.clientX, y: e.clientY };
    });
    lookZone.addEventListener('pointermove', (e) => {
      if (e.pointerId !== this.lookPtr.id) return;
      this.look.dx += (e.clientX - this.lookPtr.x); this.look.dy += (e.clientY - this.lookPtr.y);
      this.lookPtr.x = e.clientX; this.lookPtr.y = e.clientY;
    });
    const lend = (e) => { if (e.pointerId === this.lookPtr.id) this.lookPtr.id = null; };
    lookZone.addEventListener('pointerup', lend); lookZone.addEventListener('pointercancel', lend);
    lookZone.addEventListener('wheel', (e) => { this.zoom += Math.sign(e.deltaY); }, { passive: true });

    // botones
    runBtn.addEventListener('pointerdown', (e) => { e.preventDefault(); e.stopPropagation(); this.touchUsed = true; this.runBtn = !this.runBtn; runBtn.classList.toggle('on', this.runBtn); });
    actBtn.addEventListener('pointerdown', (e) => { e.preventDefault(); e.stopPropagation(); this._interact = true; });
    addEventListener('contextmenu', (e) => e.preventDefault());
  }

  _joyMove(e, R, setKnob) {
    let dx = e.clientX - this.joy.ox, dy = e.clientY - this.joy.oy;
    const d = Math.hypot(dx, dy);
    if (d > R) { dx = (dx / d) * R; dy = (dy / d) * R; }
    setKnob(dx, dy);
    let nx = dx / R, ny = -dy / R;
    const mag = Math.hypot(nx, ny), dead = 0.12;
    if (mag < dead) { nx = ny = 0; } else { const s = (mag - dead) / (1 - dead) / mag; nx *= s; ny *= s; }
    this.move.x = nx; this.move.y = ny;
    this.joy.x = nx; this.joy.y = ny;
  }
}
