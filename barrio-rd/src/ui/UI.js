import { placeAt, WAYPOINT } from '../world/Places.js';

const $ = (id) => document.getElementById(id);

export class UI {
  constructor() {
    this.el = {
      loading: $('loading'), bar: $('load-bar'), text: $('load-text'), start: $('btn-start'), tip: $('load-tip'),
      hud: $('hud'), money: $('money'), clock: $('clock'), zone: $('zone-label'), toast: $('toast'),
      act: $('btn-act'), actLabel: $('act-label'), actIcon: $('act-icon'), dialog: $('dialog'), dlgTitle: $('dlg-title'), dlgText: $('dlg-text'),
      menu: $('menu'), fps: $('fps'), zoneLoad: $('zone-load'), wpArrow: $('wp-arrow'), wpText: $('wp-text'), waypoint: $('waypoint'),
    };
    this._toastT = 0; this._zoneT = 0; this._lastPlace = '';
    this.dialogOpen = false; this.menuOpen = false;
    $('dlg-ok').addEventListener('click', () => this.closeDialog());
    this.el.dialog.addEventListener('pointerdown', (e) => { if (e.target === this.el.dialog) this.closeDialog(); });
  }
  progress(p, text) { this.el.bar.style.width = `${Math.round(p * 100)}%`; if (text) this.el.text.textContent = text; }
  ready(onStart) {
    this.el.text.textContent = '¡Listo!'; this.el.start.hidden = false;
    this.el.start.addEventListener('click', () => { this.el.loading.style.display = 'none'; this.el.hud.hidden = false; onStart(); }, { once: true });
  }
  toast(msg, ms = 3200) {
    const t = this.el.toast; t.textContent = msg; t.classList.add('show');
    clearTimeout(this._toastT); this._toastT = setTimeout(() => t.classList.remove('show'), ms);
  }
  dialog(title, text) { this.el.dlgTitle.textContent = title; this.el.dlgText.textContent = text; this.el.dialog.hidden = false; this.dialogOpen = true; }
  closeDialog() { this.el.dialog.hidden = true; this.dialogOpen = false; }
  setMenu(open) { this.menuOpen = open; this.el.menu.hidden = !open; }
  setMoney(v) { this.el.money.textContent = `RD$ ${v.toLocaleString('es-DO')}`; }
  setClock(h) { const hh = Math.floor(h), mm = Math.floor((h - hh) * 60); this.el.clock.textContent = `${String(hh).padStart(2, '0')}:${String(mm).padStart(2, '0')}`; }
  setAction(it) {
    if (!it) { this.el.act.hidden = true; return; }
    this.el.act.hidden = false; this.el.actLabel.textContent = it.label; this.el.actIcon.textContent = it.icon || '✋';
  }
  setPlace(x, z) {
    const p = placeAt(x, z);
    if (p !== this._lastPlace) {
      this._lastPlace = p; this.el.zone.textContent = p; this.el.zone.classList.add('show');
      clearTimeout(this._zoneT); this._zoneT = setTimeout(() => this.el.zone.classList.remove('show'), 2800);
    }
    return p;
  }
  setWaypoint(px, pz, camYaw) {
    const dx = WAYPOINT.x - px, dz = WAYPOINT.z - pz, d = Math.hypot(dx, dz);
    if (d < 14) { this.el.waypoint.style.display = 'none'; return; }
    this.el.waypoint.style.display = 'flex';
    // rumbo relativo a la cámara: adelante f=(-sin yaw,-cos yaw), derecha r=(cos yaw,-sin yaw)
    const fwd = dx * -Math.sin(camYaw) + dz * -Math.cos(camYaw);
    const right = dx * Math.cos(camYaw) + dz * -Math.sin(camYaw);
    this.el.wpArrow.style.transform = `rotate(${(Math.atan2(-fwd, right) * 180) / Math.PI}deg)`;
    this.el.wpText.textContent = `📍 ${WAYPOINT.name} · ${Math.round(d)} m`;
  }
  setFps(txt) { this.el.fps.textContent = txt; }
}
