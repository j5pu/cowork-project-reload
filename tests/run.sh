#!/bin/bash
# Offline checks for the classic-hooks version.
cd "$(dirname "$0")/.." || exit 1
fail=0
ok() { echo "ok   $1"; }
ko() { echo "FAIL $1"; fail=1; }

python3 -c 'import json;json.load(open("hooks/hooks.json"));json.load(open(".claude-plugin/plugin.json"));json.load(open(".claude-plugin/marketplace.json"))' && ok "JSON files parse" || ko "JSON files parse"
[ -x hooks/session-start.sh ] && ok "script executable" || ko "script executable"
start=$(CLAUDE_PLUGIN_ROOT="$PWD" "$PWD/hooks/session-start.sh" start); rc1=$?
comp=$(CLAUDE_PLUGIN_ROOT="$PWD" "$PWD/hooks/session-start.sh" compact); rc2=$?
[ $rc1 -eq 0 ] && [ $rc2 -eq 0 ] && ok "script exits 0 in both modes" || ko "script exits 0 in both modes"
echo "$start" | grep -q '~/.claude/CLAUDE.md' && ok "mentions user-level file" || ko "mentions user-level file"
echo "$start" | grep -q 'skills' && ok "mentions skills" || ko "mentions skills"
echo "$start" | grep -q 'tell the user' && ok "asks to announce what was read" || ko "asks to announce what was read"
echo "$comp" | grep -q 'compacted' && ok "compact mode says compacted" || ko "compact mode says compacted"
echo "$start" | grep -q 'compacted' && ko "start mode has no compaction text" || ok "start mode has no compaction text"
grep -q '"matcher": "startup"' hooks/hooks.json && grep -q '"matcher": "compact"' hooks/hooks.json && ok "startup and compact matchers" || ko "startup and compact matchers"
grep -q '"modules"' hooks/hooks.json && ko "no mod modules" || ok "no mod modules"
grep -q 'PreCompact' hooks/hooks.json && ko "no PreCompact" || ok "no PreCompact"
grep -q '<<' hooks/session-start.sh && ko "no heredoc" || ok "no heredoc"
[ "$(python3 -c 'import json;print(json.load(open(".claude-plugin/plugin.json"))["version"])')" = "1.1.0" ] && ok "version 1.1.0" || ko "version 1.1.0"
exit $fail
