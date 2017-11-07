FROM scratch
# MAINTAINER quorten <quorten@example.com>
WORKDIR /
ENV HOME=/root
ADD oroot.tar /
# For some reason, the ownership on the home directory is not preserved.
# Fix it up from within the container.
RUN ["/bin/sh", "-c", "import os\nos.chown('/home/docker', 500, 500)"]
CMD ["/bin/python3"]
