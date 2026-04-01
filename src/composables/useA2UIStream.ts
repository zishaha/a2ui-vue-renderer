/**
 * useA2UIStream — JSONL streaming composable
 *
 * Connects to an agent endpoint via fetch + ReadableStream,
 * parses JSONL line-by-line, and dispatches A2UI messages.
 */
import { ref } from 'vue'
import type { A2UIMessage, ClientCapabilities, UserActionMessage } from '../types'

interface UseStreamOptions {
  onMessage: (msg: A2UIMessage) => void
  onError?: (err: Error) => void
  capabilities?: Partial<ClientCapabilities>
}

export function useA2UIStream(options: UseStreamOptions) {
  const isStreaming = ref(false)
  const error = ref<Error | null>(null)
  let abortController: AbortController | null = null

  async function send(agentUrl: string, action: UserActionMessage | { message: string }) {
    // Abort any in-flight stream
    abortController?.abort()
    abortController = new AbortController()

    isStreaming.value = true
    error.value = null

    try {
      const res = await fetch(agentUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/x-ndjson, application/jsonl',
          'X-A2UI-Version': '0.8',
          'X-A2UI-Catalogs': JSON.stringify(
            options.capabilities?.supportedCatalogIds ?? ['basic']
          ),
        },
        body: JSON.stringify(action),
        signal: abortController.signal,
      })

      if (!res.ok) {
        throw new Error(`Agent responded with ${res.status}: ${res.statusText}`)
      }

      if (!res.body) {
        throw new Error('Response has no body — expected JSONL stream')
      }

      await parseJSONLStream(res.body)
    } catch (err: unknown) {
      if ((err as { name: string }).name === 'AbortError') return
      const e = err instanceof Error ? err : new Error(String(err))
      error.value = e
      options.onError?.(e)
    } finally {
      isStreaming.value = false
    }
  }

  async function parseJSONLStream(body: ReadableStream<Uint8Array>) {
    const reader = body.getReader()
    const decoder = new TextDecoder()
    let buffer = ''

    while (true) {
      const { done, value } = await reader.read()
      if (done) break

      buffer += decoder.decode(value, { stream: true })

      // Split on newlines — each line is one JSON message
      const lines = buffer.split('\n')
      buffer = lines.pop() ?? ''   // keep incomplete line in buffer

      for (const line of lines) {
        const trimmed = line.trim()
        if (!trimmed) continue
        try {
          const msg = JSON.parse(trimmed) as A2UIMessage
          options.onMessage(msg)
        } catch (e) {
          console.warn('[A2UI] Failed to parse JSONL line:', trimmed, e)
        }
      }
    }

    // Flush any remaining content
    if (buffer.trim()) {
      try {
        const msg = JSON.parse(buffer) as A2UIMessage
        options.onMessage(msg)
      } catch { /* ignore trailing garbage */ }
    }
  }

  function abort() {
    abortController?.abort()
    isStreaming.value = false
  }

  return { isStreaming, error, send, abort }
}
