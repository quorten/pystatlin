# First, install various development tools onto our CentOS machine
# that will make things easier.
sudo yum -y install yum-utils
sudo yum -y groupinstall 'Development Tools'
# sudo yum -y install openssl-devel libcurl-devel expat-devel wish \
#   'perl(ExtUtils::MakeMaker)' readline-devel
# sudo yum -y install glibc-static ncurses-static readline-static \
#   zlib-static expat-static bzip2-devel openssl-static
# Misc. build depends that `yum' will complain about if not present.
# These are either disabled by our own build processes or not needed
# on install.
# sudo yum -y install gpm-devel check-devel

######################################################################

# Development environment initialization.

# Create the relevant directories.

mkdir -p $S $COMPILE_DIR $BTOOLS_PREFIX $HDEV_PREFIX $IPREFIX \
  $BUILDROOT
mkdir -p $BTOOLS_PREFIX/bin $IPREFIX/bin $IPREFIX/lib \
  $HDEV_PREFIX/bin $HDEV_PREFIX/lib

######################################################################

# Next, let's download all Python runtime library dependencies in
# advance.

# Okay, let's go with musl as our C library for our static-linked
# Python binary.

cd $S

# musl-libc:
# 20161006/http://www.musl-libc.org/how.html
curl -L -O http://www.musl-libc.org/releases/musl-1.1.15.tar.gz

# As for the rest of the libraries that we need to build Python, we
# might as well build them from the source so that they can depend on
# musl as our C library rather than the native glibc.

# Now, to make things easier, let's use the CentOS Source RPMs as a
# starting point for vetting our build command lines, some of which
# are conveniently already written in the spec files in a standard
# form for us.  This can be more convenient than going directly to the
# upstream tarballs, but at the same time, the distribution sources
# may be a little older and use more patches hacked in to fix various
# problems discovered in the meantime.

# 20161006/https://wiki.centos.org/HowTos/RebuildSRPM

yumdownloader --source \
  libffi \
  ncurses readline \
  zlib bzip2 expat openssl \
  curl \
  python

# Note: libcurl is not needed by Python.  However, `curl' is useful
# for testing that HTTP/HTTPS networking is functional.

# These are upstream downloads:

curl -L -O https://www.openssl.org/source/openssl-1.0.2j.tar.gz
curl -L -O https://www.python.org/ftp/python/2.7.12/Python-2.7.12.tar.xz
curl -L -O https://www.python.org/ftp/python/3.5.1/Python-3.5.1.tar.xz

# Let's also take care of other downloads in advance that we'll need
# to do.

git clone --mirror https://github.com/rpodgorny/unionfs-fuse.git
git clone --mirror https://github.com/proot-me/PRoot.git
git clone --mirror https://github.com/bendmorris/static-python.git
git clone --mirror https://github.com/phusion/baseimage-docker.git
git clone --mirror https://github.com/jiacai2050/pysh.git

######################################################################

# Oh yeah, and this is important.  You can use
# `yumdownloader --source' (from `yum-utils') to download source
# packages automatically and much more easily than the `curl' commands
# below.  Note, however, that I include this for posterity, because it
# seems the upstream server does not keep old versions of SRPMs
# around, unfortunately.  So, this is to document what worked for me,
# as of 2016-10-07.

# 20161009/https://access.redhat.com/solutions/10154
# 20161009/https://linux.die.net/man/1/yumdownloader

# curl -L -O http://vault.centos.org/7.2.1511/os/Source/SPackages/readline-6.2-9.el7.src.rpm
# curl -L -O http://vault.centos.org/7.2.1511/os/Source/SPackages/zlib-1.2.7-15.el7.src.rpm
# curl -L -O http://vault.centos.org/7.2.1511/os/Source/SPackages/bzip2-1.0.6-13.el7.src.rpm
# # target version: openssl 1:1.0.1e-51.el7_2.7
# curl -L -O http://vault.centos.org/7.2.1511/os/Source/SPackages/openssl-1.0.1e-42.el7.9.src.rpm
# curl -L -O http://vault.centos.org/7.2.1511/os/Source/SPackages/curl-7.29.0-25.el7.centos.src.rpm
# curl -L -O http://vault.centos.org/7.2.1511/os/Source/SPackages/expat-2.1.0-8.el7.src.rpm
# curl -L -O http://vault.centos.org/7.2.1511/os/Source/SPackages/ncurses-5.9-13.20130511.el7.src.rpm
# curl -L -O http://vault.centos.org/7.2.1511/os/Source/SPackages/python-2.7.5-34.el7.src.rpm
# curl -L -O http://vault.centos.org/7.2.1511/os/Source/SPackages/libffi-3.0.13-16.el7.src.rpm

######################################################################

# Backstory.  Further analysis of selected dependencies for those who
# are interested.

# So what dependencies should we go for?
# 20161006/https://bede.io/build-python-from-source/

# Okay, let's take a look from the spec file of the CentOS Python
# source RPM.

# rpm -i python-2.7.5-34.el7.src.rpm
# grep '^BuildRequires' ~/rpmbuild/SPECS/python.spec
# rm -rf rpmbuild

# These are the required build executables (not needed on the deployed
# target machine):

# BuildRequires: autoconf
# BuildRequires: findutils
# BuildRequires: gcc-c++
# BuildRequires: pkgconfig
# BuildRequires: tar

# Of those, these are the libraries, this time sorted in order of
# priority for build inclusion:

# BuildRequires: glibc-devel
# BuildRequires: ncurses-devel
# BuildRequires: readline-devel
# BuildRequires: libffi-devel
# BuildRequires: zlib-devel
# BuildRequires: expat-devel >= 2.1.0
# BuildRequires: bzip2
# BuildRequires: bzip2-devel
# BuildRequires: openssl-devel
# BuildRequires: tcl-devel
# BuildRequires: tk-devel
# BuildRequires: tix-devel
# BuildRequires: gmp-devel
# BuildRequires: libdb-devel
# BuildRequires: gdbm-devel
# BuildRequires: sqlite-devel
# BuildRequires: libX11-devel
# BuildRequires: libGL-devel
# BuildRequires: bluez-libs-devel
# BuildRequires: systemtap-sdt-devel
# BuildRequires: valgrind-devel

# Whoa!  That's a lot.  Okay, now would be the time to sift it down to
# the bare minimum.

# libffi

# `libffi' is only necessary if you want support for dynamic module
# loading of native libraries.  This happens most often when using
# third-party packages installed with `pip'.  Note that it's possible
# to compile these modules into your Python interpreter considering
# that you're custom building it.

# zlib
# bzip2
# expat
# openssl

# For HTTPS network access, you will almost definitely need all of the
# previous libraries.  Maybe not `expat', and possibly you can skimp
# on `bzip2', but I haven't tested that.

# gmp

# GMP may be required for bignum support, but I haven't looked into
# the details of this myself.

# libdb
# gdbm
# sqlite

# You'll probably know if your application requires any of the
# previous local database access libraries.  If it uses only remote
# databases, you likely won't need these.

# ncurses
# readline

# `ncurses' and `readline' are nice if you want if you want to see
# colored text output and edit command lines when you type
# interactively at the Python interpreter.

# libX11
# libGL
# tcl
# tix
# tk

# You'll probably know if your application requires any of the above
# graphics/GUI libraries.  `tcl' and `tix' are primarily of interest
# for Python's use of `tk', which is used by IDLE and Python's
# built-in GUI interfaces.

# systemtap
# bluez
# valgrind

# `valgrind' might be used for Python debugging.  I'm not sure if the
# rest are even required library dependencies of Python.

######################################################################

# First of all, let's build some tools to make a more convenient
# development environment.

# For those who are not familiar, `fakeroot' is used in the Debian
# package building process to isolate the files created by
# `make install' so that they can be placed in a package archive.

# Okay, this time we're doing a unionfs FUSE to do the equivalent of
# what we do in Debian as a `fakeroot'.  Why not use `fakeroot'?
# Well, I probably could do that, but I feel it might be too
# particular to Debian `libc' and such, but FUSE is only particular to
# the Linux kernel APIs, where are shared common across both CentOS
# and Debian.  So there you go, that's the advantage.  The
# disadvantage is additional complexity in mount point management.

# 20161010/https://github.com/rpodgorny/unionfs-fuse

# NOTE: There's a particularly strong advantage of using unionfs over
# `fakeroot' LD_PRELOAD shared library substitution.  Particularly,
# the technique works with static-linked binaries, whereas LD_PRELOAD
# obviously only works on dynamic executables with shared libraries.

sudo yum -y install fuse fuse-devel # Important!
cd $COMPILE_DIR
git clone $S/unionfs-fuse.git
cd unionfs-fuse
git apply --index $PYSTAT_SOURCES/uninstall-unionfs.diff
git commit -m 'Add uninstall target to Makefile.'
make -j`getconf _NPROCESSORS_ONLN`
# nosudo make install
make install PREFIX=$BTOOLS_PREFIX
cd ..
rm -rf unionfs-fuse

##########

# `proot' is useful for not needing to be superuser to do a `chroot'.

sudo yum -y install libtalloc-devel
cd $COMPILE_DIR
git clone $S/PRoot.git
cd PRoot/src
make -j`getconf _NPROCESSORS_ONLN`
# nosudo make install
make install PREFIX=$BTOOLS_PREFIX
cd ..
mkdir -p $BTOOLS_PREFIX/share/man/man1
cp doc/proot/man.1 $BTOOLS_PREFIX/share/man/man1/proot.1
cd ..
rm -rf PRoot

# Alas, you can see that we still needed to do sudo a few times above
# to install the build dependencies, but there's no denying the
# obvious about the FUSE headers and tools.
