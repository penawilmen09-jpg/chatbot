import * as THREE from 'three';
import { CONFIG } from '../config.js';
import { initTextures, Tex } from './Textures.js';
import { createMaterials } from './Materials.js';
import { Colliders } from './Colliders.js';
import { ZoneManager } from './ZoneManager.js';
import { Player } from '../character/Player.js';
import { ThirdPersonCamera } from '../camera/ThirdPersonCamera.js';
import { Input } from '../controls/Input.js';
import { Interactions } from '../interactions/Interactions.js';
import { DayNight } from '../systems/DayNight.js';
import { GameState } from '../systems/GameState.js';
import { SaveSystem } from '../systems/SaveSystem.js';
import { AudioSystem } from '../audio/AudioSystem.js';
import { ZONES } from '../world/Barrio.js';
import { timeUniform } from '../world/Flora.js';
import { Rng } from './Rng.js';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const ZERO_INPUT = { move: { x: 0, y: 0 }, run: false };
const QUALITY = {
  low: { pr: 1.0, shadow: 0, shadowSize: 1024 },
  medium: { pr: 1.25, shadow: 1, shadowSize: 1024 },
  high: { pr: 2.0, shadow: 1, shadowSize: 2048 },
  auto: { pr: 1.5, shadow: 1, shadowSize: 2048 },
};

export class Game {
  constructor(ui) {
    this.ui = ui;
    this.state = new GameState();
    this.time = 0; this.running = false;
    this.fineMeshes = [];
    this.frames = 0; this.fpsAcc = 0; this.fpsTimer = 0; this.fps = 60; this.stable = 0;
  }

  async init(canvas) {
    const ui = this.ui;
    ui.progress(0.05, 'Preparando el motor 3D…');
    const dpr = window.devicePixelRatio || 1;
    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: dpr < 2.5, powerPreference: 'high-performance', stencil: false });
    const r = this.renderer;
    r.outputColorSpace = THREE.SRGBColorSpace;
    r.toneMapping = THREE.ACESFilmicToneMapping; r.toneMappingExposure = 1.0;
    r.shadowMap.enabled = true; r.shadowMap.type = THREE.PCFShadowMap;
    initTextures(r);

    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(CONFIG.camera.fov, 1, CONFIG.camera.near, 560);
    this.scene.add(this.camera);

    // ---- luces
    this.hemi = new THREE.HemisphereLight(0xb5d8f5, 0x7a8a58, 1.0); this.scene.add(this.hemi);
    this.sun = new THREE.DirectionalLight(0xfff1d6, 3); this.sun.castShadow = true;
    const sc = this.sun.shadow.camera; sc.left = -40; sc.right = 40; sc.top = 40; sc.bottom = -40; sc.near = 1; sc.far = 220;
    this.sun.shadow.bias = -0.0006; this.sun.shadow.normalBias = 0.05;
    this.scene.add(this.sun, this.sun.target);

    ui.progress(0.15, 'Generando texturas…');
    await new Promise((res) => setTimeout(res, 0));
    this.mats = createMaterials();
    this.colliders = new Colliders();
    this.interactions = new Interactions();
    this.dayNight = new DayNight({ scene: this.scene, renderer: r, sunLight: this.sun, hemi: this.hemi, mats: this.mats });
    this.buildGround();
    this.buildHills();

    // ---- guardado
    const save = SaveSystem.load();
    if (save) Object.assign(this.state.data, save.data || {});
    const st = this.state.data;
    this.params = new URLSearchParams(location.search);
    if (this.params.has('hour')) st.hour = parseFloat(this.params.get('hour'));
    this.dayNight.hour = st.hour;

    // ---- jugador, cámara, entrada, audio
    this.input = new Input();
    this.player = new Player(this.colliders);
    this.scene.add(this.player.object);
    this.camCtl = new ThirdPersonCamera(this.camera, this.colliders);
    this.audio = new AudioSystem(); this.audio.enabled = st.settings.sound;
    this.player.onStep = (run) => this.audio.step(run);
    this.input.onToggleMenu = () => this.toggleMenu();

    // ---- mundo por zonas (la zona 'centro' es obligatoria; las demás cargan en segundo plano)
    this.zones = new ZoneManager(this, ZONES);
    ui.progress(0.3, 'Construyendo el barrio…');
    await this.zones.load('centro');
    ui.progress(0.7, 'Construyendo Mi Casa Real…');
    await this.zones.load('casaReal');
    ui.progress(0.9, 'Colocando al personaje…');

    // posición inicial (o la guardada)
    let sp = CONFIG.player.spawn, y = 0;
    const where = this.params.get('spawn');
    const SPAWNS = {
      casa: { x: 26, z: -10.5, rot: Math.PI }, patio: { x: 26, z: -24, rot: Math.PI }, piscina: { x: 24, z: -20, rot: -Math.PI / 2 },
      escalera: { x: 33.5, z: -30, rot: Math.PI }, balcon: { x: 22, z: -38.4, rot: Math.PI, y: 3.55 }, sala: { x: 22, z: -41.5, rot: 0, y: 0.1 }, habitacion: { x: 22, z: -42, rot: 0, y: 3.55 },
      colmado: { x: -13, z: 5.2, rot: Math.PI }, calle: { x: -3, z: 5.2, rot: Math.PI / 2 },
    };
    if (where && SPAWNS[where]) sp = SPAWNS[where];
    else if (st.pos && !this.params.has('new')) sp = st.pos;
    this.player.teleport(sp.x, sp.y ?? this.colliders.groundAt(sp.x, sp.z, 5, 0.5), sp.z, sp.rot ?? 0);
    // forward del jugador = (sin rot, cos rot); la cámara mira en (-sin yaw, -cos yaw) => yaw = rot + π
    this.camCtl.yaw = this.params.has('yaw') ? parseFloat(this.params.get('yaw')) : (sp.rot ?? 0) + Math.PI;
    if (this.params.has('pitch')) this.camCtl.pitch = parseFloat(this.params.get('pitch'));
    if (this.params.has('dist')) this.camCtl.dist = this.camCtl.curDist = parseFloat(this.params.get('dist'));
    this.camCtl.snap(new THREE.Vector3(sp.x, (sp.y ?? 0) + CONFIG.camera.height, sp.z));

    this.applySettings();
    this.wireMenu();
    window.addEventListener('resize', () => this.resize());
    window.addEventListener('orientationchange', () => setTimeout(() => this.resize(), 250));
    document.addEventListener('visibilitychange', () => { if (document.hidden) this.save(); });
    window.addEventListener('pagehide', () => this.save());
    this.resize();
    // las demás zonas se cargan en segundo plano cuando el jugador está cerca
    this.zones.onChange = () => { ui.el.zoneLoad.hidden = !this.zones.loadingNow; };
    this.renderer.compile(this.scene, this.camera);
    this.update(0.016); this.renderer.render(this.scene, this.camera);
    ui.progress(1, '');
    window.__game = this; window.__THREE = THREE;
  }

  buildGround() {
    const tex = Tex.grass(); tex.repeat.set(160, 160);
    const g = new THREE.Mesh(new THREE.PlaneGeometry(800, 800), new THREE.MeshStandardMaterial({ map: tex, color: 0xb9d38e, roughness: 1 }));
    g.rotation.x = -Math.PI / 2; g.position.y = -0.06; g.receiveShadow = true; this.scene.add(g);
    this.ground = g;
  }
  buildHills() { // colinas lejanas con la silueta tropical
    const rng = new Rng(7), parts = [];
    const geo = new THREE.IcosahedronGeometry(1, 2);
    for (let i = 0; i < 34; i++) {
      const a = (i / 34) * Math.PI * 2 + rng.range(-0.08, 0.08), r = rng.range(250, 300), s = rng.range(30, 70);
      const g = geo.clone();
      const pos = g.attributes.position, col = new Float32Array(pos.count * 3), c = new THREE.Color();
      for (let k = 0; k < pos.count; k++) {
        const y = pos.getY(k);
        pos.setY(k, Math.max(-0.2, y) * (0.5 + 0.1 * Math.sin(pos.getX(k) * 3)));
        c.set(0x3d7a3a).lerp(new THREE.Color(0x6aa05a), (y + 1) / 2); col[k * 3] = c.r; col[k * 3 + 1] = c.g; col[k * 3 + 2] = c.b;
      }
      g.setAttribute('color', new THREE.BufferAttribute(col, 3));
      g.scale(s * 1.6, s * 0.8, s * 1.3); g.rotateY(a); g.translate(Math.cos(a) * r, -4, Math.sin(a) * r);
      parts.push(g.toNonIndexed());
    }
    const m = new THREE.Mesh(mergeGeometries(parts.map((p) => { p.deleteAttribute('uv'); return p; })), new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 1 }));
    this.scene.add(m);
  }

  // ------------------------------------------------ ajustes / menú
  applySettings() {
    const s = this.state.data.settings;
    this.dayNight.speed = s.cycle ? CONFIG.time.hoursPerRealMinute / 60 : 0;
    this.camCtl.sens = s.sens; this.audio.setEnabled(s.sound);
    this.ui.el.fps.hidden = !(s.fps || this.params.has('fps'));
    this.setQuality(s.quality);
  }
  setQuality(q) {
    const Q = QUALITY[q] || QUALITY.auto;
    this.quality = q; this.maxPR = Math.min(window.devicePixelRatio || 1, Q.pr);
    this.pr = this.maxPR; this.renderer.setPixelRatio(this.pr);
    this.sun.castShadow = !!Q.shadow; this.renderer.shadowMap.enabled = !!Q.shadow;
    if (this.sun.shadow.mapSize.x !== Q.shadowSize) { this.sun.shadow.mapSize.set(Q.shadowSize, Q.shadowSize); this.sun.shadow.map?.dispose(); this.sun.shadow.map = null; }
    this.shadowSize = Q.shadowSize; this.resize();
  }
  wireMenu() {
    const $ = (id) => document.getElementById(id), s = this.state.data.settings;
    $('opt-quality').value = s.quality; $('opt-sens').value = s.sens; $('opt-sound').checked = s.sound; $('opt-cycle').checked = s.cycle; $('opt-fps').checked = s.fps;
    $('opt-hour').value = this.dayNight.hour;
    $('opt-quality').onchange = (e) => { s.quality = e.target.value; this.applySettings(); };
    $('opt-sens').oninput = (e) => { s.sens = parseFloat(e.target.value); this.camCtl.sens = s.sens; };
    $('opt-sound').onchange = (e) => { s.sound = e.target.checked; this.audio.setEnabled(s.sound); };
    $('opt-cycle').onchange = (e) => { s.cycle = e.target.checked; this.applySettings(); };
    $('opt-fps').onchange = (e) => { s.fps = e.target.checked; this.applySettings(); };
    $('opt-hour').oninput = (e) => { this.dayNight.setHour(parseFloat(e.target.value)); };
    $('menu-close').onclick = () => this.toggleMenu(false);
    $('menu-save').onclick = () => { this.save(); this.ui.toast('Partida guardada ✔'); this.toggleMenu(false); };
    $('menu-casa').onclick = () => { this.player.teleport(26, this.colliders.groundAt(26, -10.5, 5, 0.5), -10.5, Math.PI); this.camCtl.yaw = 0; this.camCtl.snap(this.player.pos); this.toggleMenu(false); };
    $('btn-menu').onclick = () => this.toggleMenu();
    $('btn-fs').onclick = () => this.toggleFullscreen();
  }
  toggleMenu(v) {
    const open = v ?? !this.ui.menuOpen;
    this.ui.setMenu(open);
    if (open) document.getElementById('opt-hour').value = this.dayNight.hour;
  }
  async toggleFullscreen() {
    try {
      if (!document.fullscreenElement) { await document.documentElement.requestFullscreen({ navigationUI: 'hide' }); try { await screen.orientation.lock('landscape'); } catch { /* opcional */ } }
      else await document.exitFullscreen();
    } catch { this.ui.toast('Pantalla completa no disponible en este navegador'); }
  }
  save() {
    const s = this.state.data;
    s.hour = this.dayNight.hour; s.pos = { x: this.player.pos.x, z: this.player.pos.z, y: this.player.pos.y, rot: this.player.facing };
    SaveSystem.save({ data: s });
  }

  resize() {
    const w = window.innerWidth, h = window.innerHeight;
    this.renderer.setPixelRatio(this.pr); this.renderer.setSize(w, h, false);
    this.camera.aspect = w / h;
    // en vertical ampliamos el campo de visión para ver más
    this.camera.fov = w / h < 1 ? 74 : CONFIG.camera.fov; this.camera.updateProjectionMatrix();
  }

  // ------------------------------------------------ bucle
  start() {
    this.running = true; this.audio.start();
    let last = performance.now(), saveT = 0;
    const loop = (now) => {
      if (!this.running) return;
      requestAnimationFrame(loop);
      const dt = Math.min(0.05, (now - last) / 1000); last = now;
      this.update(dt); this.renderer.render(this.scene, this.camera);
      this.trackFps(dt);
      saveT += dt; if (saveT > 20) { saveT = 0; this.save(); }
    };
    requestAnimationFrame(loop);
  }

  update(dt) {
    this.time += dt; timeUniform.value = this.time;
    const inp = this.input, ui = this.ui;
    inp.keyLook(dt);
    const look = inp.consumeLook(), zoom = inp.consumeZoom();
    const blocked = ui.dialogOpen || ui.menuOpen;
    this.player.update(dt, blocked ? ZERO_INPUT : inp, this.camCtl.yaw);
    this.camCtl.update(dt, this.player.pos, blocked ? { dx: 0, dy: 0 } : look, zoom);

    // interacciones
    const p = this.player.pos;
    const it = blocked ? null : this.interactions.nearest(p.x, p.y, p.z);
    ui.setAction(it);
    if (inp.consumeInteract()) { if (ui.dialogOpen) ui.closeDialog(); else if (it) it.action(this); }

    // mundo
    this.zones.update(p.x, p.z);
    this.dayNight.update(dt);
    this.updateSun();
    this.audio.sources = this.zones.loadedContexts.flatMap((c) => c.audioSources);
    this.audio.update(dt, p.x, p.z, this.dayNight.night);
    for (const ctx of this.zones.loadedContexts) {
      for (const a of ctx.animated) a.update(this.time, dt);
      for (const m of ctx.fineMeshes) m.visible = Math.hypot(m.userData.cx - p.x, m.userData.cz - p.z) < CONFIG.world.detailDistance + m.userData.r;
    }
    this.dayNight.sky.position.copy(this.camera.position);
    // HUD (a ~4 Hz)
    this._hud = (this._hud || 0) + dt;
    if (this._hud > 0.25) {
      this._hud = 0; ui.setClock(this.dayNight.hour); ui.setMoney(this.state.data.money);
    }
    ui.setPlace(p.x, p.z); ui.setWaypoint(p.x, p.z, this.camCtl.yaw);
  }

  updateSun() {
    const p = this.player.pos, d = this.dayNight.sunDir;
    // el mapa de sombras sigue al jugador (rejilla para evitar parpadeos)
    const size = 80, texel = size / this.shadowSize;
    const sx = Math.round(p.x / texel) * texel, sz = Math.round(p.z / texel) * texel;
    this.sun.position.set(sx + d.x * 90, d.y * 90, sz + d.z * 90);
    this.sun.target.position.set(sx, 0, sz); this.sun.target.updateMatrixWorld();
  }

  // ------------------------------------------------ rendimiento adaptativo
  trackFps(dt) {
    this.fpsAcc += dt; this.frames++;
    if (this.fpsAcc < 1.5) return;
    this.fps = this.frames / this.fpsAcc; this.frames = 0; this.fpsAcc = 0;
    if (this.quality === 'auto' && !this.zones.loadingNow) {
      if (this.fps < 45 && this.pr > 0.75) { this.pr = Math.max(0.75, this.pr - 0.15); this.renderer.setPixelRatio(this.pr); this.renderer.setSize(innerWidth, innerHeight, false); this.stable = 0; }
      else if (this.fps < 40 && this.pr <= 0.8 && this.shadowSize > 1024) { this.shadowSize = 1024; this.sun.shadow.mapSize.set(1024, 1024); this.sun.shadow.map?.dispose(); this.sun.shadow.map = null; }
      else if (this.fps > 57 && this.pr < this.maxPR) { if (++this.stable > 3) { this.pr = Math.min(this.maxPR, this.pr + 0.1); this.renderer.setPixelRatio(this.pr); this.renderer.setSize(innerWidth, innerHeight, false); this.stable = 0; } }
      else this.stable = 0;
    }
    if (!this.ui.el.fps.hidden) {
      const ri = this.renderer.info.render;
      this.ui.setFps(`${this.fps.toFixed(0)} FPS · res ${this.pr.toFixed(2)}x\n${ri.calls} draws · ${(ri.triangles / 1000).toFixed(0)}k tris\npos ${this.player.pos.x.toFixed(1)}, ${this.player.pos.y.toFixed(2)}, ${this.player.pos.z.toFixed(1)}`);
    }
  }
}
