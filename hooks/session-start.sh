#!/bin/sh
# SessionStart: tells the agent which instruction files to read and to announce what it read.
# Argument: "start" (new chat) or "compact" (after a compaction).
if [ "$1" = "compact" ]; then
  echo "The conversation was just compacted. Before continuing, read your instructions again in this order."
else
  echo "Before doing anything else in this chat, read your instructions in this order."
fi
echo "1. User-level file: /Users/j5pu/.claude/CLAUDE.md (that is ~/.claude/CLAUDE.md on the user's computer, not in your own sandbox home). Read it whole with the device tools, together with any file it imports, if it exists and you have access to it."
echo "2. Project file: the CLAUDE.md at the root of the connected project folder, whole, if a folder is connected. Read it from disk with the device tools even if a copy of it already arrived with the session; do not rely on that copy. It prevails over the user-level file if they conflict."
echo "3. Skills: list the SKILL.md files under .claude/skills in the project folder and under /Users/j5pu/.claude/skills, and read the frontmatter of each. Read a full SKILL.md when a task fits it."
echo "Then tell the user in one short message exactly what you read and what you could not reach. Count skills only by the names you list, never give a separate number. Example: Read: ~/.claude/CLAUDE.md, project CLAUDE.md. Skills available: name1, name2. If a file or folder is not reachable or does not exist, say so in that message."
echo "Where to read: use the Filesystem MCP server (tools read_text_file, read_multiple_files and list_directory), which can read the whole of the user's computer, with absolute paths. Do not use your own sandbox, and do not use a shell limited to the connected folders for /Users/j5pu/.claude. Try the Filesystem tools before concluding that something is not reachable. If they fail, report the real error and do not say the file does not exist."
echo "Never say a folder or file does not exist unless the listing or read itself failed with that error. If a listing or read fails for another reason, report the real error, and if the folder exists, list its contents."
echo "Do not claim to have read anything you did not read, and do not invent the content of any file."
if [ "$1" = "compact" ]; then
  echo "If you cannot recover what was being done and the decisions already taken, say so instead of guessing."
fi
exit 0
