# The following configuration is not necessary for Docker images.
# However, it is useful if you want to try out your system root via
# chroot.

cd $IPREFIX

# Important.  This is how you initialize the much-needed /dev
# directory in a chroot.  Once you do that, you can run a
# static-linked process with ease in your chroot.  Note the mknod
# commands commands must be run as root.  Also note that in our case,
# we are skimping on mounting `/dev/shm' and `/dev/pts'.

# 20161008/http://www.tldp.org/LDP/lfs/LFS-BOOK-6.1.1-HTML/chapter06/devices.html

mkdir dev
cd dev
sudo mknod -m 600 console c 5 1
sudo mknod -m 666 null c 1 3
sudo mknod -m 666 zero c 1 5
sudo mknod -m 666 ptmx c 5 2
sudo mknod -m 666 tty c 5 0
sudo mknod -m 444 random c 1 8
sudo mknod -m 444 urandom c 1 9
sudo chown -v root:tty console ptmx tty
sudo mkdir -v pts
sudo mkdir -v shm
# sudo mount -vt devpts -o gid=4,mode=620 none pts
# sudo mount -vt tmpfs none shm
cd ..

# Now, you're wondering why networking doesn't work inside the chroot
# jail?  Here's why.  Make sure your `/etc/resolv.conf' is setup.
# Also, keeping around the openssl command is useful for diagnosing
# networking.  At least it gives back better error messages than
# Python.
cp /etc/resolv.conf etc/resolv.conf

# VERY IMPORTANT!  Copying `/etc/resolv.conf' to the chroot is only
# necessary when you are doing chroot on the native system, but for
# Docker containers, Docker automatically adds and sets up this file
# on container creation/execution (along with a few other network
# configuration files).

# Also note that Docker creates the `/dev' directory entirely for you,
# so you don't have to do anything to make sure the device nodes are
# initialized in advance when you are building a container from
# scratch.

# Also, another important note.  I've only got pip to work with a very
# specific version, upgrades break the pip running in the container.
# I know, the general solution is to compile with static linking,
# otherwise if I do compile with ctypes, I will also need to modify
# the colorama module to remove Windows support.

# Specifically, openssl diagnosis is done like this:
# openssl s_client -connect www.example.com:443
# 20161011/http://askubuntu.com/questions/116020/python-https-requests-urllib2-to-some-sites-fail-on-ubuntu-12-04-without-proxy
