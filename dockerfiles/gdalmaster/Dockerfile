FROM lambda-gdal:common as builder

ENV \
  GEOS_VERSION=3.9.1 \
  LIBTIFF_VERSION=4.3.0 \
  LIBGEOTIFF_VERSION=1.6.0

# geos
RUN mkdir /tmp/geos \
  && curl -sfL http://download.osgeo.org/geos/geos-$GEOS_VERSION.tar.bz2 | tar jxf - -C /tmp/geos --strip-components=1 \
  && cd /tmp/geos \
  && CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure --prefix=$PREFIX --disable-static \
  && make -j $(nproc) --silent && make install \
  && rm -rf /tmp/geos

# libdeflate
RUN mkdir /tmp/libdeflate \
  && curl -sfL https://github.com/ebiggers/libdeflate/archive/v1.7.tar.gz | tar zxf - -C /tmp/libdeflate --strip-components=1 \
  && cd /tmp/libdeflate \
  && make -j $(nproc) --silent PREFIX=$PREFIX && make install \
  && rm -rf /tmp/libdeflate

ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/

# libtiff
RUN mkdir /tmp/libtiff \
  && curl -sfL https://download.osgeo.org/libtiff/tiff-${LIBTIFF_VERSION}.tar.gz | tar zxf - -C /tmp/libtiff --strip-components=1 \
  && cd /tmp/libtiff \
  && LDFLAGS="-Wl,-rpath,'\$\$ORIGIN'" CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure \
    --prefix=$PREFIX \
    --disable-static \
    --enable-rpath \
    --with-lerc-lib-dir=$PREFIX/lib \
    --with-lerc-include-dir=$PREFIX/include \
    --with-libdeflate-lib-dir=$PREFIX/lib \
    --with-libdeflate-include-dir=$PREFIX/include \
    --with-jpeg-lib-dir=$PREFIX/lib \
    --with-jpeg-include-dir=$PREFIX/include \
  && make -j $(nproc) --silent && make install \
  && rm -rf /tmp/libtiff

# proj
# We still provide proj-datumgrid but the user can choose to set `PROJ_NETWORK=ON` to use network grids
ENV PROJ_VERSION=master
RUN mkdir /tmp/proj && mkdir /tmp/proj/data \
  && curl -sfL https://github.com/OSGeo/proj/archive/${PROJ_VERSION}.tar.gz | tar zxf - -C /tmp/proj --strip-components=1 \
  && curl -sfL http://download.osgeo.org/proj/proj-datumgrid-latest.tar.gz | tar zxf - -C /tmp/proj/data \
  && cd /tmp/proj \
  && ./autogen.sh \
  && LDFLAGS="-Wl,-rpath,'\$\$ORIGIN'" CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure --prefix=$PREFIX --disable-static --enable-lto \
  && make -j $(nproc) --silent && make install \
  && rm -rf /tmp/proj

RUN mkdir /tmp/libgeotiff \
  && curl -sfL https://github.com/OSGeo/libgeotiff/releases/download/${LIBGEOTIFF_VERSION}/libgeotiff-${LIBGEOTIFF_VERSION}.tar.gz | tar zxf - -C /tmp/libgeotiff --strip-components=1 \
  && cd /tmp/libgeotiff \
  && LDFLAGS="-Wl,-rpath,'\$\$ORIGIN'" CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure \
    --prefix=$PREFIX \
    --with-proj=$PREFIX \
    --with-jpeg=$PREFIX \
    --with-zip=yes \
    --with-zlib \
    --with-libtiff=$PREFIX \
  && make -j $(nproc) --silent && make install \
  && rm -rf /tmp/libgeotiff

# gdal
ENV GDAL_VERSION=master
RUN mkdir /tmp/gdal \
  && curl -sfL https://github.com/OSGeo/gdal/archive/${GDAL_VERSION}.tar.gz | tar zxf - -C /tmp/gdal --strip-components=2

RUN cd /tmp/gdal \
  && touch config.rpath \
  && LIBXML2_CFLAGS=$(xml2-config --cflags) LIBXML2_LIBS=$(xml2-config --libs) LDFLAGS="-Wl,-rpath,'\$\$ORIGIN'" CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure \
      --disable-debug \
      --prefix=$PREFIX \
      --without-libtool \
      --with-hide-internal-symbols \
      --with-proj=$PREFIX \
      --with-libtiff=$PREFIX --with-rename-internal-libtiff-symbols \
      --with-geotiff=$PREFIX --with-rename-internal-libgeotiff-symbols \
      --with-crypto \
      --with-curl \
      --with-expat=$PREFIX \
      --with-hdf4=$PREFIX \
      --with-hdf5=$PREFIX \
      --with-geos=$PREFIX/bin/geos-config \
      --with-jpeg=$PREFIX \
      --with-netcdf=$PREFIX \
      --with-openjpeg \
      --with-pg=yes \
      --with-png \
      --with-sqlite3=$PREFIX \
      --with-xml2=yes \
      --with-webp=$PREFIX \
      --with-zstd=$PREFIX \
      --with-libdeflate=$PREFIX \
      --with-threads=yes \
      --without-cfitsio \
      --without-ecw \
      --without-fme \
      --without-freexl \
      --without-jpeg12 \
      --without-gif \
      --without-gnm \
      --without-libtool \
      --without-pcraster \
      --without-pcidsk \
      --disable-all-optional-drivers \
      --enable-driver-pds \
      --enable-driver-shape \
      --enable-driver-gpkg \
      --enable-driver-sentinel2 \
      --enable-driver-xyz \
      --enable-driver-flatgeobuf \
      --enable-driver-mvt \
      --enable-driver-wmts \
      --enable-driver-wms \
      --enable-driver-mbtiles \
      --enable-driver-gpkg \
      --enable-driver-gml \
      --enable-driver-pgdump
      # --enable-lto \

RUN cd /tmp/gdal \
  && make -j $(nproc) --quiet && make install --quiet \
  && rm -rf /tmp/gdal

# from https://github.com/pypa/manylinux/blob/d8ef5d47433ba771fa4403fd48f352c586e06e43/docker/build_scripts/build.sh#L133-L138
# Install patchelf (latest with unreleased bug fixes)
ENV PATCHELF_VERSION 0.10
RUN mkdir /tmp/patchelf \
  && curl -sfL https://github.com/NixOS/patchelf/archive/$PATCHELF_VERSION.tar.gz | tar zxf - -C /tmp/patchelf --strip-components=1 \
  && cd /tmp/patchelf && ./bootstrap.sh && ./configure \
  && make -j $(nproc) --silent && make install \
  && cd / && rm -rf /tmp/patchelf

# libturbojpeg.so is not used by GDAL. Only libjpeg.so*
RUN rm -f $PREFIX/lib/libturbojpeg.so* \
  # Only libwebp.so is used by GDAL
  && rm -f  $PREFIX/lib/libwebpmux.so*  $PREFIX/lib/libwebpdemux.so* $PREFIX/lib/libwebpdecoder.so*

# FIX
RUN for i in $PREFIX/bin/*; do  patchelf --force-rpath --set-rpath '$ORIGIN/../lib' $i; done

# Build final image
FROM lambci/lambda-base-2:build as runner

ENV PREFIX /opt
COPY --from=builder /opt/lib/ $PREFIX/lib/
COPY --from=builder /opt/include/ $PREFIX/include/
COPY --from=builder /opt/share/ $PREFIX/share/
COPY --from=builder /opt/bin/ $PREFIX/bin/

ENV \
  GDAL_DATA=$PREFIX/share/gdal \
  PROJ_LIB=$PREFIX/share/proj \
  GDAL_CONFIG=$PREFIX/bin/gdal-config \
  GEOS_CONFIG=$PREFIX/bin/geos-config \
  PATH=$PREFIX/bin:$PATH

RUN export GDAL_VERSION=$(gdal-config --version)
