# Now that we have finished installing Python into its production
# directory, we can add the remaining files needed for general use.

cd $IPREFIX

# Clean up `.unionfs' now that we're done with it.
rm -rf .unionfs

# It's very important to have `/tmp' inside of your container.
mkdir -p tmp
chmod ugo+rwxt tmp
mkdir root
chmod o-rwx root

mkdir etc
cd etc
cat >passwd <<EOF
root:x:0:0:root:/root:/bin/sh
docker:x:500:500:docker:/home/docker:/bin/sh
EOF
cat >shadow <<EOF
root:!!:17087:0:99999:7:::
docker:!!:17087:0:99999:7:::
EOF
cat >group <<EOF
root:x:0:
docker:x:500:
EOF
cat >gshadow <<EOF
root:::
docker:::
EOF
chmod go-rwx shadow gshadow
cd ..

mkdir -p home/docker
# sudo chown 500:500 home/docker
