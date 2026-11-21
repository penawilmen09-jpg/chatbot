import { CONFIG } from '../config.js';

// Estado del jugador y del mundo. Todo lo "guardable" vive aquí (dinero, trabajo,
// inventario, propiedades, vehículos, ajustes). Los sistemas futuros se enganchan
// con on()/emit() sin acoplarse entre sí.

export class GameState {
  constructor() {
    this.data = {
      money: CONFIG.startMoney,
      job: null,                 // futuro: trabajos y misiones
      quests: {},                // futuro: progreso de misiones
      inventory: [],             // futuro: inventario
      properties: [],            // futuro: compra de propiedades (ej. 'casa_real')
      vehicles: [],              // futuro: garaje
      appearance: { shirt: 0xf4f4f0, pants: 0x2f4a7a, cap: 0xc0262d }, // futuro: personalización
      hour: CONFIG.time.startHour,
      pos: null,
      settings: { quality: 'auto', sens: 1, sound: true, cycle: true, fps: false },
    };
    this.listeners = {};
  }
  on(ev, fn) { (this.listeners[ev] ||= []).push(fn); }
  emit(ev, v) { (this.listeners[ev] || []).forEach((f) => f(v)); }
  addMoney(n) { this.data.money += n; this.emit('money', this.data.money); }
  spend(n) { if (this.data.money < n) return false; this.data.money -= n; this.emit('money', this.data.money); return true; }
}
