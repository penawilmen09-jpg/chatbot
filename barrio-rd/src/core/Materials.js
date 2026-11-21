import * as THREE from 'three';
import { Tex } from './Textures.js';

// Metros que cubre una repetición de cada textura (UV "triplanar" horneadas en Batch)
export const TEX_SCALE = { stucco: 2.6, brick: 1.3, asphalt: 5, concrete: 3.2, zinc: 1.4, tile: 1.6, grass: 5, dirt: 4, plain: 1, metal: 1, glass: 1, lamp: 1, tire: 1 };

export function createMaterials() {
  const std = (o) => new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.9, metalness: 0, ...o });
  const m = {
    stucco: std({ map: Tex.stucco() }),
    brick: std({ map: Tex.brick(), roughness: 0.85 }),
    asphalt: std({ map: Tex.asphalt(), roughness: 0.95 }),
    concrete: std({ map: Tex.concrete() }),
    zinc: std({ map: Tex.zinc(), roughness: 0.45, metalness: 0.5, side: THREE.DoubleSide }),
    tile: std({ map: Tex.tile(), roughness: 0.6 }),
    grass: std({ map: Tex.grass(), roughness: 1 }),
    dirt: std({ map: Tex.dirt(), roughness: 1 }),
    plain: std({}),
    metal: std({ roughness: 0.4, metalness: 0.7 }),
    tire: std({ roughness: 0.95 }),
    lamp: std({ emissive: new THREE.Color(0xffe2a0), emissiveIntensity: 0 }),
    glass: std({
      transparent: true, opacity: 0.5, roughness: 0.08, metalness: 0.2,
      emissive: new THREE.Color(0xffd890), emissiveIntensity: 0, depthWrite: false,
    }),
  };
  return m;
}
