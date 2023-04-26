#!/bin/bash
#
# Description: scalapack automated download and installation
# Author: (c) 2023 Dr. Vignesh Mahalingam
# Purpose: For Software installation in Temple university clusters: Owl's nest & compute
clear
date
Software="scalapack"
compiler="gnu"
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
module load gcc/9.3.0
module load mpi/openmpi/2.1.1

mkdir -p $downloaddir/$name-$version/build
cd $downloaddir/$name-$version/build

cmake $downloaddir/$name-$version \
-DCMAKE_INSTALL_PREFIX="$sourcedir" \
-DCMAKE_C_COMPILER='mpicc' \
-DCMAKE_C_FLAGS='-O3 -Wno-implicit' \
-DCMAKE_CXX_FLAGS='-O3 -Wno-implicit' \
-DCMAKE_CXX_COMPILER='mpic++' \
-DCMAKE_Fortran_COMPILER='mpif90' \
-DBLAS_LIBRARIES='-lblas' \
-DLAPACK_LIBRARIES='-L/lib64/liblapack.so.3'
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
whatis("ScaLAPACK for GNU Compilers")
help([[
This module provides ScaLAPACK parallel linear algebra library
compiled with and for the GNU Fortran compiler and OpenMPI

]])
family("scalapack")
conflict("intel-compiler")
prepend_path("LIBRARY_PATH","$sourcedir/lib")
EOF
# Remove build directories
rm -rf $downloaddir/$name
