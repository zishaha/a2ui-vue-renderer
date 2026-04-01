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
