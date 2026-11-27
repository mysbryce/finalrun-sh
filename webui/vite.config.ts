/// <reference types="vitest/config" />
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  base: './',
  build: { outDir: '../ui/web', emptyOutDir: true },
  server: { port: 5173, strictPort: true },
  test: { environment: 'jsdom', pool: 'threads' },
})
