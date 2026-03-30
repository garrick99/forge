#!/bin/bash
# Build all Forge verified applications
# Requires: Forge compiler built, GCC installed, Z3 available
set -e

FORGE=${FORGE:-../../_build/default/bin/main.exe}
DIR=$(dirname "$0")
PASS=0; FAIL=0

build_app() {
    local name=$1 fg=$2 driver=$3 binary=$4
    echo "=== Building $name ==="

    # Step 1: Verify and compile Forge source
    echo -n "  [1/3] Forge verify... "
    result=$(opam exec -- "$FORGE" build "$fg" 2>&1)
    if echo "$result" | grep -q 'all obligations discharged'; then
        obls=$(echo "$result" | grep -oP '\d+ total' | grep -oP '\d+')
        echo "✓ ($obls obligations proved)"
    else
        echo "✗ FAILED"
        echo "$result" | grep '✗' | head -3
        FAIL=$((FAIL+1))
        return
    fi

    # Step 2: Compile with GCC
    echo -n "  [2/3] GCC compile...  "
    if gcc -std=c99 -O2 -o "$binary" "$driver" 2>/dev/null; then
        echo "✓"
    else
        echo "✗ GCC failed:"
        gcc -std=c99 -O2 -o "$binary" "$driver" 2>&1 | head -3
        FAIL=$((FAIL+1))
        return
    fi

    # Step 3: Run
    echo "  [3/3] Running..."
    echo "  ─────────────────────────────────────"
    "$binary" 2>&1 | sed 's/^/  │ /'
    echo "  ─────────────────────────────────────"
    echo ""
    PASS=$((PASS+1))
}

cd "$DIR"

build_app "Packet Filter" \
    "packet_filter/filter.fg" "packet_filter/main.c" "packet_filter/packet_filter"

build_app "Password Hasher" \
    "password_hasher/hasher.fg" "password_hasher/main.c" "password_hasher/password_hasher"

build_app "Sensor Monitor" \
    "sensor_monitor/monitor.fg" "sensor_monitor/main.c" "sensor_monitor/sensor_monitor"

build_app "BMP Parser" \
    "bmp_parser/bmp.fg" "bmp_parser/main.c" "bmp_parser/bmp_parser"

build_app "Ring Buffer IPC" \
    "ring_buffer_ipc/ringbuf.fg" "ring_buffer_ipc/main.c" "ring_buffer_ipc/ring_buffer_ipc"

echo "==============================="
echo "Results: $PASS passed, $FAIL failed"
echo "==============================="
