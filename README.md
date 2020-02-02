These are some scripts and source code modifications that are useful
for building a statically-linked Python 2 or Python 3 binary, and
packaging that up into a environment suitable for running a Docker
container.

For general documentation, see the `doc` directory.  It is broken down
as follows:

* Required manual setup steps:
    * `docker-setup.txt`
    * `build-root.txt`
* Optional manual setup steps:
    * `libffi-setup.txt`
* The remaining documents are informative.

Please note that although this wasn't the intent, perhaps this
repository is more useful for the documentation contained within than
the code itself.  In particular, my documentation about how code
libraries work is quite insightful and informative.

For scripts to execute the build, see `build-scripts`.  The `total.sh`
script is an example that runs everything.  You don't actually need to
run everything to perform a useful build, though.

* There are lots of useful comments related to general usage
  documentation in the build scripts.  Do take the time to read some
  of them before you run the build scripts.  For example:

    * A word of warning: Sources that are compiled from Source RPM
      packages stage their work-in-progress in the `$HOME/rpmbuild`
      directory.  The build process regularly purges the contents of
      this directory, so make sure you don't have anything in that
      location!

CentOS 7 (as documented in the beginning of `bootstrap.sh`) is the
preferred build system to run these scripts on.  Running them on
significantly different systems will require some modifications.

Where did these patches come from?
----------------------------------

Many of these patches were copied from other sources, which are noted
in the documentation and/or build scripts.  The licenses to those
works are indicated in their respective original sources.  The
remaining original work is in the public domain.  (In jurisdictions
that are too dumb to recognize the public domain, there is the legal
code of the UNLICENSE included in the `LICENSE` file as a means to
emulate the public domain in less featureful political machines.  I
wanted to choose the UNLICENSE to keep the executable legal code short
and simple, even though that particular legal code is not very well
tested.)
