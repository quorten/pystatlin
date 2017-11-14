# Now time for the big deal... Python.

# REMEMBER to build that dummy Python 2 I've mentioned above.

# NOTE that we have to use `UHTGPREFIX' instead of `HTGPREFIX' here
# because otherwise we sometimes get runtime issues with Python not
# being able to find its installed root.

cd $COMPILE_DIR
xz -dc $S/Python-2.7.12.tar.xz | tar -x
cd Python-2.7.12
patch -p1 <$PYSTAT_SOURCES/static-prep2p1.diff
sed -i -e "s|^SSL=/usr/local/musl\$|SSL=/usr|g" \
  Modules/Setup.dist
make -f Static.make PREFIX=$UHTGPREFIX \
  MAKE_ARGS=-j`getconf _NPROCESSORS_ONLN` \
  PYTHON=$BTOOLS_PREFIX/bin/python2.7

# Make sure the target Python lib directory is clean, otherwise the
# installation won't work correctly since our use of union file
# systems will confuse the install scripts.
rm -rf $IPREFIX/lib/python2.7

# nosudo make install

# droot_buildroot
# chbuildroot /bin/sh -c "cd $COMPILE_DIR/Python-2.7.12 && make install"
# umount_buildroot

# Yeah, we'd love to use our proot to avoid being superuser to install
# to our modified prefix; unfortunately, I have found out that the
# results of running python under proot are different enough that for
# the sake of quality, I must strongly recommend performing the
# install under a real chroot.

sudo $BTOOLS_PREFIX/bin/unionfs -o cow,allow_other,use_ino,suid,dev,nonempty \
  $HDEV_PREFIX=RW:$IPREFIX=RO:/=RO $BUILDROOT
sudo chroot $BUILDROOT \
  /bin/sh -c "cd $COMPILE_DIR/Python-2.7.12 && make install"

# Finally, one of the goofiest-seeming fixups.  Manual job here.
# Beware, `pip' upgrades could break things!
# You need to edit `setuptools/dist.py' to exclude dependency on
# `windows'_support to avoid "dlopen import error."
sudo sed -i $HDEV_PREFIX/lib/python2.7/site-packages/setuptools/dist.py \
  -e 's/^\(from setuptools import windows_support\)$/# \1/' \
  -e 's/^\( *\)\(windows_support.hide_file(egg_cache_dir)\)$/\1# \2/g'
# Update our Python cache now that we've modified a file.
sudo chroot $BUILDROOT /bin/python2 -m compileall \
  /lib/python2.7/site-packages/setuptools/dist.py

sudo fusermount -u $BUILDROOT

cd ..
# nosudo rm
rm -rf Python-2.7.12

# Now that we're done with that su to root stuff (yes, only performed
# for the sake of installing Python), we should de-root the files in
# our install prefix.
cd $HDEV_PREFIX
sudo chown $USER:$GROUPS -R .

# Finally, we can move over the production Python stuff to the
# production root.
mv $HDEV_PREFIX/bin/{py*,idle*,2to3*,easy_install*,pip*} $IPREFIX/bin/
mkdir -p $IPREFIX/include/python2.7
cp $HDEV_PREFIX/include/python2.7/pyconfig.h $IPREFIX/include/python2.7/
# mv $HDEV_PREFIX/include/python2.7 $IPREFIX/include/
mv $HDEV_PREFIX/lib/python2.7 $IPREFIX/lib/

# We also like to strip all symbols from the Python executable to make
# it look smaller.
strip -s $IPREFIX/bin/python2.7
