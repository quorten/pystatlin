rpm -i $S/zlib-*.src.rpm
cd $HOME/rpmbuild/SPECS
rpmbuild -bp --nodeps zlib.spec
cd ../BUILD/zlib-*
CC=musl-gcc LDFLAGS=-static ./configure --prefix=$HDEV_PREFIX --static
make -j`getconf _NPROCESSORS_ONLN`
# nosudo make install
make install
# Our RPM spec file instructs us to build minizip too.
cd contrib/minizip
autoreconf --install
./configure CC=musl-gcc LDFLAGS=-static --prefix=$HDEV_PREFIX --disable-shared
make -j`getconf _NPROCESSORS_ONLN`
# nosudo make install
make install
cd $HOME/rpmbuild
rm -rf *
