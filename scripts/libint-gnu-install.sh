#!/bin/bash
#
# Description: Libintautomated download and installation
# Author: (c) 2023 Dr. Vignesh Mahalingam
# Purpose: For Software installation in Temple university clusters: Owl's nest & compute
clear
date
Software="libint"
echo "----------------------"
echo "$Software installation"
echo "----------------------"
name="libint"
version="2.8.0"
extension="tgz"
taroption="xzf"
compiler="gnu"
FILE=$name-$version.$extension
weburl="https://github.com/evaleev/libint.git"

rootdir="/home/tur09027/work"
appsdir="$rootdir/apps"
libsdir="$rootdir/libs"
downloaddir="$appsdir/downloads"
sourcedir="$libsdir/$name-$version-$compiler"
moduledir="$libsdir/modulefiles"

nthreads=12

cd $downloaddir
if [ -d $downloaddir/$name ]; then
	rm -rf $downloaddir/$name
fi
echo "Extracting from github archive ..."
git clone $weburl
cd $downloaddir/$name
./autogen.sh
# Loading dependency modules
# Reproducibilty depends on modules. So, decide for yourself which one you need. These are the latest/ only modules available.

module load cmake/3.22.1
module load gcc/9.3.0
module load boost/1.76.0

if [ -d $downloaddir/build-$name ]; then
	rm -rf $downloaddir/build-$name
fi
mkdir -p $downloaddir/build-$name
cd $downloaddir/build-$name
$downloaddir/$name/configure CC='gcc' CXX='g++' # CPPLIBS='-lgmp'
make export
tar $taroption $name-$version.$extension
cd $downloaddir/build-$name/$name-$version
cmake . -DCMAKE_INSTALL_PREFIX=$sourcedir -DCMAKE_CXX_COMPILER='g++' -DLIBINT2_BUILD_SHARED_AND_STATIC_LIBS=ON
cmake --build . -j $nthreads
cmake --build . --target install -j $nthreads

if [ -d $moduledir/$name ]; then
        echo "$moduledir/$name exists"
else
        mkdir -p "$moduledir/$name"
fi
if [ -f $moduledir/$name/$version-$compiler.lua ]; then
        rm -f $moduledir/$name/$version-$compiler.lua
fi

cat > $moduledir/$name/$version-$compiler.lua << EOF
-- -*- $name/$version-$compiler.lua -*- --

whatis("LIBINT Library for GNU Compilers")
help([[
This module provides the LIBINT library with functions to compute
many-body integrals over Gaussian functions in electronic and
molecular structure theory.

The components of this module have been compiled with and for the
Intel C++ compilers.

This module sets the environment variables: CPATH,
LIBRARY_PATH, and LIBINT_HOME

]])
family("libint")
conflict("intel-compiler")
setenv("LIBINT_HOME","$sourcedir")
prepend_path("CPATH","$sourcedir/include")
prepend_path("LIBRARY_PATH","$sourcedir/lib")
prepend_path("LD_LIBRARY_PATH","$sourcedir/lib")
prepend_path("PKG_CONFIG_PATH","$sourcedir/lib/pkgconfig")
EOF
# Remove build directories
rm -rf $downloaddir/$name
rm -rf $downloaddir/build-$name
