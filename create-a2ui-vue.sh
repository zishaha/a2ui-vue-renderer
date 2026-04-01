#!/bin/bash
set -e
echo "🚀 创建 a2ui-vue-renderer..."

mkdir -p a2ui-vue-renderer/demo a2ui-vue-renderer/src a2ui-vue-renderer/src/components a2ui-vue-renderer/src/components/catalog a2ui-vue-renderer/src/composables a2ui-vue-renderer/src/types a2ui-vue-renderer/src/utils

cat > a2ui-vue-renderer/demo/App.vue << 'FILEOF_demo_App_vue'
<template>
  <div class="demo-app">
    <header class="demo-header">
      <h1>🦾 A2UI Vue Renderer — Demo</h1>
      <p>Vue 3 implementation of the A2UI Agent-to-User Interface protocol</p>
    </header>

    <div class="demo-tabs">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        :class="['demo-tab', { active: activeTab === tab.id }]"
        @click="activeTab = tab.id"
      >{{ tab.label }}</button>
    </div>

    <div class="demo-body">
      <!-- Static messages demo -->
      <section v-if="activeTab === 'flight'" class="demo-section">
        <h2>✈️ Flight Booking Form</h2>
        <p class="demo-desc">
          Simulates an Agent response that generates a flight booking UI.
          Demonstrates: Column, Row, TextField, DateTimeInput, ChoicePicker, Button.
        </p>
        <div class="demo-renderer">
          <A2UIRenderer
            :messages="flightMessages"
            @action="onAction"
          />
        </div>
        <pre class="demo-log" v-if="lastAction">Last action: {{ JSON.stringify(lastAction, null, 2) }}</pre>
      </section>

      <!-- Product comparison demo -->
      <section v-if="activeTab === 'product'" class="demo-section">
        <h2>🛍️ Product List (Dynamic Template)</h2>
        <p class="demo-desc">
          Demonstrates dynamic list rendering: a template component repeated
          per item in a data model array (A2UI adjacency list + template children).
        </p>
        <div class="demo-renderer">
          <A2UIRenderer
            :messages="productMessages"
            @action="onAction"
          />
        </div>
      </section>

      <!-- Data binding demo -->
      <section v-if="activeTab === 'form'" class="demo-section">
        <h2>📝 Survey Form (Two-way Data Binding)</h2>
        <p class="demo-desc">
          Demonstrates two-way data binding: form fields update the local
          data model, and bound Text components reflect changes live.
        </p>
        <div class="demo-renderer">
          <A2UIRenderer
            :messages="surveyMessages"
            @action="onAction"
          />
        </div>
      </section>

      <!-- Protocol inspector -->
      <section v-if="activeTab === 'inspector'" class="demo-section">
        <h2>🔍 Protocol Message Inspector</h2>
        <p class="demo-desc">Paste A2UI JSONL messages below and see them rendered live.</p>
        <textarea
          v-model="customJsonl"
          class="demo-jsonl"
          placeholder='{"type":"beginRendering","surfaceId":"s1","rootComponentId":"root"}
{"type":"surfaceUpdate","surfaceId":"s1","components":[{"id":"root","type":"Column","children":{"explicitList":["t1"]}},{"id":"t1","type":"Text","text":{"literalString":"Hello from A2UI!"}}]}'
        />
        <button class="demo-btn" @click="applyCustom">▶ Render</button>
        <div class="demo-renderer" v-if="customMessages.length">
          <A2UIRenderer :messages="customMessages" @action="onAction" />
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { A2UIRenderer } from 'a2ui-vue'
import type { A2UIMessage, UserActionMessage } from 'a2ui-vue'

const activeTab = ref('flight')
const lastAction = ref<UserActionMessage | null>(null)
const customJsonl = ref('')
const customMessages = ref<A2UIMessage[]>([])

const tabs = [
  { id: 'flight',    label: '✈️ Flight Booking' },
  { id: 'product',   label: '🛍️ Product List' },
  { id: 'form',      label: '📝 Survey Form' },
  { id: 'inspector', label: '🔍 Inspector' },
]

function onAction(action: UserActionMessage) {
  lastAction.value = action
  console.log('[A2UI Demo] Action received:', action)
}

function applyCustom() {
  try {
    customMessages.value = customJsonl.value
      .split('\n')
      .map(l => l.trim())
      .filter(Boolean)
      .map(l => JSON.parse(l) as A2UIMessage)
  } catch (e) {
    alert('Invalid JSONL: ' + (e as Error).message)
  }
}

// ── Demo Messages ─────────────────────────────────────────────────────────

const flightMessages: A2UIMessage[] = [
  {
    type: 'beginRendering',
    surfaceId: 'flight-surface',
    rootComponentId: 'root',
  },
  {
    type: 'dataModelUpdate',
    surfaceId: 'flight-surface',
    updates: [
      { key: 'from',   valueString: 'Beijing' },
      { key: 'to',     valueString: '' },
      { key: 'date',   valueString: '' },
      { key: 'cabin',  valueString: 'Economy' },
      { key: 'count',  valueNumber: 1 },
    ],
  },
  {
    type: 'surfaceUpdate',
    surfaceId: 'flight-surface',
    components: [
      {
        id: 'root', type: 'Card',
        elevation: 1, padding: '24px',
        children: { explicitList: ['title', 'form-col', 'submit-row'] },
      },
      { id: 'title', type: 'Text', variant: 'title',
        text: { literalString: '✈️ Search Flights' } },
      {
        id: 'form-col', type: 'Column', gap: '16px',
        children: { explicitList: ['row1', 'row2', 'cabin-field'] },
      },
      {
        id: 'row1', type: 'Row', gap: '12px',
        children: { explicitList: ['from-field', 'to-field'] },
      },
      {
        id: 'from-field', type: 'TextField', flex: 1,
        label: 'From', dataPath: '/from',
        text: { path: '/from' },
      },
      {
        id: 'to-field', type: 'TextField', flex: 1,
        label: 'To', placeholder: 'Destination', dataPath: '/to',
        text: { path: '/to' },
      },
      {
        id: 'row2', type: 'Row', gap: '12px',
        children: { explicitList: ['date-field', 'count-slider'] },
      },
      {
        id: 'date-field', type: 'DateTimeInput', flex: 1,
        label: 'Departure Date', mode: 'date', dataPath: '/date',
        value: { path: '/date' },
      },
      {
        id: 'count-slider', type: 'Column', flex: 1, gap: '4px',
        children: { explicitList: ['count-label', 'count-input'] },
      },
      { id: 'count-label', type: 'Text', variant: 'caption',
        text: { literalString: 'Passengers' } },
      {
        id: 'count-input', type: 'Slider',
        minValue: 1, maxValue: 9, step: 1, dataPath: '/count',
        value: { path: '/count' },
      },
      {
        id: 'cabin-field', type: 'ChoicePicker',
        label: 'Cabin Class',
        options: ['Economy', 'Business', 'First Class'],
        dataPath: '/cabin',
        value: { path: '/cabin' },
      },
      {
        id: 'submit-row', type: 'Row', gap: '8px', justify: 'end',
        children: { explicitList: ['search-btn'] },
      },
      {
        id: 'search-btn', type: 'Button', primary: true,
        label: { literalString: 'Search Flights' },
        actionId: 'search_flights',
        context: {
          from:  { path: '/from' },
          to:    { path: '/to' },
          date:  { path: '/date' },
          cabin: { path: '/cabin' },
          count: { path: '/count' },
        },
      },
    ],
  },
]

const productMessages: A2UIMessage[] = [
  {
    type: 'beginRendering',
    surfaceId: 'product-surface',
    rootComponentId: 'root',
  },
  {
    type: 'dataModelUpdate',
    surfaceId: 'product-surface',
    updates: [
      {
        key: 'products',
        valueList: [
          { name: 'MacBook Pro 16"', price: '¥22,999', tag: '推荐' },
          { name: 'Dell XPS 15',     price: '¥15,499', tag: '热销' },
          { name: 'ThinkPad X1 Carbon', price: '¥12,999', tag: '' },
        ],
      },
    ],
  },
  {
    type: 'surfaceUpdate',
    surfaceId: 'product-surface',
    components: [
      {
        id: 'root', type: 'Column', gap: '12px',
        children: { explicitList: ['heading', 'product-list'] },
      },
      { id: 'heading', type: 'Text', variant: 'title',
        text: { literalString: '🛍️ 推荐笔记本电脑' } },
      {
        id: 'product-list', type: 'List',
        children: {
          template: {
            dataBinding:         { path: '/products' },
            templateComponentId: 'product-card',
          },
        },
      },
      // Template component (rendered once per item)
      {
        id: 'product-card', type: 'Card',
        elevation: 1, padding: '16px',
        children: { explicitList: ['card-row'] },
      },
      {
        id: 'card-row', type: 'Row', gap: '12px', justify: 'between',
        children: { explicitList: ['info-col', 'buy-btn'] },
      },
      {
        id: 'info-col', type: 'Column', gap: '4px',
        children: { explicitList: ['prod-name', 'prod-price'] },
      },
      { id: 'prod-name',  type: 'Text', variant: 'body',   text: { path: '/name' } },
      { id: 'prod-price', type: 'Text', variant: 'caption', text: { path: '/price' } },
      {
        id: 'buy-btn', type: 'Button', primary: true,
        label: { literalString: '加入购物车' },
        actionId: 'add_to_cart',
      },
    ],
  },
]

const surveyMessages: A2UIMessage[] = [
  {
    type: 'beginRendering',
    surfaceId: 'survey-surface',
    rootComponentId: 'root',
  },
  {
    type: 'dataModelUpdate',
    surfaceId: 'survey-surface',
    updates: [
      { key: 'name',      valueString: '' },
      { key: 'rating',    valueNumber: 5 },
      { key: 'subscribe', valueBoolean: false },
      { key: 'feedback',  valueString: '' },
    ],
  },
  {
    type: 'surfaceUpdate',
    surfaceId: 'survey-surface',
    components: [
      {
        id: 'root', type: 'Card', elevation: 1, padding: '24px',
        children: { explicitList: ['title', 'divider1', 'name-field', 'rating-section', 'subscribe-check', 'feedback-field', 'divider2', 'preview-section', 'submit-btn'] },
      },
      { id: 'title', type: 'Text', variant: 'title',
        text: { literalString: '📝 用户满意度调查' } },
      { id: 'divider1', type: 'Divider' },
      {
        id: 'name-field', type: 'TextField',
        label: '您的姓名', placeholder: '请输入姓名',
        dataPath: '/name', text: { path: '/name' },
      },
      {
        id: 'rating-section', type: 'Column', gap: '4px',
        children: { explicitList: ['rating-label', 'rating-slider'] },
      },
      { id: 'rating-label', type: 'Text', variant: 'caption',
        text: { literalString: '满意度评分 (1-10)' } },
      {
        id: 'rating-slider', type: 'Slider',
        minValue: 1, maxValue: 10, step: 1,
        dataPath: '/rating', value: { path: '/rating' },
      },
      {
        id: 'subscribe-check', type: 'CheckBox',
        label: '订阅产品更新邮件',
        dataPath: '/subscribe', checked: { path: '/subscribe' },
      },
      {
        id: 'feedback-field', type: 'TextField',
        label: '建议与反馈', placeholder: '请告诉我们您的想法…',
        dataPath: '/feedback', text: { path: '/feedback' },
      },
      { id: 'divider2', type: 'Divider' },
      {
        id: 'preview-section', type: 'Card', elevation: 0, padding: '12px',
        children: { explicitList: ['preview-title', 'preview-name', 'preview-rating'] },
      },
      { id: 'preview-title', type: 'Text', variant: 'caption',
        text: { literalString: '实时预览（数据绑定演示）：' } },
      { id: 'preview-name',   type: 'Text', text: { path: '/name' } },
      { id: 'preview-rating', type: 'Text', text: { path: '/rating' } },
      {
        id: 'submit-btn', type: 'Button', primary: true,
        label: { literalString: '提交问卷' }, actionId: 'submit_survey',
      },
    ],
  },
]
</script>

<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #f0f2f5;
  color: #212121;
}

.demo-app { max-width: 860px; margin: 0 auto; padding: 32px 20px 64px; }

.demo-header { text-align: center; margin-bottom: 32px; }
.demo-header h1 { font-size: 26px; font-weight: 700; margin-bottom: 8px; }
.demo-header p  { color: #666; font-size: 15px; }

.demo-tabs {
  display: flex; gap: 4px;
  background: #fff;
  border-radius: 10px;
  padding: 4px;
  box-shadow: 0 1px 4px rgba(0,0,0,.08);
  margin-bottom: 24px;
}
.demo-tab {
  flex: 1; padding: 10px;
  border: none; background: none;
  border-radius: 8px;
  font-size: 14px; font-weight: 500;
  Claude Code: pointer; color: #555;
  transition: background .15s, color .15s;
}
.demo-tab.active { background: #1976d2; color: #fff; }

.demo-section {}
.demo-section h2 { font-size: 18px; margin-bottom: 6px; }
.demo-desc { color: #666; font-size: 13px; margin-bottom: 16px; line-height: 1.6; }

.demo-renderer {
  background: #fff;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 1px 6px rgba(0,0,0,.08);
}

.demo-log {
  margin-top: 12px;
  background: #1e1e1e;
  color: #d4d4d4;
  border-radius: 8px;
  padding: 16px;
  font-size: 12px;
  overflow-x: auto;
}

.demo-jsonl {
  width: 100%;
  height: 160px;
  font-family: monospace;
  font-size: 12px;
  padding: 12px;
  border: 1.5px solid #e0e0e0;
  border-radius: 8px;
  resize: vertical;
  margin-bottom: 10px;
  outline: none;
}
.demo-jsonl:focus { border-color: #1976d2; }

.demo-btn {
  padding: 8px 20px;
  background: #1976d2; color: #fff;
  border: none; border-radius: 6px;
  Claude Code: pointer; font-size: 14px;
  margin-bottom: 16px;
}
.demo-btn:hover { background: #1565c0; }
</style>

FILEOF_demo_App_vue

cat > a2ui-vue-renderer/demo/index.html << 'FILEOF_demo_index_html'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>A2UI Vue Renderer — Demo</title>
</head>
<body>
  <div id="app"></div>
  <script type="module" src="./main.ts"></script>
</body>
</html>

FILEOF_demo_index_html

cat > a2ui-vue-renderer/demo/main.ts << 'FILEOF_demo_main_ts'
import { createApp } from 'vue'
import App from './App.vue'
import A2UIPlugin from 'a2ui-vue'
import 'a2ui-vue/src/styles.css'

createApp(App).use(A2UIPlugin).mount('#app')

FILEOF_demo_main_ts

cat > a2ui-vue-renderer/package.json << 'FILEOF_package_json'
{
  "name": "a2ui-vue",
  "version": "0.1.0",
  "description": "Vue 3 renderer for the A2UI protocol",
  "type": "module",
  "main": "./dist/index.cjs",
  "module": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "import": "./dist/index.js",
      "require": "./dist/index.cjs",
      "types": "./dist/index.d.ts"
    },
    "./styles.css": "./dist/styles.css"
  },
  "scripts": {
    "dev":   "vite",
    "build": "vite build",
    "demo":  "vite --config vite.demo.config.js"
  },
  "dependencies": {
    "vue": "^3.4.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.0.0",
    "vite": "^5.0.0",
    "typescript": "^5.3.0",
    "vue-tsc": "^2.0.0"
  },
  "peerDependencies": {
    "vue": "^3.0.0"
  }
}

FILEOF_package_json

cat > a2ui-vue-renderer/src/components/A2UIComponent.ts << 'FILEOF_src_components_A2UIComponent_ts'
/**
 * A2UIComponent — Recursive component renderer
 *
 * Core of the Vue A2UI renderer. Recursively renders a component
 * and its children from the adjacency list model.
 *
 * React equivalent: A recursive <Component /> that resolves catalog entries
 * and renders children. Vue uses h() + defineComponent for the same pattern.
 */
import {
  h,
  defineComponent,
  inject,
  type PropType,
} from 'vue'
import type { ComponentUpdate, Surface, UserActionMessage } from '../../types'
import { resolveProps } from '../../utils/boundValue'
import { get } from '../../utils/jsonPointer'
import { DEFAULT_CATALOG } from './catalog'
import { A2UI_CONTEXT_KEY, type A2UIContext } from '../A2UIContext'

export const A2UIComponent = defineComponent({
  name: 'A2UIComponent',

  props: {
    componentId: { type: String, required: true },
    surface:     { type: Object as PropType<Surface>, required: true },
    scopePath:   { type: String, default: '' },
  },

  setup(props) {
    const ctx = inject<A2UIContext>(A2UI_CONTEXT_KEY)!

    return () => {
      const comp = props.surface.components.get(props.componentId)
      if (!comp) return null

      return renderComponent(comp, props.surface, props.scopePath, ctx)
    }
  },
})

// ── Core render logic ─────────────────────────────────────────────────────

function renderComponent(
  comp: ComponentUpdate,
  surface: Surface,
  scopePath: string,
  ctx: A2UIContext
): ReturnType<typeof h> | null {
  const { catalog, onAction, updateDataPath } = ctx

  // 1. Resolve component from catalog (user overrides take priority)
  const CatalogComponent = (catalog[comp.type] ?? DEFAULT_CATALOG[comp.type]) as Parameters<typeof h>[0] | undefined
  if (!CatalogComponent) {
    console.warn(`[A2UI] Unknown component type: "${comp.type}" — rendering fallback div`)
    return h('div', { 'data-a2ui-unknown': comp.type },
      renderChildren(comp, surface, scopePath, ctx)
    )
  }

  // 2. Resolve bound prop values against the data model
  const resolvedProps = resolveProps(
    comp as unknown as Record<string, unknown>,
    surface.dataModel,
    scopePath || undefined
  )

  // 3. Build event handlers
  const handlers = buildHandlers(comp, surface, resolvedProps, onAction, updateDataPath)

  // 4. Render children
  const children = renderChildren(comp, surface, scopePath, ctx)

  // 5. h() — Vue's equivalent of React.createElement()
  return h(
    CatalogComponent,
    {
      key: comp.id,
      ...resolvedProps,
      ...handlers,
    },
    children.length > 0 ? { default: () => children } : undefined
  )
}

// ── Children resolution (adjacency list → VNodes) ─────────────────────────

function renderChildren(
  comp: ComponentUpdate,
  surface: Surface,
  scopePath: string,
  ctx: A2UIContext
): ReturnType<typeof h>[] {
  if (!comp.children) return []

  const children = comp.children

  // Static list: explicit array of child component IDs
  if ('explicitList' in children) {
    return children.explicitList
      .map(childId => {
        const child = surface.components.get(childId)
        if (!child) return null
        return renderComponent(child, surface, scopePath, ctx)
      })
      .filter(Boolean) as ReturnType<typeof h>[]
  }

  // Dynamic list: template component repeated per data array item
  if ('template' in children) {
    const { dataBinding, templateComponentId } = children.template
    const templateComp = surface.components.get(templateComponentId)
    if (!templateComp) return []

    // Resolve the array from the data model
    let arrayPath = ''
    if ('path' in dataBinding) {
      arrayPath = scopePath
        ? scopePath.replace(/\/$/, '') + dataBinding.path
        : dataBinding.path
    }

    const array = get(surface.dataModel, arrayPath)
    if (!Array.isArray(array)) return []

    // Render one template instance per item, with scoped path
    return array.map((_, index) => {
      const itemScope = `${arrayPath}/${index}`
      return renderComponent(templateComp, surface, itemScope, ctx)
    }).filter(Boolean) as ReturnType<typeof h>[]
  }

  return []
}

// ── Event handler factory ─────────────────────────────────────────────────

function buildHandlers(
  comp: ComponentUpdate,
  surface: Surface,
  resolvedProps: Record<string, unknown>,
  onAction: A2UIContext['onAction'],
  updateDataPath: A2UIContext['updateDataPath']
): Record<string, unknown> {
  const handlers: Record<string, unknown> = {}

  // Button / action components: emit userAction to agent
  if (comp.type === 'Button') {
    handlers['onAction'] = ({ actionId }: { actionId: string }) => {
      const msg: UserActionMessage = {
        type: 'userAction',
        surfaceId: surface.id,
        actionId: (resolvedProps.actionId as string) || actionId || comp.id,
        context: collectContext(comp, surface),
      }
      onAction?.(msg)
    }
  }

  // Two-way bound components: write back to local data model
  if (['TextField', 'CheckBox', 'Slider', 'ChoicePicker',
       'MultipleChoice', 'DateTimeInput'].includes(comp.type)) {
    handlers['onUpdate'] = ({ path, value }: { path: string; value: unknown }) => {
      if (path) updateDataPath(surface.id, path, value)
    }
  }

  return handlers
}

// ── Context collection for action payloads ────────────────────────────────

function collectContext(
  comp: ComponentUpdate,
  surface: Surface
): Record<string, unknown> {
  // Collect any context bindings declared on the component
  const ctx: Record<string, unknown> = {}
  const raw = comp as Record<string, unknown>

  if (raw.context && typeof raw.context === 'object') {
    for (const [k, binding] of Object.entries(raw.context as Record<string, { path: string }>)) {
      if (binding?.path) {
        ctx[k] = get(surface.dataModel, binding.path)
      }
    }
  }

  return ctx
}

FILEOF_src_components_A2UIComponent_ts

cat > a2ui-vue-renderer/src/components/A2UIContext.ts << 'FILEOF_src_components_A2UIContext_ts'
/**
 * A2UI Context — provide/inject pattern
 *
 * React equivalent: React.createContext + useContext
 * Vue equivalent:   provide() + inject() with a Symbol key
 *
 * Passes catalog, action handler, and state updater down the
 * component tree without prop drilling.
 */
import type { InjectionKey } from 'vue'
import type { UserActionMessage } from '../types'

export interface A2UIContext {
  catalog: Record<string, unknown>
  onAction?: (action: UserActionMessage) => void
  updateDataPath: (surfaceId: string, path: string, value: unknown) => void
}

export const A2UI_CONTEXT_KEY: InjectionKey<A2UIContext> = Symbol('a2ui-context')

FILEOF_src_components_A2UIContext_ts

cat > a2ui-vue-renderer/src/components/A2UIRenderer.vue << 'FILEOF_src_components_A2UIRenderer_vue'
<template>
  <div :class="['a2ui-renderer', `a2ui-theme--${theme}`]">
    <!-- Loading state -->
    <slot v-if="isStreaming && !hasSurfaces" name="loading">
      <div class="a2ui-renderer__loading">
        <span class="a2ui-spinner" />
        <span>Agent is thinking…</span>
      </div>
    </slot>

    <!-- Error state -->
    <slot v-if="streamError" name="error" :error="streamError">
      <div class="a2ui-renderer__error">
        ⚠️ {{ streamError.message }}
      </div>
    </slot>

    <!-- Render each surface -->
    <template v-for="surface in activeSurfaces" :key="surface.id">
      <div
        v-if="surface.isReady"
        class="a2ui-surface"
        :data-surface-id="surface.id"
        :style="surfaceThemeVars(surface)"
      >
        <A2UIComponent
          :component-id="surface.rootComponentId"
          :surface="surface"
        />
      </div>
    </template>

    <!-- Empty state -->
    <slot v-if="!isStreaming && !hasSurfaces && !streamError" name="empty">
      <div class="a2ui-renderer__empty">
        Send a message to get started.
      </div>
    </slot>
  </div>
</template>

<script setup lang="ts">
import { computed, provide, watch } from 'vue'
import type { A2UIRendererProps, UserActionMessage } from '../types'
import { useA2UIState } from '../composables/useA2UIState'
import { useA2UIStream } from '../composables/useA2UIStream'
import { DEFAULT_CATALOG } from './catalog'
import { A2UIComponent } from './A2UIComponent'
import { A2UI_CONTEXT_KEY } from './A2UIContext'

// ── Props & Emits ──────────────────────────────────────────────────────────

const props = withDefaults(defineProps<A2UIRendererProps>(), {
  catalog: () => ({}),
  theme: 'light',
})

const emit = defineEmits<{
  action: [action: UserActionMessage]
  error:  [error: Error]
  ready:  [surfaceId: string]
}>()

// Additional props not in interface for convenience
defineProps<{ theme?: string }>()

// ── State ──────────────────────────────────────────────────────────────────

const { surfaces, dispatch, dispatchAll, updateDataPath, reset } = useA2UIState()

const { isStreaming, error: streamError, send, abort } = useA2UIStream({
  onMessage: (msg) => dispatch(msg),
  onError:   (err) => emit('error', err),
  capabilities: props.capabilities,
})

// ── Computed ───────────────────────────────────────────────────────────────

const activeSurfaces = computed(() =>
  Object.values(surfaces).filter(s => s.isReady)
)

const hasSurfaces = computed(() => activeSurfaces.value.length > 0)

const mergedCatalog = computed(() => ({
  ...DEFAULT_CATALOG,
  ...(props.catalog ?? {}),
}))

// ── Provide context to all descendant components ───────────────────────────
// React equivalent: <A2UIContext.Provider value={...}>

provide(A2UI_CONTEXT_KEY, {
  get catalog() { return mergedCatalog.value },
  onAction: (action: UserActionMessage) => {
    emit('action', action)
    // If agentUrl is provided, send back to agent automatically
    if (props.agentUrl) {
      send(props.agentUrl, action)
    }
  },
  updateDataPath,
})

// ── Watch for direct messages prop ────────────────────────────────────────

watch(
  () => props.messages,
  (msgs) => {
    if (msgs?.length) {
      reset()
      dispatchAll(msgs)
    }
  },
  { immediate: true, deep: true }
)

// ── Watch for surface ready events ────────────────────────────────────────

watch(
  activeSurfaces,
  (current, previous) => {
    const prevIds = new Set(previous.map(s => s.id))
    for (const surface of current) {
      if (!prevIds.has(surface.id)) {
        emit('ready', surface.id)
      }
    }
  }
)

// ── Public API (via defineExpose) ─────────────────────────────────────────
// React equivalent: useImperativeHandle

/**
 * Send a user message to the agent and stream the response.
 * Usage: rendererRef.value.sendMessage('Book a flight to Paris')
 */
async function sendMessage(message: string) {
  if (!props.agentUrl) {
    console.warn('[A2UI] sendMessage() requires agentUrl prop')
    return
  }
  reset()
  await send(props.agentUrl, { message })
}

/** Abort any in-flight stream */
function abortStream() {
  abort()
}

/** Reset all surfaces */
function resetSurfaces() {
  reset()
}

defineExpose({ sendMessage, abortStream, resetSurfaces })

// ── Helpers ────────────────────────────────────────────────────────────────

function surfaceThemeVars(surface: typeof activeSurfaces.value[0]): Record<string, string> {
  if (!surface.theme) return {}
  return Object.fromEntries(
    Object.entries(surface.theme).map(([k, v]) => [`--a2ui-${k}`, v])
  )
}
</script>

FILEOF_src_components_A2UIRenderer_vue

cat > a2ui-vue-renderer/src/components/catalog/index.ts << 'FILEOF_src_components_catalog_index_ts'
/**
 * A2UI Component Catalog — Vue 3 Implementation
 *
 * Maps A2UI component type strings to Vue components.
 * Uses Vue's h() render function for maximum flexibility.
 *
 * React equivalent: catalog object mapping type → React component
 * Vue equivalent:   catalog object mapping type → { setup/render } component
 */
import { h, defineComponent, type PropType } from 'vue'
import type { ComponentUpdate, BoundValue } from '../../types'

// ── Helper: resolve BoundValue to display string ─────────────────────────

function resolveText(val: unknown): string {
  if (val == null) return ''
  if (typeof val === 'string') return val
  if (typeof val === 'number' || typeof val === 'boolean') return String(val)
  return JSON.stringify(val)
}

// ── Text ─────────────────────────────────────────────────────────────────

export const A2Text = defineComponent({
  name: 'A2Text',
  props: {
    text: { type: [String, Number, Boolean] as PropType<string | number | boolean>, default: '' },
    variant: { type: String as PropType<'headline' | 'title' | 'body' | 'caption'>, default: 'body' },
    color: { type: String, default: '' },
  },
  setup(props) {
    const tagMap: Record<string, string> = {
      headline: 'h1',
      title:    'h3',
      body:     'p',
      caption:  'span',
    }
    return () =>
      h(tagMap[props.variant] ?? 'p', {
        class: `a2ui-text a2ui-text--${props.variant}`,
        style: props.color ? { color: props.color } : {},
      }, resolveText(props.text))
  },
})

// ── Button ───────────────────────────────────────────────────────────────

export const A2Button = defineComponent({
  name: 'A2Button',
  props: {
    label:    { type: [String, Number, Boolean] as PropType<string | number | boolean>, default: 'Button' },
    primary:  { type: Boolean, default: false },
    variant:  { type: String as PropType<'filled' | 'outlined' | 'text'>, default: 'outlined' },
    disabled: { type: Boolean, default: false },
    actionId: { type: String, default: '' },
  },
  emits: ['action'],
  setup(props, { emit }) {
    return () =>
      h('button', {
        class: [
          'a2ui-btn',
          props.primary || props.variant === 'filled' ? 'a2ui-btn--filled' : '',
          props.variant === 'outlined' ? 'a2ui-btn--outlined' : '',
          props.variant === 'text'     ? 'a2ui-btn--text'     : '',
        ].filter(Boolean),
        disabled: props.disabled,
        onClick: () => emit('action', { actionId: props.actionId }),
      }, resolveText(props.label))
  },
})

// ── TextField ────────────────────────────────────────────────────────────

export const A2TextField = defineComponent({
  name: 'A2TextField',
  props: {
    label:       { type: String, default: '' },
    text:        { type: String, default: '' },   // v0.8 prop name
    value:       { type: String, default: '' },   // v0.9 prop name
    placeholder: { type: String, default: '' },
    dataPath:    { type: String, default: '' },   // for two-way binding
  },
  emits: ['update', 'action'],
  setup(props, { emit }) {
    return () =>
      h('div', { class: 'a2ui-field' }, [
        props.label && h('label', { class: 'a2ui-field__label' }, props.label),
        h('input', {
          class: 'a2ui-field__input',
          type: 'text',
          value: props.text || props.value,
          placeholder: props.placeholder,
          onInput: (e: Event) => {
            const val = (e.target as HTMLInputElement).value
            emit('update', { path: props.dataPath, value: val })
          },
        }),
      ])
  },
})

// ── CheckBox ─────────────────────────────────────────────────────────────

export const A2CheckBox = defineComponent({
  name: 'A2CheckBox',
  props: {
    label:    { type: String, default: '' },
    checked:  { type: Boolean, default: false },
    dataPath: { type: String, default: '' },
  },
  emits: ['update'],
  setup(props, { emit }) {
    return () =>
      h('label', { class: 'a2ui-checkbox' }, [
        h('input', {
          type: 'checkbox',
          checked: props.checked,
          onChange: (e: Event) => {
            const val = (e.target as HTMLInputElement).checked
            emit('update', { path: props.dataPath, value: val })
          },
        }),
        h('span', { class: 'a2ui-checkbox__label' }, props.label),
      ])
  },
})

// ── Slider ───────────────────────────────────────────────────────────────

export const A2Slider = defineComponent({
  name: 'A2Slider',
  props: {
    value:    { type: Number, default: 0 },
    minValue: { type: Number, default: 0 },  // v0.8
    maxValue: { type: Number, default: 100 }, // v0.8
    min:      { type: Number, default: 0 },  // v0.9
    max:      { type: Number, default: 100 }, // v0.9
    step:     { type: Number, default: 1 },
    dataPath: { type: String, default: '' },
  },
  emits: ['update'],
  setup(props, { emit }) {
    return () =>
      h('input', {
        class: 'a2ui-slider',
        type: 'range',
        min: props.min || props.minValue,
        max: props.max || props.maxValue,
        step: props.step,
        value: props.value,
        onInput: (e: Event) => {
          const val = Number((e.target as HTMLInputElement).value)
          emit('update', { path: props.dataPath, value: val })
        },
      })
  },
})

// ── ChoicePicker / Select ────────────────────────────────────────────────

export const A2ChoicePicker = defineComponent({
  name: 'A2ChoicePicker',
  props: {
    label:    { type: String, default: '' },
    options:  { type: Array as PropType<string[]>, default: () => [] },
    value:    { type: String, default: '' },
    dataPath: { type: String, default: '' },
  },
  emits: ['update'],
  setup(props, { emit }) {
    return () =>
      h('div', { class: 'a2ui-choice' }, [
        props.label && h('label', { class: 'a2ui-choice__label' }, props.label),
        h('select', {
          class: 'a2ui-choice__select',
          value: props.value,
          onChange: (e: Event) => {
            const val = (e.target as HTMLSelectElement).value
            emit('update', { path: props.dataPath, value: val })
          },
        },
        props.options.map(opt =>
          h('option', { key: opt, value: opt }, opt)
        )),
      ])
  },
})

// ── DateTimeInput ────────────────────────────────────────────────────────

export const A2DateTimeInput = defineComponent({
  name: 'A2DateTimeInput',
  props: {
    label:    { type: String, default: '' },
    value:    { type: String, default: '' },
    mode:     { type: String as PropType<'date' | 'time' | 'datetime'>, default: 'date' },
    dataPath: { type: String, default: '' },
  },
  emits: ['update'],
  setup(props, { emit }) {
    const typeMap: Record<string, string> = {
      date:     'date',
      time:     'time',
      datetime: 'datetime-local',
    }
    return () =>
      h('div', { class: 'a2ui-datetime' }, [
        props.label && h('label', { class: 'a2ui-datetime__label' }, props.label),
        h('input', {
          class: 'a2ui-datetime__input',
          type: typeMap[props.mode] ?? 'date',
          value: props.value,
          onInput: (e: Event) => {
            emit('update', { path: props.dataPath, value: (e.target as HTMLInputElement).value })
          },
        }),
      ])
  },
})

// ── Image ─────────────────────────────────────────────────────────────────

export const A2Image = defineComponent({
  name: 'A2Image',
  props: {
    src: { type: String, default: '' },
    alt: { type: String, default: '' },
    fit: { type: String as PropType<'cover' | 'contain' | 'fill'>, default: 'cover' },
  },
  setup(props) {
    return () =>
      h('img', {
        class: 'a2ui-image',
        src: props.src,
        alt: props.alt,
        style: { objectFit: props.fit },
      })
  },
})

// ── Icon ──────────────────────────────────────────────────────────────────

export const A2Icon = defineComponent({
  name: 'A2Icon',
  props: {
    name:  { type: String, default: '' },
    size:  { type: [String, Number], default: '24px' },
    color: { type: String, default: 'currentColor' },
  },
  setup(props) {
    return () =>
      h('span', {
        class: `a2ui-icon material-icons`,
        style: {
          fontSize: typeof props.size === 'number' ? `${props.size}px` : props.size,
          color: props.color,
        },
        'aria-hidden': 'true',
      }, props.name)
  },
})

// ── Divider ───────────────────────────────────────────────────────────────

export const A2Divider = defineComponent({
  name: 'A2Divider',
  setup() {
    return () => h('hr', { class: 'a2ui-divider' })
  },
})

// ── Card ──────────────────────────────────────────────────────────────────

export const A2Card = defineComponent({
  name: 'A2Card',
  props: {
    elevation: { type: Number, default: 1 },
    padding:   { type: String, default: '16px' },
  },
  setup(props, { slots }) {
    return () =>
      h('div', {
        class: `a2ui-card a2ui-card--elevation-${props.elevation}`,
        style: { padding: props.padding },
      }, slots.default?.())
  },
})

// ── Row ───────────────────────────────────────────────────────────────────

export const A2Row = defineComponent({
  name: 'A2Row',
  props: {
    gap:     { type: String, default: '8px' },
    align:   { type: String as PropType<'start' | 'center' | 'end' | 'stretch'>, default: 'center' },
    justify: { type: String as PropType<'start' | 'center' | 'end' | 'between' | 'around'>, default: 'start' },
    wrap:    { type: Boolean, default: false },
  },
  setup(props, { slots }) {
    const justifyMap: Record<string, string> = {
      start:   'flex-start',
      center:  'center',
      end:     'flex-end',
      between: 'space-between',
      around:  'space-around',
    }
    const alignMap: Record<string, string> = {
      start:   'flex-start',
      center:  'center',
      end:     'flex-end',
      stretch: 'stretch',
    }
    return () =>
      h('div', {
        class: 'a2ui-row',
        style: {
          display: 'flex',
          flexDirection: 'row',
          gap: props.gap,
          alignItems: alignMap[props.align] ?? 'center',
          justifyContent: justifyMap[props.justify] ?? 'flex-start',
          flexWrap: props.wrap ? 'wrap' : 'nowrap',
        },
      }, slots.default?.())
  },
})

// ── Column ────────────────────────────────────────────────────────────────

export const A2Column = defineComponent({
  name: 'A2Column',
  props: {
    gap:   { type: String, default: '8px' },
    align: { type: String as PropType<'start' | 'center' | 'end' | 'stretch'>, default: 'stretch' },
    flex:  { type: Number, default: 0 },  // flex-grow weight
  },
  setup(props, { slots }) {
    return () =>
      h('div', {
        class: 'a2ui-column',
        style: {
          display: 'flex',
          flexDirection: 'column',
          gap: props.gap,
          alignItems: props.align === 'stretch'
            ? 'stretch'
            : props.align === 'center'
            ? 'center'
            : props.align === 'end'
            ? 'flex-end'
            : 'flex-start',
          flex: props.flex > 0 ? props.flex : undefined,
        },
      }, slots.default?.())
  },
})

// ── List ──────────────────────────────────────────────────────────────────

export const A2List = defineComponent({
  name: 'A2List',
  setup(_, { slots }) {
    return () =>
      h('div', { class: 'a2ui-list' }, slots.default?.())
  },
})

// ── Modal ─────────────────────────────────────────────────────────────────

export const A2Modal = defineComponent({
  name: 'A2Modal',
  props: {
    open:  { type: Boolean, default: false },
    title: { type: String, default: '' },
  },
  emits: ['close'],
  setup(props, { slots, emit }) {
    return () =>
      props.open
        ? h('div', { class: 'a2ui-modal-overlay', onClick: () => emit('close') }, [
            h('div', { class: 'a2ui-modal', onClick: (e: Event) => e.stopPropagation() }, [
              props.title && h('div', { class: 'a2ui-modal__header' }, [
                h('h2', { class: 'a2ui-modal__title' }, props.title),
                h('button', { class: 'a2ui-modal__close', onClick: () => emit('close') }, '×'),
              ]),
              h('div', { class: 'a2ui-modal__body' }, slots.default?.()),
            ]),
          ])
        : null
  },
})

// ── Default Catalog ───────────────────────────────────────────────────────

export const DEFAULT_CATALOG: Record<string, unknown> = {
  Text:          A2Text,
  Button:        A2Button,
  TextField:     A2TextField,
  CheckBox:      A2CheckBox,
  Slider:        A2Slider,
  ChoicePicker:  A2ChoicePicker,
  MultipleChoice:A2ChoicePicker,  // alias
  DateTimeInput: A2DateTimeInput,
  Image:         A2Image,
  Icon:          A2Icon,
  Divider:       A2Divider,
  Card:          A2Card,
  Row:           A2Row,
  Column:        A2Column,
  List:          A2List,
  Modal:         A2Modal,
}

FILEOF_src_components_catalog_index_ts

cat > a2ui-vue-renderer/src/composables/useA2UIState.ts << 'FILEOF_src_composables_useA2UIState_ts'
/**
 * useA2UIState — Core state composable
 *
 * Manages surfaces, components, and data models with Vue 3 reactivity.
 * Mirrors the React renderer's state management, adapted for Vue patterns.
 */
import { reactive, readonly } from 'vue'
import type {
  A2UIMessage,
  Surface,
  BeginRenderingMessage,
  SurfaceUpdateMessage,
  DataModelUpdateMessage,
  DeleteSurfaceMessage,
  ComponentUpdate,
} from '../types'
import { set } from '../utils/jsonPointer'

export function useA2UIState() {
  // All surfaces keyed by surfaceId
  const surfaces = reactive<Record<string, Surface>>({})
  // Message buffer: components arriving before beginRendering
  const componentBuffer = new Map<string, Map<string, ComponentUpdate>>()

  // ── Message Dispatcher ─────────────────────────────────────────────────

  function dispatch(msg: A2UIMessage) {
    switch (msg.type) {
      case 'beginRendering':   return handleBeginRendering(msg)
      case 'surfaceUpdate':    return handleSurfaceUpdate(msg)
      case 'dataModelUpdate':  return handleDataModelUpdate(msg)
      case 'deleteSurface':    return handleDeleteSurface(msg)
    }
  }

  function dispatchAll(messages: A2UIMessage[]) {
    for (const msg of messages) dispatch(msg)
  }

  // ── Handlers ───────────────────────────────────────────────────────────

  function handleBeginRendering(msg: BeginRenderingMessage) {
    const buffered = componentBuffer.get(msg.surfaceId) ?? new Map()
    componentBuffer.delete(msg.surfaceId)

    surfaces[msg.surfaceId] = {
      id: msg.surfaceId,
      rootComponentId: msg.rootComponentId,
      components: buffered,
      dataModel: {},
      theme: msg.theme,
      isReady: true,
    }
  }

  function handleSurfaceUpdate(msg: SurfaceUpdateMessage) {
    const surface = surfaces[msg.surfaceId]

    if (!surface) {
      // Surface not yet created — buffer the components
      if (!componentBuffer.has(msg.surfaceId)) {
        componentBuffer.set(msg.surfaceId, new Map())
      }
      const buf = componentBuffer.get(msg.surfaceId)!
      for (const comp of msg.components) {
        buf.set(comp.id, comp)
      }
      return
    }

    for (const comp of msg.components) {
      surface.components.set(comp.id, comp)
    }
  }

  function handleDataModelUpdate(msg: DataModelUpdateMessage) {
    const surface = surfaces[msg.surfaceId]
    if (!surface) return

    for (const update of msg.updates) {
      const value =
        update.valueString  !== undefined ? update.valueString  :
        update.valueNumber  !== undefined ? update.valueNumber  :
        update.valueBoolean !== undefined ? update.valueBoolean :
        update.valueMap     !== undefined ? update.valueMap     :
        update.valueList    !== undefined ? update.valueList    :
        undefined

      if (value !== undefined) {
        surface.dataModel = set(surface.dataModel, `/${update.key}`, value)
      }
    }
  }

  function handleDeleteSurface(msg: DeleteSurfaceMessage) {
    delete surfaces[msg.surfaceId]
    componentBuffer.delete(msg.surfaceId)
  }

  // ── Data model write-back (from user interactions) ─────────────────────

  function updateDataPath(surfaceId: string, path: string, value: unknown) {
    const surface = surfaces[surfaceId]
    if (!surface) return
    surface.dataModel = set(surface.dataModel, path, value)
  }

  // ── Reset ──────────────────────────────────────────────────────────────

  function reset() {
    for (const key of Object.keys(surfaces)) delete surfaces[key]
    componentBuffer.clear()
  }

  return {
    surfaces: readonly(surfaces),
    dispatch,
    dispatchAll,
    updateDataPath,
    reset,
  }
}

FILEOF_src_composables_useA2UIState_ts

cat > a2ui-vue-renderer/src/composables/useA2UIStream.ts << 'FILEOF_src_composables_useA2UIStream_ts'
/**
 * useA2UIStream — JSONL streaming composable
 *
 * Connects to an agent endpoint via fetch + ReadableStream,
 * parses JSONL line-by-line, and dispatches A2UI messages.
 */
import { ref } from 'vue'
import type { A2UIMessage, ClientCapabilities, UserActionMessage } from '../types'

interface UseStreamOptions {
  onMessage: (msg: A2UIMessage) => void
  onError?: (err: Error) => void
  capabilities?: Partial<ClientCapabilities>
}

export function useA2UIStream(options: UseStreamOptions) {
  const isStreaming = ref(false)
  const error = ref<Error | null>(null)
  let abortController: AbortController | null = null

  async function send(agentUrl: string, action: UserActionMessage | { message: string }) {
    // Abort any in-flight stream
    abortController?.abort()
    abortController = new AbortController()

    isStreaming.value = true
    error.value = null

    try {
      const res = await fetch(agentUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/x-ndjson, application/jsonl',
          'X-A2UI-Version': '0.8',
          'X-A2UI-Catalogs': JSON.stringify(
            options.capabilities?.supportedCatalogIds ?? ['basic']
          ),
        },
        body: JSON.stringify(action),
        signal: abortController.signal,
      })

      if (!res.ok) {
        throw new Error(`Agent responded with ${res.status}: ${res.statusText}`)
      }

      if (!res.body) {
        throw new Error('Response has no body — expected JSONL stream')
      }

      await parseJSONLStream(res.body)
    } catch (err: unknown) {
      if ((err as { name: string }).name === 'AbortError') return
      const e = err instanceof Error ? err : new Error(String(err))
      error.value = e
      options.onError?.(e)
    } finally {
      isStreaming.value = false
    }
  }

  async function parseJSONLStream(body: ReadableStream<Uint8Array>) {
    const reader = body.getReader()
    const decoder = new TextDecoder()
    let buffer = ''

    while (true) {
      const { done, value } = await reader.read()
      if (done) break

      buffer += decoder.decode(value, { stream: true })

      // Split on newlines — each line is one JSON message
      const lines = buffer.split('\n')
      buffer = lines.pop() ?? ''   // keep incomplete line in buffer

      for (const line of lines) {
        const trimmed = line.trim()
        if (!trimmed) continue
        try {
          const msg = JSON.parse(trimmed) as A2UIMessage
          options.onMessage(msg)
        } catch (e) {
          console.warn('[A2UI] Failed to parse JSONL line:', trimmed, e)
        }
      }
    }

    // Flush any remaining content
    if (buffer.trim()) {
      try {
        const msg = JSON.parse(buffer) as A2UIMessage
        options.onMessage(msg)
      } catch { /* ignore trailing garbage */ }
    }
  }

  function abort() {
    abortController?.abort()
    isStreaming.value = false
  }

  return { isStreaming, error, send, abort }
}

FILEOF_src_composables_useA2UIStream_ts

cat > a2ui-vue-renderer/src/index.ts << 'FILEOF_src_index_ts'
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

FILEOF_src_index_ts

cat > a2ui-vue-renderer/src/styles.css << 'FILEOF_src_styles_css'
/**
 * A2UI Vue Renderer — Default Styles
 * Import in your app: import 'a2ui-vue/dist/style.css'
 */

/* ── Base variables ──────────────────────────────────────────────────────── */
:root {
  --a2ui-primary:       #1976d2;
  --a2ui-primary-hover: #1565c0;
  --a2ui-danger:        #d32f2f;
  --a2ui-radius:        8px;
  --a2ui-font:          -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  --a2ui-surface-bg:    #ffffff;
  --a2ui-border:        #e0e0e0;
  --a2ui-text:          #212121;
  --a2ui-text-muted:    #757575;
  --a2ui-gap:           8px;
  --a2ui-shadow-1:      0 1px 3px rgba(0,0,0,.12), 0 1px 2px rgba(0,0,0,.24);
  --a2ui-shadow-2:      0 3px 6px rgba(0,0,0,.16), 0 3px 6px rgba(0,0,0,.23);
}

/* Dark theme */
.a2ui-theme--dark {
  --a2ui-surface-bg: #1e1e1e;
  --a2ui-border:     #424242;
  --a2ui-text:       #f5f5f5;
  --a2ui-text-muted: #9e9e9e;
}

/* ── Renderer wrapper ─────────────────────────────────────────────────────── */
.a2ui-renderer {
  font-family: var(--a2ui-font);
  color: var(--a2ui-text);
  width: 100%;
}

.a2ui-surface {
  background: var(--a2ui-surface-bg);
  border-radius: var(--a2ui-radius);
  padding: 16px;
}

.a2ui-renderer__loading,
.a2ui-renderer__error,
.a2ui-renderer__empty {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 24px;
  color: var(--a2ui-text-muted);
  font-size: 14px;
}
.a2ui-renderer__error { color: var(--a2ui-danger); }

/* ── Spinner ─────────────────────────────────────────────────────────────── */
.a2ui-spinner {
  width: 18px; height: 18px;
  border: 2px solid var(--a2ui-border);
  border-top-color: var(--a2ui-primary);
  border-radius: 50%;
  animation: a2ui-spin 0.7s linear infinite;
  display: inline-block;
  flex-shrink: 0;
}
@keyframes a2ui-spin { to { transform: rotate(360deg); } }

/* ── Typography ──────────────────────────────────────────────────────────── */
.a2ui-text { margin: 0; padding: 0; }
.a2ui-text--headline { font-size: 28px; font-weight: 700; line-height: 1.2; }
.a2ui-text--title    { font-size: 20px; font-weight: 600; line-height: 1.3; }
.a2ui-text--body     { font-size: 15px; line-height: 1.6; }
.a2ui-text--caption  { font-size: 12px; color: var(--a2ui-text-muted); }

/* ── Button ──────────────────────────────────────────────────────────────── */
.a2ui-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 8px 18px;
  font-size: 14px;
  font-weight: 500;
  border-radius: var(--a2ui-radius);
  cursor: pointer;
  border: none;
  transition: background 0.15s, box-shadow 0.15s;
  white-space: nowrap;
}
.a2ui-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.a2ui-btn--filled  { background: var(--a2ui-primary); color: #fff; }
.a2ui-btn--filled:hover:not(:disabled)   { background: var(--a2ui-primary-hover); }
.a2ui-btn--outlined {
  background: transparent;
  color: var(--a2ui-primary);
  border: 1.5px solid var(--a2ui-primary);
}
.a2ui-btn--outlined:hover:not(:disabled) { background: rgba(25,118,210,.08); }
.a2ui-btn--text {
  background: transparent;
  color: var(--a2ui-primary);
}
.a2ui-btn--text:hover:not(:disabled) { background: rgba(25,118,210,.08); }

/* ── Form fields ─────────────────────────────────────────────────────────── */
.a2ui-field,
.a2ui-datetime,
.a2ui-choice { display: flex; flex-direction: column; gap: 4px; }

.a2ui-field__label,
.a2ui-datetime__label,
.a2ui-choice__label {
  font-size: 13px;
  font-weight: 500;
  color: var(--a2ui-text-muted);
}

.a2ui-field__input,
.a2ui-datetime__input,
.a2ui-choice__select {
  padding: 9px 12px;
  border: 1.5px solid var(--a2ui-border);
  border-radius: calc(var(--a2ui-radius) / 1.5);
  font-size: 14px;
  color: var(--a2ui-text);
  background: var(--a2ui-surface-bg);
  outline: none;
  transition: border-color 0.15s;
}
.a2ui-field__input:focus,
.a2ui-datetime__input:focus,
.a2ui-choice__select:focus {
  border-color: var(--a2ui-primary);
  box-shadow: 0 0 0 3px rgba(25,118,210,.15);
}

/* ── Checkbox ────────────────────────────────────────────────────────────── */
.a2ui-checkbox {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  font-size: 14px;
}
.a2ui-checkbox input { width: 16px; height: 16px; cursor: pointer; }

/* ── Slider ──────────────────────────────────────────────────────────────── */
.a2ui-slider {
  -webkit-appearance: none;
  width: 100%;
  height: 4px;
  border-radius: 2px;
  background: var(--a2ui-border);
  outline: none;
  Claude Code: pointer;
}
.a2ui-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  width: 18px; height: 18px;
  border-radius: 50%;
  background: var(--a2ui-primary);
}

/* ── Card ────────────────────────────────────────────────────────────────── */
.a2ui-card {
  background: var(--a2ui-surface-bg);
  border-radius: var(--a2ui-radius);
  border: 1px solid var(--a2ui-border);
}
.a2ui-card--elevation-1 { box-shadow: var(--a2ui-shadow-1); }
.a2ui-card--elevation-2 { box-shadow: var(--a2ui-shadow-2); }

/* ── Layout ──────────────────────────────────────────────────────────────── */
.a2ui-row    { display: flex; flex-direction: row; }
.a2ui-column { display: flex; flex-direction: column; }
.a2ui-list   { display: flex; flex-direction: column; gap: var(--a2ui-gap); }

/* ── Divider ─────────────────────────────────────────────────────────────── */
.a2ui-divider {
  border: none;
  border-top: 1px solid var(--a2ui-border);
  margin: 8px 0;
}

/* ── Image ───────────────────────────────────────────────────────────────── */
.a2ui-image { display: block; max-width: 100%; border-radius: calc(var(--a2ui-radius) / 2); }

/* ── Modal ───────────────────────────────────────────────────────────────── */
.a2ui-modal-overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,.5);
  display: flex; align-items: center; justify-content: center;
  z-index: 1000;
}
.a2ui-modal {
  background: var(--a2ui-surface-bg);
  border-radius: var(--a2ui-radius);
  min-width: 320px;
  max-width: 90vw;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: var(--a2ui-shadow-2);
}
.a2ui-modal__header {
  display: flex; align-items: center; justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid var(--a2ui-border);
}
.a2ui-modal__title { margin: 0; font-size: 18px; font-weight: 600; }
.a2ui-modal__close {
  background: none; border: none; cursor: pointer;
  font-size: 22px; color: var(--a2ui-text-muted);
  line-height: 1;
}
.a2ui-modal__body { padding: 20px; }

FILEOF_src_styles_css

cat > a2ui-vue-renderer/src/types/index.ts << 'FILEOF_src_types_index_ts'
/**
 * A2UI Protocol v0.8 TypeScript Types
 * Reference: https://a2ui.org/specification/v0.8-a2ui/
 */

// ─── Server → Client Messages ──────────────────────────────────────────────

export type A2UIMessage =
  | BeginRenderingMessage
  | SurfaceUpdateMessage
  | DataModelUpdateMessage
  | DeleteSurfaceMessage

export interface BeginRenderingMessage {
  type: 'beginRendering'
  surfaceId: string
  rootComponentId: string
  catalogId?: string
  theme?: Record<string, string>
}

export interface SurfaceUpdateMessage {
  type: 'surfaceUpdate'
  surfaceId: string
  components: ComponentUpdate[]
}

export interface DataModelUpdateMessage {
  type: 'dataModelUpdate'
  surfaceId: string
  updates: DataModelUpdate[]
}

export interface DeleteSurfaceMessage {
  type: 'deleteSurface'
  surfaceId: string
}

// ─── Component Definitions (Adjacency List Model) ──────────────────────────

export interface ComponentUpdate {
  id: string
  type: ComponentType
  children?: ChildList
  [prop: string]: unknown
}

export type ChildList =
  | { explicitList: string[] }               // static list of child IDs
  | { template: TemplateChildList }          // dynamic list from data

export interface TemplateChildList {
  dataBinding: BoundValue                    // points to an array in data model
  templateComponentId: string               // component ID to repeat
}

// ─── Data Model ─────────────────────────────────────────────────────────────

export interface DataModelUpdate {
  key: string
  valueString?: string
  valueNumber?: number
  valueBoolean?: boolean
  valueMap?: Record<string, unknown>
  valueList?: unknown[]
}

// ─── Bound Values ────────────────────────────────────────────────────────────

export type BoundValue =
  | { literalString: string }
  | { literalNumber: number }
  | { literalBoolean: boolean }
  | { path: string; surfaceId?: string }    // JSON Pointer path

// ─── Component Types ─────────────────────────────────────────────────────────

export type ComponentType =
  // Layout
  | 'Row'
  | 'Column'
  | 'List'
  // Display
  | 'Text'
  | 'Image'
  | 'Icon'
  | 'Divider'
  // Interactive
  | 'Button'
  | 'TextField'
  | 'CheckBox'
  | 'Slider'
  | 'DateTimeInput'
  | 'ChoicePicker'
  | 'MultipleChoice'
  // Container
  | 'Card'
  | 'Modal'
  | 'Tabs'
  | string  // extensible for custom catalogs

// ─── Client → Server Messages ────────────────────────────────────────────────

export interface UserActionMessage {
  type: 'userAction'
  surfaceId: string
  actionId: string
  context?: Record<string, unknown>
  dataModel?: Record<string, unknown>  // when sendDataModel: true
}

export interface ClientCapabilities {
  supportedCatalogIds: string[]
  version: string
}

// ─── Internal State ──────────────────────────────────────────────────────────

export interface Surface {
  id: string
  rootComponentId: string
  components: Map<string, ComponentUpdate>
  dataModel: Record<string, unknown>
  theme?: Record<string, string>
  isReady: boolean
}

export interface A2UIRendererProps {
  /** Connect to an agent endpoint (URL) */
  agentUrl?: string
  /** Or directly receive parsed messages */
  messages?: A2UIMessage[]
  /** Component catalog override — maps type → Vue component */
  catalog?: Record<string, unknown>
  /** Called when user triggers an action */
  onAction?: (action: UserActionMessage) => void
  /** Called when renderer encounters an error */
  onError?: (err: Error) => void
  /** Client capabilities sent to agent */
  capabilities?: Partial<ClientCapabilities>
}

FILEOF_src_types_index_ts

cat > a2ui-vue-renderer/src/utils/boundValue.ts << 'FILEOF_src_utils_boundValue_ts'
/**
 * Resolve BoundValue objects against a surface's data model.
 * Handles both literal values and JSON Pointer path references.
 */
import type { BoundValue } from '../types'
import { get } from './jsonPointer'

export function resolveBoundValue(
  value: BoundValue | undefined,
  dataModel: Record<string, unknown>,
  scopePath?: string
): unknown {
  if (value == null) return undefined

  if ('literalString' in value) return value.literalString
  if ('literalNumber' in value) return value.literalNumber
  if ('literalBoolean' in value) return value.literalBoolean

  if ('path' in value) {
    // scope path used in dynamic list templates
    const pointer = scopePath
      ? scopePath.replace(/\/$/, '') + value.path
      : value.path
    return get(dataModel, pointer)
  }

  return undefined
}

/**
 * Resolve all BoundValues in a component's props.
 * Recursively processes nested objects.
 */
export function resolveProps(
  rawProps: Record<string, unknown>,
  dataModel: Record<string, unknown>,
  scopePath?: string
): Record<string, unknown> {
  const resolved: Record<string, unknown> = {}
  for (const [key, val] of Object.entries(rawProps)) {
    if (key === 'id' || key === 'type' || key === 'children') continue
    if (isBoundValue(val)) {
      resolved[key] = resolveBoundValue(val as BoundValue, dataModel, scopePath)
    } else if (val && typeof val === 'object' && !Array.isArray(val)) {
      resolved[key] = resolveProps(
        val as Record<string, unknown>,
        dataModel,
        scopePath
      )
    } else {
      resolved[key] = val
    }
  }
  return resolved
}

function isBoundValue(val: unknown): boolean {
  if (val == null || typeof val !== 'object') return false
  const keys = Object.keys(val as object)
  return (
    keys.includes('literalString') ||
    keys.includes('literalNumber') ||
    keys.includes('literalBoolean') ||
    keys.includes('path')
  )
}

FILEOF_src_utils_boundValue_ts

cat > a2ui-vue-renderer/src/utils/jsonPointer.ts << 'FILEOF_src_utils_jsonPointer_ts'
/**
 * RFC 6901 JSON Pointer utilities
 * Used for A2UI data binding path resolution
 */

/**
 * Resolve a JSON Pointer path against an object.
 * e.g. get({ a: { b: 1 } }, '/a/b') → 1
 */
export function get(obj: Record<string, unknown>, pointer: string): unknown {
  if (!pointer || pointer === '/') return obj
  const tokens = parsePointer(pointer)
  let current: unknown = obj
  for (const token of tokens) {
    if (current == null || typeof current !== 'object') return undefined
    current = (current as Record<string, unknown>)[token]
  }
  return current
}

/**
 * Set a value at a JSON Pointer path (immutable — returns new object).
 */
export function set(
  obj: Record<string, unknown>,
  pointer: string,
  value: unknown
): Record<string, unknown> {
  if (!pointer || pointer === '/') return value as Record<string, unknown>
  const tokens = parsePointer(pointer)
  return setDeep(obj, tokens, value) as Record<string, unknown>
}

function setDeep(
  current: unknown,
  tokens: string[],
  value: unknown
): unknown {
  if (tokens.length === 0) return value
  const [head, ...rest] = tokens
  const isArray = /^\d+$/.test(head)
  const base = (
    isArray
      ? Array.isArray(current) ? [...current] : []
      : { ...(current as object) }
  ) as Record<string, unknown>
  base[head] = setDeep(base[head], rest, value)
  return base
}

/**
 * Parse a JSON Pointer string into an array of reference tokens.
 * RFC 6901: '~1' → '/', '~0' → '~'
 */
function parsePointer(pointer: string): string[] {
  if (!pointer.startsWith('/')) {
    throw new Error(`Invalid JSON Pointer: "${pointer}" — must start with /`)
  }
  return pointer
    .slice(1)
    .split('/')
    .map(t => t.replace(/~1/g, '/').replace(/~0/g, '~'))
}

/**
 * Build a scoped pointer for dynamic list templates.
 * e.g. scope('/items', '/name') → '/items/name'
 */
export function scopePointer(basePointer: string, relativePointer: string): string {
  if (!relativePointer.startsWith('/')) return basePointer
  return basePointer.replace(/\/$/, '') + relativePointer
}

FILEOF_src_utils_jsonPointer_ts

cat > a2ui-vue-renderer/vite.config.js << 'FILEOF_vite_config_js'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

// Library build config
export default defineConfig({
  plugins: [vue()],
  build: {
    lib: {
      entry: resolve(__dirname, 'src/index.ts'),
      name: 'A2UIVue',
      formats: ['es', 'cjs'],
      fileName: (format) => `index.${format === 'es' ? 'js' : 'cjs'}`,
    },
    rollupOptions: {
      external: ['vue'],
      output: {
        globals: { vue: 'Vue' },
      },
    },
  },
})

FILEOF_vite_config_js

cat > a2ui-vue-renderer/vite.demo.config.js << 'FILEOF_vite_demo_config_js'
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

FILEOF_vite_demo_config_js

echo ""
echo "✅ 文件创建完成！"
echo ""
echo "启动 Demo:"
echo "  cd a2ui-vue-renderer && npm install && npm run demo"
echo "  浏览器打开 http://localhost:5200"
