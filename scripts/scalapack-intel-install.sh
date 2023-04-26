#!/bin/bash
#
# Description: scalapack automated download and installation
# Author: (c) 2023 Dr. Vignesh Mahalingam
# Purpose: For Software installation in Temple university clusters: Owl's nest & compute
clear
date
Software="scalapack"
compiler="intel"
echo "--------------------------------"
echo "$Software-$compiler installation"
echo "--------------------------------"
name="scalapack"
version="2.2.0"
extension="tar.gz"
taroption="xzf"
FILE=$name-$version.$extension
weburl="https://github.com/Reference-ScaLAPACK/scalapack/archive/refs/tags"

rootdir="/home/tur09027/work"
appsdir="$rootdir/apps"
libsdir="$rootdir/libs"
downloaddir="$appsdir/downloads"
sourcedir="$libsdir/$name-$version-$compiler"
moduledir="$libsdir/modulefiles"

nthreads=12

rm -rf $downloaddir/$name-$version
cd $downloaddir
if [ -d $downloaddir/$name-$version ]; then
	rm -rf $downloaddir/$name-$version
fi

if [ -f "$FILE" ]; then
	echo "$FILE exists in $downloaddir"
else
	echo "Extracting from github archive ..."
	wget $weburl/v${version}.tar.gz -O $name-${version}.$extension
fi
tar $taroption $name-$version.$extension
cd $downloaddir/$name-$version

# Loading dependency modules
# Reproducibilty depends on modules. So, decide for yourself which one you need. These are the latest/ only modules available.

module load cmake/3.22.1
module load intel-compiler/2022.1.1

mkdir -p $downloaddir/$name-$version/build
cd $downloaddir/$name-$version/build
sed -i 's/\-fp_port/\-fp-port/g' $downloaddir/$name-$version/CMakeLists.txt

cmake $downloaddir/$name-$version \
-DCMAKE_INSTALL_PREFIX="$sourcedir" \
-DCMAKE_C_COMPILER='mpiicc' \
-DCMAKE_CXX_COMPILER='mpicxx' \
-DMPI_Fortran_COMPILER='mpiifort' \
-DUSE_OPTIMIZED_LAPACK_BLAS='on'
cmake --build . -j $nthreads --target scalapack

rm -rf $sourcedir
mkdir -p $sourcedir
cd $sourcedir
mv $downloaddir/$name-$version/build/lib .
mkdir -p $sourcedir/lib/pkgconfig $sourcedir/lib/cmake
mv $downloaddir/$name-$version/build/${name}.pc lib/pkgconfig/.
mv $downloaddir/$name-$version/${name}*.cmake lib/cmake/.

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
whatis("ScaLAPACK for Intel Compilers")
help([[
This module provides ScaLAPACK parallel linear algebra library
compiled with and for the Intel Fortran compiler and Intel MPI

]])
family("scalapack")
prepend_path("LIBRARY_PATH","$sourcedir/lib")
EOF
# Remove build directories
rm -rf $downloaddir/$name
