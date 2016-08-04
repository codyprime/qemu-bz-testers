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

TEST_DIR=/mnt/test

USER=`whoami`
SRC_IMG="/home/${USER}/Fedora-Cloud-Base-23-20151030.x86_64.qcow2"
TEST_IMG="$TEST_DIR/target1.qcow2"

cleanup()
{
    _cleanup_qemu
    rm -f "${TEST_IMG}"
}

trap "cleanup; exit ${QEMU_STATUS[$h]}" 0 1 2 3 15

qemu_comm_method="qmp"
_launch_qemu -device virtio-scsi-pci,id=virtio_scsi_pci0,bus=pci.0,addr=06 \
	     -drive id=drive_image1,if=none,cache=none,snapshot=off,aio=native,file="${SRC_IMG}"

h=$QEMU_HANDLE

echo "Sending QEMU commands"

echo -n "capabilities... "
# in each of these _send_qemu_cmd instances, the last string is the expected
# result for success.  If not seen, it will timeout with a failure error
# code (caught and returned by our trap, above)

_send_qemu_cmd $h "{ 'execute': 'qmp_capabilities' }" "return"

echo -n "drive-mirror... "

# First live snapshot, new overlay as active layer
QEMU_COMM_TIMEOUT=60 _send_qemu_cmd $h  \
        "{'execute': 'drive-mirror',
         'arguments': 
                 {  'device': 'drive_image1',
                    'mode': 'absolute-paths',
                    'format': 'qcow2',
                    'target': '${TEST_IMG}',
                    'sync': 'full' },
          'id': '8eq6T4TN'}" "BLOCK_JOB_READY"

echo "block-job-complete... "

# Block commit on active layer, push the new overlay into base
_send_qemu_cmd $h \
	"{ 'execute': 'block-job-complete',
	   'arguments':
		 { 'device': 'drive_image1' }
	  }" "BLOCK_JOB_COMPLETED"

echo "Success!"

