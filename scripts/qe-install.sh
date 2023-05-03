#!/bin/bash
#
# Description: Quantum espresso automated download and installation
# Author: (c) 2023 Dr. Vignesh Mahalingam
# Purpose: For Software installation in Temple university clusters: Owl's nest & compute
clear
date
Software="Quantum ESPRESSO"
echo "----------------------"
echo "$Software installation"
echo "----------------------"
name="q-e-qe"
shortname='qe'
#version="stable"
version="7.2"
#version="24Jun2022"
extension="tar.gz"
taroption="xzf"
FILE=$name-$version.$extension
web_url="https://gitlab.com/QEF/q-e/-/archive/qe-$version"

rootdir="/home/tur09027/work"
appsdir="$rootdir/apps"
libsdir="$rootdir/libs"
downloaddir="$appsdir/downloads"
sourcedir="$appsdir/$shortname-$version"
moduledir="$rootdir/apps/modulefiles"

nthreads=12

rm -rf $downloaddir/$name-$version
rm -rf $sourcedir
mkdir -p $sourcedir
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

echo "Extracting from archive ..."
tar $taroption $downloaddir/$FILE
# Loading dependency modules
# Reproducibilty depends on modules. So, decide for yourself which one you need. These are the latest/ only modules available.

module load cmake/3.22.1 # This is the only cmake module available in Owl's nest
module load gcc/11.2.0 # Using the default gcc in cluster
module load mpi/openmpi/4.1.5 # This is the latest available. Decide for yourself. For default choose module load mpi/openmpi
module load scalapack/2.2.0-gnu
module load libxc/6.1.0-gnu
# For Owl's nest

echo "Starting qe installation"
cd $downloaddir/$name-$version
export FC=mpif90
export CC=mpicc
./configure --prefix=${sourcedir} \
--enable-openmp=yes \
--enable-parallel=yes \
--with-libxc=yes \
--with-libxc-prefix="${libsdir}/libxc-6.1.0-gnu/bin" \
--with-libxc-include="${libsdir}/libxc-6.1.0-gnu/include" \
--with-scalapack=yes
make -j$nthreads pwall cp
make install
# ls $sourcedir/bin
if [ -d $moduledir/$shortname ]; then
	echo "$moduledir/$shortname exists"
else
	mkdir -p "$moduledir/$shortname"
fi
if [ -f $moduledir/$shortname/$version.lua ]; then
	rm -f $moduledir/$shortname/$version.lua
fi

cat > $moduledir/$shortname/$version.lua << EOF
-- -*- $shortname-$version.lua -*- --
family("qe")
depends_on("gcc/11.2.0")
depends_on("mpi/openmpi/4.1.5")
depends_on("scalapack/2.2.0-gnu")
depends_on("libxc/6.1.0-gnu")
whatis("Quantum Espresso Plane Wave DFT Package")
help([[
This module provides the Quantum Espresso integrated suite of Open-Source
computer codes for electronic-structure calculations and materials modeling
at the nanoscale. It is based on density-functional theory, plane waves,
and pseudopotentials. This module contains the executables from the following
core and third-party packages:
pw ph pwcond neb pp tddfpt qipaw gwl upf xspectra couple epw w90 want

This also updates the environment variable PATH

]])
prepend_path("PATH","$sourcedir/bin")
EOF
