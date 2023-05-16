#!/bin/bash
#
# Description: Gromacs automated download and installation
# Author: (c) 2023 Dr. Vignesh Mahalingam
# Purpose: For Software installation in Temple university clusters: Owl's nest & compute
clear
date
Software="gromacs"
echo "----------------------"
echo "$Software installation"
echo "----------------------"
name="gromacs"
version="2023"
subversion="1"
extension="tar.gz"
taroption="xzf"
FILE=$name-$version.$extension
web_url="ftp://ftp.gromacs.org/gromacs"

rootdir="/home/tur09027/work"
appsdir="$rootdir/apps"
downloaddir="$appsdir/downloads"
sourcedir="$appsdir/$name-$version.$subversion"
moduledir="$rootdir/apps/modulefiles"

cs="MD5SUMS"
cscommand=md5sum
nthreads=12

mkdir -p $downloaddir
cd $downloaddir

if [ -f "$FILE" ]; then
	echo "$FILE exists in destination $downloaddir"
else
	echo "Downloading $FILE from $web_url ..."
	wget "$web_url/$FILE" -q
	if [ $? -ne 0 ]; then
		echo " Download failed; Check URL and if $FILE exists in $web_url"
		exit 1
	fi
fi

if [ -f "$cs" ]; then
	echo "Checksum file $cs exists"
else
	echo "f0b2b000c2bf2505f7d6eee0c432bd95 $name-$version.$extension" > $cs
fi

echo -n "Checking checksum: "
$cscommand -c MD5SUMS 2>&1 | grep OK
if [ $? -ne 0 ]; then
	echo "Checksum failed"
	exit 1
fi
rm -rf $downloaddir/$name-$version
echo "Extracting from archive ..."
tar $taroption $downloaddir/$FILE
cd $downloaddir/$name-$version
# Loading dependency modules
# Reproducibilty depends on modules. So, decide for yourself which one you need. These are the latest/ only modules available.

module load cmake/3.22.1
module load gcc/9.3.0
module load mpi/openmpi/2.1.1
module load python/3.10.2
module unload cuda

# create BUILD DIR
rm -rf $sourcedir
mkdir -p $sourcedir
cd $downloaddir/$name-$version

mkdir -p $downloaddir/$name-$version/serial
cd $downloaddir/$name-$version/serial

export serialdir="$sourcedir/serial"
cmake .. \
-DGMX_FFT_LIBRARY=fftw3 \
-DCMAKE_INSTALL_PREFIX="${serialdir}" \
-DGMX_SIMD=AVX2_256 \
-DREGRESSIONTEST_DOWNLOAD=OFF \
-DCMAKE_C_COMPILER=gcc \
-DCMAKE_CXX_COMPILER=g++
make -j $nthreads
make install -j $nthreads

module unload cuda
mkdir -p $downloaddir/$name-$version/mpi_s
cd $downloaddir/$name-$version/mpi_s
export mpisdir="$sourcedir/mpi_s"
cmake .. \
-DGMX_FFT_LIBRARY=fftw3 \
-DCMAKE_INSTALL_PREFIX="${mpisdir}" \
-DREGRESSIONTEST_DOWNLOAD=OFF \
-DCMAKE_C_COMPILER=gcc \
-DCMAKE_CXX_COMPILER=g++ \
-DGMX_MPI=on \
-DGMX_SIMD=AVX2_256 \
-DGMX_DOUBLE=off \
-DGMX_GPU=off
make -j $nthreads
make install -j $nthreads

mkdir -p $downloaddir/$name-$version/mpi_d
cd $downloaddir/$name-$version/mpi_d
export mpiddir="$sourcedir/mpi_d"

cmake .. \
-DCMAKE_INSTALL_PREFIX="${mpiddir}" \
-DGMX_FFT_LIBRARY=fftw3 \
-DREGRESSIONTEST_DOWNLOAD=OFF \
-DCMAKE_C_COMPILER=mpicc \
-DCMAKE_CXX_COMPILER=mpic++ \
-DGMX_MPI=on \
-DGMX_DOUBLE=on \
-DGMX_SIMD=AVX2_256 \
-DBUILD_SHARED_LIBS=on
make -j $nthreads
make install -j $nthreads

module load cuda/11.6.0
mkdir -p $downloaddir/$name-$version/gpu_s
cd $downloaddir/$name-$version/gpu_s
export gpusdir="$sourcedir/gpu_s"

cmake .. \
-DCMAKE_INSTALL_PREFIX="${gpusdir}" \
-DREGRESSIONTEST_DOWNLOAD=OFF \
-DGMX_DEFAULT_SUFFIX=OFF \
-DGMX_BINARY_SUFFIX="_gpu" \
-DCMAKE_C_COMPILER=gcc \
-DCMAKE_CXX_COMPILER=g++ \
-DGMX_DOUBLE=off \
-DGMX_MPI=on \
-DGMX_SIMD=AVX2_256 \
-DBUILD_SHARED_LIBS=off \
-DGMX_GPU=CUDA
make -j $nthreads
make install -j $nthreads

cp -r $mpiddir/* $sourcedir/.
cp $mpisdir/lib64/* $sourcedir/lib64/.
cp $serialdir/lib64/* $sourcedir/lib64/.
cp $gpusdir/bin/gmx_gpu $sourcedir/bin/.
cp $mpisdir/bin/gmx_mpi $sourcedir/bin/.
cp $serialdir/bin/gmx $sourcedir/bin/.

rm -rf $mpisdir $gpusdir $mpiddir $serialdir $sourcedir/lib64/cmake

if [ -d $moduledir/$name ]; then
        echo "$moduledir/$name exists"
else
        mkdir -p "$moduledir/$name"
fi
if [ -f $moduledir/$name/$version.$subversion.lua ]; then
        rm -f $moduledir/$name/$version.$subversion.lua
fi

cat > $moduledir/$name/$version.$subversion.lua << EOF
-- -*- $name-$version.$subversion.lua -*- --
depends_on("gcc/9.3.0")
depends_on("mpi/openmpi/2.1.1")
depends_on("cuda/11.6.0")
whatis("Gromacs MD Simulation Package")
help([[
This module provides the Gromacs molecular dynamics software package.

It contains the Gromacs suite of tools compiled for serial execution 
using the 'gmx' prefix and several variants of 'gmx_mpi' binaries with AVX2_256 precision:
- gmx           : single precision CPU-only Threads binary
- gmx_mpi       : single precision CPU-only MPI+Threads binary
- gmx_mpi_d     : double precision CPU-only MPI+Threads binary
- gmx_gpu       : single precision MPI binary with GPU support

This also updates the environment variables PATH, LD_LIBRARY_PATH,
PKG_CONFIG_PATH, MANPATH, GROMACS_DIR, GMXBIN, GMXLDLIB, GMXMAN, GMXDATA

]])
prepend_path("PATH","$sourcedir/bin")
prepend_path("LD_LIBRARY_PATH","$sourcedir/lib64")
prepend_path("PKG_CONFIG_PATH","$sourcedir/lib64/pkgconfig")
prepend_path("MANPATH","$sourcedir/share/man")
setenv("GROMACS_DIR","$sourcedir")
setenv("GMXBIN","$sourcedir/bin")
setenv("GMXLDLIB","$sourcedir/lib64")
setenv("GMXMAN","$sourcedir/share/man")
setenv("GMXDATA","$sourcedir/share/gromacs")
EOF
