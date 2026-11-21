import * as THREE from 'three';
import { Builder } from '../core/Builder.js';
import { Tex } from '../core/Textures.js';
import { createHuman } from '../character/HumanModel.js';
import { plasticChair, dominoTable, crateStack, speaker } from '../world/Props.js';

// COLMADO dominicano: tienda de esquina de cemento, amarilla con franjas rojas,
// mostrador con reja, estantes con productos, nevera, mesa de dominó y bocinas.
// Local: x∈[-4.5,4.5], z∈[-7,0], frente a +z. Terraza z∈[0,2.6].

export function buildColmado(world, group, frame) {
  const b = new Builder(world, frame, group);
  const hx = 4.5, d = 7, H = 3.1, FH = 0.15, wall = 0xf5d142, red = 0xc1121f, blue = 0x1d4e9e;
  const P = (lx, lz) => ({ x: frame.wx(lx, lz), z: frame.wz(lx, lz) });

  b.block('concrete', -hx - 0.08, 0, -d - 0.08, hx + 0.08, FH, 0.1, 0xb8b4aa);
  // terraza de cemento + césped alrededor
  b.block('concrete', -hx - 0.5, 0, 0.1, hx + 0.5, 0.06, 2.6, 0xd2cfc5);
  b.floorBox(-hx - 0.5, 0.1, hx + 0.5, 2.6, 0.06);
  // paredes
  b.wall('stucco', -hx, -0.15, hx, -0.15, FH, FH + H, 0.3, wall, [
    { t0: 0.35, t1: 2.15, y0: FH, y1: FH + 2.3, kind: 'door', open: true, trim: red },
    { t0: 3.0, t1: 8.1, y0: FH + 1.0, y1: FH + 2.25, kind: 'gap' },
  ]);
  b.wall('stucco', -hx + 0.15, 0, -hx + 0.15, -d, FH, FH + H, 0.3, wall);
  b.wall('stucco', hx - 0.15, 0, hx - 0.15, -d, FH, FH + H, 0.3, wall, [{ t0: 2.4, t1: 3.8, y0: FH + 1.2, y1: FH + 2.2, kind: 'window', trim: red, reja: 0x25282d }]);
  b.wall('stucco', -hx, -d + 0.15, hx, -d + 0.15, FH, FH + H, 0.3, wall);
  // reja del mostrador (barras) + colisión del hueco
  b.fine(() => { for (let i = 0; i <= 28; i++) b.box('metal', -1.5 + i * 0.18 * 1 + 0.0, FH + 1.62, 0.04, 0.025, 1.25, 0.025, 0x25282d); });
  b.box('metal', 0.9, FH + 2.22, 0.04, 5.1, 0.05, 0.05, 0x25282d); b.box('metal', 0.9, FH + 1.0, 0.04, 5.1, 0.05, 0.05, 0x25282d);
  b.colBox(0.9, -0.15, 2.55, 0.15, FH + 1.0, FH + 2.25);
  // franjas de pintura (rojo y azul) + zócalo
  b.block('plain', -hx - 0.02, FH, -0.2, hx + 0.02, FH + 0.6, 0.02, blue);
  b.block('plain', -hx - 0.02, FH + 2.35, -0.2, hx + 0.02, FH + 2.75, 0.04, red);
  // cornisa y techo plano con parapeto
  b.block('concrete', -hx - 0.25, FH + H, -d - 0.25, hx + 0.25, FH + H + 0.2, 0.3, 0xbdbab1);
  b.block('stucco', -hx - 0.25, FH + H + 0.2, 0.1, hx + 0.25, FH + H + 0.95, 0.3, wall);
  for (const [x0, z0, x1, z1] of [[-hx - 0.25, -d - 0.25, hx + 0.25, -d - 0.05], [-hx - 0.25, -d - 0.25, -hx - 0.05, 0.1], [hx + 0.05, -d - 0.25, hx + 0.25, 0.1]]) b.block('stucco', x0, FH + H + 0.2, z0, x1, FH + H + 0.75, z1, wall);
  b.block('plain', -hx - 0.27, FH + H + 0.95, 0.08, hx + 0.27, FH + H + 1.02, 0.32, red);
  // toldo de zinc sobre la terraza (soportado por postes)
  b.box('zinc', 0, FH + 2.95, 1.45, hx * 2 + 1.0, 0.05, 2.5, 0xd7d9db, 0, 0.12);
  for (const x of [-hx - 0.3, -1.5, 1.5, hx + 0.3]) b.block('plain', x - 0.06, 0.06, 2.45, x + 0.06, 2.9, 2.57, blue, true);
  // piso interior + mostrador
  b.block('tile', -hx + 0.3, FH, -d + 0.3, hx - 0.3, FH + 0.05, -0.3, 0xffffff);
  b.floorBox(-hx + 0.3, -d + 0.3, hx - 0.3, -0.3, FH + 0.05);
  b.block('plain', -1.6, FH, -1.6, 4.0, FH + 1.0, -0.9, 0xcaa56a, true);
  b.block('plain', -1.6, FH + 1.0, -1.65, 4.05, FH + 1.06, -0.85, 0x6d4a2f);
  b.block('plain', 3.3, FH, -4.5, 4.0, FH + 1.0, -1.6, 0xcaa56a, true); // esquina del mostrador
  // estantes con productos coloridos
  const cols = [0xd62828, 0xf2c94c, 0x2a9d8f, 0x1d4e9e, 0xf4a259, 0xffffff, 0x6a994e, 0x8e44ad];
  const shelf = (x0, z0, x1, z1) => {
    const alongX = Math.abs(x1 - x0) > Math.abs(z1 - z0);
    b.block('plain', Math.min(x0, x1), FH, Math.min(z0, z1), Math.max(x0, x1) + (alongX ? 0 : 0.05), FH + 2.3, Math.max(z0, z1) + (alongX ? 0.05 : 0), 0x7a5a3c, true);
    const len = alongX ? Math.abs(x1 - x0) : Math.abs(z1 - z0);
    const n = Math.floor(len / 0.3);
    b.fine(() => {
      for (let lv = 0; lv < 5; lv++) for (let i = 0; i < n; i++) {
        const t = 0.15 + i * 0.3, c = cols[(i * 3 + lv * 5) % cols.length];
        const h = 0.18 + ((i * 7 + lv) % 3) * 0.04;
        if (alongX) b.box('plain', Math.min(x0, x1) + t, FH + 0.35 + lv * 0.42, z0 + 0.14, 0.2, h, 0.16, c);
        else b.box('plain', x0 + 0.14, FH + 0.35 + lv * 0.42, Math.min(z0, z1) + t, 0.16, h, 0.2, c);
      }
    });
  };
  shelf(-3.7, -6.5, 3.7, -6.75); shelf(-4.0, -6.2, -4.25, -1.3 + 0.0);
  // neveras
  for (let i = 0; i < 2; i++) {
    const x = 1.0 + i * 1.4;
    b.block('plain', x - 0.6, FH, -6.2, x + 0.6, FH + 1.95, -5.2, 0xf4f4f4, true);
    b.block('glass', x - 0.5, FH + 0.15, -5.17, x + 0.5, FH + 1.85, -5.14, 0xaad4e8);
    b.fine(() => { for (let j = 0; j < 12; j++) b.box('plain', x - 0.4 + (j % 4) * 0.27, FH + 0.4 + Math.floor(j / 4) * 0.55, -5.4, 0.16, 0.3, 0.16, j % 2 ? 0x2a9d4a : 0xd62828); });
  }
  // cartel grande (canvas) sobre la fachada
  const sign = new THREE.Mesh(new THREE.PlaneGeometry(6.8, 1.35), new THREE.MeshStandardMaterial({ map: Tex.sign('COLMADO EL BUEN VECINO', { bg: '#c1121f', sub: 'HIELO · CERVEZA FRÍA · RECARGAS · PICA POLLO', w: 1024, h: 200, font: 'bold 74px Arial Black, Impact, sans-serif' }), roughness: 0.7 }));
  sign.position.set(frame.wx(0, 0.36), FH + H + 0.55 + 0.0, frame.wz(0, 0.36)); sign.rotation.y = frame.rot; sign.position.y = FH + 2.65 + 0.2;
  sign.position.y = FH + H + 0.55; sign.castShadow = false; group.add(sign);
  const sign2 = new THREE.Mesh(new THREE.PlaneGeometry(2.6, 1.0), new THREE.MeshStandardMaterial({ map: Tex.sign('FRÍA', { bg: '#1d4e9e', sub: 'CERVEZA 🍺 YELO', w: 512, h: 200, font: 'bold 90px Arial Black, Impact, sans-serif' }), roughness: 0.7 }));
  sign2.position.set(frame.wx(hx + 0.04, -3.3), FH + 2.6, frame.wz(hx + 0.04, -3.3)); sign2.rotation.y = frame.rot + Math.PI / 2; group.add(sign2);
  // exterior: bocinas, dominó, cajas, sillas
  speaker(b, -hx - 0.1, 1.5, 0.3); speaker(b, -hx + 1.4, 2.2, -0.2);
  dominoTable(b, -2.0, 1.7); plasticChair(b, 2.2, 2.0, 0.3, 0xf4f4f4); plasticChair(b, 3.0, 1.7, -0.2, 0xf4f4f4);
  crateStack(b, hx - 0.3, 1.6, 4); crateStack(b, hx - 0.9, 1.7, 3, 0x2a9d4a);
  b.block('plain', hx + 0.0, FH, 1.0, hx + 0.9, FH + 1.0, 1.9, 0xf4f4f4, true); // nevera de hielo
  // colmadero (NPC) detrás del mostrador
  const npc = createHuman({ shirt: 0x2060c0, pants: 0x3a3a3a, skin: 0x6e4430, cap: false, hair: 0x111111 });
  npc.root.position.set(frame.wx(1.2, -2.5), FH + 0.05, frame.wz(1.2, -2.5)); npc.root.rotation.y = frame.rot;
  group.add(npc.root);
  world.animated.push({ update: (t, dt) => npc.animate(dt, 0, 0) });
  // luz interior
  const l = new THREE.PointLight(0xfff0d0, 16, 10, 1.6); const lp = P(0, -3); l.position.set(lp.x, 2.7, lp.z); group.add(l);
  // música (para el audio posicional)
  world.audioSources.push({ x: P(-hx, 1.8).x, z: P(-hx, 1.8).z, type: 'merengue', radius: 38 });
  // interacciones
  world.interactions.add({ ...P(1.2, -0.2 + 1.1), y: 0, radius: 2.6, label: 'Hablar con el colmadero', icon: '🛒', action: (g) => g.ui.dialog('Colmadero', '¡Qué lo qué, mi hermano! Aquí hay de todo: hielo, pica pollo, jugo y recarga. La tienda abre pronto — por ahora, ¡pasa a saludar!') });
  world.interactions.add({ ...P(-2.0, 1.7 + 0.9), y: 0, radius: 2.4, label: 'Mesa de dominó', icon: '🁢', action: (g) => g.ui.toast('Dominó: ¡capicúa! Los muchachos te invitan a jugar (próximamente).') });
  return { npc };
}
