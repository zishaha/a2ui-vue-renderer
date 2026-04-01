/**
 * a2ui-vue — Vue 3 A2UI Protocol Renderer
 *
 * Public API entry point.
 *
 * Usage:
 *   import { A2UIRenderer, useA2UIState, useA2UIStream } from 'a2ui-vue'
 *
 * Or as a Vue plugin:
 *   import A2UIPlugin from 'a2ui-vue'
 *   app.use(A2UIPlugin)
 */
import type { App } from 'vue'
import A2UIRenderer from './components/A2UIRenderer.vue'
import { A2UIComponent } from './components/A2UIComponent'
import { DEFAULT_CATALOG } from './components/catalog'
import { useA2UIState } from './composables/useA2UIState'
import { useA2UIStream } from './composables/useA2UIStream'

// ── Vue Plugin ────────────────────────────────────────────────────────────

const A2UIPlugin = {
  install(app: App) {
    app.component('A2UIRenderer', A2UIRenderer)
    app.component('A2UIComponent', A2UIComponent)
  },
}

export default A2UIPlugin

// ── Named exports ─────────────────────────────────────────────────────────

export { A2UIRenderer, A2UIComponent, DEFAULT_CATALOG, useA2UIState, useA2UIStream }

// ── Type exports ──────────────────────────────────────────────────────────

export type {
  A2UIMessage,
  A2UIRendererProps,
  Surface,
  UserActionMessage,
  BoundValue,
  ComponentUpdate,
  ComponentType,
} from './types'
