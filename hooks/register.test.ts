import { test, expect } from 'claude-code/testing'
import { register } from './register'

// Captures the plugin's hooks and runs them against a fake engine.
function load() {
  const hooks: Record<string, any> = {}
  const on: any = (ev: string, a: any, b?: any) => {
    hooks[ev] = typeof a === 'function' ? a : b
    return { catch: () => {} }
  }
  register(on, {} as any)
  return hooks
}
const msgs = [{ role: 'user', text: 'hello', toolUses: [] }]
const block = (r: any) => r.blocks.find((x: any) => x.name === 'projectReload').text

test('new chat: asks to read CLAUDE.md and skills', async () => {
  const h = load()
  const r = await h['prompt.context']({}, { blocks: [] }, async (e: any) => e)
  const t = block(r)
  expect(t).toContain('New chat')
  expect(t).toContain('.claude/skills')
})

test('compaction: instructs the summarizer and notes it afterwards, only once', async () => {
  const h = load()
  let received = ''
  await h['session.compact']({}, { trigger: 'auto', instructions: 'extra', messages: msgs },
    async (e: any) => { received = e.instructions; return { messages: msgs } })
  expect(received).toContain('extra')
  expect(received).toContain('LITERALLY')
  const ctx = async () => block(await h['prompt.context']({}, { blocks: [] }, async (e: any) => e))
  expect(await ctx()).toContain('A compaction has just happened')
  expect(await ctx()).toContain('New chat')
})

test('subagents and precompute do not trigger the notice', async () => {
  const h = load()
  await h['session.compact']({}, { trigger: 'precompute', messages: msgs }, async () => ({ messages: msgs }))
  await h['session.compact']({}, { trigger: 'auto', agentId: 'x', messages: msgs }, async () => ({ messages: msgs }))
  const r = await h['prompt.context']({}, { blocks: [] }, async (e: any) => e)
  expect(block(r)).toContain('New chat')
})

test('real engine load: the block reaches the context', async ($, on) => {
  on('prompt.context', () => ({ blocks: [] }))
  const r = await $.prompt.context({ blocks: [] })
  expect(r.blocks.some(x => x.name === 'projectReload')).toBe(true)
})

test('visible notices: new chat, before and after compacting', async () => {
  const h = load()
  const said: string[] = []
  const $ = { ui: { toast: (t: string) => said.push(t), log: (t: string) => said.push(t) } }
  await h['session.start']($, {}, async (e: any) => e)
  await h['session.compact']($, { trigger: 'auto', messages: msgs }, async () => ({ messages: msgs }))
  const all = said.join('\n')
  expect(all).toContain('New chat')
  expect(all).toContain('Before compacting')
  expect(all).toContain('Compaction done')
})

test('precompute shows no notices', async () => {
  const h = load()
  const said: string[] = []
  const $ = { ui: { toast: (t: string) => said.push(t), log: (t: string) => said.push(t) } }
  await h['session.compact']($, { trigger: 'precompute', messages: msgs }, async () => ({ messages: msgs }))
  expect(said.length).toBe(0)
})
