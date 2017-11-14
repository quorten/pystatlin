rpm -i $S/readline-*.src.rpm
cd $HOME/rpmbuild/SPECS
rpmbuild -bp --nodeps readline.spec
cd ../BUILD/readline-*
./configure CC=musl-gcc LDFLAGS=-static --prefix=$HDEV_PREFIX --disable-shared

# This one gets tricky.  We have an audit patch that wants to have
# some Linux-specific headers available.  (But that's only because
# we're choosing to build with Red Hat's patches.)  Okay, let's setup
# some symlinks.
# nosudo
ln -s /usr/include/linux $HDEV_PREFIX/include/linux
ln -s /usr/include/asm $HDEV_PREFIX/include/asm
ln -s /usr/include/asm-generic $HDEV_PREFIX/include/asm-generic

make -j`getconf _NPROCESSORS_ONLN`
# nosudo make install
make install
cd $HOME/rpmbuild
rm -rf *
