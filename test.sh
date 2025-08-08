#!/bin/sh

CURRENT_DIR=$PWD
# locate
if [ -z "$BASH_SOURCE" ]; then
    SCRIPT_DIR=`dirname "$(readlink -f $0)"`
elif [ -e '/bin/zsh' ]; then
    F=`/bin/zsh -c "print -lr -- $BASH_SOURCE(:A)"`
    SCRIPT_DIR=`dirname $F`
elif [ -e '/usr/bin/realpath' ]; then
    F=`/usr/bin/realpath $BASH_SOURCE`
    SCRIPT_DIR=`dirname $F`
else
    F=$BASH_SOURCE
    while [ -h "$F" ]; do F="$(readlink $F)"; done
    SCRIPT_DIR=`dirname $F`
fi

cd $SCRIPT_DIR

echo '\n# ==================================================\n# debug\n' && \
zig build test $@ && \
echo '\n# ==================================================\n# safe\n' && \
zig build -Doptimize=ReleaseSafe test $@ && \
echo '\n# ==================================================\n# small\n' && \
zig build -Doptimize=ReleaseSmall test $@ && \
echo '\n# ==================================================\n# fast\n' && \
zig build -Doptimize=ReleaseFast test $@
