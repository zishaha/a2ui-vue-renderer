/**
 * Tests for BoundValue resolution utilities
 */
import { describe, it, expect } from 'vitest'
import { resolveBoundValue, resolveProps } from '../utils/boundValue'

const dataModel = {
  title: 'Hello A2UI',
  count: 42,
  active: true,
  nested: { label: 'Nested Label' },
  items: [{ name: 'Item A' }, { name: 'Item B' }],
}

describe('resolveBoundValue()', () => {
  it('resolves literalString', () => {
    expect(resolveBoundValue({ literalString: 'fixed' }, dataModel)).toBe('fixed')
  })

  it('resolves literalNumber', () => {
    expect(resolveBoundValue({ literalNumber: 99 }, dataModel)).toBe(99)
  })

  it('resolves literalBoolean', () => {
    expect(resolveBoundValue({ literalBoolean: false }, dataModel)).toBe(false)
  })

  it('resolves path reference from dataModel', () => {
    expect(resolveBoundValue({ path: '/title' }, dataModel)).toBe('Hello A2UI')
  })

  it('resolves nested path', () => {
    expect(resolveBoundValue({ path: '/nested/label' }, dataModel)).toBe('Nested Label')
  })

  it('resolves path with scopePath', () => {
    expect(resolveBoundValue({ path: '/name' }, dataModel, '/items/0')).toBe('Item A')
    expect(resolveBoundValue({ path: '/name' }, dataModel, '/items/1')).toBe('Item B')
  })

  it('returns undefined for missing path', () => {
    expect(resolveBoundValue({ path: '/missing' }, dataModel)).toBeUndefined()
  })

  it('returns undefined for undefined input', () => {
    expect(resolveBoundValue(undefined, dataModel)).toBeUndefined()
  })
})

describe('resolveProps()', () => {
  it('resolves mixed props', () => {
    const raw = {
      id: 'btn1',
      type: 'Button',
      label: { literalString: 'Click me' },
      disabled: { literalBoolean: false },
      count: { path: '/count' },
    }
    const resolved = resolveProps(raw, dataModel)
    expect(resolved.label).toBe('Click me')
    expect(resolved.disabled).toBe(false)
    expect(resolved.count).toBe(42)
  })

  it('skips id, type, children keys', () => {
    const raw = { id: 'x', type: 'Text', children: [], text: { literalString: 'hi' } }
    const resolved = resolveProps(raw, dataModel)
    expect(resolved).not.toHaveProperty('id')
    expect(resolved).not.toHaveProperty('type')
    expect(resolved).not.toHaveProperty('children')
    expect(resolved.text).toBe('hi')
  })

  it('passes through plain values unchanged', () => {
    const raw = { elevation: 2, padding: '16px' }
    const resolved = resolveProps(raw, dataModel)
    expect(resolved.elevation).toBe(2)
    expect(resolved.padding).toBe('16px')
  })
})
