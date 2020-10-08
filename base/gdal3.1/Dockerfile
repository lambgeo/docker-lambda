FROM lambci/lambda-base:build as builder

LABEL maintainer="lambgeo <geolambdas@gmail.com>"

################################################################################
# COMMON
RUN yum makecache fast
RUN yum install -y automake16 libpng-devel nasm

ENV PREFIX /opt
WORKDIR /opt

# versions of packages
ENV \
  LIBTIFF_VERSION=4.1.0 \
  HDF4_VERSION=4.2.15 \
  HDF5_VERSION=1.12.0 \
  NETCDF_VERSION=4.7.4 \
  LIBPNG_VERSION=1.6.37 \
  LIBJPEG_TURBO_VERSION=2.0.5 \
  OPENJPEG_VERSION=2.3.1 \
  PG_VERSION=13.0 \
  PKGCONFIG_VERSION=0.29.2 \
  SZIP_VERSION=2.1.1 \
  WEBP_VERSION=1.1.0 \
  ZSTD_VERSION=1.4.5

ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/$PREFIX/lib:/$PREFIX/lib64

# pkg-config
RUN mkdir /tmp/pkg-config \
  && curl -sfL https://pkg-config.freedesktop.org/releases/pkg-config-$PKGCONFIG_VERSION.tar.gz | tar zxf - -C /tmp/pkg-config --strip-components=1 \
  && cd /tmp/pkg-config \
  && CFLAGS="-O2 -Wl,-S" ./configure --prefix=$PREFIX \
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/pkg-config

# png
RUN mkdir /tmp/png \
  && curl -sfL http://prdownloads.sourceforge.net/libpng/libpng-$LIBPNG_VERSION.tar.gz | tar zxf - -C /tmp/png --strip-components=1 \
  && cd /tmp/png \
  && CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure --prefix=$PREFIX \
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/png

# openjpeg
RUN mkdir /tmp/openjpeg \
  && curl -sfL https://github.com/uclouvain/openjpeg/archive/v$OPENJPEG_VERSION.tar.gz | tar zxf - -C /tmp/openjpeg --strip-components=1 \
  && cd /tmp/openjpeg \
  && mkdir build && cd build \
  && cmake .. -DBUILD_THIRDPARTY:BOOL=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX \
  && make -j $(nproc) install && make clean \
  && rm -rf /tmp/openjpeg

# jpeg_turbo
RUN mkdir /tmp/jpeg \
  && curl -sfL https://github.com/libjpeg-turbo/libjpeg-turbo/archive/${LIBJPEG_TURBO_VERSION}.tar.gz | tar zxf - -C /tmp/jpeg --strip-components=1 \
  && cd /tmp/jpeg \
  && cmake -G"Unix Makefiles" -DCMAKE_INSTALL_PREFIX=$PREFIX . \
  && make -j $(nproc) install && make clean \
  && rm -rf /tmp/jpeg

# webp
RUN mkdir /tmp/webp \
  && curl -sfL https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${WEBP_VERSION}.tar.gz | tar zxf - -C /tmp/webp --strip-components=1 \
  && cd /tmp/webp \
  && CFLAGS="-O2 -Wl,-S" ./configure --prefix=$PREFIX \
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/webp

# zstd
RUN mkdir /tmp/zstd \
  && curl -sfL https://github.com/facebook/zstd/archive/v${ZSTD_VERSION}.tar.gz | tar zxf - -C /tmp/zstd --strip-components=1 \
  && cd /tmp/zstd \
  && make -j $(nproc) PREFIX=$PREFIX ZSTD_LEGACY_SUPPORT=0 CFLAGS=-O1 --silent && make install PREFIX=$PREFIX ZSTD_LEGACY_SUPPORT=0 CFLAGS=-O1 && make clean \
  && rm -rf /tmp/zstd


# szip (for hdf)
RUN mkdir /tmp/szip \
  && curl -sfL https://support.hdfgroup.org/ftp/lib-external/szip/$SZIP_VERSION/src/szip-$SZIP_VERSION.tar.gz | tar zxf - -C /tmp/szip --strip-components=1 \
  && cd /tmp/szip \
  && CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure --prefix=$PREFIX --disable-static \
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/szip

# libhdf4
RUN mkdir /tmp/hdf4 \
  && curl -sfL https://support.hdfgroup.org/ftp/HDF/releases/HDF$HDF4_VERSION/src/hdf-$HDF4_VERSION.tar | tar xvf - -C /tmp/hdf4 --strip-components=1 \
  && cd /tmp/hdf4 \
  && CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure \
  --prefix=$PREFIX \
  --with-szlib=$PREFIX \
  --enable-shared \
  --disable-static \
  --disable-netcdf \
  --disable-fortran \
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/hdf4

# libhdf5
RUN mkdir /tmp/hdf5 \
  && curl -sfL https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_VERSION%.*}/hdf5-${HDF5_VERSION}/src/hdf5-$HDF5_VERSION.tar.gz | tar zxf - -C /tmp/hdf5 --strip-components=1 \
  && cd /tmp/hdf5 \
  && CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure \
  --prefix=$PREFIX \
  --with-szlib=$PREFIX \
  --enable-cxx \
  --enable-thread-safe \
  --disable-static \
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/hdf5

# NetCDF
RUN mkdir /tmp/netcdf \
  && curl -sfL https://github.com/Unidata/netcdf-c/archive/v$NETCDF_VERSION.tar.gz | tar zxf - -C /tmp/netcdf --strip-components=1 \
  && cd /tmp/netcdf \
  && CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" CPPFLAGS="-I${PREFIX}/include" LDFLAGS="-L${PREFIX}/lib" ./configure \
  --with-default-chunk-size=67108864 \
  --with-chunk-cache-size=67108864 \
  --prefix=$PREFIX \
  --disable-static \
  --enable-netcdf4 \
  --enable-dap \
  --with-pic \
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/netcdf

# postgres
RUN mkdir /tmp/postgres \
  && curl -sfL https://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.gz | tar zxf - -C /tmp/postgres --strip-components=1 \
  && cd /tmp/postgres \
  && CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure --prefix=$PREFIX --with-openssl \
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/postgres

# sqlite
RUN mkdir /tmp/sqlite \
  && curl -sfL https://www.sqlite.org/2020/sqlite-autoconf-3330000.tar.gz | tar zxf - -C /tmp/sqlite --strip-components=1 \
  && cd /tmp/sqlite \
  && CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure --prefix=$PREFIX --disable-static \
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/sqlite

ENV \
  SQLITE3_LIBS="-L${PREFIX}/lib -lsqlite3" \
  SQLITE3_INCLUDE_DIR="${PREFIX}/include" \
  SQLITE3_CFLAGS="$CFLAGS -I${PREFIX}/include" \
  PATH=${PREFIX}/bin/:$PATH

# libtiff
RUN mkdir /tmp/libtiff \
  && curl -sfL https://download.osgeo.org/libtiff/tiff-${LIBTIFF_VERSION}.tar.gz | tar zxf - -C /tmp/libtiff --strip-components=1 \
  && cd /tmp/libtiff \
  && CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure --prefix=$PREFIX \
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/libtiff

################################################################################
# BUILD SPECIFIC
# OSGEO
ENV \
  GEOS_VERSION=3.8.1 \
  PROJ_VERSION=7.1.1

# proj
RUN mkdir /tmp/proj \
   && curl -sfL http://download.osgeo.org/proj/proj-$PROJ_VERSION.tar.gz | tar zxf - -C /tmp/proj --strip-components=1 \
   && curl -sfL http://download.osgeo.org/proj/proj-datumgrid-latest.tar.gz | tar zxf - -C /tmp/proj/data \
   && cd /tmp/proj \
   && LDFLAGS="-Wl,-rpath,'\$\$ORIGIN'" CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure --prefix=$PREFIX --disable-static --enable-lto \
   && make -j $(nproc) --silent && make install && make clean \
   && rm -rf /tmp/proj

# geos
RUN mkdir /tmp/geos \
  && curl -sfL http://download.osgeo.org/geos/geos-$GEOS_VERSION.tar.bz2 | tar jxf - -C /tmp/geos --strip-components=1 \
  && cd /tmp/geos \
  && CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure --prefix=$PREFIX --disable-static \
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/geos

ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/

# gdal
# Use latest commits from Github instead of release
# "release/3.1" is the up to date 3.1.3 github branch
RUN mkdir /tmp/gdal \
  && curl -sfL https://github.com/OSGeo/gdal/archive/release/3.1.tar.gz | tar zxf - -C /tmp/gdal --strip-components=2

RUN cd /tmp/gdal \
  && touch config.rpath \
  && LIBXML2_CFLAGS=$(xml2-config --cflags) LIBXML2_LIBS=$(xml2-config --libs) LDFLAGS="-Wl,-rpath,'\$\$ORIGIN'" CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure \
      --disable-debug \
      --enable-lto \
      --prefix=$PREFIX \
      --with-crypto \
      --with-curl \
      --with-expat \
      --with-hdf4=$PREFIX \
      --with-hdf5=$PREFIX \
      --with-libtiff=$PREFIX \
      --with-hide-internal-symbols=yes \
      --with-geos=$PREFIX/bin/geos-config \
      --with-geotiff=internal \
      --with-rename-internal-libgeotiff-symbols \
      --with-jpeg=$PREFIX \
      --with-rename-internal-libtiff-symbols \
      --with-netcdf=$PREFIX \
      --with-openjpeg \
      --with-pg=yes \
      --with-png \
      --with-proj=$PREFIX \
      --with-sqlite3=$PREFIX \
      --with-xml2=yes \
      --with-webp=$PREFIX \
      --with-zstd=$PREFIX \
      --disable-driver-bsb \
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
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/gdal

# from https://github.com/pypa/manylinux/blob/d8ef5d47433ba771fa4403fd48f352c586e06e43/docker/build_scripts/build.sh#L133-L138
# Install patchelf (latest with unreleased bug fixes)
ENV PATCHELF_VERSION 0.10
RUN mkdir /tmp/patchelf \
  && curl -sfL https://github.com/NixOS/patchelf/archive/$PATCHELF_VERSION.tar.gz | tar zxf - -C /tmp/patchelf --strip-components=1 \
  && cd /tmp/patchelf && ./bootstrap.sh && ./configure \
  && make -j $(nproc) --silent && make install && make clean \
  && cd / && rm -rf /tmp/patchelf

# Move /lib64 (libjpeg) to /lib
RUN mv $PREFIX/lib64/lib* $PREFIX/lib/

# FIX
RUN for i in $PREFIX/bin/*; do  patchelf --force-rpath --set-rpath '$ORIGIN/../lib' $i; done

# Build final image
FROM lambci/lambda-base:build  as runner

ENV PREFIX /opt
COPY --from=builder /opt/lib/ $PREFIX/lib/
COPY --from=builder /opt/include/ $PREFIX/include/
COPY --from=builder /opt/share/ $PREFIX/share/
COPY --from=builder /opt/bin/ $PREFIX/bin/

ENV \
  GDAL_VERSION=3.1.0 \
  GDAL_DATA=$PREFIX/share/gdal \
  PROJ_LIB=$PREFIX/share/proj \
  GDAL_CONFIG=$PREFIX/bin/gdal-config \
  GEOS_CONFIG=$PREFIX/bin/geos-config \
  PATH=$PREFIX/bin:$PATH
