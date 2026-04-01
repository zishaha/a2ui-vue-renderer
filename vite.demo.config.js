import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

// Demo app config — serves the demo/index.html
export default defineConfig({
  plugins: [vue()],
  root: resolve(__dirname, 'demo'),
  resolve: {
    alias: { 'a2ui-vue': resolve(__dirname, 'src/index.ts') },
  },
  server: { port: 5200 },
})
