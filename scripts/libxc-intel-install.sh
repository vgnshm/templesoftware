#!/bin/bash
#
# Description: Libxc automated download and installation
# Author: (c) 2023 Dr. Vignesh Mahalingam
# Purpose: For Software installation in Temple university clusters: Owl's nest & compute
clear
date
Software="libxc"
compiler="intel"
echo "----------------------"
echo "$Software-$compiler installation"
echo "----------------------"
name="libxc"
version="6.1.0"
FILE=$name-$version.$extension
weburl="https://gitlab.com/libxc/libxc.git"

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
git clone $weburl --branch $version
cd $downloaddir/$name
# Loading dependency modules
# Reproducibilty depends on modules. So, decide for yourself which one you need. These are the latest/ only modules available.

module load cmake/3.22.1
module load gcc/9.3.0
module load intel-compiler/2022.1.1

autoreconf -i 
$downloaddir/$name/configure CC='icc' FC="ifort" --prefix="$sourcedir"
make -j $nthreads
make install -j $nthreads

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

whatis("Libxc Library for INTEL Compilers")
help([[
This module provides Libxc a portable, well tested and reliable library
of exchange-correlation functionals for density-functional theory.

The components of this module have been compiled with and for the
GNU C and Fortran compilers.

This module sets the environment variables: PATH, CPATH,
LD_LIBRARY_PATH, LIBRARY_PATH, PKG_CONFIG_PATH, and LIBXC_HOME

]])
family("libxc")
conflict("intel-compiler")
prepend_path("PATH","$sourcedir/bin")
prepend_path("CPATH","$sourcedir/include")
prepend_path("LIBRARY_PATH","$sourcedir/lib")
prepend_path("LD_LIBRARY_PATH","$sourcedir/lib")
prepend_path("PKG_CONFIG_PATH","$sourcedir/lib/pkgconfig")
setenv("LIBXC_HOME","$sourcedir")
setenv("LIBXC_DIR","$sourcedir")
EOF
# Remove build directories
rm -rf $downloaddir/$name
