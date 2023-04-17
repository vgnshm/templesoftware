#!/bin/bash
#
# Description: LIGGHTS automated download and installation
# Author: (c) 2023 Dr. Vignesh Mahalingam
# Purpose: For Software installation in Temple university clusters: Owl's nest & compute
clear
date
Software="LIGGGHTS-PUBLIC"
echo "----------------------"
echo "$Software installation"
echo "----------------------"
name="liggghts"
#version="stable"
version="3.8.0"
extension="zip"
#taroption="xzf"
FILE=master.$extension
web_url="https://github.com/CFDEMproject/LIGGGHTS-PUBLIC/archive"

rootdir="/home/tur09027/work"
appsdir="$rootdir/apps"
downloaddir="$appsdir/downloads"
sourcedir="$appsdir/$name-$version"
moduledir="$rootdir/apps/modulefiles"

nthreads=12

cd $downloaddir

if [ -f "$FILE" ]; then
	echo "$FILE exists in destination $downloaddir"
else
	echo "Downloading $FILE from $web_url ..."
	wget "$web_url/$FILE" -q
	echo "$FILE downloaded"
fi

if [ -d $sourcedir ]; then
	rm -rf $sourcedir
fi
mkdir -p $sourcedir
cd $sourcedir
echo "Extracting from archive ..."
unzip -q $downloaddir/$FILE
mv LIGGGHTS-PUBLIC-master/* .
rm -rf LIGGGHTS-PUBLIC-master
cd src/MAKE
# Loading modules
module load cmake/3.22.1
module load mpi/openmpi/2.1.1
module load vtk/7.1.1
cat > Makefile.user << EOF
USE_MPI = "ON"
USE_CATALYST = "OFF"
USE_VTK = "ON"
USE_SUPERQUADRICS = "ON"
USE_JPG = "OFF"
USE_FPIC = "ON"
USE_DEBUG = "OFF"
USE_PROFILE = "OFF"
USE_CONVEX = "OFF"
USE_GZIP = "OFF"
USE_XDR = "OFF"
USE_MFEM = "OFF"
BUILD_LIBRARIES = "NONE"
MPICXX_USR=/gpfs/opt/base/openmpi-2.1.1/bin/mpicxx
MPI_INC_USR=/gpfs/opt/base/openmpi-2.1.1/include
MPI_LIB_USR=/gpfs/opt/base/openmpi-2.1.1/lib
VTK_INC_USR=-I/gpfs/opt/libs/vtk-7.1.1/include
VTK_LIB_USR=-L/gpfs/opt/libs/vtk-7.1.1/lib
MPI_ADDLIBS_USR=-lmpi
MAKEFILE_USER_VERSION = "1.4"
EOF
cd ..
sed -i 's/nLimit=1200/nLimit=5000/g' $sourcedir/src/Make.sh
make auto -j $nthreads
mv lmp_auto liggghts
mv $sourcedir/src/liggghts $appsdir/.
rm -rf $sourcedir/*
mv $appsdir/liggghts $sourcedir/.
# # Creating module file in $rootdir/apps/modulefiles
# # Note: needs install permission to install in /gvfs/opt/apps/modulefiles"
# 
if [ -d $moduledir/$name ]; then
	echo "$moduledir/$name exists"
else
 	mkdir -p "$moduledir/$name"
fi
#if [ -f $moduledir/$name/$version.lua ]; then
	rm -f $moduledir/$name/$version.lua
#fi
cat > $moduledir/$name/$version.lua << EOF
-- -*- $name-$version.lua -*- --
 
depends_on("mpi/openmpi/2.1.1")
depends_on("vtk/7.1.1")
whatis("LIGGGHTS Discrete Element Method Particle Simulation Code")
help([[
This module provides the LIGGGHTS Open Source Discrete Element Method
Particle Simulation Software. It can be used for the simulation of
particulate materials, and aims to for applications it to industrial
problems.

The LIGGGHTS binary in this installation is called: liggghts

]])
prepend_path("PATH","$sourcedir")
EOF
module load $name/$version.lua
