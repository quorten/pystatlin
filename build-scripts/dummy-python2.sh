# Here's the commands I've used to setup a "dummy" helper Python
# installation, to be used only during the build process, mainly for
# Cython.  I know, I know, I could make it more elegant like the rest
# of my updated scripts, but for now, it works.

sudo mkdir /usr/local/dummy

cd $COMPILE_DIR
xz -dc $S/Python-2.7.12.tar.xz | tar -x
cd Python-2.7.12
./configure --prefix=/usr/local/dummy --with-ensurepip=install
make -j`getconf _NPROCESSORS_ONLN`
sudo make install
cd ..
sudo rm -rf Python-2.7.12
sudo /usr/local/dummy/bin/pip install cython
