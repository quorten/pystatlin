rpm -i $S/bzip2-*.src.rpm
cd $HOME/rpmbuild/SPECS
rpmbuild -bp --nodeps bzip2.spec
cd ../BUILD/bzip2-*
make CC=musl-gcc LDFLAGS=-static -j`getconf _NPROCESSORS_ONLN`
# nosudo make install
make install PREFIX=$HDEV_PREFIX
cd $HOME/rpmbuild
rm -rf *
