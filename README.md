# cowork-project-reload

At the start of every chat and after every compaction, this plugin asks the agent to read, in this order:

1. `~/.claude/CLAUDE.md`, the user-level instructions for all projects, if it has access to it.
2. The `CLAUDE.md` at the root of the connected project folder, if a folder is connected.
3. The skills under `.claude/skills` in the project folder and under `~/.claude/skills`.

Then the agent tells you in one short message what it read, which skills it has, and what it could not reach. If the two CLAUDE.md files conflict, the project file prevails. The agent must not claim to have read anything it did not read.

## Install

```
/plugin install cowork-project-reload --marketplace j5pu/cowork-project-reload
```

## How it works

It uses classic hooks, so it is meant to run in both Claude Code and Cowork:

- `hooks/hooks.json` registers two `SessionStart` hooks: matcher `startup` (new chat) and matcher `compact` (after a compaction).
- `hooks/session-start.sh start|compact` prints the instruction; the output is added to the model's context.

It does not use `PreCompact`, so it cannot change the compaction summary. It only makes the agent read again afterwards.

## Notes

- Claude Code already loads `~/.claude/CLAUDE.md` and the project `CLAUDE.md` natively; the hook makes the order explicit and adds the announcement.
- In Cowork the agent runs in a VM, so files on your computer may not be visible from it. The instruction tells the agent to use the device tools, and to say so if it cannot reach them (for example in a mobile chat without folder access).
- The 0.x line was a mod (compaction summary and prompt context). It lives on `main` at tag `v0.4.0`.
- Whether the hooks fire in Cowork has to be checked in a real chat.

## Tests

`tests/run.sh` runs offline checks (valid JSON, both script modes, matchers, no mod, no PreCompact, version).

## License

MIT
