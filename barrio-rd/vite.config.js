import { defineConfig } from 'vite';

// base './' permite abrir el build desde cualquier carpeta o servidor estático
export default defineConfig({
  base: './',
  server: { host: true, port: 5173 },
  build: {
    target: 'es2020',
    chunkSizeWarningLimit: 900,
    rollupOptions: { output: { manualChunks: { three: ['three'] } } },
  },
});
