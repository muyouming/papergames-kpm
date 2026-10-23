#!/bin/sh
# KPM uninstall hook for PaperGames.
# Runs from the unpacked package folder. Only touches /mnt/us and our process.

TARGET=/mnt/us/PaperGames
DOCS=/mnt/us/documents

# Stop the local server, but only if it is really ours.
pid=$(netstat -lntp 2>/dev/null | awk '$4 ~ /:8080$/ {print $NF}' | cut -d/ -f1)
if [ -n "$pid" ]; then
    cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
    case "$cmd" in
        *PaperGames/server.lua*) kill "$pid" 2>/dev/null; echo "Stopped local server (pid $pid)." ;;
    esac
fi

# Remove the scriptlet only if it is still the unmodified one we installed.
if [ -f "$DOCS/PaperGames.sh" ]; then
    ours=$(md5sum ./scriptlets/PaperGames.sh | cut -d' ' -f1)
    cur=$(md5sum "$DOCS/PaperGames.sh" | cut -d' ' -f1)
    if [ "$ours" = "$cur" ]; then
        rm -f "$DOCS/PaperGames.sh"
    fi
fi

rm -rf "$TARGET"
restart scanner 2>/dev/null || true

echo "PaperGames removed."
exit 0
