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
import type { ComponentUpdate, Surface, UserActionMessage } from '../types'
import { resolveProps } from '../utils/boundValue'
import { get } from '../utils/jsonPointer'
import { DEFAULT_CATALOG } from './catalog'
import { A2UI_CONTEXT_KEY, type A2UIContext } from './A2UIContext'

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
