import { type NextRequest, NextResponse } from "next/server";
import { construirInstrucciones, TIPOS, TONOS } from "@/lib/generator-config";

// La clave solo se lee aquí, en el servidor. Nunca se envía al navegador.
const API_BASE = "https://generativelanguage.googleapis.com/v1beta/models";
// gemini-2.5-flash figura como modelo estable en la documentación oficial, pero
// Google restringe su acceso en cuentas nuevas. Si responde 404, se busca
// automáticamente otro modelo Flash compatible con generateContent.
const MODELO_PREDETERMINADO = "gemini-2.5-flash";

function error(mensaje: string, status: number) {
  return NextResponse.json({ error: mensaje }, { status });
}

function mensajeParaEstado(status: number): string {
  switch (status) {
    case 400:
    case 401:
    case 403:
      return "La clave de Gemini no es válida o no tiene permiso. Revisa el secreto GEMINI_API_KEY.";
    case 404:
      return "No se encontró un modelo de Gemini disponible. Elige uno en aistudio.google.com y guárdalo en la variable GEMINI_MODEL.";
    case 429:
      return "Se alcanzó el límite gratuito de Gemini. Espera un momento e inténtalo de nuevo.";
    default:
      return "Gemini no pudo responder en este momento. Inténtalo de nuevo en unos segundos.";
  }
}

function generar(modelo: string, payload: string, apiKey: string) {
  return fetch(`${API_BASE}/${encodeURIComponent(modelo)}:generateContent`, {
    body: payload,
    headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
    method: "POST",
    signal: AbortSignal.timeout(45_000),
  });
}

async function buscarModeloFlash(apiKey: string, excluir: string) {
  const res = await fetch(`${API_BASE}?pageSize=200`, {
    headers: { "x-goog-api-key": apiKey },
    signal: AbortSignal.timeout(15_000),
  });
  if (!res.ok) {
    return null;
  }
  const data = (await res.json().catch(() => null)) as {
    models?: { name?: string; supportedGenerationMethods?: string[] }[];
  } | null;
  const candidatos = (data?.models ?? [])
    .filter((m) => m.supportedGenerationMethods?.includes("generateContent"))
    .map((m) => m.name?.replace(/^models\//, "") ?? "")
    .filter((n) => /^gemini-[\d.]+-flash$/.test(n) && n !== excluir)
    .sort()
    .reverse();
  return candidatos[0] ?? null;
}

export async function POST(request: NextRequest) {
  let body: { prompt?: unknown; tipo?: unknown; tono?: unknown };
  try {
    body = await request.json();
  } catch {
    return error("Solicitud inválida.", 400);
  }

  const prompt = typeof body.prompt === "string" ? body.prompt.trim() : "";
  if (!prompt) {
    return error("Escribe lo que necesitas antes de generar.", 400);
  }
  if (prompt.length > 2000) {
    return error("El texto es demasiado largo (máximo 2000 caracteres).", 400);
  }

  const apiKey = process.env.GEMINI_API_KEY?.trim();
  if (!apiKey) {
    return error(
      "Falta configurar la clave de Gemini. Agrega el secreto GEMINI_API_KEY (consulta el README) y reinicia la aplicación.",
      503
    );
  }

  const tipo = TIPOS.find((t) => t.id === body.tipo)?.id ?? "libre";
  const tono = TONOS.find((t) => t.id === body.tono)?.id ?? "profesional";
  const modelo = process.env.GEMINI_MODEL?.trim() || MODELO_PREDETERMINADO;

  const payload = JSON.stringify({
    contents: [{ parts: [{ text: prompt }], role: "user" }],
    generationConfig: { maxOutputTokens: 4096, temperature: 0.9 },
    systemInstruction: {
      parts: [{ text: construirInstrucciones(tipo, tono) }],
    },
  });

  let respuesta: Response;
  try {
    respuesta = await generar(modelo, payload, apiKey);
    if (respuesta.status === 404 && !process.env.GEMINI_MODEL?.trim()) {
      const alternativo = await buscarModeloFlash(apiKey, modelo);
      if (alternativo) {
        respuesta = await generar(alternativo, payload, apiKey);
      }
    }
  } catch {
    return error(
      "No se pudo conectar con Gemini (sin conexión o tiempo agotado). Inténtalo de nuevo.",
      504
    );
  }

  if (!respuesta.ok) {
    return error(mensajeParaEstado(respuesta.status), 502);
  }

  const data = (await respuesta.json().catch(() => null)) as {
    candidates?: { content?: { parts?: { text?: string }[] } }[];
    promptFeedback?: { blockReason?: string };
  } | null;

  const texto = data?.candidates?.[0]?.content?.parts
    ?.map((p) => p.text ?? "")
    .join("")
    .trim();

  if (!texto) {
    return error(
      data?.promptFeedback?.blockReason
        ? "Gemini no pudo atender esta solicitud por sus normas de seguridad. Prueba con otra redacción."
        : "Gemini no devolvió texto. Inténtalo de nuevo.",
      502
    );
  }

  return NextResponse.json({ resultado: texto });
}
