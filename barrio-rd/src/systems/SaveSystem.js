// Guardado local (localStorage). Versionado para poder migrar partidas en el futuro.
const KEY = 'barriord.save.v1';
export const SaveSystem = {
  load() { try { const s = localStorage.getItem(KEY); return s ? JSON.parse(s) : null; } catch { return null; } },
  save(data) { try { localStorage.setItem(KEY, JSON.stringify({ v: 1, ...data })); return true; } catch { return false; } },
  clear() { try { localStorage.removeItem(KEY); } catch { /* ignorar */ } },
};
