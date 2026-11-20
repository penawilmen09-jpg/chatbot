export const TIPOS = [
  { etiqueta: "Correo", icono: "✉️", id: "correo" },
  { etiqueta: "Redes sociales", icono: "📣", id: "redes" },
  { etiqueta: "Descripción de producto", icono: "🛍️", id: "producto" },
  { etiqueta: "Ideas de negocio", icono: "💡", id: "idea" },
  { etiqueta: "Texto libre", icono: "✍️", id: "libre" },
] as const;

export const TONOS = [
  { etiqueta: "Profesional", id: "profesional" },
  { etiqueta: "Cercano", id: "cercano" },
  { etiqueta: "Entusiasta", id: "entusiasta" },
] as const;

export type TipoId = (typeof TIPOS)[number]["id"];
export type TonoId = (typeof TONOS)[number]["id"];

const SALUDOS: Record<TonoId, string> = {
  cercano: "¡Hola!",
  entusiasta: "¡Hola, qué gusto saludarte!",
  profesional: "Estimado/a:",
};

const CIERRES: Record<TonoId, string> = {
  cercano: "Cualquier cosa me avisas.\n\nUn abrazo,",
  entusiasta: "¡Estoy muy emocionado por lo que viene!\n\n¡Un abrazo grande!",
  profesional: "Quedo atento a su respuesta.\n\nCordialmente,",
};

const limpiar = (t: string) => t.trim().replace(/\s+/g, " ");

const resumir = (t: string, max = 140) => {
  const s = limpiar(t);
  return s.length > max ? `${s.slice(0, max).trimEnd()}…` : s;
};

export function generarDemo(
  entrada: string,
  tipo: TipoId,
  tono: TonoId
): string {
  const tema = resumir(entrada);
  const aviso =
    "\n\n———\nRespuesta de demostración: aún no hay una IA real conectada.";

  switch (tipo) {
    case "correo":
      return `Asunto: ${resumir(entrada, 60)}\n\n${SALUDOS[tono]}\n\nMe comunico con relación a lo siguiente: ${tema}.\n\nMe gustaría coordinar los próximos pasos y resolver cualquier duda que pueda surgir. Si le resulta conveniente, podemos agendar una breve llamada esta semana.\n\n${CIERRES[tono]}\n[Tu nombre]${aviso}`;
    case "redes":
      return `${tono === "entusiasta" ? "🚀 ¡Gran novedad! " : tono === "cercano" ? "👋 Te cuento algo: " : ""}${tema}\n\n✅ Fácil de entender\n✅ Pensado para ti\n✅ Listo para empezar hoy\n\n¿Qué opinas? Cuéntanos en los comentarios 👇\n\n#WilmenAI #Innovación #Emprendimiento${aviso}`;
    case "producto":
      return `${resumir(entrada, 50)}\n\n${tono === "entusiasta" ? "¡Descubre" : "Presentamos"} una solución diseñada para destacar: ${tema}.\n\nBeneficios principales\n- Calidad que se nota desde el primer uso.\n- Diseño pensado para el día a día.\n- Excelente relación entre precio y valor.\n\n¿Por qué elegirlo?\nPorque combina practicidad y confianza, y ofrece justo lo que necesitas.${aviso}`;
    case "idea":
      return `3 ideas de negocio a partir de: “${tema}”\n\n1. Servicio por suscripción — Ofrece una versión mensual con entregas o acceso recurrente y una comunidad cerrada.\n2. Plataforma de asesoría en línea — Conecta a especialistas con clientes mediante sesiones de pago por hora.\n3. Producto digital — Crea una guía, plantilla o curso que resuelva el problema más frecuente de tu público.\n\nSiguiente paso sugerido: valida la idea con 5 personas reales antes de invertir.${aviso}`;
    default:
      return `Borrador\n\n${tema}\n\nA partir de lo que pides, aquí tienes una propuesta estructurada:\n\n1. Introducción: presenta el contexto con claridad.\n2. Desarrollo: explica las ideas clave con ejemplos concretos.\n3. Cierre: resume y propone una acción final.\n\nPuedes ajustar el tono (${tono}) y volver a generar para obtener otra versión.${aviso}`;
  }
}
