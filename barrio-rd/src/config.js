// Parámetros globales de BARRIO RD. Todo lo "ajustable" vive aquí.
export const CONFIG = {
  world: { halfSize: 118, chunk: 40, detailDistance: 85 },
  player: {
    walkSpeed: 2.0,
    runSpeed: 5.4,
    radius: 0.34,
    height: 1.75,
    stepUp: 0.46,
    gravity: 24,
    turnSpeed: 12,
    spawn: { x: -13, z: 9.5, rot: Math.PI },
  },
  camera: { fov: 62, distance: 5.4, minDistance: 1.3, maxDistance: 9, height: 1.55, near: 0.15, far: 260 },
  time: { startHour: 15.2, hoursPerRealMinute: 0.8 },
  startMoney: 500,
};

// Paleta dominicana / de la casa real (tomada de las fotografías)
export const COLORS = {
  casaVerde: 0x9bd8a4,
  casaVerdeMedio: 0x6fc18a,
  turquesa: 0x2fa6c4,
  turquesaClaro: 0x6cd0d4,
  ladrillo: 0xb5543c,
  blanco: 0xf3f0e6,
  amarillo: 0xf2c94c,
};
