#!/bin/bash

# Copyright (C) 2016 Red Hat, Inc.
#
# Jeff Cody <jcody@redhat.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.



## ucomment to rebuild and install binaries - useful for
# git bisect run
# ./virt.build

# everything to launch, and talk with QEMU
. virt.qemu

TEST_IMG="$TEST_DIR/test.qcow2"

cleanup()
{
    _cleanup_qemu
    rm -f "${TEST_IMG}"
}

trap "cleanup; exit ${QEMU_STATUS[$h]}" 0 1 2 3 15


$QEMU_IMG create -f qcow2 "${TEST_IMG}" 512M

qemu_comm_method="qmp"
_launch_qemu -drive file="${TEST_IMG}",if=virtio
h=$QEMU_HANDLE

echo "Sending QEMU commands"

# in each of these _send_qemu_cmd instances, the last string is the expected
# result for success.  If not seen, it will timeout with a failure error
# code (caught and returned by our trap, above)

_send_qemu_cmd $h "{ 'execute': 'qmp_capabilities' }" "return"


# First live snapshot, new overlay as active layer
_send_qemu_cmd $h "{ 'execute': 'blockdev-snapshot-sync', 
                                'arguments': { 
                                             'device': 'virtio0',
                                             'snapshot-file':'tmp.qcow2',
                                             'format': 'qcow2'
                                             }
                    }" "return"


# Block commit on active layer, push the new overlay into base
_send_qemu_cmd $h "{ 'execute': 'block-commit',
                                'arguments': {
                                                 'device': 'virtio0'
                                              }
                    }" "READY"

_send_qemu_cmd $h "{ 'execute': 'block-job-complete',
                                'arguments': {
                                                'device': 'virtio0'
                                              }
                   }" "COMPLETED"

# New live snapshot, new overlays as active layer
_send_qemu_cmd $h "{ 'execute': 'blockdev-snapshot-sync',
                                'arguments': {
                                                'device': 'virtio0',
                                                'snapshot-file':'tmp2.qcow2',
                                                'format': 'qcow2'
                                              }
                   }" "return"

echo "Success!"

