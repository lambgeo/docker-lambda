#!/bin/bash

version=$(gdal-config --version)
echo Running tests for GDAL ${version}

echo "Checking formats"
if [[ ! "$(gdal-config --prefix | grep $PREFIX)" ]]; then echo "NOK" && exit 1; fi
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
echo "OK"

echo "Checking sqlite build"
if [[ ! "$(ldd $PREFIX/bin/gdalwarp | grep '/opt/bin/../lib/libsqlite3')" ]]; then echo "libsql NOK" && exit 1; fi
echo "OK"

echo "Checking OGR"
if [[ ! "$(ogrinfo fixtures/map.geojson | grep 'GeoJSON')" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(ogrinfo fixtures/POLYGON.shp | grep 'ESRI Shapefile')" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(ogrinfo fixtures/MSK_CLOUDS_B00.gml | grep 'GML')" ]]; then echo "NOK" && exit 1; fi
echo "OK"

if [ "${version}" != "2.4.4" ]; then
    # for GDAL >=3.1
    echo "Checking PROJ_NETWORK:"
    if [[ ! "$(PROJ_NETWORK=ON projinfo --remote-data | grep 'Status: enabled')" ]]; then echo "NOK" && exit 1; fi
    if [[ ! "$(projinfo --remote-data | grep 'Status: disabled')" ]]; then echo "NOK" && exit 1; fi
    echo "OK"
fi

echo "Checking Reading COG"
if [[ ! "$(gdal_translate fixtures/cog.tif /tmp/tmp.tif | grep "done.")" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(gdal_translate fixtures/cog_webp.tif /tmp/tmp.tif | grep "done.")" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(gdal_translate fixtures/cog_jpeg.tif /tmp/tmp.tif | grep "done.")" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(gdal_translate fixtures/cog_zstd.tif /tmp/tmp.tif | grep "done.")" ]]; then echo "NOK" && exit 1; fi
echo "OK"

exit 0
