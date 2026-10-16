# cowork-project-reload

A plugin that makes the agent re-read the project folder's `CLAUDE.md` and skills when a chat starts and right after every compaction, and asks the compaction summary to keep rules, decisions and the current step.

## The problem

When a conversation is compacted, the history is replaced by a summary. Skills read in the middle of a chat are lost in that summary, and the agent carries on without the procedures it had. This plugin tells it to re-read them, and to warn you if it cannot recover what was being done instead of inventing it.

## What the hooks do and what they change

The plugin is a mod with three hooks, in `hooks/register.ts`. They are explained one by one because the directory asks what each hook sees and what it changes.

### Hook `session.compact` (line 36 of `register.ts`)

`session.compact` is an event that is also the name of a call: when Claude Code compacts the conversation, the hook sees that call and could change it. The mod **does not make that call itself**; it only intercepts it when other code makes it.

- **What it sees:** the compaction event: what triggered it (`trigger`), whether it comes from a subagent (`agentId`) and the summary instructions it already carries (`instructions`).
- **What it changes:** only the `instructions` field. It appends a fixed text that asks the summarizer to copy rules, decisions and the current step literally into their own sections, and to write "not stated" when something is unclear. Existing instructions are kept and the plugin's text goes after them.
- **What it does not touch:** any other field of the call, the compaction result, the messages or any file. Subagent compactions are ignored.
- **Visible notice:** it shows the user a notice (`$.ui.toast` and `$.ui.log`) just before and just after compacting. It is only text on screen and does not enter the model's context.
- **If it fails:** the `.catch` handler lets the event through unchanged and compaction goes on as usual.

### Hook `prompt.context` (line 57 of `register.ts`)

`prompt.context` is an event that the instructions and context the model receives pass through.

- **What it sees:** the list of context blocks Claude Code is about to send.
- **What it changes:** it **adds one block** (`projectReload`) with a fixed text. In a new chat it asks the agent to read `CLAUDE.md` in full, list the skills in `.claude/skills/*/SKILL.md` and read the one that fits the task in full. After a compaction it asks for the same and also to check the summary against what was re-read, and to tell the user if what was being done or decided cannot be recovered.
- **What it does not touch:** it does not modify, remove or reorder existing blocks, nor settings, nor other instructions.

### Hook `session.start` (line 51 of `register.ts`)

- **What it does:** when a chat starts it shows a visible notice (`$.ui.toast` and `$.ui.log`).
- **What it changes:** nothing. It passes the event through as is; the notice is for the user only and does not enter the model's context.

No hook makes network calls, reads or writes files, reads environment variables or settings, or stores the user's messages. They only call `$.ui.toast` and `$.ui.log` to show notices. The text they add is always the same.

## Installation

In Cowork: Customize → Plugins → Add → marketplace `j5pu/cowork-project-reload`.

In Claude Code (2.1.287 or later, because of mods):

```
/plugin install cowork-project-reload --marketplace j5pu/cowork-project-reload
```

## How to tell it works

You will see notices on screen, a box at the top right and a dim line in the transcript:

- When a chat starts: "New chat: asking the agent to read the project CLAUDE.md and skills before starting."
- Before compacting: "Before compacting: asking the summary to keep your rules, the decisions made and the current step word for word."
- After compacting: "Compaction done: asking the agent to re-read the project CLAUDE.md and skills, and to tell you if it cannot recover what was being done."

After a compaction the agent should re-read `CLAUDE.md` and the skills.

## Test status

- `claude plugin test`: 6 of 6 with Claude Code 2.1.299, including loading in the real engine and the notices.
- Real session with the plugin as an organization mod (declared in managed settings): the three notices fire and the compaction summary comes out with the RULES, DECISIONS and CURRENT STEP sections, marking "not stated" what is unknown. **Verified.**
- Real session with the plugin installed as a regular user on a Team account or on a machine with managed settings: the built-in guard `cc-plugin-sec-default` passes over `session.compact` and `prompt.context` (`bypassed ... tier user`) and the mod does not act. On those machines an administrator must declare the plugin in managed settings (see below). On machines without the guard it should work, but that has not been tested.
- Cowork: the directory lists mods for Claude Code only, so the plugin is not listed for Cowork and has not been verified there.

### Machines with managed settings

In `managed-settings.json`, declare the marketplace as a local folder and enable the plugin:

```json
{
  "extraKnownMarketplaces": {
    "cowork-project-reload": { "source": { "source": "directory", "path": "/path/to/cowork-project-reload" } }
  },
  "enabledPlugins": { "cowork-project-reload@cowork-project-reload": true }
}
```

## Structure

```
.claude-plugin/plugin.json        manifest
.claude-plugin/marketplace.json   single-plugin catalog
hooks/hooks.json                  registers the module
hooks/register.ts                 the three hooks
hooks/register.test.ts            tests (claude plugin test)
```

## TODO: alternative without a mod (classic hooks)

Pending in case the mod does not run (for example on a Team or Enterprise plan or with managed settings, where the guard `cc-plugin-sec-default` passes over `session.compact` and `prompt.context`). Tested with Claude Code 2.1.299; this is what would be done:

- [ ] Replace `hooks/hooks.json` with classic hooks (`hooks` instead of `modules`) and remove `register.ts`, `register.test.ts` and `tsconfig.json`.
- [ ] `SessionStart` with a `startup` matcher and another with `compact`, both calling the same script `hooks/session-start.sh startup|compact` by a literal path under `${CLAUDE_PLUGIN_ROOT}` (quoted). Its standard output is added to the model's context, so the agent re-reads `CLAUDE.md` and the skills at the start and after compacting. **Tested: works on a Team account.**
- [ ] `PreCompact` can only block (exit code 2); its output does not enter the summary. To protect rules and decisions a backup would have to be saved before compacting:
  - the script receives `transcript_path` and `session_id`; it would write the user's literal messages to `.claude/precompact/<session_id>.md` (one file per session so two chats do not overwrite each other);
  - `SessionStart:compact` would tell the agent to consult it only if the summary is not enough, giving priority to the most recent messages and confirming any doubtful rule with the user;
  - filter obvious keys and tokens before writing. Risks to weigh: rules that were changed later coming back, sensitive data on disk, and file size.
- [ ] Avoid heredocs (`cat <<EOT`) in the scripts: the directory flagged them as `COMMAND_SCRIPT_NOT_FOLLOWED` (a policy hold, not blocking). Use `echo` or `printf`.
- [ ] Rewrite the tests (`tests/run.sh`): scripts, `hooks.json` without `modules`, and a real run with `--plugin-dir`, `/compact` and a check that the agent recovers a rule from `CLAUDE.md`.
- [ ] Document in the README what each script does. A complete version of those hooks is in the git history (commit `4e9c60b`).

## License

MIT.
