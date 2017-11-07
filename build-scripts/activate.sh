# This should be sourced from your shell as follows:
#   source actviate.sh

# Setup environment variables for working within a configured
# development environment.

# Note that we're setting up our new files to land in "droot", short
# for "development root."  This will contain all the development
# headers and libraries needed to build subsequent packages, but when
# we're done, we'll trim it down to only what's necessary to run
# python and put the results in `oroot'.

# Setup important environment variables that control the build
# process:

# pystat development root:
PYSTAT_DEV=`cd .. && pwd`
# pystat patches and original source files:
PYSTAT_SOURCES=$PYSTAT_DEV/mod-pystat
# Third party sources directory
S=$PYSTAT_DEV/build-deps
# Compilation work directory:
COMPILE_DIR=$PYSTAT_DEV/work
# Build tools prefix directory:
BTOOLS_PREFIX=$PYSTAT_DEV/build-tools
# Host dev system prefix directory:
HDEV_PREFIX=$PYSTAT_DEV/droot
# Host production install prefix directory:
IPREFIX=$PYSTAT_DEV/oroot
# "Host target prefix": the host production prefix as seen from inside
# the host.  Empty is the same as `/'.
HTGPREFIX=
# "Ugly" HTGPREFIX.  Some tools don't like being given an empty prefix
# variable for installation to the root directory.
UHTGPREFIX=/
# Host `/etc' directory:
EPREFIX=$PYSTAT_DEV/eroot
# Special directory used for unionfs mounts:
BUILDROOT=$PYSTAT_DEV/buildroot

export PATH=$BTOOLS_PREFIX/bin:$PATH
export MANPATH=$BTOOLS_PREFIX/share/man:$MANPATH
export PKG_CONFIG_PATH=$HDEV_PREFIX/lib/pkgconfig

# A word of warning: Sources that are compiled from Source RPM
# packages stage their work-in-progress in the `$HOME/rpmbuild'
# directory.  The build process regularly purges the contents of this
# directory, so make sure you don't have anything in that location!

# The following aliases are useful shortcuts for working with
# `unionfs-FUSE' and `proot' in the build process.  See the relevant
# section in the development environment setup for more information.

alias oroot_buildroot='unionfs \
  -o cow,use_ino,suid,dev,nonempty,relaxed_permissions \
  $IPREFIX=RW:/=RO $BUILDROOT'
alias droot_buildroot='unionfs -o \
  cow,use_ino,suid,dev,nonempty,relaxed_permissions \
  $HDEV_PREFIX=RW:$IPREFIX=RO:/=RO $BUILDROOT'
alias umount_buildroot='fusermount -u $BUILDROOT'
# Usage: chbuildroot COMMAND
alias chbuildroot='proot -r $BUILDROOT -b /dev'

# We need to use the `-b' (bind) option otherwise our unionfs-FUSE
# will have trouble accessing device nodes in the /dev directory
# (permission denied).  It works fine if the unionfs mount is done as
# superuser, but FUSE as a regular user... you get the idea.
