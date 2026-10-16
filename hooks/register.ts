import type { Register } from 'claude-code'

export const SUMMARY_INSTRUCTIONS = [
  'When summarizing, do NOT paraphrase. Copy LITERALLY, in their own sections:',
  '1. RULES: every instruction, procedure and preference the user has given, exactly as written.',
  '2. DECISIONS: every decision made in the conversation, with its reason if one was given.',
  '3. CURRENT STEP: exactly what was being done, what is still pending and which files were in use.',
  'If any of this is unclear from the conversation, write "not stated" instead of inventing it.',
].join('\n')

const READ_PROJECT = [
  'If a project folder is connected:',
  '- Read the whole CLAUDE.md at its root and follow it.',
  '- List the skills in .claude/skills/*/SKILL.md and read at least the name and description (frontmatter) of each, so you know they exist.',
  '- When a task fits one of those skills, read its full SKILL.md before doing the task.',
  'If no folder is connected or those files do not exist, say so in one line; do not invent their content.',
].join('\n')

export const NEW_CHAT_TEXT = `New chat. Before starting work:\n${READ_PROJECT}`

export const COMPACTION_TEXT =
  `A compaction has just happened. Before continuing, re-read CLAUDE.md, and the skills if you are in a project.\n${READ_PROJECT}\n` +
  'Then check the summary against what you re-read. If you cannot recover what was being done or what had been decided, stop and tell the user instead of guessing.'

let justCompacted = false

// Visible notice for the user (toast at the top right and a dim line in the transcript).
// It must never break anything: if $.ui is missing (tests) or fails, it is ignored.
const notify = ($: any, text: string) => {
  try { $.ui.toast(text) } catch { /* no interface */ }
  try { $.ui.log(text) } catch { /* no interface */ }
}

export const register: Register = on => {
  // Before compacting: ask the summarizer to keep rules, decisions and the current step.
  on('session.compact', async ($, e, next) => {
    if (e.agentId) return next(e) // main conversation only
    const instructions = e.instructions
      ? `${e.instructions}\n\n${SUMMARY_INSTRUCTIONS}`
      : SUMMARY_INSTRUCTIONS
    if (e.trigger !== 'precompute') notify($, 'Before compacting: asking the summary to keep your rules, the decisions made and the current step word for word.')
    const r = await next({ ...e, instructions })
    if (r.skip === undefined && e.trigger !== 'precompute') {
      justCompacted = true
      notify($, 'Compaction done: asking the agent to re-read the project CLAUDE.md and skills, and to tell you if it cannot recover what was being done.')
    }
    return r
  }).catch(($, e, next) => next(e)) // if the hook fails, compaction goes on as usual

  // When a chat starts: visible notice only (changes nothing in the context).
  on('session.start', async ($, e, next) => {
    notify($, 'New chat: asking the agent to read the project CLAUDE.md and skills before starting.')
    return next(e)
  })

  // At chat start and after each compaction (the engine asks for the context again).
  on('prompt.context', async ($, e, next) => {
    const r = await next(e)
    const text = justCompacted ? COMPACTION_TEXT : NEW_CHAT_TEXT
    justCompacted = false
    return { ...r, blocks: [...r.blocks, { name: 'projectReload', text }] }
  })
}
