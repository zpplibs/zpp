#!/bin/sh

zig build test && \
echo '\n# ==================================================\n' && \
zig build test -Drelease-safe && \
echo '\n# ==================================================\n' && \
zig build test -Drelease-fast && \
echo '\n# ==================================================\n' && \
zig build test -Drelease-small
