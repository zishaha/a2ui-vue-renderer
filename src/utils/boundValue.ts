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
