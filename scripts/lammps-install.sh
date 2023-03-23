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
	echo "$FILE downloaded"
fi

if [ -f "$cs" ]; then
	echo "Checksum file $cs exists"
else
	echo "Downloading $csfile ..."
	wget $csfile -q --progress=dot
	echo "$csfile downloaded"
fi

echo -n "Checking checksum: "
$cscommand -c SHA256SUMS 2>&1 | grep OK

cd $appsdir
if [ -d $sourcedir ]; then
	echo "Directory already extracted. No need to extract from tar"
else
	echo "Extracting from archive ..."
	tar $taroption $downloaddir/$FILE
fi

# Loading modules
module load lmod
module load cmake
module load mpi/openmpi
module load cuda

# create LAMMPS BUILD DIR
cd $sourcedir
if [ -d $sourcedir/build ]; then
	echo "Build directory $sourcedir/build already exists"
else
	mkdir build
fi
cd build

# For Owl's nest
if [ -f $sourcedir/build/lmp_mpi ]; then
	echo "lmp_mpi already installed. Nothing needed"
else
	cmake -C $sourcedir/cmake/presets/most.cmake -D LAMMPS_MACHINE=mpi -D CMAKE_INSTALL_PREFIX=$sourcedir -D CMAKE_BUILD_TYPE=Release -D BUILD_MPI=on -D BUILD_OMP=on $sourcedir/cmake
	make -j $nthreads 2>&1
	make install 2>&1
	echo "lmp_mpi installed"
fi

# Comment following 3 lines for compute nodes
if [ -f $sourcedir/build/lmp_gpu ]; then
	echo "lmp_gpu already installed.Nothing needed"
else
	cmake -C $sourcedir/cmake/presets/most.cmake -D LAMMPS_MACHINE=gpu -D PKG_GPU=on -D CMAKE_INSTALL_PREFIX=$sourcedir -D CMAKE_BUILD_TYPE=Release -D BUILD_MPI=on -D BUILD_OMP=on $sourcedir/cmake
	make -j $nthreads 2>&1
	make install 2>&1
	echo "lmp_gpu installed"
fi

# Creating module file in $rootdir/apps/modulefiles
# Note: needs install permission to install in /gvfs/opt/apps/modulefiles"
#export MODULEPATH=$MODULEPATH:$moduledir
# echo "MODULEPATH: $MODULEPATH"

if [ -d $moduledir/$name ]; then
	echo "$moduledir/$name exists"
else
	mkdir -p "$moduledir/$name"
fi
if [ -f $moduledir/$name/$version.lua ]; then
	echo "Module file $moduledir/$name/$version.lua exists"
else
	cat > $moduledir/$name/$version.lua << EOF
-- -*- lua -*-

depends_on("cuda")
depends_on("gcc/default")

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
fi
module load $name/$version
module list lammps
