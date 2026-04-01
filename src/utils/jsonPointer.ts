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
