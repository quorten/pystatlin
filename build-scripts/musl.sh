# Okay, now we can build our first component, musl-libc.

# Beware!  The easy setup of the musl-gcc wrapper will not provide you
# with a C++ development toolchain.  For that, you have to rebuild gcc
# natively with musl, or go to the `musl-cross' project here:

20161009/http://www.musl-libc.org/faq.html
20161009/https://bitbucket.org/GregorR/musl-cross

cd $COMPILE_DIR
tar -zxf $S/musl-1.1.15.tar.gz
cd musl-1.1.15
./configure --prefix=$HDEV_PREFIX
make -j`getconf _NPROCESSORS_ONLN`
# nosudo make install
make install
# Technically musl-gcc is a build tool and not a host executable, so
# let's move it to the correct location.
mv $HDEV_PREFIX/bin/musl-gcc $BTOOLS_PREFIX/bin/musl-gcc
which musl-gcc
cd ..
rm -rf musl-1.1.15

# TODO: Note: The installation process normally create /lib/ld-musl.so
# or something like that.
