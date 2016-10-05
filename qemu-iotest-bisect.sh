#!/bin/sh
#
# Simple script intended to be used with QEMU to git bisect
# via qemu-iotests.
#
# Just pass the script the tests to check, or nothing for all
# of them.  E.g., 'git bisect run qemu-iotest-bisect 085'
#
# This is intended to be run from your build directory
# (right now it assumes building in-tree)

make -j12
pushd tests/qemu-iotests
./check -qcow2 $@
ret=$?
popd
exit $ret

