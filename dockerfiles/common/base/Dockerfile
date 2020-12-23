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

ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$PREFIX/lib:$PREFIX/lib64

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

# libjpeg_turbo
RUN mkdir /tmp/jpeg \
  && curl -sfL https://github.com/libjpeg-turbo/libjpeg-turbo/archive/${LIBJPEG_TURBO_VERSION}.tar.gz | tar zxf - -C /tmp/jpeg --strip-components=1 \
  && cd /tmp/jpeg \
  && cmake -G"Unix Makefiles" -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_BUILD_TYPE=Release . \
  && make -j $(nproc) install && make clean \
  && mv $PREFIX/lib64/lib* $PREFIX/lib/ \
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
  --with-jpeg=$PREFIX \
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

# libexpat
RUN mkdir /tmp/libexpat \
  && curl -sfL https://github.com/libexpat/libexpat/releases/download/R_2_2_10/expat-2.2.10.tar.gz | tar zxf - -C /tmp/libexpat --strip-components=1 \
  && cd /tmp/libexpat \
  && CFLAGS="-O2 -Wl,-S" CXXFLAGS="-O2 -Wl,-S" ./configure --prefix=$PREFIX --disable-static \
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/libexpat

# nghttp2
ENV NGHTTP2_VERSION=1.42.0
RUN mkdir /tmp/nghttp2 \
  && curl -sfL https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERSION}/nghttp2-${NGHTTP2_VERSION}.tar.gz | tar zxf - -C /tmp/nghttp2 --strip-components=1 \
  && cd /tmp/nghttp2 \
  && ./configure --enable-lib-only --prefix=$PREFIX \
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/nghttp2

# libcurl
ENV CURL_VERSION=7.73.0
RUN mkdir /tmp/libcurl \
  && curl -sfL https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz | tar zxf - -C /tmp/libcurl --strip-components=1 \
  && cd /tmp/libcurl \
  && ./configure --disable-manual --disable-cookies --with-nghttp2=$PREFIX --prefix=$PREFIX \
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/libcurl

# libxml2
ENV LIBXML2_VERSION=2.9.10
RUN mkdir /tmp/libxml2 \
  && curl -sfL https://gitlab.gnome.org/GNOME/libxml2/-/archive/v2.9.10/libxml2-v2.9.10.tar.gz | tar zxf - -C /tmp/libxml2 --strip-components=1  \
  && cd /tmp/libxml2 \
  && ./autogen.sh --prefix=$PREFIX --with-ftp=no --with-http=no --with-python=no \
  && make -j $(nproc) --silent && make install && make clean \
  && rm -rf /tmp/libxml2

ENV \
  SQLITE3_LIBS="-L${PREFIX}/lib -lsqlite3" \
  SQLITE3_INCLUDE_DIR="${PREFIX}/include" \
  SQLITE3_CFLAGS="$CFLAGS -I${PREFIX}/include" \
  PATH=${PREFIX}/bin/:$PATH
