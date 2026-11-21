export const TIPOS = [
  { etiqueta: "Correo", icono: "✉️", id: "correo" },
  { etiqueta: "Publicación", icono: "📣", id: "publicacion" },
  { etiqueta: "Historia", icono: "📖", id: "historia" },
  { etiqueta: "Guion", icono: "🎬", id: "guion" },
  { etiqueta: "Descripción", icono: "🛍️", id: "descripcion" },
  { etiqueta: "Ideas de negocio", icono: "💡", id: "idea" },
  { etiqueta: "Carreras RD", icono: "🏁", id: "carreras" },
  { etiqueta: "Texto libre", icono: "✍️", id: "libre" },
] as const;

export const TONOS = [
  { etiqueta: "Profesional", id: "profesional" },
  { etiqueta: "Cercano", id: "cercano" },
  { etiqueta: "Entusiasta", id: "entusiasta" },
] as const;

export type TipoId = (typeof TIPOS)[number]["id"];
export type TonoId = (typeof TONOS)[number]["id"];

const INSTRUCCION_TIPO: Record<TipoId, string> = {
  carreras:
    "Escribe contenido sobre el automovilismo y las carreras en República Dominicana (autódromo, arrancones, rally, motos, pilotos, equipos y eventos). Puede ser una crónica de carrera, un anuncio de evento, una publicación para redes o una presentación de equipo o piloto. Usa un ambiente de pasión por la velocidad y toques del español dominicano sin exagerar. No inventes resultados, nombres ni cifras reales: si faltan datos, usa marcadores como [piloto] o [fecha].",
  correo:
    "Redacta un correo electrónico completo con asunto, saludo, cuerpo y despedida.",
  descripcion:
    "Escribe una descripción atractiva y clara (de producto, servicio, lugar o perfil) según lo que pida el usuario.",
  guion:
    "Escribe un guion con escenas, acotaciones breves y diálogos o narración según corresponda (por ejemplo, para un video corto, anuncio o presentación).",
  historia:
    "Escribe una historia original, con inicio, desarrollo y final, y con personajes y ambiente bien definidos.",
  idea: "Propone ideas de negocio originales y realistas, cada una con una explicación breve y un primer paso concreto.",
  libre: "Responde a la solicitud del usuario con el formato que mejor encaje.",
  publicacion:
    "Escribe una publicación lista para redes sociales, con un buen gancho inicial, texto breve y, si encaja, algunos hashtags y emojis.",
};

const INSTRUCCION_TONO: Record<TonoId, string> = {
  cercano: "Usa un tono cercano, cálido y natural.",
  entusiasta: "Usa un tono entusiasta, energético y positivo.",
  profesional: "Usa un tono profesional, claro y respetuoso.",
};

export function construirInstrucciones(tipo: TipoId, tono: TonoId): string {
  return [
    "Eres WILMEN AI, un asistente de escritura creativa.",
    "Responde siempre en español, a menos que el usuario pida expresamente otro idioma.",
    INSTRUCCION_TIPO[tipo],
    INSTRUCCION_TONO[tono],
    "Entrega solo el texto pedido, sin explicaciones previas. No uses formato Markdown: nada de asteriscos, almohadillas ni tablas; usa texto plano con saltos de línea.",
    "Si la solicitud es dañina, ilegal o pide contenido inapropiado, rechaza amablemente en una o dos frases.",
  ].join("\n");
}
