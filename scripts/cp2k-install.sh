#!/bin/bash
#
# Description: CP2K automated download and installation
# Author: (c) 2023 Dr. Vignesh Mahalingam
# Purpose: For Software installation in Temple university clusters: Owl's nest & compute
clear
date
Software="cp2k"
echo "----------------------"
echo "$Software installation"
echo "----------------------"
name="cp2k"
version="2023"
subversion="1"
extension="tar.bz2"
taroption="jxf"
FILE=$name-$version.$subversion.$extension
web_url="https://github.com/cp2k/cp2k/releases/download/v$version.$subversion"
nthreads=12

rootdir="/home/tur09027/work"
appsdir="$rootdir/apps"
downloaddir="$appsdir/downloads"
sourcedir="$appsdir/$name-$version.$subversion"
moduledir="$rootdir/apps/modulefiles"

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

rm -rf $sourcedir
cd $appsdir
echo "Extracting from archive ..."
tar $taroption $downloaddir/$FILE
cd $sourcedir
# Loading dependency modules
# Reproducibilty depends on modules. So, decide for yourself which one you need. These are the latest/ only modules available.

module load cmake/3.22.1
module load gcc/9.3.0
module load mpi/openmpi/4.1.5
module load libxc/6.1.0-gnu
module load hdf5/1.10.1

cd $sourcedir/tools/toolchain
./install_cp2k_toolchain.sh \
--with-libxsmm=install \
--with-libxc=system \
--with-elpa=no \
--with-hdf5=system \
--with-cmake=system \
--with-openmpi=system
cd $sourcedir
cp $sourcedir/tools/toolchain/install/arch/* arch/
source $sourcedir/tools/toolchain/install/setup
make -j $nthreads ARCH=local VERSION="ssmp sdbg psmp pdbg"
cd $sourcedir/exe/local

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

whatis("CP2k Quantum Chemistry and Solid State Physics Package")
help([[
This module provides the CP2k quantum chemistry and solid state physics
software package that can perform atomistic simulations of solid state,
liquid, molecular, periodic, material, crystal, and biological systems.
CP2K provides a general framework for different modeling methods such
as DFT using the mixed Gaussian and plane waves approaches GPW and GAPW.
Supported theory levels include DFTB, LDA, GGA, MP2, RPA, semi-empirical
methods (AM1, PM3, PM6, RM1, MNDO, etc.), and classical force fields
(AMBER, CHARMM, etc). CP2K can do simulations of molecular dynamics,
metadynamics, Monte Carlo, Ehrenfest dynamics, vibrational analysis,
core level spectroscopy, energy minimization, and transition state
optimization using NEB or dimer method.

The excutables in this module contain support for the following
optional features: libxc, libint

This also updates the environment variable PATH

]])
prepend_path("PATH","$sourcedir/exe/local")
EOF
