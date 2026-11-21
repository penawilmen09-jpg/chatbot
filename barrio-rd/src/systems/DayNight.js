import * as THREE from 'three';

// Ciclo de día y noche: sol/luna, color del cielo, niebla, luz ambiente y farolas.
// keys: hora -> parámetros (se interpolan en el tiempo).
const K = [
  { h: 0,  top: 0x0a1230, hor: 0x1c2c58, sun: 0x9fb4ee, si: 1.1, hemiS: 0x5566a8, hemiG: 0x232a40, hi: 1.7, exp: 1.2, night: 1 },
  { h: 5,  top: 0x101a40, hor: 0x3a4272, sun: 0x9fa8d8, si: 1.0,  hemiS: 0x5566a8, hemiG: 0x232a40, hi: 1.6, exp: 1.15, night: 0.9 },
  { h: 6.2,top: 0x4a6fa8, hor: 0xf3a46b, sun: 0xffb27a, si: 1.1,  hemiS: 0x8aa0cc, hemiG: 0x4a4038, hi: 0.7, exp: 0.95, night: 0.4 },
  { h: 8,  top: 0x2f7fd0, hor: 0xaed8f0, sun: 0xfff1d6, si: 2.6,  hemiS: 0xa8cdf0, hemiG: 0x6a7a50, hi: 0.95, exp: 1.0, night: 0 },
  { h: 12, top: 0x1f78e0, hor: 0xbfe3f8, sun: 0xfffaf0, si: 3.2,  hemiS: 0xb5d8f5, hemiG: 0x7a8a58, hi: 1.05, exp: 1.0, night: 0 },
  { h: 16.5,top: 0x2a78d0, hor: 0xc9e2f0, sun: 0xffeccc, si: 2.9, hemiS: 0xa8cdee, hemiG: 0x7a7a50, hi: 0.95, exp: 1.0, night: 0 },
  { h: 18.3,top: 0x3a5a9a, hor: 0xf29a58, sun: 0xff9a55, si: 1.3, hemiS: 0x8a98c0, hemiG: 0x50402e, hi: 0.7, exp: 0.95, night: 0.35 },
  { h: 19.6,top: 0x1c2858, hor: 0x6a4c7e, sun: 0xb09ad0, si: 1.0, hemiS: 0x5060a0, hemiG: 0x2a2638, hi: 1.5, exp: 1.15, night: 0.85 },
  { h: 21, top: 0x0a1230, hor: 0x1c2c58, sun: 0x9fb4ee, si: 1.1, hemiS: 0x5566a8, hemiG: 0x232a40, hi: 1.7, exp: 1.2, night: 1 },
  { h: 24, top: 0x0a1230, hor: 0x1c2c58, sun: 0x9fb4ee, si: 1.1, hemiS: 0x5566a8, hemiG: 0x232a40, hi: 1.7, exp: 1.2, night: 1 },
];
const A = new THREE.Color(), B = new THREE.Color();
const mix = (k0, k1, t, key, out) => out.copy(A.set(k0[key])).lerp(B.set(k1[key]), t);

export class DayNight {
  constructor({ scene, renderer, sunLight, hemi, mats }) {
    Object.assign(this, { scene, renderer, sun: sunLight, hemi, mats });
    this.hour = 15; this.speed = 0; // horas por segundo
    this.sunDir = new THREE.Vector3(0.5, 0.8, 0.3);
    this.night = 0;
    this.top = new THREE.Color(); this.hor = new THREE.Color();
    // cúpula del cielo
    const geo = new THREE.SphereGeometry(400, 24, 16);
    this.skyMat = new THREE.ShaderMaterial({
      side: THREE.BackSide, depthWrite: false, fog: false,
      uniforms: { top: { value: this.top }, hor: { value: this.hor }, sunDir: { value: this.sunDir }, sunCol: { value: new THREE.Color() }, night: { value: 0 } },
      vertexShader: 'varying vec3 vP; void main(){ vP = normalize(position); gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }',
      fragmentShader: `
        varying vec3 vP; uniform vec3 top, hor, sunCol, sunDir; uniform float night;
        float h(vec3 p){ return fract(sin(dot(p, vec3(12.9898,78.233,37.719))) * 43758.5453); }
        void main(){
          vec3 d = normalize(vP);
          float t = pow(clamp(d.y, 0.0, 1.0), 0.55);
          vec3 c = mix(hor, top, t);
          float sd = max(dot(d, normalize(sunDir)), 0.0);
          c += sunCol * (pow(sd, 900.0) * 3.0 + pow(sd, 18.0) * 0.28);
          if (night > 0.01 && d.y > 0.0) { vec3 q = floor(d * 260.0); float s = step(0.9975, h(q)); c += vec3(s) * night * smoothstep(0.0, 0.3, d.y); }
          gl_FragColor = vec4(c, 1.0);
          #include <colorspace_fragment>
        }`,
    });
    this.sky = new THREE.Mesh(geo, this.skyMat);
    this.sky.renderOrder = -10; this.sky.frustumCulled = false;
    scene.add(this.sky);
    scene.fog = new THREE.Fog(0xbfe3f8, 70, 230);
    this.sunColor = new THREE.Color(); this.tmp = new THREE.Color();
  }

  setHour(h) { this.hour = ((h % 24) + 24) % 24; this.apply(); }
  update(dt) { if (this.speed) { this.hour = (this.hour + this.speed * dt) % 24; } this.apply(); }

  apply() {
    const h = this.hour;
    let i = 0; while (i < K.length - 2 && K[i + 1].h <= h) i++;
    const k0 = K[i], k1 = K[i + 1], t = THREE.MathUtils.clamp((h - k0.h) / (k1.h - k0.h), 0, 1);
    const L = THREE.MathUtils.lerp;
    mix(k0, k1, t, 'top', this.top); mix(k0, k1, t, 'hor', this.hor); mix(k0, k1, t, 'sun', this.sunColor);
    this.sun.color.copy(this.sunColor);
    this.sun.intensity = L(k0.si, k1.si, t);
    mix(k0, k1, t, 'hemiS', this.hemi.color); mix(k0, k1, t, 'hemiG', this.hemi.groundColor);
    this.hemi.intensity = L(k0.hi, k1.hi, t);
    this.renderer.toneMappingExposure = L(k0.exp, k1.exp, t);
    this.night = L(k0.night, k1.night, t);
    this.skyMat.uniforms.sunCol.value.copy(this.sunColor);
    this.skyMat.uniforms.night.value = this.night;
    this.scene.fog.color.copy(this.hor).lerp(this.tmp.set(0x888a90), 0.0);
    // dirección: sol de día (6–18h), luna de noche
    const day = h >= 6 && h <= 18;
    const ang = day ? ((h - 6) / 12) * Math.PI : (((h + 6) % 24) / 12) * Math.PI;
    const el = Math.max(0.12, Math.sin(ang));
    this.sunDir.set(Math.cos(ang) * 0.85, el, 0.45).normalize();
    // luces nocturnas: farolas y ventanas
    this.mats.lamp.emissiveIntensity = this.night * 3.2;
    this.mats.glass.emissiveIntensity = this.night * 0.55;
  }
}
