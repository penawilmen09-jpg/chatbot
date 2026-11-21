// Audio 100% procedural (WebAudio): brisa/ambiente, pájaros, pasos y merengue de colmado
// con volumen según la distancia. Sin archivos, sin descargas.
export class AudioSystem {
  constructor() { this.ctx = null; this.enabled = true; this.sources = []; this.musicGain = null; this.ambGain = null; this.beat = 0; this.nextBeat = 0; this.nightF = 0; }

  start() {
    if (this.ctx) { this.ctx.resume?.(); return; }
    try {
      const AC = window.AudioContext || window.webkitAudioContext; if (!AC) return;
      this.ctx = new AC();
      const c = this.ctx;
      this.master = c.createGain(); this.master.gain.value = this.enabled ? 0.9 : 0; this.master.connect(c.destination);
      // ambiente: ruido filtrado (brisa)
      const len = c.sampleRate * 2, buf = c.createBuffer(1, len, c.sampleRate), d = buf.getChannelData(0);
      let last = 0; for (let i = 0; i < len; i++) { const w = Math.random() * 2 - 1; last = (last + 0.02 * w) / 1.02; d[i] = last * 3.2; }
      this.noiseBuf = buf;
      const src = c.createBufferSource(); src.buffer = buf; src.loop = true;
      const lp = c.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 700;
      this.ambGain = c.createGain(); this.ambGain.gain.value = 0.35;
      src.connect(lp).connect(this.ambGain).connect(this.master); src.start();
      this.musicGain = c.createGain(); this.musicGain.gain.value = 0; this.musicGain.connect(this.master);
      this.nextBeat = c.currentTime + 0.1; this.nextBird = c.currentTime + 3;
    } catch { this.ctx = null; }
  }
  setEnabled(v) { this.enabled = v; if (this.master) this.master.gain.value = v ? 0.9 : 0; }

  step(running) {
    if (!this.ctx || !this.enabled) return;
    const c = this.ctx, t = c.currentTime;
    const s = c.createBufferSource(); s.buffer = this.noiseBuf; s.playbackRate.value = 3 + Math.random();
    const f = c.createBiquadFilter(); f.type = 'bandpass'; f.frequency.value = running ? 900 : 600; f.Q.value = 0.8;
    const g = c.createGain(); g.gain.setValueAtTime(running ? 0.22 : 0.13, t); g.gain.exponentialRampToValueAtTime(0.001, t + 0.09);
    s.connect(f).connect(g).connect(this.master); s.start(t, Math.random() * 1.5, 0.12);
  }

  chirp(t) {
    const c = this.ctx, o = c.createOscillator(), g = c.createGain();
    const f0 = 2400 + Math.random() * 1600;
    o.frequency.setValueAtTime(f0, t); o.frequency.exponentialRampToValueAtTime(f0 * (1.2 + Math.random() * 0.4), t + 0.07); o.frequency.exponentialRampToValueAtTime(f0 * 0.9, t + 0.14);
    g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(0.05, t + 0.02); g.gain.exponentialRampToValueAtTime(0.0001, t + 0.16);
    o.connect(g).connect(this.master); o.start(t); o.stop(t + 0.2);
  }

  // Merengue simple: güira (ruido agudo) + tambora (golpe grave) + bajo
  beatAt(t, i) {
    const c = this.ctx, step = i % 16;
    const hat = c.createBufferSource(); hat.buffer = this.noiseBuf; hat.playbackRate.value = 6;
    const hf = c.createBiquadFilter(); hf.type = 'highpass'; hf.frequency.value = 5200;
    const hg = c.createGain(); hg.gain.setValueAtTime(step % 2 ? 0.06 : 0.12, t); hg.gain.exponentialRampToValueAtTime(0.001, t + 0.05);
    hat.connect(hf).connect(hg).connect(this.musicGain); hat.start(t, 0.2, 0.06);
    if (step % 4 === 0 || step === 6 || step === 14) { // tambora
      const o = c.createOscillator(), g = c.createGain(); o.type = 'sine';
      o.frequency.setValueAtTime(130, t); o.frequency.exponentialRampToValueAtTime(70, t + 0.12);
      g.gain.setValueAtTime(0.5, t); g.gain.exponentialRampToValueAtTime(0.001, t + 0.18);
      o.connect(g).connect(this.musicGain); o.start(t); o.stop(t + 0.2);
    }
    if (step % 8 === 0 || step === 6 || step === 14) { // bajo
      const o = c.createOscillator(), g = c.createGain(); o.type = 'triangle';
      const notes = [98, 98, 123.5, 110]; o.frequency.value = notes[Math.floor(i / 16) % 4];
      g.gain.setValueAtTime(0.28, t); g.gain.exponentialRampToValueAtTime(0.001, t + 0.28);
      o.connect(g).connect(this.musicGain); o.start(t); o.stop(t + 0.3);
    }
    if (step === 3 || step === 7 || step === 11 || step === 15) { // acordes cortos
      for (const f of [392, 494, 587]) { const o = c.createOscillator(), g = c.createGain(); o.type = 'square'; o.frequency.value = f * (Math.floor(i / 16) % 2 ? 1.122 : 1);
        const lpf = c.createBiquadFilter(); lpf.type = 'lowpass'; lpf.frequency.value = 1800;
        g.gain.setValueAtTime(0.03, t); g.gain.exponentialRampToValueAtTime(0.001, t + 0.11); o.connect(lpf).connect(g).connect(this.musicGain); o.start(t); o.stop(t + 0.14); }
    }
  }

  update(dt, px, pz, night) {
    if (!this.ctx || !this.enabled || this.ctx.state !== 'running') return;
    const c = this.ctx, t = c.currentTime;
    // volumen de la música por distancia a la fuente más cercana
    let vol = 0;
    for (const s of this.sources) { const d = Math.hypot(s.x - px, s.z - pz); vol = Math.max(vol, Math.max(0, 1 - d / s.radius) ** 2); }
    this.musicGain.gain.setTargetAtTime(vol * 0.7, t, 0.2);
    // secuenciador (adelantado ~0.2 s)
    if (vol > 0.01) { while (this.nextBeat < t + 0.2) { this.beatAt(this.nextBeat, this.beat++); this.nextBeat += 0.14; } } else this.nextBeat = t + 0.05;
    // pájaros de día
    if (night < 0.5 && t > this.nextBird) { for (let i = 0; i < 1 + Math.floor(Math.random() * 3); i++) this.chirp(t + i * 0.18); this.nextBird = t + 3 + Math.random() * 7; }
    this.ambGain.gain.setTargetAtTime(0.25 + night * 0.15, t, 1);
  }
}
