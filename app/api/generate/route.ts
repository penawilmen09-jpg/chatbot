import { type NextRequest, NextResponse } from "next/server";
import { generarDemo, TIPOS, TONOS } from "@/lib/demo-generator";

export async function POST(request: NextRequest) {
  let body: { prompt?: unknown; tipo?: unknown; tono?: unknown };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Solicitud inválida." }, { status: 400 });
  }

  const prompt = typeof body.prompt === "string" ? body.prompt.trim() : "";
  if (!prompt) {
    return NextResponse.json(
      { error: "Escribe lo que necesitas antes de generar." },
      { status: 400 }
    );
  }
  if (prompt.length > 2000) {
    return NextResponse.json(
      { error: "El texto es demasiado largo (máximo 2000 caracteres)." },
      { status: 400 }
    );
  }

  const tipo = TIPOS.find((t) => t.id === body.tipo)?.id ?? "libre";
  const tono = TONOS.find((t) => t.id === body.tono)?.id ?? "profesional";

  await new Promise((r) => setTimeout(r, 900));

  return NextResponse.json({ resultado: generarDemo(prompt, tipo, tono) });
}
