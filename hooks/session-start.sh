#!/bin/sh
# SessionStart (startup): tells the agent which CLAUDE.md files to read before starting.
echo "Before doing anything else in this chat, read your instructions in this order."
echo "1. User-level instructions: read the whole file ~/.claude/CLAUDE.md if it exists and is reachable. In Cowork it may live on the user's computer, so use the device tools to read it. If you cannot reach it, say so in one line and continue."
echo "2. Project instructions: if a project folder is connected, read the whole CLAUDE.md at the root of that folder. If no folder is connected, say so in one line."
echo "Follow both. If they conflict, the project CLAUDE.md prevails over the user-level one."
echo "Do not invent the content of any file you could not read."
exit 0
