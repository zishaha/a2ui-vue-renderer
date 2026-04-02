# 🦾 A2UI Vue Renderer

**Vue 3 implementation of the A2UI (Agent-to-User Interface) protocol**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Vue 3](https://img.shields.io/badge/vue-3.x-brightgreen.svg)](https://vuejs.org/)
[![TypeScript](https://img.shields.io/badge/typescript-5.x-blue.svg)](https://www.typescriptlang.org/)

A production-ready Vue 3 renderer that enables AI agents to dynamically generate interactive user interfaces using declarative JSON messages instead of executable code.

[Live Demo](https://zishaha.github.io/a2ui-vue-renderer) • [A2UI Specification](https://a2ui.org/) • [Report Issue](https://github.com/zishaha/a2ui-vue-renderer/issues)

---

## 📖 Table of Contents

- [What is A2UI?](#what-is-a2ui)
- [Architecture Overview](#architecture-overview)
- [How This Renderer Works](#how-this-renderer-works)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Demo Scenarios](#demo-scenarios)
- [API Reference](#api-reference)
- [Development](#development)
- [Testing](#testing)
- [Contributing](#contributing)

---

## 🤔 What is A2UI?

**A2UI (Agent-to-User Interface)** is an open protocol developed by Google that solves a fundamental problem in AI applications: **how can AI agents efficiently collect structured information from users?**

### The Problem

Traditional chatbots suffer from the "chat wall" problem:

```
User: I want to book a flight
AI: What's your departure city?
User: Beijing
AI: Destination?
User: Shanghai
AI: Date?
User: ...  (endless back-and-forth)
```

### The A2UI Solution

Instead of text-only responses, agents send **declarative UI descriptions** that clients render natively:

```json
{
  "type": "surfaceUpdate",
  "components": [
    { "id": "from", "type": "TextField", "label": "From" },
    { "id": "to", "type": "TextField", "label": "To" },
    { "id": "date", "type": "DateTimeInput" },
    { "id": "submit", "type": "Button", "label": "Search Flights" }
  ]
}
```

The client renders this as a **native form**, collects all inputs at once, and sends structured data back to the agent.

### Key Benefits

| Traditional Chat | A2UI |
|------------------|------|
| 10+ message rounds | 1 form submission |
| Unstructured text parsing | Structured JSON data |
| Poor mobile UX | Native UI components |
| Security risks (code injection) | Declarative, safe JSON |

---

## 🏗️ Architecture Overview

A2UI follows a **three-layer architecture**:

```
┌─────────────────────────────────────────────────────────┐
│                    AI Agent (Server)                     │
│  - Generates UI descriptions based on task context       │
│  - Sends A2UI messages (JSONL stream)                   │
└────────────────────┬────────────────────────────────────┘
                     │ A2UI Protocol (JSON messages)
                     ▼
┌─────────────────────────────────────────────────────────┐
│              A2UI Renderer (This Library)                │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 1. Message Processing Layer                      │   │
│  │    - Parse JSONL stream                          │   │
│  │    - Dispatch message types                      │   │
│  │    - Buffer until beginRendering                 │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 2. State Management Layer                        │   │
│  │    - Surface registry (multiple UIs)             │   │
│  │    - Component adjacency list                    │   │
│  │    - Data model (reactive state)                 │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 3. Rendering Layer                               │   │
│  │    - Resolve data bindings (JSON Pointer)        │   │
│  │    - Map A2UI types → Vue components             │   │
│  │    - Handle user interactions                    │   │
│  └─────────────────────────────────────────────────┘   │
└────────────────────┬────────────────────────────────────┘
                     │ Native Vue Components
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   User Interface (DOM)                   │
│  - Forms, buttons, date pickers, tables, etc.           │
│  - Fully interactive, accessible, responsive            │
└─────────────────────────────────────────────────────────┘
```


### Message Flow

```
Agent                    Renderer                   User
  │                         │                         │
  ├─ beginRendering ───────>│                         │
  ├─ surfaceUpdate ────────>│                         │
  ├─ dataModelUpdate ──────>│                         │
  │                         ├─ Render UI ───────────>│
  │                         │                         │
  │                         │<─ User fills form ──────┤
  │                         │                         │
  │<─ userAction ───────────┤<─ Click submit ────────┤
  │                         │                         │
  ├─ surfaceUpdate ────────>│ (update with results)  │
```

---

## 🔧 How This Renderer Works

### 1. Message Processing

The renderer consumes **JSONL streams** (newline-delimited JSON) from agents:

```typescript
import { A2UIRenderer } from 'a2ui-vue'

<A2UIRenderer 
  agentUrl="https://your-agent.com/api"
  @action="handleUserAction"
/>
```

Four message types are handled:

| Message Type | Purpose |
|--------------|---------|
| `beginRendering` | Signals start of rendering, provides surface ID and root component |
| `surfaceUpdate` | Adds/updates components in the adjacency list |
| `dataModelUpdate` | Updates reactive data bindings |
| `deleteSurface` | Removes a UI surface |

### 2. Component Adjacency List

A2UI uses a **flat adjacency list** instead of nested trees, making it easier for LLMs to generate:

```json
{
  "type": "surfaceUpdate",
  "surfaceId": "main",
  "components": [
    { "id": "root", "type": "Column", "children": { "explicitList": ["field1", "btn1"] } },
    { "id": "field1", "type": "TextField", "label": "Name" },
    { "id": "btn1", "type": "Button", "label": "Submit", "actionId": "submit" }
  ]
}
```

The renderer:
1. Stores components in a `Map<id, ComponentUpdate>`
2. Recursively renders starting from `rootComponentId`
3. Resolves child references via IDs

### 3. Data Binding (JSON Pointer)

Components can bind to reactive data using **RFC 6901 JSON Pointer** paths:

```json
{
  "type": "dataModelUpdate",
  "surfaceId": "main",
  "updates": [
    { "key": "user", "valueMap": { "name": "Alice", "age": 30 } }
  ]
}
```

```json
{
  "id": "greeting",
  "type": "Text",
  "text": { "path": "/user/name" }
}
```

Renders as: `<span>Alice</span>`

When data updates, Vue's reactivity automatically re-renders bound components.

### 4. Dynamic Lists (Template Children)

For rendering arrays, A2UI supports **template-based repetition**:

```json
{
  "id": "productList",
  "type": "Column",
  "children": {
    "template": {
      "dataBinding": { "path": "/products" },
      "templateComponentId": "productCard"
    }
  }
}
```

The renderer:
1. Reads the array at `/products`
2. Renders `productCard` once per item
3. Provides scoped data context for each iteration

### 5. User Actions

When users interact (click button, submit form), the renderer sends `userAction` messages back:

```json
{
  "type": "userAction",
  "surfaceId": "main",
  "actionId": "submit",
  "dataModel": {
    "name": "Alice",
    "email": "alice@example.com"
  }
}
```

The agent receives structured data and can respond with new UI updates.

---

## 📦 Installation

```bash
npm install a2ui-vue
# or
yarn add a2ui-vue
# or
pnpm add a2ui-vue
```

**Requirements:**
- Vue 3.4+
- TypeScript 5.0+ (optional but recommended)

---

## 🚀 Quick Start

### Basic Usage

```vue
<script setup lang="ts">
import { A2UIRenderer } from 'a2ui-vue'
import type { UserActionMessage } from 'a2ui-vue'

function handleAction(action: UserActionMessage) {
  console.log('User action:', action)
  // Send to your agent backend
  fetch('/api/agent', {
    method: 'POST',
    body: JSON.stringify(action)
  })
}
</script>

<template>
  <A2UIRenderer 
    agentUrl="https://your-agent.com/stream"
    @action="handleAction"
    @error="console.error"
  />
</template>
```

### Static Messages (No Agent)

```vue
<script setup lang="ts">
import { ref } from 'vue'
import { A2UIRenderer } from 'a2ui-vue'
import type { A2UIMessage } from 'a2ui-vue'

const messages = ref<A2UIMessage[]>([
  {
    type: 'beginRendering',
    surfaceId: 'demo',
    rootComponentId: 'root'
  },
  {
    type: 'surfaceUpdate',
    surfaceId: 'demo',
    components: [
      { id: 'root', type: 'Column', children: { explicitList: ['text1', 'btn1'] } },
      { id: 'text1', type: 'Text', text: { literalString: 'Hello A2UI!' } },
      { id: 'btn1', type: 'Button', label: { literalString: 'Click Me' }, actionId: 'click' }
    ]
  }
])
</script>

<template>
  <A2UIRenderer :messages="messages" @action="console.log" />
</template>
```


---

## 🎨 Demo Scenarios

The included demo showcases three real-world A2UI use cases:

### ✈️ Flight Booking Form

**Demonstrates:** Form inputs, date pickers, dropdowns, button actions

**Key Features:**
- `TextField` for departure/arrival cities
- `DateTimeInput` for travel dates
- `ChoicePicker` for cabin class selection
- `Button` with `actionId` for form submission
- Data collection in a single interaction

**A2UI Concepts:**
- Static component layout (`explicitList` children)
- Literal values (`literalString`, `literalNumber`)
- Action handling with structured data payload

---

### 🛍️ Product List (Dynamic Template)

**Demonstrates:** Dynamic list rendering from data arrays

**Key Features:**
- Template-based repetition (`template` children)
- Data binding to `/products` array
- Per-item scoped context
- Add-to-cart button per product

**A2UI Concepts:**
- `TemplateChildList` for array iteration
- JSON Pointer data binding (`{ "path": "/products" }`)
- Dynamic UI generation based on data model

---

### 📝 Survey Form (Two-Way Binding)

**Demonstrates:** Reactive data binding and form state management

**Key Features:**
- Text inputs bound to data model paths
- Checkbox and radio button groups
- Slider with live value display
- Real-time data model updates

**A2UI Concepts:**
- Bidirectional data binding
- `dataModelUpdate` messages for state changes
- Form validation and submission

---

## 📚 API Reference

### `<A2UIRenderer>` Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `agentUrl` | `string?` | - | Agent endpoint URL (JSONL stream) |
| `messages` | `A2UIMessage[]?` | - | Static messages (alternative to `agentUrl`) |
| `catalog` | `Record<string, Component>?` | `{}` | Custom component catalog override |
| `capabilities` | `ClientCapabilities?` | - | Client capabilities sent to agent |
| `theme` | `string?` | `'light'` | UI theme (`'light'` \| `'dark'`) |

### Events

| Event | Payload | Description |
|-------|---------|-------------|
| `@action` | `UserActionMessage` | Emitted when user triggers an action (button click, form submit) |
| `@error` | `Error` | Emitted on rendering or stream errors |
| `@ready` | `string` (surfaceId) | Emitted when a surface finishes initial render |

### Composables

#### `useA2UIState()`

Manages surface registry, component adjacency list, and data model.

```typescript
const { surfaces, dispatch, updateDataPath, reset } = useA2UIState()
```

#### `useA2UIStream(options)`

Handles JSONL stream parsing and message dispatching.

```typescript
const { isStreaming, error, send, abort } = useA2UIStream({
  onMessage: (msg) => dispatch(msg),
  onError: (err) => console.error(err)
})
```


---

## 🛠️ Development

### Project Structure

```
a2ui-vue-renderer/
├── src/
│   ├── components/
│   │   ├── A2UIRenderer.vue      # Main renderer component
│   │   ├── A2UIComponent.ts      # Recursive component renderer
│   │   ├── A2UIContext.ts        # Vue provide/inject context
│   │   └── catalog/
│   │       └── index.ts          # Default component catalog
│   ├── composables/
│   │   ├── useA2UIState.ts       # State management
│   │   └── useA2UIStream.ts      # JSONL stream handling
│   ├── utils/
│   │   ├── boundValue.ts         # Data binding resolver
│   │   └── jsonPointer.ts        # RFC 6901 JSON Pointer
│   ├── types/
│   │   └── index.ts              # TypeScript type definitions
│   ├── styles.css                # Default component styles
│   └── index.ts                  # Public API exports
├── demo/
│   ├── App.vue                   # Demo application
│   ├── main.ts                   # Demo entry point
│   └── index.html                # Demo HTML template
└── src/__tests__/                # Unit tests (Vitest)
```

### Build Commands

```bash
# Install dependencies
npm install

# Run demo locally
npm run demo

# Build library for production
npm run build

# Run unit tests
npm test

# Run tests in watch mode
npm run test:watch

# Type check
npm run type-check
```


---

## 🧪 Testing

This project includes comprehensive unit tests using **Vitest** and **@vue/test-utils**.

### Test Coverage

- ✅ JSON Pointer resolution (`jsonPointer.test.ts`)
- ✅ Bound value resolution (`boundValue.test.ts`)
- ✅ State management (`useA2UIState.test.ts`)
- ✅ Message dispatching and surface updates
- ✅ Data model updates and reactivity

### Running Tests

```bash
# Run all tests
npm test

# Watch mode
npm run test:watch

# Coverage report
npm run test:coverage
```

**Current Status:** 44/44 tests passing ✅

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for new functionality
4. Ensure all tests pass (`npm test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🔗 Related Resources

- [A2UI Official Specification](https://a2ui.org/)
- [A2UI Protocol Blog Post](https://developers.googleblog.com/introducing-a2ui)
- [Vue 3 Documentation](https://vuejs.org/)
- [RFC 6901 JSON Pointer](https://datatracker.ietf.org/doc/html/rfc6901)

---

## 🙏 Acknowledgments

- **Google A2UI Team** for creating the protocol specification
- **Vue.js Core Team** for the excellent reactive framework
- **Anthropic** for Claude Code assistance in development

---

**Built with ❤️ using Vue 3 and TypeScript**

