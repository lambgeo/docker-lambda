ARG IMAGE_VERSION

FROM ${IMAGE_VERSION}:build as builder

ENV \
  GEOS_VERSION=3.8.1 \
  PROJ_VERSION=5.2.0

ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/

# proj
RUN mkdir /tmp/proj && mkdir /tmp/proj/data \
  && curl -sfL http://download.osgeo.org/proj/proj-$PROJ_VERSION.tar.gz | tar zxf - -C /tmp/proj --strip-components=1 \
  && curl -sfL http://download.osgeo.org/proj/proj-datumgrid-latest.tar.gz | tar zxf - -C /tmp/proj/data \
  && cd /tmp/proj \
  && LDFLAGS="-Wl,-rpath,'\$\$ORIGIN'" CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure --prefix=$PREFIX --disable-static --enable-lto \
  && make -j $(nproc) --silent && make install \
  && rm -rf /tmp/proj

# geos
RUN mkdir /tmp/geos \
  && curl -sfL http://download.osgeo.org/geos/geos-$GEOS_VERSION.tar.bz2 | tar jxf - -C /tmp/geos --strip-components=1 \
  && cd /tmp/geos \
  && CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure --prefix=$PREFIX --disable-static \
  && make -j $(nproc) --silent && make install \
  && rm -rf /tmp/geos

# gdal
# Use latest commits from Github instead of release
# "release/2.4" is the up to date 2.4 github branch
RUN mkdir /tmp/gdal \
  && curl -sfL https://github.com/OSGeo/gdal/archive/release/2.4.tar.gz | tar zxf - -C /tmp/gdal --strip-components=2

RUN cd /tmp/gdal \
  && touch config.rpath \
  && LDFLAGS="-Wl,-rpath,'\$\$ORIGIN'" CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure \
      --disable-debug \
      --enable-lto \
      --prefix=$PREFIX \
      --with-crypto \
      --with-curl=$PREFIX \
      --with-expat=$PREFIX \
      --with-hdf4=$PREFIX \
      --with-hdf5=$PREFIX \
      --with-hide-internal-symbols=yes \
      --with-geos=$PREFIX/bin/geos-config \
      --with-geotiff=internal \
      --with-rename-internal-libgeotiff-symbols \
      --with-jpeg=$PREFIX \
      --with-libtiff=internal \
      --with-rename-internal-libtiff-symbols \
      --with-netcdf=$PREFIX \
      --with-openjpeg \
      --with-pg=yes \
      --with-png \
      --with-proj=$PREFIX \
      --with-sqlite3 \
      --with-xml2=yes \
      --with-webp=$PREFIX \
      --with-zstd=$PREFIX \
      --with-threads=yes \
      --without-bsb \
      --without-cfitsio \
      --without-ecw \
      --without-fme \
      --without-freexl \
      --without-jpeg12 \
      --without-gif \
      --without-gnm \
      --without-lerc \
      --without-libtool \
      --without-pcraster \
      --without-pcidsk

RUN cd /tmp/gdal \
  && make -j $(nproc) --silent && make install \
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
FROM lambci/lambda-${IMAGE_VERSION}:build  as runner

ENV PREFIX /opt
COPY --from=builder /opt/lib/ $PREFIX/lib/
COPY --from=builder /opt/include/ $PREFIX/include/
COPY --from=builder /opt/share/ $PREFIX/share/
COPY --from=builder /opt/bin/ $PREFIX/bin/

ENV \
  GDAL_VERSION=2.4.4 \
  GDAL_DATA=$PREFIX/share/gdal \
  PROJ_LIB=$PREFIX/share/proj \
  GDAL_CONFIG=$PREFIX/bin/gdal-config \
  GEOS_CONFIG=$PREFIX/bin/geos-config \
  PATH=$PREFIX/bin:$PATH
