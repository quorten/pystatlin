# Okay, openssl is our particular exception.  Here, CentOS is using an
# older version of openssl such that it does not properly use
# termios.h and instead uses termio.h.  Hence, we build an upstream
# tarball instead.  However, we still carry over the knowledge on how
# to run the Configure script from the spec file.

# rpm -i openssl-1.0.1e-42.el7.9.src.rpm
# cd $HOME/rpmbuild/SPECS
# rpmbuild -bp --nodeps openssl.spec
# cd ../BUILD/openssl-1.0.1e

cd $COMPILE_DIR
tar -zxf $S/openssl-1.0.2j.tar.gz
cd openssl-1.0.2j

# Whoa!  Does building with krb5 introduce circular dependencies?
# Anyways, I can tell you one thing, I definitely built OpenSSL
# without krb5 and was able to access HTTPS just fine.  Enough said,
# We don't need to include support for krb5 in our build.

#        --with-krb5-flavor=MIT \
#        --with-krb5-dir=/usr/local/musl  

# NOTE: We use `--libdir' below so as to avoid problems with the
# `Configure' script detecting `/lib64' under our unionfs and having
# that cause the libraries to end up getting installed in `/lib64' in
# our overlaid directory.  We want the libraries to end up in `/lib'
# in the overlaid directory.

CC=musl-gcc ./Configure \
        --prefix=$UHTGPREFIX --openssldir=$HTGPREFIX/openssl \
        --libdir=$HTGPREFIX/lib \
        zlib enable-camellia enable-seed enable-tlsext enable-rfc3779 \
        enable-cms enable-md2 no-mdc2 no-rc5 no-ec2m no-gost no-srp \
        linux-x86_64

# Fix up MAKEDEPPROG.  This is necessary due to the special code that
# recognizes gcc as an exception, yet we are not configuring a full
# formal cross compiling environment here because we are lazy, so we
# can't use the CROSS_COMPILE variable, which is our alternative.

sed -i -e 's/^MAKEDEPPROG=.*$/MAKEDEPPROG= musl-gcc/' Makefile

make depend

# Because we can't setup LDFLAGS via the configure script, we instead
# pass it in via the make command line.

make all -j`getconf _NPROCESSORS_ONLN` LDFLAGS=-static
# We actually don't need to "make rehash" because Python doesn't
# evaluate HTTPS certificates anyways.
# make rehash
# nosudo make install
droot_buildroot
chbuildroot /bin/sh -c "cd $COMPILE_DIR/openssl-1.0.2j && make install"
umount_buildroot
cd ..
rm -rf openssl-1.0.2j
