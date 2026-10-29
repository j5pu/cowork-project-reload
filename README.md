# cowork-project-reload

At the start of every chat, this plugin asks the agent to read two files before doing anything else:

1. `~/.claude/CLAUDE.md`, the user-level instructions that apply to all projects.
2. The `CLAUDE.md` at the root of the connected project folder, with the project-specific rules.

If the two conflict, the project file prevails. If a file cannot be reached, the agent says so in one line and does not invent its content.

## Install

```
/plugin install cowork-project-reload --marketplace j5pu/cowork-project-reload
```

## How it works

It uses a classic hook, so it runs in both Claude Code and Cowork:

- `hooks/hooks.json` registers one `SessionStart` hook with the `startup` matcher.
- `hooks/session-start.sh` prints the instruction; the output is added to the model's context.

The version 1.x line deliberately does nothing on compaction. Only the chat start is covered.

## Notes

- Claude Code already loads `~/.claude/CLAUDE.md` and the project `CLAUDE.md` natively; the hook reinforces it and makes the order explicit.
- In Cowork the agent runs in a VM, so `~/.claude/CLAUDE.md` of your computer may not be visible from it. The instruction tells the agent to use the device tools in that case.
- The earlier 0.x line was a mod (compaction summary and prompt context). It lives on `main` at tag `v0.4.0`.

## Tests

`tests/run.sh` runs offline checks (valid JSON, script behaviour, no compaction wording, version).

## License

MIT
