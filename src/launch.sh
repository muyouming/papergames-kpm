#!/bin/sh
# KPM launch hook: "kpm launch papergames" opens the game list.

if [ -f /mnt/us/documents/PaperGames.sh ]; then
    exec /bin/sh /mnt/us/documents/PaperGames.sh
fi

# Fallback if the scriptlet was removed: start server + open browser directly.
ROOT=/mnt/us/PaperGames
URL="http://127.0.0.1:8080/index.html"
if ! /usr/bin/curl -s -o /dev/null --max-time 2 "$URL"; then
    export LD_LIBRARY_PATH="$ROOT/runtime"
    /usr/bin/setsid "$ROOT/runtime/luajit" "$ROOT/server.lua" 8080 >/var/local/pg-server.log 2>&1 &
    sleep 2
fi
/usr/bin/lipc-set-prop com.lab126.appmgrd start app://com.lab126.browser >/dev/null 2>&1
sleep 8
/usr/bin/lipc-set-prop -s com.lab126.browser loadURL "$URL"
