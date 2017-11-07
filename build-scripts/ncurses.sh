rpm -i $S/ncurses-*.src.rpm
cd $HOME/rpmbuild/SPECS
rpmbuild -bp ncurses.spec
# rpmbuild -bc ncurses.spec
cd ../BUILD/ncurses-*

#  --with-terminfo-dirs=/etc/terminfo:/usr/share/terminfo
./configure CC=musl-gcc LDFLAGS=-static --prefix=$HTGPREFIX \
  --with-pkg-config-libdir=$HTGPREFIX/lib/pkgconfig \
  --without-cxx-binding --without-ada --with-ospeed=unsigned \
  --enable-hard-tabs --enable-xmc-glitch --enable-colorfgbg \
  --enable-overwrite \
  --enable-pc-files \
  --with-termlib=tinfo \
  --with-chtype=long \
  --with-xterm-kbs=DEL \
  --with-ticlib
make -j`getconf _NPROCESSORS_ONLN`
# nosudo make install
droot_buildroot
chbuildroot /bin/sh -c "cd $HOME/rpmbuild/BUILD/ncurses-* && make install"
umount_buildroot
cd $HOME/rpmbuild
rm -rf *

# Move the production files into the production prefix.
mkdir $IPREFIX/lib
rm -rf $IPREFIX/lib/terminfo
mv $HDEV_PREFIX/lib/terminfo $IPREFIX/lib/
mkdir $IPREFIX/share
rm -rf $IPREFIX/share/tabset
mv $HDEV_PREFIX/share/tabset/ $IPREFIX/share/
rm -rf $IPREFIX/share/terminfo
mv $HDEV_PREFIX/share/terminfo/ $IPREFIX/share/
