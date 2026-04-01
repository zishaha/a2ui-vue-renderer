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
