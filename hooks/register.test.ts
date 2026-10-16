import { test, expect } from 'claude-code/testing'
import { register } from './register'

// Captura los hooks del plugin y los ejecuta con un "motor" falso.
function cargar() {
  const hooks: Record<string, any> = {}
  const on: any = (ev: string, a: any, b?: any) => {
    hooks[ev] = typeof a === 'function' ? a : b
    return { catch: () => {} }
  }
  register(on, {} as any)
  return hooks
}
const msgs = [{ role: 'user', text: 'hola', toolUses: [] }]

test('nuevo chat: pide leer CLAUDE.md y skills', async () => {
  const h = cargar()
  const r = await h['prompt.context']({}, { blocks: [] }, async (e: any) => e)
  const t = r.blocks.find((x: any) => x.name === 'relecturaProyecto').text
  expect(t).toContain('Nuevo chat')
  expect(t).toContain('.claude/skills')
})

test('compactación: instruye al resumidor y avisa después, una sola vez', async () => {
  const h = cargar()
  let recibidas = ''
  await h['session.compact']({}, { trigger: 'auto', instructions: 'extra', messages: msgs },
    async (e: any) => { recibidas = e.instructions; return { messages: msgs } })
  expect(recibidas).toContain('extra')
  expect(recibidas).toContain('LITERALMENTE')
  const ctx = async () => (await h['prompt.context']({}, { blocks: [] }, async (e: any) => e))
    .blocks.find((x: any) => x.name === 'relecturaProyecto').text
  expect(await ctx()).toContain('Ha habido compactación')
  expect(await ctx()).toContain('Nuevo chat')
})

test('subagentes y precompute no disparan el aviso', async () => {
  const h = cargar()
  await h['session.compact']({}, { trigger: 'precompute', messages: msgs }, async () => ({ messages: msgs }))
  await h['session.compact']({}, { trigger: 'auto', agentId: 'x', messages: msgs }, async () => ({ messages: msgs }))
  const r = await h['prompt.context']({}, { blocks: [] }, async (e: any) => e)
  expect(r.blocks.find((x: any) => x.name === 'relecturaProyecto').text).toContain('Nuevo chat')
})

test('carga real en el motor: el bloque llega al contexto', async ($, on) => {
  on('prompt.context', () => ({ blocks: [] }))
  const r = await $.prompt.context({ blocks: [] })
  expect(r.blocks.some(x => x.name === 'relecturaProyecto')).toBe(true)
})
