<template>
  <div class="demo-app">
    <!-- Toast notification -->
    <div v-if="toast" :class="['demo-toast', toast.startsWith('⚠️') ? 'demo-toast--warn' : '']">{{ toast }}</div>

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
        <div class="demo-header-section">
          <h2>✈️ Flight Booking Form</h2>
          <p class="demo-desc">
            Simulates an Agent response that generates a flight booking UI with form inputs.
          </p>
        </div>

        <div class="demo-features">
          <div class="feature-card">
            <div class="feature-icon">📝</div>
            <div class="feature-title">Form Components</div>
            <div class="feature-desc">TextField, DateTimeInput, ChoicePicker</div>
          </div>
          <div class="feature-card">
            <div class="feature-icon">🎯</div>
            <div class="feature-title">Static Layout</div>
            <div class="feature-desc">explicitList children with literal values</div>
          </div>
          <div class="feature-card">
            <div class="feature-icon">🔘</div>
            <div class="feature-title">Action Handling</div>
            <div class="feature-desc">Button with actionId for form submission</div>
          </div>
        </div>

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
        <div class="demo-header-section">
          <h2>🛍️ Product List (Dynamic Template)</h2>
          <p class="demo-desc">
            Demonstrates dynamic list rendering from data arrays using template-based repetition.
          </p>
        </div>

        <div class="demo-features">
          <div class="feature-card">
            <div class="feature-icon">🔄</div>
            <div class="feature-title">Template Children</div>
            <div class="feature-desc">Repeat component per array item</div>
          </div>
          <div class="feature-card">
            <div class="feature-icon">🔗</div>
            <div class="feature-title">Data Binding</div>
            <div class="feature-desc">JSON Pointer paths to data model</div>
          </div>
          <div class="feature-card">
            <div class="feature-icon">⚡</div>
            <div class="feature-title">Dynamic UI</div>
            <div class="feature-desc">UI generated from data structure</div>
          </div>
        </div>

        <div class="demo-renderer">
          <A2UIRenderer
            :messages="productMessages"
            @action="onAction"
          />
        </div>
      </section>

      <!-- Data binding demo -->
      <section v-if="activeTab === 'form'" class="demo-section">
        <div class="demo-header-section">
          <h2>📝 Survey Form (Two-Way Binding)</h2>
          <p class="demo-desc">
            Demonstrates reactive data binding and real-time form state management.
          </p>
        </div>

        <div class="demo-features">
          <div class="feature-card">
            <div class="feature-icon">↔️</div>
            <div class="feature-title">Bidirectional Binding</div>
            <div class="feature-desc">Form inputs sync with data model</div>
          </div>
          <div class="feature-card">
            <div class="feature-icon">🔄</div>
            <div class="feature-title">Reactive Updates</div>
            <div class="feature-desc">Live data model changes</div>
          </div>
          <div class="feature-card">
            <div class="feature-icon">✅</div>
            <div class="feature-title">State Management</div>
            <div class="feature-desc">Form validation and submission</div>
          </div>
        </div>

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
const toast = ref<string | null>(null)

const tabs = [
  { id: 'flight',    label: '✈️ Flight Booking' },
  { id: 'product',   label: '🛍️ Product List' },
  { id: 'form',      label: '📝 Survey Form' },
  { id: 'inspector', label: '🔍 Inspector' },
]

function onAction(action: UserActionMessage) {
  lastAction.value = action
  console.log('[A2UI Demo] Action received:', action)

  // Show toast notification
  toast.value = `✅ Button clicked: ${action.actionId}`
  setTimeout(() => { toast.value = null }, 3000)
}

function applyCustom() {
  if (!customJsonl.value.trim()) {
    toast.value = '⚠️ 请先输入 JSONL 消息内容'
    setTimeout(() => { toast.value = null }, 3000)
    return
  }
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

.demo-app { max-width: 860px; margin: 0 auto; padding: 32px 20px 64px; position: relative; }

.demo-toast {
  position: fixed; top: 20px; left: 50%; transform: translateX(-50%);
  background: #4CAF50; color: white; padding: 12px 24px;
  border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,.15);
  font-size: 15px; font-weight: 500; z-index: 9999;
  animation: slideDown 0.3s ease;
}
.demo-toast--warn { background: #f59e0b; }
@keyframes slideDown {
  from { opacity: 0; transform: translateX(-50%) translateY(-20px); }
  to { opacity: 1; transform: translateX(-50%) translateY(0); }
}

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
  cursor: pointer; color: #555;
  transition: background .15s, color .15s;
}
.demo-tab.active { background: #1976d2; color: #fff; }

.demo-section {}

.demo-header-section { margin-bottom: 20px; }
.demo-section h2 { font-size: 22px; font-weight: 700; margin-bottom: 8px; color: #1a1a1a; }
.demo-desc { color: #666; font-size: 14px; line-height: 1.6; }

.demo-features {
  display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 12px; margin-bottom: 24px;
}
.feature-card {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white; padding: 16px; border-radius: 12px;
  box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
  transition: transform 0.2s, box-shadow 0.2s;
}
.feature-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}
.feature-icon { font-size: 28px; margin-bottom: 8px; }
.feature-title { font-size: 14px; font-weight: 600; margin-bottom: 4px; }
.feature-desc { font-size: 12px; opacity: 0.9; line-height: 1.4; }

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
  cursor: pointer; font-size: 14px;
  margin-bottom: 16px;
}
.demo-btn:hover { background: #1565c0; }
</style>
