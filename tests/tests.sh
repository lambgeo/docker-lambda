#!/bin/bash

version=$(gdal-config --version)
echo Running tests for GDAL ${version}

echo "Checking formats"
if [[ ! "$(gdal-config --prefix | grep $PREFIX)" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'JP2OpenJPEG')" ]]; then echo "JP2OpenJPEG NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'GTIFF')" ]]; then echo "GTIFF NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'MBTiles')" ]]; then echo "MBTiles NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'WEBP')" ]]; then echo "WEBP NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'JPEG')" ]]; then echo "JPEG NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'PNG')" ]]; then echo "PNG NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'netCDF')" ]]; then echo "netCDF NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'Zarr')" ]]; then echo "Zarr NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'HDF5')" ]]; then echo "HDF5 NOK" && exit 1; fi
if [[ ! "$(gdal-config --formats | grep 'HDF4')" ]]; then echo "HDF4 NOK" && exit 1; fi
if [[ ! "$(ogrinfo --formats | grep 'GML')" ]]; then echo "GLM NOK" && exit 1; fi
if [[ ! "$(ogrinfo --formats | grep 'PostgreSQL')" ]]; then echo "PostgreSQL NOK" && exit 1; fi
if [[ ! "$(ogrinfo --formats | grep 'DXF')" ]]; then echo "DXF NOK" && exit 1; fi
echo "OK"

echo "Checking sqlite build"
if [[ ! "$(ldd $PREFIX/bin/gdalwarp | grep '/opt/bin/../lib/libsqlite3')" ]]; then echo "gdalwarp libsql NOK" && exit 1; fi
if [[ ! "$(ldd $PREFIX/lib/libgdal.so | grep '/opt/lib/libsqlite3')" ]]; then echo "libgdal libsql NOK" && exit 1; fi
if [[ ! "$(ldd $PREFIX/lib/libproj.so | grep '/opt/lib/libsqlite3')" ]]; then echo "libproj libsql NOK" && exit 1; fi
if [[ ! "$(ldd $PREFIX/lib/libgeotiff.so | grep '/opt/lib/libsqlite3')" ]]; then echo "libgeotiff libsql NOK" && exit 1; fi
echo "OK"

echo "Checking OGR"
if [[ ! "$(ogrinfo /local/tests/fixtures/map.geojson | grep 'successful')" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(ogrinfo /local/tests/fixtures/POLYGON.shp | grep 'successful')" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(ogrinfo /local/tests/fixtures/MSK_CLOUDS_B00.gml | grep 'successful')" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(ogrinfo /local/tests/fixtures/square.dxf | grep 'successful')" ]]; then echo "NOK" && exit 1; fi
echo "OK"

if [ "${version}" != "2.4.4" ]; then
    # for GDAL >=3.1
    echo "Checking PROJ_NETWORK:"
    if [[ ! "$(PROJ_NETWORK=ON projinfo --remote-data | grep 'Status: enabled')" ]]; then echo "NOK" && exit 1; fi
    if [[ ! "$(projinfo --remote-data | grep 'Status: disabled')" ]]; then echo "NOK" && exit 1; fi
    echo "OK"
fi

echo "Checking Reading COG"
if [[ ! "$(gdal_translate /local/tests/fixtures/cog.tif /tmp/tmp.tif | grep "done.")" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(gdal_translate /local/tests/fixtures/cog_webp.tif /tmp/tmp.tif | grep "done.")" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(gdal_translate /local/tests/fixtures/cog_jpeg.tif /tmp/tmp.tif | grep "done.")" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(gdal_translate /local/tests/fixtures/cog_zstd.tif /tmp/tmp.tif | grep "done.")" ]]; then echo "NOK" && exit 1; fi
if [[ ! "$(gdal_translate /local/tests/fixtures/cog_lerc.tif /tmp/tmp.tif | grep "done.")" ]]; then echo "NOK" && exit 1; fi
echo "OK"

exit 0
