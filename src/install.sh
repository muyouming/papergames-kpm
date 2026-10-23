#!/bin/sh
# KPM install hook for PaperGames.
# Runs from the unpacked package folder. Only writes to /mnt/us (never rootfs).

set -e

TARGET=/mnt/us/PaperGames
DOCS=/mnt/us/documents

echo "Installing PaperGames to $TARGET ..."

# Stop an existing PaperGames server before replacing its files.
pid=$(netstat -lntp 2>/dev/null | awk '$4 ~ /:8080$/ {print $NF}' | cut -d/ -f1)
if [ -n "$pid" ]; then
    cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
    case "$cmd" in
        *PaperGames/server.lua*) kill "$pid" 2>/dev/null ;;
    esac
fi

rm -rf "$TARGET"
mkdir -p "$TARGET"

# Site (index.html, games, assets) goes straight into the install root.
cp -r ./site/. "$TARGET/"

# Bundled runtime: LuaJIT + LuaSocket + libstdc++.
cp -r ./runtime "$TARGET/runtime"
chmod +x "$TARGET/runtime/luajit" 2>/dev/null || true

# Local HTTP server.
cp ./server.lua "$TARGET/server.lua"

# Library launcher (scriptlet).
mkdir -p "$DOCS"
cp ./scriptlets/PaperGames.sh "$DOCS/PaperGames.sh"
chmod +x "$DOCS/PaperGames.sh"

# Make the new tile show up without a reboot.
restart scanner 2>/dev/null || true

echo "PaperGames installed. Open it from the library."
exit 0
