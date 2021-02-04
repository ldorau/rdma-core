#!/bin/bash
set -e

SRCDIR=`dirname $0`
BUILDDIR="$SRCDIR/build"

mkdir -p "$BUILDDIR"

if hash cmake3 2>/dev/null; then
    # CentOS users are encouraged to install cmake3 from EPEL
    CMAKE=cmake3
else
    CMAKE=cmake
fi

if hash ninja-build 2>/dev/null; then
    # Fedora uses this name
    NINJA=ninja-build
elif hash ninja 2>/dev/null; then
    NINJA=ninja
fi

cd "$BUILDDIR"

if [ "x" == "x" ]; then
    cmake \
        -DENABLE_VALGRIND=0 \
        -DCMAKE_BUILD_TYPE='Debug' \
        -DCMAKE_INSTALL_PREFIX='/usr' \
        -DCMAKE_INSTALL_RUNDIR='/run' \
        -DCMAKE_INSTALL_SBINDIR='/usr/bin' \
        -DCMAKE_INSTALL_LIBDIR='/usr/lib' \
        -DCMAKE_INSTALL_LIBEXECDIR='/usr/lib/rdma' \
        -DCMAKE_INSTALL_SYSCONFDIR='/etc' \
        -DCMAKE_INSTALL_PERLDIR='/usr/share/perl5/vendor_perl' \
        ..
    make -j$(nproc)
    make -j$(nproc)
else
    $CMAKE -DIN_PLACE=1 -GNinja ${EXTRA_CMAKE_FLAGS:-} ..
    $NINJA
fi

if [ "$1" == "install" ]; then
    make -j$(nproc)
    sudo make -j$(nproc) install

    pkgdir=""
    cd ../redhat
    sudo install -D --mode=0644 rdma.conf "${pkgdir}/etc/rdma/rdma.conf"
    sudo install -D --mode=0644 rdma.mlx4.conf "${pkgdir}/etc/rdma/mlx4.conf"
    sudo install -D --mode=0755 rdma.mlx4-setup.sh "${pkgdir}/usr/lib/rdma/mlx4-setup.sh"
    sudo install -D --mode=0644 rdma.mlx4.sys.modprobe "${pkgdir}/usr/lib/modprobe.d/libmlx4.conf"
    sudo install -D --mode=0755 rdma.modules-setup.sh "${pkgdir}/usr/lib/dracut/modules.d/05rdma/module-setup.sh"
fi
