# Final steps to create our Docker container image.

cd $IPREFIX/bin
cp $PYOS_SOURCES/sh.py sh
cd ..
mkdir sbin
cp $PYOS_SOURCES/{py_init,setuser} sbin/
mkdir etc/py_init.d

# Create your Dockerfile:
mkdir $PYOS_DEV/build
cd $PYOS_DEV/build
cp $PYOS_SOURCES/build/Dockerfile .
( cd $IPREFIX && tar --owner=root --group=root \
    -cf $PYOS_DEV/build/oroot.tar * )

# This is it!
sudo docker build -t pyos .

# Now that we're done, let's delete our created `sh.py' to avoid
# future problems when building sub-steps.
rm -f $IPREFIX/bin/sh
