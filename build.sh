#!/bin/sh

set -e

OPTS='-Drelease-safe'

zig build $@ $OPTS
