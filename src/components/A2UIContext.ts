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
