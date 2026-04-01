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
  /** UI theme: 'light' | 'dark' */
  theme?: string
}
