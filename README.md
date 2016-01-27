# qemu-bz-testers

This repo contains scripts that I've found helpful to reproduce various BZs for QEMU.

The intent is to make it easy to run QEMU instances, and pass QMP/HMP commands to QEMU, to aid in either reproducing a bug, or using 'git bisect run' to find regressions.

I extracted the 'common.qemu' file from qemu-kvm/tests/qemu-iotests so that I could use it stand-alone, and just include it in each reproducer script.

This initial import is not generalized yet; there are a few (easy to find) hardcoded paths.  This will eventually be fixed, but if I waited to import it until I did fix it, who knows when it would end up here.  This way it may prove useful to someone in the interim.

To see how to use it, look at one of the bz*.sh files - it should be fairly straightforward.
