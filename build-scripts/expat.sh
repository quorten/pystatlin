rpm -i $S/expat-*.src.rpm
cd $HOME/rpmbuild/SPECS
rpmbuild -bp --nodeps expat.spec
cd ../BUILD/expat-*
./configure CC=musl-gcc LDFLAGS=-static --prefix=$HDEV_PREFIX --disable-shared

# We must do things a little weird here.  `expat' uses `libtool' to
# link rather than plain `gcc', so we must setup LDFLAGS the `libtool'
# way rather than the `gcc' way.  Unfortunately, we can't set this up
# right away in the `configure' command line because `configure' does
# the linking sanity check using `gcc' rather than `libtool'.  Let's
# just put it this way: The `expat' build system is slightly
# defective.

make -j`getconf _NPROCESSORS_ONLN` LDFLAGS='-all-static'
# nosudo make install
make install
cd $HOME/rpmbuild
rm -rf *
