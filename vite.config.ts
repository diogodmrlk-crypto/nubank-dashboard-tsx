import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: './', // MUITO IMPORTANTE: Faz os caminhos serem relativos (./assets/index.js)
  build: { 
    outDir: 'dist',
    emptyOutDir: true 
  },
})
