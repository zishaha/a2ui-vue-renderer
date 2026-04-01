/**
 * Tests for useA2UIState composable
 * Tests message dispatching, state management, and data model updates
 */
import { describe, it, expect, beforeEach } from 'vitest'
import { useA2UIState } from '../composables/useA2UIState'
import type { A2UIMessage } from '../types'

// ── Helpers ───────────────────────────────────────────────────────────────

function makeSurface(surfaceId = 's1', rootComponentId = 'root') {
  return {
    type: 'beginRendering' as const,
    surfaceId,
    rootComponentId,
  }
}

function makeTextComponent(id: string, text: string, surfaceId = 's1') {
  return {
    type: 'surfaceUpdate' as const,
    surfaceId,
    components: [{ id, type: 'Text', text: { literalString: text } }],
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────

describe('useA2UIState', () => {
  let state: ReturnType<typeof useA2UIState>

  beforeEach(() => {
    state = useA2UIState()
  })

  // ── beginRendering ──────────────────────────────────────────────────────

  describe('beginRendering', () => {
    it('creates a surface with isReady=true', () => {
      state.dispatch(makeSurface('s1', 'root'))
      expect(state.surfaces['s1']).toBeDefined()
      expect(state.surfaces['s1'].isReady).toBe(true)
      expect(state.surfaces['s1'].rootComponentId).toBe('root')
    })

    it('flushes buffered surfaceUpdate components', () => {
      // surfaceUpdate arrives BEFORE beginRendering (buffered)
      state.dispatch(makeTextComponent('t1', 'Buffered Text'))
      expect(state.surfaces['s1']).toBeUndefined()

      // Now beginRendering arrives → flush buffer
      state.dispatch(makeSurface('s1', 'root'))
      expect(state.surfaces['s1'].components.get('t1')).toBeDefined()
    })

    it('sets theme if provided', () => {
      state.dispatch({
        type: 'beginRendering',
        surfaceId: 's1',
        rootComponentId: 'root',
        theme: { primary: '#ff0000' },
      })
      expect(state.surfaces['s1'].theme?.primary).toBe('#ff0000')
    })
  })

  // ── surfaceUpdate ───────────────────────────────────────────────────────

  describe('surfaceUpdate', () => {
    beforeEach(() => state.dispatch(makeSurface()))

    it('adds components to an existing surface', () => {
      state.dispatch(makeTextComponent('t1', 'Hello'))
      expect(state.surfaces['s1'].components.get('t1')).toBeDefined()
    })

    it('updates an existing component', () => {
      state.dispatch(makeTextComponent('t1', 'Original'))
      state.dispatch(makeTextComponent('t1', 'Updated'))
      const comp = state.surfaces['s1'].components.get('t1') as Record<string, unknown>
      expect((comp.text as { literalString: string }).literalString).toBe('Updated')
    })

    it('handles multiple components in one message', () => {
      state.dispatch({
        type: 'surfaceUpdate',
        surfaceId: 's1',
        components: [
          { id: 'c1', type: 'Text', text: { literalString: 'A' } },
          { id: 'c2', type: 'Button', label: { literalString: 'B' } },
        ],
      })
      expect(state.surfaces['s1'].components.get('c1')).toBeDefined()
      expect(state.surfaces['s1'].components.get('c2')).toBeDefined()
    })

    it('buffers components if surface does not exist yet', () => {
      const newState = useA2UIState()
      newState.dispatch(makeTextComponent('t1', 'Early', 'new-surface'))
      // Surface not created yet
      expect(newState.surfaces['new-surface']).toBeUndefined()
      // Create surface — buffer should flush
      newState.dispatch(makeSurface('new-surface', 'root'))
      expect(newState.surfaces['new-surface'].components.get('t1')).toBeDefined()
    })
  })

  // ── dataModelUpdate ─────────────────────────────────────────────────────

  describe('dataModelUpdate', () => {
    beforeEach(() => state.dispatch(makeSurface()))

    it('sets string value', () => {
      state.dispatch({ type: 'dataModelUpdate', surfaceId: 's1', updates: [{ key: 'name', valueString: 'Alice' }] })
      expect(state.surfaces['s1'].dataModel.name).toBe('Alice')
    })

    it('sets number value', () => {
      state.dispatch({ type: 'dataModelUpdate', surfaceId: 's1', updates: [{ key: 'count', valueNumber: 7 }] })
      expect(state.surfaces['s1'].dataModel.count).toBe(7)
    })

    it('sets boolean value', () => {
      state.dispatch({ type: 'dataModelUpdate', surfaceId: 's1', updates: [{ key: 'active', valueBoolean: true }] })
      expect(state.surfaces['s1'].dataModel.active).toBe(true)
    })

    it('sets list value', () => {
      state.dispatch({ type: 'dataModelUpdate', surfaceId: 's1', updates: [{ key: 'items', valueList: [1, 2, 3] }] })
      expect(state.surfaces['s1'].dataModel.items).toEqual([1, 2, 3])
    })

    it('handles multiple updates in one message', () => {
      state.dispatch({
        type: 'dataModelUpdate',
        surfaceId: 's1',
        updates: [
          { key: 'a', valueString: 'x' },
          { key: 'b', valueNumber: 42 },
        ],
      })
      expect(state.surfaces['s1'].dataModel.a).toBe('x')
      expect(state.surfaces['s1'].dataModel.b).toBe(42)
    })

    it('ignores updates for non-existent surface', () => {
      expect(() =>
        state.dispatch({ type: 'dataModelUpdate', surfaceId: 'none', updates: [{ key: 'x', valueString: 'y' }] })
      ).not.toThrow()
    })
  })

  // ── deleteSurface ───────────────────────────────────────────────────────

  describe('deleteSurface', () => {
    it('removes an existing surface', () => {
      state.dispatch(makeSurface())
      expect(state.surfaces['s1']).toBeDefined()
      state.dispatch({ type: 'deleteSurface', surfaceId: 's1' })
      expect(state.surfaces['s1']).toBeUndefined()
    })

    it('is a no-op for non-existent surface', () => {
      expect(() =>
        state.dispatch({ type: 'deleteSurface', surfaceId: 'ghost' })
      ).not.toThrow()
    })
  })

  // ── updateDataPath ──────────────────────────────────────────────────────

  describe('updateDataPath', () => {
    beforeEach(() => {
      state.dispatch(makeSurface())
      state.dispatch({ type: 'dataModelUpdate', surfaceId: 's1', updates: [{ key: 'name', valueString: 'Alice' }] })
    })

    it('updates a value at JSON Pointer path', () => {
      state.updateDataPath('s1', '/name', 'Bob')
      expect(state.surfaces['s1'].dataModel.name).toBe('Bob')
    })

    it('creates new path if not existing', () => {
      state.updateDataPath('s1', '/email', 'test@example.com')
      expect(state.surfaces['s1'].dataModel.email).toBe('test@example.com')
    })

    it('is a no-op for missing surface', () => {
      expect(() => state.updateDataPath('none', '/x', 1)).not.toThrow()
    })
  })

  // ── dispatchAll ─────────────────────────────────────────────────────────

  describe('dispatchAll', () => {
    it('processes an array of messages in order', () => {
      const messages: A2UIMessage[] = [
        makeSurface('s2', 'root'),
        makeTextComponent('t1', 'Hello', 's2'),
        { type: 'dataModelUpdate', surfaceId: 's2', updates: [{ key: 'x', valueNumber: 1 }] },
      ]
      state.dispatchAll(messages)
      expect(state.surfaces['s2'].isReady).toBe(true)
      expect(state.surfaces['s2'].components.get('t1')).toBeDefined()
      expect(state.surfaces['s2'].dataModel.x).toBe(1)
    })
  })

  // ── reset ───────────────────────────────────────────────────────────────

  describe('reset', () => {
    it('clears all surfaces', () => {
      state.dispatch(makeSurface('s1'))
      state.dispatch(makeSurface('s2'))
      state.reset()
      expect(Object.keys(state.surfaces)).toHaveLength(0)
    })
  })
})
