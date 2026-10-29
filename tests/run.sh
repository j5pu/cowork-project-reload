#!/bin/bash
# Offline checks for the classic-hooks version.
cd "$(dirname "$0")/.." || exit 1
fail=0
ok() { echo "ok   $1"; }
ko() { echo "FAIL $1"; fail=1; }

python3 -c 'import json;json.load(open("hooks/hooks.json"));json.load(open(".claude-plugin/plugin.json"));json.load(open(".claude-plugin/marketplace.json"))' && ok "JSON files parse" || ko "JSON files parse"
[ -x hooks/session-start.sh ] && ok "script executable" || ko "script executable"
out=$(CLAUDE_PLUGIN_ROOT="$PWD" "$PWD/hooks/session-start.sh"); rc=$?
[ $rc -eq 0 ] && ok "script exits 0" || ko "script exits 0"
echo "$out" | grep -q '~/.claude/CLAUDE.md' && ok "mentions user-level file" || ko "mentions user-level file"
echo "$out" | grep -q 'project' && ok "mentions project file" || ko "mentions project file"
grep -q '"modules"' hooks/hooks.json && ko "no mod modules" || ok "no mod modules"
grep -qi 'compact' hooks/hooks.json hooks/session-start.sh && ko "nothing about compaction" || ok "nothing about compaction"
grep -q '<<' hooks/session-start.sh && ko "no heredoc" || ok "no heredoc"
[ "$(python3 -c 'import json;print(json.load(open(".claude-plugin/plugin.json"))["version"])')" = "1.0.0" ] && ok "version 1.0.0" || ko "version 1.0.0"
exit $fail
