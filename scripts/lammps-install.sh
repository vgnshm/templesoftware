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

rootdir="/home/tur09027/work"
appsdir="$rootdir/apps"
downloaddir="$appsdir/downloads"
sourcedir="$appsdir/$name-$version"
moduledir="$rootdir/apps/modulefiles"

cs="SHA256SUMS"
csfile="$web_url/$cs"
cscommand=sha256sum
nthreads=24

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
echo "Extracting from archive ..."
tar $taroption $downloaddir/$FILE
# Loading dependency modules
# Reproducibilty depends on modules. So, decide for yourself which one you need. These are the latest/ only modules available.
module load cmake/3.22.1 # This is the only cmake module available in Owl's nest
module load gcc/9.3.0 # Using the default gcc in cluster
module load mpi/openmpi/4.1.2 # This is the latest available. Decide for yourself. For default choose module load mpi/openmpi
module load plumed/2.8.0
# create LAMMPS BUILD DIR

rm -rf $sourcedir
mkdir -p $sourcedir
cd $sourcedir

# For Owl's nest
cmake -C \
$downloaddir/$name-$version/cmake/presets/most.cmake \
-D LAMMPS_MACHINE=mpi \
-D CMAKE_INSTALL_PREFIX=$sourcedir \
-D CMAKE_BUILD_TYPE=Release \
-D BUILD_MPI=on \
-D BUILD_OMP=on \
-D PKG_ATC=on \
-D PKG_AWPMD=on \
-D PKG_EXTRA-MOLECULE=on \
-D PKG_KOKKOS=on \
-D Kokkos_ENABLE_OPENMP=yes \
-D BUILD_OMP=yes \
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
-D PKG_PLUMED=on \
-D DOWNLOAD_PLUMED=no \
-D PLUMED_MODE=shared \
-D PKG_ML-QUIP=on -D USE_INTERNAL_LINALG=yes \
-D BUILD_SHARED_LIBS=on \
$downloaddir/$name-$version/cmake
cmake --build $sourcedir -j $nthreads --target install 2>&1
# -D CMAKE_CXX_COMPILER=$downloaddir/$name-$version/lib/kokkos/bin/nvcc_wrapper \
# -D Kokkos_ARCH_PASCAL60=yes \
if [ -f $sourcedir/lmp_mpi ]; then
	echo "lmp_mpi installed"
fi

# Reproducibilty depends on modules. So, decide for yourself which one you need. This is the latest cuda in 'module avail cuda'
module load cmake/3.22.1 # This is the only cmake module available in Owl's nest
module load gcc/9.3.0 # Using the default gcc in cluster
module load mpi/openmpi/4.1.2 # This is the latest available. Decide for yourself. For default choose module load mpi/openmpi
module load cuda/11.6.0
module load plumed/2.8.0
#lmp_gpu installation
cmake \
-C $downloaddir/$name-$version/cmake/presets/most.cmake \
-D LAMMPS_MACHINE=gpu \
-D CMAKE_INSTALL_PREFIX=$sourcedir \
-D CMAKE_BUILD_TYPE=Release \
-D BUILD_SHARED_LIBS=on \
-D BUILD_MPI=on \
-D BUILD_OMP=on \
-D PKG_ATC=on \
-D PKG_AWPMD=on \
-D PKG_EXTRA-MOLECULE=on \
-D GPU_API=cuda \
-D GPU_PREC=mixed \
-D GPU_ARCH=sm_60 \
-D PKG_GPU=on \
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
-D PKG_PLUMED=on \
-D DOWNLOAD_PLUMED=no \
-D PLUMED_MODE=shared \
-D PKG_ML-QUIP=on -D USE_INTERNAL_LINALG=yes \
-D PKG_KOKKOS=on \
-D Kokkos_ENABLE_OPENMP=yes \
$downloaddir/$name-$version/cmake
cmake --build $sourcedir -j $nthreads --target install 2>&1

if [ -f $sourcedir/lmp_gpu ]; then
	echo "lmp_gpu installed"
fi

rm -f $sourcedir/*.fatbin

echo "Starting lmp_kokkos installation"
module load cmake/3.22.1 # This is the only cmake module available in Owl's nest
module load gcc/9.3.0 # Using the default gcc in cluster
module load mpi/openmpi/4.1.2 # This is the latest available. Decide for yourself. For default choose module load mpi/openmpi
module load cuda/11.6.0
module load plumed/2.8.0

cmake \
-C $downloaddir/$name-$version/cmake/presets/most.cmake \
-C $downloaddir/$name-$version/cmake/presets/kokkos-cuda.cmake \
-D CMAKE_INSTALL_PREFIX=$sourcedir \
-D CMAKE_BUILD_TYPE=Release \
-D CMAKE_CXX_COMPILER=$downloaddir/$name-$version/lib/kokkos/bin/nvcc_wrapper \
-D BUILD_SHARED_LIBS=on \
-D BUILD_MPI=on \
-D BUILD_OMP=on \
-D PKG_MANYBODY=on \
-D PKG_AWPMD=on \
-D PKG_MOLECULE=on \
-D PKG_EXTRA-MOLECULE=on \
-D PKG_LATBOLTZ=on \
-D PKG_MANIFOLD=on \
-D PKG_MOLFILE=on \
-D PKG_POEMS=on \
-D PKG_PTM=on \
-D PKG_PYTHON=on \
-D PKG_QTB=on \
-D PKG_SMTBQ=on \
-D PKG_PLUMED=on \
-D DOWNLOAD_PLUMED=no \
-D PLUMED_MODE=shared \
-D PKG_ML-QUIP=on -D USE_INTERNAL_LINALG=yes \
-D GPU_API=cuda \
-D GPU_PREC=mixed \
-D GPU_ARCH=sm_60 \
-D PKG_GPU=on \
-D PKG_KOKKOS=on \
-D Kokkos_ARCH_PASCAL60=yes \
-D Kokkos_ARCH_GPUARCH=yes  \
-D Kokkos_ENABLE_CUDA=yes \
-D Kokkos_ENABLE_OPENMP=yes \
-D LAMMPS_MACHINE=kokkos \
$downloaddir/$name-$version/cmake
cmake --build $sourcedir -j $nthreads --target install 2>&1
mv $sourcedir/lmp  $sourcedir/lmp_kokkos
if [ -f $sourcedir/lmp_kokkos ]; then
	echo "lmp_kokkos installed"
fi

# copying tools to sourcedir
mkdir -p $appsdir/lammps
mv $sourcedir/bin/* $appsdir/lammps/.
mv $sourcedir/*.a $appsdir/lammps/.
mv $sourcedir/*.so* $appsdir/lammps/.
rm -rf $sourcedir/*
mv $appsdir/lammps/* $sourcedir/.
rm -rf $appsdir/lammps
cp -r $downloaddir/$name-$version/potentials $sourcedir/.
cp -r $downloaddir/$name-$version/tools/msi2lmp/frc_files $sourcedir/.
cp -r $downloaddir/$name-$version/tools/python $sourcedir/.
rm -rf $downloaddir/$name-$version
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

cat > $moduledir/$name/$version.lua << EOF
-- -*- $name-$version.lua -*- --
depends_on("gcc/9.3.0")
depends_on("mpi/openmpi/4.1.2")
depends_on("cuda/11.6.0")
depends_on("plumed/2.8.0")
whatis([===[LAMMPS MD Simulation Package]===])

help([===[

This module provides the latest LAMMPS molecular dynamics software package with MOST packages. 

It contains several LAMMPS binaries compiled with different settings:
- lmp_mpi             : regular CPU-only MPI+OpenMP binary
- lmp_gpu             : like lmp_mpi but with GPU package added
- lmp_kokkos   : MPI+OpenMP+CUDA KOKKOS version w/o ATC, ML-PACE, ML-HDNNP, ML-RANN
- LAMMPS Python3 module using the lmp_mpi shared library

Included utils: binary2txt, chain, msi2lmp, stl_bin2txt, nvc_get_devices
Environment variables set: LAMMPS_POTENTIALS

]===])

prepend_path("PATH","$sourcedir")
prepend_path("LD_LIBRARY_PATH","$sourcedir")
setenv("LAMMPS_POTENTIALS","$sourcedir/potentials")
prepend_path("PYTHONPATH","$sourcedir/python")
setenv("MSI2LMP_LIBRARY","$sourcedir/frc_files")

EOF
module load $name/$version
module list lammps
