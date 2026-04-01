/**
 * Tests for JSON Pointer utilities (RFC 6901)
 */
import { describe, it, expect } from 'vitest'
import { get, set, scopePointer } from '../utils/jsonPointer'

describe('get()', () => {
  const obj = { user: { name: 'Alice', age: 30 }, items: ['a', 'b', 'c'] }

  it('returns root object for empty pointer', () => {
    expect(get(obj, '/')).toBe(obj)
  })

  it('resolves single-level key', () => {
    expect(get(obj, '/user')).toEqual({ name: 'Alice', age: 30 })
  })

  it('resolves nested key', () => {
    expect(get(obj, '/user/name')).toBe('Alice')
  })

  it('resolves array index', () => {
    expect(get(obj, '/items/1')).toBe('b')
  })

  it('returns undefined for missing key', () => {
    expect(get(obj, '/missing')).toBeUndefined()
  })

  it('returns undefined for deep missing path', () => {
    expect(get(obj, '/user/missing/deep')).toBeUndefined()
  })

  it('handles ~ escaping: ~0 → ~, ~1 → /', () => {
    const special = { 'a/b': { 'c~d': 42 } }
    expect(get(special, '/a~1b/c~0d')).toBe(42)
  })
})

describe('set()', () => {
  it('sets a nested value immutably', () => {
    const obj = { user: { name: 'Alice' } }
    const next = set(obj, '/user/name', 'Bob')
    expect(next.user.name).toBe('Bob')
    expect(obj.user.name).toBe('Alice') // original unchanged
  })

  it('sets a value at array index', () => {
    const obj = { items: [1, 2, 3] } as Record<string, unknown>
    const next = set(obj, '/items/1', 99)
    expect((next.items as number[])[1]).toBe(99)
    expect((obj.items as number[])[1]).toBe(2) // original unchanged
  })

  it('creates nested path if missing', () => {
    const obj = {} as Record<string, unknown>
    const next = set(obj, '/a/b/c', 'deep')
    expect((next as Record<string, unknown>).a).toBeDefined()
  })
})

describe('scopePointer()', () => {
  it('concatenates base and relative pointers', () => {
    expect(scopePointer('/items/0', '/name')).toBe('/items/0/name')
  })

  it('handles trailing slash on base', () => {
    expect(scopePointer('/items/0/', '/name')).toBe('/items/0/name')
  })

  it('returns base if relative does not start with /', () => {
    expect(scopePointer('/items/0', 'name')).toBe('/items/0')
  })
})
