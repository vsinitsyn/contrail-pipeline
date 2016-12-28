#!/bin/bash -e

sudo apt-get update
which equivs-control || sudo apt-get install -y equivs

cd build/packages
for d in */ ; do
    pushd $d
    sudo mk-build-deps -t "apt-get -o Debug::pkgProblemResolver=yes -y" -i debian/control
    #sudo dpkg -i $d*.deb
    popd
done
cd ../..

export KERNELDIR=/lib/modules/$(basename `ls -d /lib/modules/*|tail -1`)/build
export RTE_KERNELDIR=${KERNELDIR}

sudo scons --root=`pwd` --kernel-dir=$KERNELDIR install
sudo scons --root=`pwd` --kernel-dir=$KERNELDIR test
