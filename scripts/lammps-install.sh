#!/bin/bash
#
# Description: LAMMPS automated download and installation
# Author: (c) 2023 Dr. Vignesh Mahalingam
# Purpose: For Software installation in Temple university clusters: Owl's nest & compute
clear
date
Software="LAMMPS"
echo "----------------------"
echo "$Software installation"
echo "----------------------"
name="lammps"
#version="stable"
version="23Jun2022"
#version="24Jun2022"
extension="tar.gz"
taroption="xzf"
FILE=$name-$version.$extension
web_url="https://download.lammps.org/tars"

rootdir="/gpfs/opt/apps"
downloaddir="$rootdir"
appsdir="$rootdir/apps"
sourcedir="$appsdir/$name-$version"
moduledir="$rootdir/apps/modulefiles"

cs="SHA256SUMS"
csfile="$web_url/$cs"
cscommand=sha256sum
nthreads=12

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
	echo "Downloading $csfile ..."
	wget $csfile -q
	if [ $? -ne 0 ]; then
                echo " Download failed; Check if $csfile exists in $web_url"
                exit 1
	fi
fi

echo -n "Checking checksum: "
$cscommand -c SHA256SUMS 2>&1 | grep OK
if [ $? -ne 0 ]; then
	echo "Checksum failed"
	exit 1
fi
cd $appsdir
if [ -d $sourcedir ]; then
	echo "Directory $sourcedir already exists...will be removed ..."
	rm -rf $sourcedir
fi
echo "Extracting from archive ..."
tar $taroption $downloaddir/$FILE

# Loading dependency modules
# Reproducibilty depends on modules. So, decide for yourself which one you need. These are the latest/ only modules available.
module load cmake # This is the only cmake module available in Owl's nest
module load gcc/11.2.0 # Using the latest gcc in cluster
module load mpi/openmpi/4.1.2 # This is the latest available. Decide for yourself. For default choose module load mpi/openmpi

# create LAMMPS BUILD DIR
# cd $sourcedir
# rm -rf $sourcedir/build
# if [ -d $sourcedir/build ]; then
# 	echo "Build directory $sourcedir/build already exists"
# else
rm -rf $appsdir/$name-latest
mkdir -p $appsdir/$name-latest
cd $appsdir/$name-latest
# fi
#cd build

# For Owl's nest
cmake -C \
$sourcedir/cmake/presets/most.cmake \
-D LAMMPS_MACHINE=mpi \
-D CMAKE_INSTALL_PREFIX=$sourcedir \
-D CMAKE_BUILD_TYPE=Release \
-D BUILD_MPI=on \
-D BUILD_OMP=on \
-D PKG_ATC=on \
-D PKG_AWPMD=on \
-D PKG_EXTRA-MOLECULE=on \
-D PKG_KOKKOS=on \
-D PKG_LATBOLTZ=on \
-D PKG_MANIFOLD=on \
-D PKG_ML-HDNNP=on \
-D PKG_ML-PACE=on \
-D PKG_ML-RANN=on \
-D PKG_MOLFILE=on \
-D PKG_POEMS=on \
-D PKG_PTM=on \
-D PKG_PYTHON=on \
-D PKG_QTB=on \
-D PKG_SMTBQ=on \
$sourcedir/cmake
#-D BUILD_SHARED_LIBS=on \
#-D PKG_PLUMED=on \
# -D PKG_ML-QUIP=on -D USE_INTERNAL_LINALG=yes \
cmake --build . -j $nthreads 2>&1
if [ -f $sourcedir/build/lmp_mpi ]; then
	echo "lmp_mpi installed"
fi

# Reproducibilty depends on modules. So, decide for yourself which one you need. This is the latest cuda in 'module avail cuda'

module load cuda/11.6.0
# 
# if [ -f $sourcedir/build/lmp_gpu ]; then
# 	echo "lmp_gpu already installed.Nothing needed"
# else
cmake -C \
$sourcedir/cmake/presets/most.cmake \
-D LAMMPS_MACHINE=gpu \
-D GPU_API=cuda \
-D GPU_PREC=mixed \
-D GPU_ARCH=sm_60 \
-D CMAKE_INSTALL_PREFIX=$sourcedir \
-D CMAKE_BUILD_TYPE=Release \
-D BUILD_MPI=on \
-D BUILD_OMP=on \
-D PKG_GPU=on \
-D PKG_ATC=on \
-D PKG_AWPMD=on \
-D PKG_EXTRA-MOLECULE=on \
-D PKG_KOKKOS=on \
-D PKG_LATBOLTZ=on \
-D PKG_MANIFOLD=on \
-D PKG_ML-HDNNP=on \
-D PKG_ML-PACE=on \
-D PKG_ML-RANN=on \
-D PKG_MOLFILE=on \
-D PKG_POEMS=on \
-D PKG_PTM=on \
-D PKG_PYTHON=on \
-D PKG_QTB=on \
-D PKG_SMTBQ=on \
$sourcedir/cmake
cmake --build . -j $nthreads 2>&1
echo "lmp_gpu installed"
# -D PKG_ML-QUIP=on -D USE_INTERNAL_LINALG=yes \
# fi

## Creating module file in $rootdir/apps/modulefiles
# Note: needs install permission to install in /gvfs/opt/apps/modulefiles"
#export MODULEPATH=$MODULEPATH:$moduledir
# echo "MODULEPATH: $MODULEPATH"

if [ -d $moduledir/$name ]; then
	echo "$moduledir/$name exists"
else
	mkdir -p "$moduledir/$name"
fi
if [ -f $moduledir/$name/$version.lua ]; then
	rm -f $moduledir/$name/$version.lua
fi
# depends_on("cuda")
cat > $moduledir/$name/$version.lua << EOF
-- -*- lua -*-
depends_on("gcc/11.2.0")
depends_on("mpi/openmpi/4.1.2")
depends_on("cuda/11.6.0")
whatis([===[LAMMPS MD Simulation Package]===])

help([===[

This module provides the latest LAMMPS molecular dynamics software package with MOST packages. 

It contains several LAMMPS binaries compiled with different settings:
- lmp_mpi             : regular CPU-only MPI+OpenMP binary
- lmp_gpu             : like lmp_mpi but with GPU package added

Environment variables set: LAMMPS_POTENTIALS

]===])

prepend_path("PATH","$sourcedir/build")
setenv("LAMMPS_POTENTIALS","$sourcedir/potentials")
EOF
module load $name/$version
module list lammps
