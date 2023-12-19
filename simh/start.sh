#!/bin/sh

PDP6=$HOME/src/sims/BIN/pdp6
GECON=$HOME/src/its/tools/vt05/gecon

cleanup() {
    stty sane
    kill $PID
}

gecon() {
    (sleep 1; exec "$GECON" telnet localhost 10001) &
    PID=$!
    trap cleanup EXIT INT TERM QUIT
}

gecon

if test -z "$GDB"; then
    $PDP6 its138.do 2>pdp6.log
else
    $GDB -x its138.gdb $PDP6
fi
