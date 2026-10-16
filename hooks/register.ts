import type { Register } from 'claude-code'

export const INSTRUCCIONES_RESUMEN = [
  'Al resumir, NO resumas sino que copia LITERALMENTE, en secciones propias:',
  '1. REGLAS: todas las instrucciones, procedimientos y preferencias que el usuario ha dado, tal cual las escribió.',
  '2. DECISIONES: cada decisión tomada en la conversación, con su motivo si se dijo.',
  '3. PASO EN CURSO: qué se estaba haciendo exactamente, qué queda pendiente y qué archivos se estaban usando.',
  'Si algo de esto no está claro en la conversación, indícalo como "no consta" en lugar de inventarlo.',
].join('\n')

const LEER_PROYECTO = [
  'Si hay una carpeta de proyecto conectada:',
  '- Lee entero el CLAUDE.md de su raíz y síguelo.',
  '- Lista los skills de .claude/skills/*/SKILL.md y lee de cada uno al menos su nombre y descripción (frontmatter), para saber que existen.',
  '- Cuando una tarea encaje con uno de esos skills, lee su SKILL.md completo antes de hacerla.',
  'Si no hay carpeta conectada o no existen esos archivos, dilo en una línea; no inventes su contenido.',
].join('\n')

export const TEXTO_INICIO = `Nuevo chat. Antes de empezar a trabajar:\n${LEER_PROYECTO}`

export const TEXTO_COMPACTACION =
  `Ha habido compactación. Antes de seguir, relee CLAUDE.md, y los skills si estás en un proyecto.\n${LEER_PROYECTO}\n` +
  'Después, contrasta el resumen con lo releído. Si no puedes recuperar qué se estaba haciendo o qué se había decidido, para y avisa al usuario en vez de suponer.'

let huboCompactacion = false

export const register: Register = on => {
  // Antes de compactar: pedir al resumidor que conserve reglas, decisiones y paso en curso.
  on('session.compact', async ($, e, next) => {
    if (e.agentId) return next(e) // solo la conversación principal
    const instructions = e.instructions
      ? `${e.instructions}\n\n${INSTRUCCIONES_RESUMEN}`
      : INSTRUCCIONES_RESUMEN
    const r = await next({ ...e, instructions })
    if (r.skip === undefined && e.trigger !== 'precompute') huboCompactacion = true
    return r
  }).catch(($, e, next) => next(e)) // si el hook falla, la compactación sigue normal

  // Al iniciar un chat y tras cada compactación (el motor vuelve a pedir el contexto).
  on('prompt.context', async ($, e, next) => {
    const r = await next(e)
    const text = huboCompactacion ? TEXTO_COMPACTACION : TEXTO_INICIO
    huboCompactacion = false
    return { ...r, blocks: [...r.blocks, { name: 'relecturaProyecto', text }] }
  })
}
