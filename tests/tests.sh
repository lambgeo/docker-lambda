#!/bin/bash

version=$(gdal-config --version)
echo Running tests for GDAL ${version}

if [[ ! "$(gdal-config --prefix | grep $PREFIX)" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(gdal-config --version | grep $GDALVERSION)" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'openjpeg')" ]]; then echo "openjpeg NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'gtiff')" ]]; then echo "gtiff NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'mbtiles')" ]]; then echo "mbtiles NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'webp')" ]]; then echo "webp NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'jpeg')" ]]; then echo "jpeg NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'png')" ]]; then echo "png NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'netcdf')" ]]; then echo "netcdf NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'hdf5')" ]]; then echo "hdf5 NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'hdf4')" ]]; then echo "hdf4 NOK" && exit 1; fi
if [[ ! "$(ogrinfo --formats | grep 'GML')" ]]; then echo "GLM NOK" && exit 1; fi
if [[ ! "$(ogrinfo --formats | grep 'PostgreSQL')" ]]; then echo "PostGres NOK" && exit 1; fi

if [[ ! "$(ldd $PREFIX/bin/gdalwarp | grep '/opt/bin/../lib/libsqlite3')" ]]; then echo "libsql NOK" && exit 1; fi

if [[ ! "$(ogrinfo fixtures/map.geojson | grep 'GeoJSON')" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(ogrinfo fixtures/POLYGON.shp | grep 'ESRI Shapefile')" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(ogrinfo fixtures/MSK_CLOUDS_B00.gml | grep 'GML')" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(gdalinfo fixtures/cog.tif | grep 'GTiff/GeoTIFF')" ]]; then echo "NOK" && exit 1; fi

echo "OK"
exit 0
