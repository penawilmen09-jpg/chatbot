// Nombres de lugares (para el cartel de zona y el marcador de destino)
export const PLACES = [
  { name: 'Mi Casa Real', test: (x, z) => x > 5.5 && x < 46.5 && z > -49.5 && z < -6.5 },
  { name: 'Colmado El Buen Vecino', test: (x, z) => x > -19 && x < -7 && z > 6.2 && z < 18 },
  { name: 'Calle Mella', test: (x, z) => x > -31 && x < -19 && Math.abs(z) > 4 },
  { name: 'Cancha del Barrio', test: (x, z) => x > 70 && x < 102 && z > 14 && z < 34 },
  { name: 'Calle Duarte', test: (x, z) => Math.abs(z) < 6.3 },
  { name: 'Barrio Las Palmas', test: () => true },
];
export function placeAt(x, z) { return PLACES.find((p) => p.test(x, z)).name; }

// Marcador: portón de Mi Casa Real
export const WAYPOINT = { name: 'Mi Casa Real', x: 26, z: -6 };
