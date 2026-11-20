// Crea un AUTH_SECRET aleatorio y local (en .env.local, que Git ignora) si no existe.
// Así el proyecto arranca en Codespaces sin configurar nada y sin secretos en el código.
import { randomBytes } from "node:crypto";
import { appendFileSync, existsSync, readFileSync } from "node:fs";

const archivos = [".env.local", ".env.development.local", ".env"];
const yaDefinido =
  Boolean(process.env.AUTH_SECRET) ||
  archivos.some(
    (f) =>
      existsSync(f) &&
      /^\s*AUTH_SECRET\s*=\s*\S+/m.test(readFileSync(f, "utf8"))
  );

if (!yaDefinido) {
  appendFileSync(
    ".env.local",
    `AUTH_SECRET=${randomBytes(32).toString("base64")}\n`
  );
  console.log("WILMEN AI: se generó un AUTH_SECRET local en .env.local");
}
