import * as THREE from 'three';

// Humanoide procedural con articulaciones (hombros, codos, caderas, rodillas) y
// animación por código: idle / caminar / correr mezclados por velocidad.
// Geometrías compartidas + materiales compartidos => muy barato.

const geoCache = {};
const G = {
  get capsule() { return (geoCache.cap ||= new THREE.CapsuleGeometry(1, 1, 4, 8)); },
  get sphere() { return (geoCache.sph ||= new THREE.SphereGeometry(1, 12, 10)); },
  get box() { return (geoCache.box ||= new THREE.BoxGeometry(1, 1, 1)); },
  get cyl() { return (geoCache.cyl ||= new THREE.CylinderGeometry(1, 1, 1, 12)); },
};
const matCache = new Map();
function mat(color, rough = 0.85) {
  const k = color + ':' + rough;
  if (!matCache.has(k)) matCache.set(k, new THREE.MeshStandardMaterial({ color, roughness: rough }));
  return matCache.get(k);
}

function part(geo, color, sx, sy, sz, x = 0, y = 0, z = 0, rough) {
  const m = new THREE.Mesh(geo, mat(color, rough));
  m.scale.set(sx, sy, sz); m.position.set(x, y, z);
  m.castShadow = true; m.receiveShadow = false;
  return m;
}

// limb: cápsula colgando desde el pivote (origen) hacia abajo
function limb(len, rad, color) {
  const k = `l${len}_${rad}`;
  const g = (geoCache[k] ||= new THREE.CapsuleGeometry(rad, Math.max(0.01, len - 2 * rad), 4, 8));
  const m = new THREE.Mesh(g, mat(color));
  m.position.y = -len / 2; m.castShadow = true;
  return m;
}

export function createHuman(o = {}) {
  const skin = o.skin ?? 0x8a5a3c, shirt = o.shirt ?? 0xf4f4f0, pants = o.pants ?? 0x2f4a7a, shoe = o.shoe ?? 0xf0f0f0, hair = o.hair ?? 0x15110e, cap = o.cap ?? 0xc0262d;
  const root = new THREE.Group();
  const body = new THREE.Group(); root.add(body);               // se inclina al correr
  const hips = new THREE.Group(); hips.position.y = 0.93; body.add(hips);

  // pelvis + torso
  hips.add(part(G.box, pants, 0.34, 0.2, 0.2, 0, 0.0, 0));
  const spine = new THREE.Group(); spine.position.y = 0.08; hips.add(spine);
  const torso = part(G.capsule, shirt, 0.19, 0.2, 0.12, 0, 0.27, 0); spine.add(torso);
  spine.add(part(G.cyl, skin, 0.05, 0.1, 0.05, 0, 0.62, 0));       // cuello
  // cabeza
  const head = new THREE.Group(); head.position.y = 0.7; spine.add(head);
  head.add(part(G.sphere, skin, 0.105, 0.125, 0.115, 0, 0.1, 0));
  head.add(part(G.sphere, hair, 0.11, 0.1, 0.12, 0, 0.15, -0.01));         // pelo
  head.add(part(G.sphere, 0x111111, 0.014, 0.014, 0.01, -0.04, 0.115, 0.108)); // ojos
  head.add(part(G.sphere, 0x111111, 0.014, 0.014, 0.01, 0.04, 0.115, 0.108));
  head.add(part(G.sphere, skin, 0.025, 0.03, 0.03, 0, 0.085, 0.118));      // nariz
  if (o.cap !== false) {
    head.add(part(G.sphere, cap, 0.115, 0.08, 0.125, 0, 0.19, 0));          // gorra
    head.add(part(G.box, cap, 0.17, 0.014, 0.12, 0, 0.16, 0.14));           // visera
  }
  // brazos
  const arm = (sx) => {
    const sh = new THREE.Group(); sh.position.set(sx * 0.235, 0.5, 0); spine.add(sh);
    sh.add(part(G.sphere, shirt, 0.065, 0.065, 0.065));
    sh.add(limb(0.3, 0.05, shirt));
    const el = new THREE.Group(); el.position.y = -0.3; sh.add(el);
    el.add(limb(0.28, 0.042, skin));
    el.add(part(G.sphere, skin, 0.045, 0.05, 0.045, 0, -0.3, 0));
    return { sh, el };
  };
  const armL = arm(-1), armR = arm(1);
  // piernas
  const leg = (sx) => {
    const th = new THREE.Group(); th.position.set(sx * 0.095, -0.02, 0); hips.add(th);
    th.add(limb(0.44, 0.075, pants));
    const kn = new THREE.Group(); kn.position.y = -0.44; th.add(kn);
    kn.add(limb(0.42, 0.06, pants));
    const foot = part(G.box, shoe, 0.095, 0.06, 0.19, 0, -0.45, 0.05); kn.add(foot);
    kn.add(part(G.box, 0x222222, 0.1, 0.02, 0.2, 0, -0.485, 0.05));
    return { th, kn };
  };
  const legL = leg(-1), legR = leg(1);

  root.traverse((c) => { if (c.isMesh) c.castShadow = true; });
  root.scale.setScalar(0.93);

  // ---------- animación ----------
  let phase = 0, breathe = 0;
  const lerp = THREE.MathUtils.lerp;
  const st = { walk: 0, run: 0 };
  function animate(dt, speed, runBlend = 0) {
    // speed: m/s reales; runBlend 0..1
    const moving = THREE.MathUtils.clamp(speed / 1.6, 0, 1);
    const rb = THREE.MathUtils.clamp(runBlend, 0, 1) * moving;
    st.walk = lerp(st.walk, moving, 1 - Math.exp(-12 * dt));
    st.run = lerp(st.run, rb, 1 - Math.exp(-10 * dt));
    const freq = lerp(lerp(5.5, 8.0, st.run), 3.5, 1 - st.walk) ; // rad/s relativos a velocidad
    phase += dt * (speed > 0.05 ? (4.2 + speed * 1.35) : 0);
    breathe += dt * 1.8;
    const s = Math.sin(phase), c = Math.cos(phase);
    const w = st.walk, r = st.run;
    const swing = lerp(0.55, 1.05, r) * w;
    const kneeAmp = lerp(0.55, 1.45, r) * w;
    // piernas
    legL.th.rotation.x = s * swing;
    legR.th.rotation.x = -s * swing;
    legL.kn.rotation.x = Math.max(0, -Math.sin(phase + 0.9)) * kneeAmp + 0.05 * w;
    legR.kn.rotation.x = Math.max(0, Math.sin(phase + 0.9)) * kneeAmp + 0.05 * w;
    // brazos (contrafase)
    const as = lerp(0.5, 1.0, r) * w;
    armL.sh.rotation.x = -s * as; armR.sh.rotation.x = s * as;
    armL.el.rotation.x = -(0.25 + 0.9 * r) * w - 0.05; armR.el.rotation.x = -(0.25 + 0.9 * r) * w - 0.05;
    armL.sh.rotation.z = 0.08; armR.sh.rotation.z = -0.08;
    // cuerpo: inclinación al correr, rebote, balanceo de cadera
    body.rotation.x = 0.28 * r;
    hips.position.y = 0.93 - 0.02 * w + Math.abs(c) * 0.035 * w * (1 + r * 0.8) + Math.sin(breathe) * 0.004 * (1 - w);
    hips.rotation.y = s * 0.12 * w * (1 + r);
    spine.rotation.y = -s * 0.1 * w * (1 + r);
    spine.rotation.z = c * 0.03 * w;
    head.rotation.x = -0.18 * r + Math.sin(breathe * 0.7) * 0.01;
    torso.scale.x = 0.19 + Math.sin(breathe) * 0.003;
  }
  return { root, animate, parts: { head, spine, hips } };
}
