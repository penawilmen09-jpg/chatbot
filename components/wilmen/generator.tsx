"use client";

import { useCallback, useState } from "react";
import { TIPOS, type TipoId, TONOS, type TonoId } from "@/lib/generator-config";

const MAX = 2000;

const EJEMPLOS = [
  "Una publicación para anunciar la apertura de mi cafetería",
  "Una historia corta sobre un robot que aprende a pintar",
  "Una publicación anunciando una carrera de arrancones este sábado en Santo Domingo",
  "Un guion de 30 segundos para un video sobre ahorrar dinero",
];

export function Generator() {
  const [prompt, setPrompt] = useState("");
  const [tipo, setTipo] = useState<TipoId>("correo");
  const [tono, setTono] = useState<TonoId>("profesional");
  const [resultado, setResultado] = useState("");
  const [error, setError] = useState("");
  const [cargando, setCargando] = useState(false);
  const [copiado, setCopiado] = useState(false);

  const generar = useCallback(async () => {
    if (!prompt.trim() || cargando) {
      if (!prompt.trim()) {
        setError("Escribe lo que necesitas antes de generar.");
      }
      return;
    }
    setCargando(true);
    setError("");
    setCopiado(false);
    try {
      const res = await fetch("/api/generate", {
        body: JSON.stringify({ prompt, tipo, tono }),
        headers: { "Content-Type": "application/json" },
        method: "POST",
        signal: AbortSignal.timeout(60_000),
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error ?? "No se pudo generar el texto.");
      }
      setResultado(data.resultado);
    } catch (e) {
      setError(
        e instanceof DOMException && e.name === "TimeoutError"
          ? "La respuesta tardó demasiado. Inténtalo de nuevo."
          : e instanceof Error
            ? e.message
            : "Ocurrió un error inesperado."
      );
    } finally {
      setCargando(false);
    }
  }, [prompt, tipo, tono, cargando]);

  const copiar = useCallback(async () => {
    try {
      await navigator.clipboard.writeText(resultado);
      setCopiado(true);
      setTimeout(() => setCopiado(false), 2000);
    } catch {
      setError("No se pudo copiar el texto.");
    }
  }, [resultado]);

  const elegirTipo = useCallback((e: React.MouseEvent<HTMLButtonElement>) => {
    setTipo(e.currentTarget.dataset.id as TipoId);
  }, []);
  const elegirTono = useCallback((e: React.MouseEvent<HTMLButtonElement>) => {
    setTono(e.currentTarget.dataset.id as TonoId);
  }, []);
  const elegirEjemplo = useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      setPrompt(e.currentTarget.dataset.id ?? "");
    },
    []
  );
  const cambiarPrompt = useCallback(
    (e: React.ChangeEvent<HTMLTextAreaElement>) => setPrompt(e.target.value),
    []
  );

  const chip = (activo: boolean) =>
    `rounded-full border px-3.5 py-2 text-sm transition-colors ${
      activo
        ? "border-violet-400/60 bg-violet-500/20 text-violet-100"
        : "border-white/10 bg-white/5 text-zinc-300 hover:bg-white/10"
    }`;

  return (
    <div className="grid gap-6 lg:grid-cols-2">
      <section className="rounded-2xl border border-white/10 bg-white/[0.04] p-5 shadow-xl backdrop-blur sm:p-6">
        <h2 className="mb-4 font-semibold text-lg text-white">
          ¿Qué necesitas?
        </h2>

        <fieldset className="mb-4">
          <legend className="mb-2 text-sm text-zinc-400">Tipo de texto</legend>
          <div className="flex flex-wrap gap-2">
            {TIPOS.map((t) => (
              <button
                aria-pressed={tipo === t.id}
                className={chip(tipo === t.id)}
                data-id={t.id}
                key={t.id}
                onClick={elegirTipo}
                type="button"
              >
                <span aria-hidden="true">{t.icono}</span> {t.etiqueta}
              </button>
            ))}
          </div>
        </fieldset>

        <fieldset className="mb-4">
          <legend className="mb-2 text-sm text-zinc-400">Tono</legend>
          <div className="flex flex-wrap gap-2">
            {TONOS.map((t) => (
              <button
                aria-pressed={tono === t.id}
                className={chip(tono === t.id)}
                data-id={t.id}
                key={t.id}
                onClick={elegirTono}
                type="button"
              >
                {t.etiqueta}
              </button>
            ))}
          </div>
        </fieldset>

        <label className="mb-2 block text-sm text-zinc-400" htmlFor="prompt">
          Describe lo que quieres generar
        </label>
        <textarea
          className="min-h-40 w-full resize-y rounded-xl border border-white/10 bg-black/30 p-4 text-base text-white placeholder:text-zinc-500 focus:border-violet-400/60 focus:outline-none focus:ring-2 focus:ring-violet-500/30"
          id="prompt"
          maxLength={MAX}
          onChange={cambiarPrompt}
          placeholder="Ej.: Un correo para presentar mi servicio de diseño a una empresa nueva…"
          value={prompt}
        />
        <div className="mt-1 text-right text-xs text-zinc-500">
          {prompt.length}/{MAX}
        </div>

        <div className="mt-2 mb-5 flex flex-wrap gap-2">
          {EJEMPLOS.map((ej) => (
            <button
              className="rounded-lg bg-white/5 px-3 py-1.5 text-left text-xs text-zinc-400 transition-colors hover:bg-white/10 hover:text-zinc-200"
              data-id={ej}
              key={ej}
              onClick={elegirEjemplo}
              type="button"
            >
              {ej}
            </button>
          ))}
        </div>

        {error !== "" && (
          <p
            className="mb-3 rounded-lg border border-red-400/30 bg-red-500/10 px-3 py-2 text-red-200 text-sm"
            role="alert"
          >
            {error}
          </p>
        )}

        <button
          className="w-full rounded-xl bg-gradient-to-r from-violet-500 to-fuchsia-500 px-6 py-3.5 font-semibold text-base text-white shadow-lg shadow-violet-900/40 transition hover:brightness-110 active:scale-[0.99] disabled:cursor-not-allowed disabled:opacity-60"
          disabled={cargando}
          onClick={generar}
          type="button"
        >
          {cargando ? "Generando…" : "Generar"}
        </button>
      </section>

      <section
        aria-live="polite"
        className="flex min-h-72 flex-col rounded-2xl border border-white/10 bg-white/[0.04] p-5 shadow-xl backdrop-blur sm:p-6"
      >
        <div className="mb-4 flex items-center justify-between gap-3">
          <h2 className="font-semibold text-lg text-white">Resultado</h2>
          {resultado && !cargando && (
            <button
              className="rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-sm text-zinc-200 transition-colors hover:bg-white/10"
              onClick={copiar}
              type="button"
            >
              {copiado ? "¡Copiado!" : "Copiar"}
            </button>
          )}
        </div>

        {cargando === true && (
          <div className="flex flex-1 animate-pulse flex-col gap-3">
            <div className="h-4 w-2/3 rounded bg-white/10" />
            <div className="h-4 w-full rounded bg-white/10" />
            <div className="h-4 w-5/6 rounded bg-white/10" />
            <div className="h-4 w-1/2 rounded bg-white/10" />
          </div>
        )}

        {!cargando && resultado && (
          <div
            className="flex-1 whitespace-pre-wrap break-words text-[15px] text-zinc-200 leading-relaxed"
            data-testid="resultado"
          >
            {resultado}
          </div>
        )}

        {!(cargando || resultado) && (
          <div className="flex flex-1 flex-col items-center justify-center gap-2 text-center text-zinc-500">
            <span aria-hidden="true" className="text-4xl">
              ✨
            </span>
            <p className="max-w-xs text-sm">
              Tu texto aparecerá aquí. Escribe lo que necesitas y pulsa
              “Generar”.
            </p>
          </div>
        )}
      </section>
    </div>
  );
}
