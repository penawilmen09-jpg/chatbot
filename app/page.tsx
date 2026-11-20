import { Generator } from "@/components/wilmen/generator";

export default function Home() {
  return (
    <main className="relative min-h-dvh overflow-hidden bg-[#09090f] text-zinc-100">
      <div
        aria-hidden="true"
        className="pointer-events-none absolute -top-40 left-1/2 h-[28rem] w-[44rem] -translate-x-1/2 rounded-full bg-violet-600/25 blur-[120px]"
      />
      <div
        aria-hidden="true"
        className="pointer-events-none absolute right-0 bottom-0 h-80 w-80 rounded-full bg-fuchsia-600/15 blur-[110px]"
      />

      <div className="relative mx-auto w-full max-w-6xl px-4 py-6 sm:px-6 sm:py-10">
        <header className="mb-10 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <span className="flex size-9 items-center justify-center rounded-xl bg-gradient-to-br from-violet-500 to-fuchsia-500 font-bold text-white">
              W
            </span>
            <span className="font-semibold text-lg tracking-tight">
              WILMEN AI
            </span>
          </div>
        </header>

        <section className="mx-auto mb-10 max-w-2xl text-center sm:mb-14">
          <h1 className="text-balance font-bold text-4xl text-white tracking-tight sm:text-5xl">
            Crea textos increíbles en{" "}
            <span className="bg-gradient-to-r from-violet-400 to-fuchsia-400 bg-clip-text text-transparent">
              segundos
            </span>
          </h1>
          <p className="mt-4 text-balance text-base text-zinc-400 sm:text-lg">
            Tu asistente de escritura con inteligencia artificial. Correos,
            publicaciones, historias, guiones y más, todo en español.
          </p>
        </section>

        <Generator />

        <footer className="mt-12 text-center text-xs text-zinc-500">
          WILMEN AI · Textos generados con inteligencia artificial
        </footer>
      </div>
    </main>
  );
}
