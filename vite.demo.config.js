import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

// Demo app config — serves the demo/index.html
export default defineConfig({
  plugins: [vue()],
  root: resolve(__dirname, 'demo'),
  base: '/a2ui-vue-renderer/',
  resolve: {
    alias: { 'a2ui-vue': resolve(__dirname, 'src/index.ts') },
  },
  server: { port: 5200 },
  build: {
    outDir: resolve(__dirname, 'dist-demo'),
    emptyOutDir: true,
  },
})
