# 🦾 A2UI Vue 渲染器

**A2UI（Agent-to-User Interface）协议的 Vue 3 实现**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Vue 3](https://img.shields.io/badge/vue-3.x-brightgreen.svg)](https://vuejs.org/)
[![TypeScript](https://img.shields.io/badge/typescript-5.x-blue.svg)](https://www.typescriptlang.org/)

一个生产就绪的 Vue 3 渲染器，使 AI 代理能够使用声明式 JSON 消息而非可执行代码动态生成交互式用户界面。

[在线演示](https://zishaha.github.io/a2ui-vue-renderer) • [A2UI 规范](https://a2ui.org/) • [报告问题](https://github.com/zishaha/a2ui-vue-renderer/issues)

---

## 📖 目录

- [什么是 A2UI？](#什么是-a2ui)
- [架构概览](#架构概览)
- [渲染器工作原理](#渲染器工作原理)
- [安装](#安装)
- [快速开始](#快速开始)
- [演示场景](#演示场景)
- [API 参考](#api-参考)
- [开发](#开发)
- [测试](#测试)
- [贡献](#贡献)

---

## 🤔 什么是 A2UI？

**A2UI（Agent-to-User Interface）** 是由 Google 开发的开放协议，解决了 AI 应用中的一个基本问题：**AI 代理如何高效地从用户那里收集结构化信息？**

### 问题所在

传统聊天机器人存在"聊天墙"问题：

```
用户：我想预订航班
AI：您的出发城市是？
用户：北京
AI：目的地呢？
用户：上海
AI：日期呢？
用户：...（无休止的来回对话）
```

### A2UI 解决方案

代理不再只发送文本响应，而是发送**声明式 UI 描述**，客户端原生渲染：

```json
{
  "type": "surfaceUpdate",
  "components": [
    { "id": "from", "type": "TextField", "label": "出发地" },
    { "id": "to", "type": "TextField", "label": "目的地" },
    { "id": "date", "type": "DateTimeInput" },
    { "id": "submit", "type": "Button", "label": "搜索航班" }
  ]
}
```

客户端将其渲染为**原生表单**，一次性收集所有输入，并将结构化数据发送回代理。

### 主要优势

| 传统聊天 | A2UI |
|---------|------|
| 10+ 轮消息 | 1 次表单提交 |
| 非结构化文本解析 | 结构化 JSON 数据 |
| 移动端用户体验差 | 原生 UI 组件 |
| 安全风险（代码注入） | 声明式、安全的 JSON |

---

## 🏗️ 架构概览

A2UI 遵循**三层架构**：

```
┌─────────────────────────────────────────────────────────┐
│                    AI 代理（服务端）                      │
│  - 根据任务上下文生成 UI 描述                             │
│  - 发送 A2UI 消息（JSONL 流）                            │
└────────────────────┬────────────────────────────────────┘
                     │ A2UI 协议（JSON 消息）
                     ▼
┌─────────────────────────────────────────────────────────┐
│              A2UI 渲染器（本库）                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 1. 消息处理层                                     │   │
│  │    - 解析 JSONL 流                               │   │
│  │    - 分发消息类型                                 │   │
│  │    - 缓冲直到 beginRendering                     │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 2. 状态管理层                                     │   │
│  │    - Surface 注册表（多个 UI）                    │   │
│  │    - 组件邻接表                                   │   │
│  │    - 数据模型（响应式状态）                        │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 3. 渲染层                                         │   │
│  │    - 解析数据绑定（JSON Pointer）                 │   │
│  │    - 映射 A2UI 类型 → Vue 组件                    │   │
│  │    - 处理用户交互                                 │   │
│  └─────────────────────────────────────────────────┘   │
└────────────────────┬────────────────────────────────────┘
                     │ 原生 Vue 组件
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   用户界面（DOM）                         │
│  - 表单、按钮、日期选择器、表格等                          │
│  - 完全交互式、可访问、响应式                             │
└─────────────────────────────────────────────────────────┘
```


### 消息流

```
代理                    渲染器                   用户
  │                         │                         │
  ├─ beginRendering ───────>│                         │
  ├─ surfaceUpdate ────────>│                         │
  ├─ dataModelUpdate ──────>│                         │
  │                         ├─ 渲染 UI ───────────>│
  │                         │                         │
  │                         │<─ 用户填写表单 ──────┤
  │                         │                         │
  │<─ userAction ───────────┤<─ 点击提交 ────────┤
  │                         │                         │
  ├─ surfaceUpdate ────────>│ （更新结果）           │
```

---

## 🔧 渲染器工作原理

### 1. 消息处理

渲染器消费来自代理的 **JSONL 流**（换行符分隔的 JSON）：

```typescript
import { A2UIRenderer } from 'a2ui-vue'

<A2UIRenderer
  agentUrl="https://your-agent.com/api"
  @action="handleUserAction"
/>
```

处理四种消息类型：

| 消息类型 | 用途 |
|---------|------|
| `beginRendering` | 标志渲染开始，提供 surface ID 和根组件 |
| `surfaceUpdate` | 在邻接表中添加/更新组件 |
| `dataModelUpdate` | 更新响应式数据绑定 |
| `deleteSurface` | 移除 UI surface |

### 2. 组件邻接表

A2UI 使用**扁平邻接表**而非嵌套树，使 LLM 更容易生成：

```json
{
  "type": "surfaceUpdate",
  "surfaceId": "main",
  "components": [
    { "id": "root", "type": "Column", "children": { "explicitList": ["field1", "btn1"] } },
    { "id": "field1", "type": "TextField", "label": "姓名" },
    { "id": "btn1", "type": "Button", "label": "提交", "actionId": "submit" }
  ]
}
```

渲染器：
1. 将组件存储在 `Map<id, ComponentUpdate>` 中
2. 从 `rootComponentId` 开始递归渲染
3. 通过 ID 解析子组件引用

### 3. 数据绑定（JSON Pointer）

组件可以使用 **RFC 6901 JSON Pointer** 路径绑定到响应式数据：

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

渲染为：`<span>Alice</span>`

当数据更新时，Vue 的响应式系统会自动重新渲染绑定的组件。

### 4. 动态列表（模板子组件）

对于渲染数组，A2UI 支持**基于模板的重复**：

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

渲染器：
1. 读取 `/products` 处的数组
2. 为每个项目渲染一次 `productCard`
3. 为每次迭代提供作用域数据上下文

### 5. 用户操作

当用户交互（点击按钮、提交表单）时，渲染器发送 `userAction` 消息：

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

代理接收结构化数据，并可以响应新的 UI 更新。

---

## 📦 安装

```bash
npm install a2ui-vue
# 或
yarn add a2ui-vue
# 或
pnpm add a2ui-vue
```

**要求：**
- Vue 3.4+
- TypeScript 5.0+（可选但推荐）

---

## 🚀 快速开始

### 基本用法

```vue
<script setup lang="ts">
import { A2UIRenderer } from 'a2ui-vue'
import type { UserActionMessage } from 'a2ui-vue'

function handleAction(action: UserActionMessage) {
  console.log('用户操作:', action)
  // 发送到您的代理后端
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

### 静态消息（无代理）

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
      { id: 'text1', type: 'Text', text: { literalString: '你好 A2UI！' } },
      { id: 'btn1', type: 'Button', label: { literalString: '点击我' }, actionId: 'click' }
    ]
  }
])
</script>

<template>
  <A2UIRenderer :messages="messages" @action="console.log" />
</template>
```


---

## 🎨 演示场景

包含的演示展示了三个真实世界的 A2UI 用例：

### ✈️ 航班预订表单

**演示：** 表单输入、日期选择器、下拉菜单、按钮操作

**主要功能：**
- 用于出发/到达城市的 `TextField`
- 用于旅行日期的 `DateTimeInput`
- 用于舱位选择的 `ChoicePicker`
- 带有 `actionId` 的 `Button` 用于表单提交
- 单次交互中的数据收集

**A2UI 概念：**
- 静态组件布局（`explicitList` 子组件）
- 字面值（`literalString`、`literalNumber`）
- 带有结构化数据负载的操作处理

---

### 🛍️ 产品列表（动态模板）

**演示：** 从数据数组动态列表渲染

**主要功能：**
- 基于模板的重复（`template` 子组件）
- 数据绑定到 `/products` 数组
- 每个项目的作用域上下文
- 每个产品的加入购物车按钮

**A2UI 概念：**
- 用于数组迭代的 `TemplateChildList`
- JSON Pointer 数据绑定（`{ "path": "/products" }`）
- 基于数据模型的动态 UI 生成

---

### 📝 调查表单（双向绑定）

**演示：** 响应式数据绑定和表单状态管理

**主要功能：**
- 绑定到数据模型路径的文本输入
- 复选框和单选按钮组
- 带有实时值显示的滑块
- 实时数据模型更新

**A2UI 概念：**
- 双向数据绑定
- 用于状态更改的 `dataModelUpdate` 消息
- 表单验证和提交

---

## 📚 API 参考

### `<A2UIRenderer>` 属性

| 属性 | 类型 | 默认值 | 描述 |
|-----|------|--------|------|
| `agentUrl` | `string?` | - | 代理端点 URL（JSONL 流） |
| `messages` | `A2UIMessage[]?` | - | 静态消息（`agentUrl` 的替代方案） |
| `catalog` | `Record<string, Component>?` | `{}` | 自定义组件目录覆盖 |
| `capabilities` | `ClientCapabilities?` | - | 发送给代理的客户端能力 |
| `theme` | `string?` | `'light'` | UI 主题（`'light'` \| `'dark'`） |

### 事件

| 事件 | 负载 | 描述 |
|-----|------|------|
| `@action` | `UserActionMessage` | 当用户触发操作时发出（按钮点击、表单提交） |
| `@error` | `Error` | 渲染或流错误时发出 |
| `@ready` | `string`（surfaceId） | 当 surface 完成初始渲染时发出 |

### 组合式函数

#### `useA2UIState()`

管理 surface 注册表、组件邻接表和数据模型。

```typescript
const { surfaces, dispatch, updateDataPath, reset } = useA2UIState()
```

#### `useA2UIStream(options)`

处理 JSONL 流解析和消息分发。

```typescript
const { isStreaming, error, send, abort } = useA2UIStream({
  onMessage: (msg) => dispatch(msg),
  onError: (err) => console.error(err)
})
```


---

## 🛠️ 开发

### 项目结构

```
a2ui-vue-renderer/
├── src/
│   ├── components/
│   │   ├── A2UIRenderer.vue      # 主渲染器组件
│   │   ├── A2UIComponent.ts      # 递归组件渲染器
│   │   ├── A2UIContext.ts        # Vue provide/inject 上下文
│   │   └── catalog/
│   │       └── index.ts          # 默认组件目录
│   ├── composables/
│   │   ├── useA2UIState.ts       # 状态管理
│   │   └── useA2UIStream.ts      # JSONL 流处理
│   ├── utils/
│   │   ├── boundValue.ts         # 数据绑定解析器
│   │   └── jsonPointer.ts        # RFC 6901 JSON Pointer
│   ├── types/
│   │   └── index.ts              # TypeScript 类型定义
│   ├── styles.css                # 默认组件样式
│   └── index.ts                  # 公共 API 导出
├── demo/
│   ├── App.vue                   # 演示应用
│   ├── main.ts                   # 演示入口点
│   └── index.html                # 演示 HTML 模板
└── src/__tests__/                # 单元测试（Vitest）
```

### 构建命令

```bash
# 安装依赖
npm install

# 本地运行演示
npm run demo

# 构建生产库
npm run build

# 运行单元测试
npm test

# 以监视模式运行测试
npm run test:watch

# 类型检查
npm run type-check
```


---

## 🧪 测试

本项目包含使用 **Vitest** 和 **@vue/test-utils** 的全面单元测试。

### 测试覆盖

- ✅ JSON Pointer 解析（`jsonPointer.test.ts`）
- ✅ 绑定值解析（`boundValue.test.ts`）
- ✅ 状态管理（`useA2UIState.test.ts`）
- ✅ 消息分发和 surface 更新
- ✅ 数据模型更新和响应式

### 运行测试

```bash
# 运行所有测试
npm test

# 监视模式
npm run test:watch

# 覆盖率报告
npm run test:coverage
```

**当前状态：** 44/44 测试通过 ✅

---

## 🤝 贡献

欢迎贡献！请遵循以下指南：

1. Fork 仓库
2. 创建功能分支（`git checkout -b feature/amazing-feature`）
3. 为新功能编写测试
4. 确保所有测试通过（`npm test`）
5. 提交您的更改（`git commit -m 'Add amazing feature'`）
6. 推送到分支（`git push origin feature/amazing-feature`）
7. 打开 Pull Request

---

## 📄 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE)。

---

## 🔗 相关资源

- [A2UI 官方规范](https://a2ui.org/)
- [A2UI 协议博客文章](https://developers.googleblog.com/introducing-a2ui)
- [Vue 3 文档](https://vuejs.org/)
- [RFC 6901 JSON Pointer](https://datatracker.ietf.org/doc/html/rfc6901)

---

## 🙏 致谢

- **Google A2UI 团队** 创建协议规范
- **Vue.js 核心团队** 提供出色的响应式框架
- **Anthropic** 在开发中提供 Claude Code 协助

---

**使用 Vue 3 和 TypeScript 用 ❤️ 构建**
