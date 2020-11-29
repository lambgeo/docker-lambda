
# GDAL based docker image made for AWS Lambda

<p align="center">
  <img src="https://user-images.githubusercontent.com/10407788/95621320-7b226080-0a3f-11eb-8194-4b55a5555836.png" style="max-width: 800px;" alt="docker-lambda"></a>
</p>
<p align="center">
  <em>AWS lambda (Amazonlinux) like docker images with GDAL.</em>
</p>
<p align="center">
  <a href="https://github.com/cogeotiff/rio-tiler/actions?query=workflow%3ACI" target="_blank">
      <img src="https://github.com/cogeotiff/rio-tiler/workflows/CI/badge.svg" alt="Test">
  </a>
</p>


# Docker Images

Based on lambci/lambda-base:build (amazonlinux)
  - GDAL 3.2.0 (Oct. 2020)
    - **lambgeo/lambda-gdal:3.2**

  - GDAL 3.1.4 (Oct. 2020)
    - **lambgeo/lambda-gdal:3.1**

  - GDAL 2.4.4 (June 2020)
    - **lambgeo/lambda-gdal:2.4**

  - For python 3.7
    - **lambgeo/lambda-gdal:3.2-python3.7**
    - **lambgeo/lambda-gdal:3.1-python3.7**
    - **lambgeo/lambda-gdal:2.4-python3.7**

Based on lambci/lambda-base-2:build (amazonlinux2) for newer runtimes (e.g python 3.8)
  - GDAL 3.2.0 (Oct. 2020)
    - **lambgeo/lambda2-gdal:3.2**

  - GDAL 3.1.4 (Oct. 2020)
    - **lambgeo/lambda2-gdal:3.1**

  - GDAL 2.4.4 (June 2020)
    - **lambgeo/lambda2-gdal:2.4**

  - For python 3.8
    - **lambgeo/lambda-gdal:3.2-python3.8**
    - **lambgeo/lambda-gdal:3.1-python3.8**
    - **lambgeo/lambda-gdal:2.4-python3.8**

## Creating Lambda packages

1. Dockerfile

```Dockerfile
FROM lambgeo/lambda-gdal:3.2-python3.8

ENV PACKAGE_PREFIX=/var/task

# Copy any local files to the package
COPY handler.py ${PACKAGE_PREFIX}/handler.py

# Install some requirements
RUN pip install numpy rasterio mercantile --no-binary :all: -t ${PACKAGE_PREFIX}/

# Cleanup the package of useless files
RUN rm -rdf $PACKAGE_PREFIX/boto3/ \
  && rm -rdf $PACKAGE_PREFIX/botocore/ \
  && rm -rdf $PACKAGE_PREFIX/docutils/ \
  && rm -rdf $PACKAGE_PREFIX/dateutil/ \
  && rm -rdf $PACKAGE_PREFIX/jmespath/ \
  && rm -rdf $PACKAGE_PREFIX/s3transfer/ \
  && rm -rdf $PACKAGE_PREFIX/numpy/doc/ \
  && rm -rdf $PREFIX/share/doc \
  && rm -rdf $PREFIX/share/man \
  && rm -rdf $PREFIX/share/hdf*

# Reduce size of the C libs
RUN cd $PREFIX && find lib -name \*.so\* -exec strip {} \;

# Copy python files
RUN cd $PACKAGE_PREFIX && zip -r9q /tmp/package.zip *

# Copy shared libs
RUN cd $PREFIX && zip -r9q --symlinks /tmp/package.zip lib/*.so* share
RUN cd $PREFIX && zip -r9q --symlinks /tmp/package.zip bin/gdal* bin/ogr* bin/geos* bin/nearblack
```

2. Build and create package.zip

```bash
docker build --tag package:latest .
docker run --name lambda -w /var/task --volume $(shell pwd)/:/local -itd package:latest bash
docker cp lambda:/tmp/package.zip package.zip
docker stop lambda
docker rm lambda
```
Package content should be like:
```
package.zip
  |
  |___ lib/      # Shared libraries (GDAL, PROJ, GEOS...)
  |___ share/    # GDAL/PROJ data directories
  |___ rasterio/
  ....
  |___ handler.py
  |___ other python module
```

3. Deploy and Set Environment variables

For Rasterio or other libraries to be aware of GDAL/PROJ C libraries, you need to set up those 2 envs:
- **GDAL_DATA:** /var/task/share/gdal
- **PROJ_LIB:** /var/task/share/proj

### Other variable

Starting with gdal3.1 (PROJ 7.1), you can set `PROJ_NETWORK=ON` to use remote grids: https://proj.org/usage/network.html


### Refactor

We recently refactored the repo, to see old documentation please refer to https://github.com/lambgeo/docker-lambda/tree/ef66339724b1b7e1a375df912dfd58a9c59ac109
