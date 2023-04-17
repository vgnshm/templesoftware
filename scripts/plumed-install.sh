#!/bin/bash
#
# Description: Plumed automated download and installation
# Author: (c) 2023 Dr. Vignesh Mahalingam
# Purpose: For Software installation in Temple university clusters: Owl's nest & compute
clear
date
Software="plumed"
echo "----------------------"
echo "$Software installation"
echo "----------------------"
name="plumed"
version="2.8.2"
extension="tgz"
taroption="xzf"
FILE=$name-$version.$extension
web_url="https://github.com/plumed/plumed2/releases/download/v$version"

rootdir="/home/tur09027/work"
appsdir="$rootdir/apps"
downloaddir="$appsdir/downloads"
sourcedir="$appsdir/$name-$version"
moduledir="$rootdir/apps/modulefiles"

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
# module unload cuda

rm -rf $sourcedir
mkdir -p $sourcedir
$downloaddir/$name-$version/configure --prefix=$sourcedir
# LIBS="-lblas -llapack"
make -j $nthreads
make install

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

whatis("PLUMED Free Energy Methods Tool and Library")
help([[
This module provides the PLUMED free energy methods library and analysis codes.

It contains the 'plumed' executable and libraries to be included into MD
codes. PLUMED-enabled MD software packages are available as modules, where
the PLUMED support is indicated by a '-plumed' suffix to the version number.

The module sets the environment variable PLUMED_DIR to the root folder
this package. It also updates the environment variables PATH, CPATH,
LIBRARY_PATH, and LD_LIBRARY_PATH.

]])
family("plumed")
prepend_path("PATH","$sourcedir/bin")
prepend_path("CPATH","$sourcedir/include")
prepend_path("LIBRARY_PATH","$sourcedir/lib")
prepend_path("LD_LIBRARY_PATH","$sourcedir/lib")
prepend_path("PKG_CONFIG_PATH","$sourcedir/lib/pkgconfig")
setenv("PLUMED_DIR","$sourcedir")
EOF
