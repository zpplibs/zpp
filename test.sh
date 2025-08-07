#!/bin/sh

echo '\n# ==================================================\n# debug\n' && \
zig build test && \
echo '\n# ==================================================\n# safe\n' && \
zig build -Doptimize=ReleaseSafe test && \
echo '\n# ==================================================\n# small\n' && \
zig build -Doptimize=ReleaseSmall test && \
echo '\n# ==================================================\n# fast\n' && \
zig build -Doptimize=ReleaseFast test
