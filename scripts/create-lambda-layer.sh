#!/bin/bash
echo "-----------------------"
echo "Creating lambda layer"
echo "-----------------------"

ARCHIVE_NAME=gdal"$(gdal-config --version | cut -b 1-3)"

echo "Remove useless files"
rm -rdf $PREFIX/share/doc \
&& rm -rdf $PREFIX/share/man \
&& rm -rdf $PREFIX/share/hdf*

echo "Strip shared libraries"
cd $PREFIX && find lib -name \*.so\* -exec strip {} \;

echo "Create archives"
cd $PREFIX && zip -r9q --symlinks /tmp/package.zip lib/*.so*
cd $PREFIX && zip -r9q --symlinks /tmp/package.zip share
cd $PREFIX && zip -r9q --symlinks /tmp/package.zip bin/gdal* bin/ogr* bin/geos* bin/nearblack

cp /tmp/package.zip /local/${ARCHIVE_NAME}.zip
