#!/bin/sh
# SessionStart: tells the agent which instruction files to read and to announce what it read.
# Argument: "start" (new chat) or "compact" (after a compaction).
if [ "$1" = "compact" ]; then
  echo "The conversation was just compacted. Before continuing, read your instructions again in this order."
else
  echo "Before doing anything else in this chat, read your instructions in this order."
fi
echo "1. User-level file: ~/.claude/CLAUDE.md, whole, if it exists and you have access to it. In Cowork it may be on the user's computer, so use the device tools."
echo "2. Project file: the CLAUDE.md at the root of the connected project folder, whole, if a folder is connected. It prevails over the user-level file if they conflict."
echo "3. Skills: list the SKILL.md files under .claude/skills in the project folder and under ~/.claude/skills, and read the frontmatter of each. Read a full SKILL.md when a task fits it."
echo "Then tell the user in one short message exactly what you read and what you could not reach, for example: Read: ~/.claude/CLAUDE.md, project CLAUDE.md. Skills available: name1, name2. If a file or folder is not reachable or does not exist, say so in that message."
echo "Do not claim to have read anything you did not read, and do not invent the content of any file."
if [ "$1" = "compact" ]; then
  echo "If you cannot recover what was being done and the decisions already taken, say so instead of guessing."
fi
exit 0
