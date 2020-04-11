# GDAL based docker-lambda

[![CircleCI](https://circleci.com/gh/lambgeo/docker-lambda.svg?style=svg)](https://circleci.com/gh/lambgeo/docker-lambda)

Create an **AWS lambda** like docker images and lambda layer with GDAL.


# Docker Images
Based on lambci/lambda-base:build
  - 3.1.0 (April. 2020) - **lambgeo/lambda:gdal3.1** - Pre-release
  - 3.0.4 (April. 2020) - **lambgeo/lambda:gdal3.0** 
  - 2.4.4 (April. 2020) - **lambgeo/lambda:gdal2.4**

# Lambda Layers
We are publishing each gdal version as lambda layer on the AWS infrastructure. 
Each layer are available for all runtimes.

#### versions:

gdal | version | size (Mb)| unzipped size (Mb)| arn
  ---|      ---|       ---|                ---| ---
3.1  |        1|        24|               61.7| arn:aws:lambda:us-east-1:524387336408:layer:gdal31:1
3.0  |        1|        23|               58.5| arn:aws:lambda:us-east-1:524387336408:layer:gdal30:1
2.4  |        1|      14.8|               48.6| arn:aws:lambda:us-east-1:524387336408:layer:gdal24:1

[Full list of version and ARN](/arns.json)

#### Regions
- ap-northeast-1
- ap-northeast-2
- ap-south-1 
- ap-southeast-1
- ap-southeast-2
- ca-central-1
- eu-central-1
- eu-north-1
- eu-west-1
- eu-west-2
- eu-west-3
- sa-east-1
- us-east-1
- us-east-2
- us-west-1
- us-west-2

#### content

```
layer.zip
  |
  |___ bin/      # Binaries
  |___ lib/      # Shared libraries (GDAL, PROJ, GEOS...)
  |___ share/    # GDAL/PROJ data directories   
```

You may want to extent this layer by adding runtime specific code 

```
layer.zip
  |
  ...
  |___ python/            # Runtime
         |__ rasterio/
         |__ rio_tiler/
         |__ handler.py  
```

## Create a Python Lambda package

To help the creation of lambda Python package (or complex layers) we are also creating Python (3.7 and 3.8) docker images.

- **3.1**
  - **lambgeo/lambda:gdal3.1-py3.8**
  - **lambgeo/lambda:gdal3.1-py3.7**

- **3.0**
  - **lambgeo/lambda:gdal3.0-py3.8**
  - **lambgeo/lambda:gdal3.0-py3.7**

- **2.4**
  - **lambgeo/lambda:gdal2.4-py3.8**
  - **lambgeo/lambda:gdal2.4-py3.7**

Checkout [/base/python/Dockerfile](/base/python/Dockerfile) to see how to create other runtime supported images.

You can use the docker container to either build a full package (you provide all the libraries)
or adapt for the use of AWS Lambda layer.

### 1. Create full package (see [/examples/package](/examples/package))

- /Dockerfile

```Dockerfile
FROM lambgeo/lambda:gdal3.0-py3.7

ENV PACKAGE_PREFIX=/var/task

COPY handler.py ${PACKAGE_PREFIX}/handler.py
RUN pip install numpy rasterio mercantile --no-binary :all: -t ${PACKAGE_PREFIX}/
```

- /package.sh

```bash
#!/bin/bash
echo "-----------------------"
echo "Creating lambda package"
echo "-----------------------"
echo "Remove lambda python packages"
rm -rdf $PACKAGE_PREFIX/boto3/ \
  && rm -rdf $PACKAGE_PREFIX/botocore/ \
  && rm -rdf $PACKAGE_PREFIX/docutils/ \
  && rm -rdf $PACKAGE_PREFIX/dateutil/ \
  && rm -rdf $PACKAGE_PREFIX/jmespath/ \
  && rm -rdf $PACKAGE_PREFIX/s3transfer/ \
  && rm -rdf $PACKAGE_PREFIX/numpy/doc/

echo "Strip shared libraries"
cd $PREFIX && find lib -name \*.so\* -exec strip {} \;

echo "Create archive"
cd $PACKAGE_PREFIX && zip -r9q /tmp/package.zip *
cd $PREFIX && zip -r9q --symlinks /tmp/package.zip lib/*.so* share bin
cp /tmp/package.zip /local/package.zip
```

- commands
```bash
docker build --tag package:latest .
docker run --name lambda -w /var/task --volume $(shell pwd)/:/local -itd package:latest bash
docker exec -it lambda bash '/local/package.sh'
docker stop lambda
docker rm lambda
```

### 2. Use Lambda Layer (see [/examples/layer](/examples/layer))

- dockerfile

Here we install rasterio and we add our handler method. The final package structure should be 

```
package/
  |___ handler.py  
  |___ mercantile/
  |___ rasterio/
```

```Dockerfile
FROM lambgeo/lambda:gdal3.0-py3.7

# Basically we don't want to replicated existant modules found in the layer ($PYTHONPATH)
# So we use the $PYTHONUSERBASE trick to set the output directory
ENV PYTHONUSERBASE=/var/task

# Create a package
COPY handler.py $PYTHONUSERBASE/handler.py
RUN pip install numpy rasterio mercantile --no-binary :all: --user
```

- layer.sh
```bash
# We move all the package to the root directory
version=$(python -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")')
PYPATH=${PYTHONUSERBASE}/lib/python${version}/site-packages/
mv ${PYPATH}/* ${PYTHONUSERBASE}/
rm -rf ${PYTHONUSERBASE}/lib

echo "Create archive"
cd $PYTHONUSERBASE && zip -r9q /tmp/layer.zip *

cp /tmp/layer.zip /local/layer.zip
```
- commands
```bash
docker build --tag package:latest .
docker run --name lambda -w /var/task --volume $(shell pwd)/:/local -itd package:latest bash
docker exec -it lambda bash '/local/layer.sh'
docker stop lambda
docker rm lambda

```

## AWS Lambda config
- When using lambgeo gdal layer

  - **GDAL_DATA:** /opt/share/gdal
  - **PROJ_LIB:** /opt/share/proj

- When creating full package
  - **GDAL_DATA:** /var/task/share/gdal
  - **PROJ_LIB:** /var/task/share/proj

### Other variable for optimal config
- **GDAL_CACHEMAX:** 512
- **VSI_CACHE:** TRUE
- **VSI_CACHE_SIZE:** 536870912
- **CPL_TMPDIR:** "/tmp"
- **GDAL_HTTP_MERGE_CONSECUTIVE_RANGES:** YES
- **GDAL_HTTP_MULTIPLEX:** YES
- **GDAL_HTTP_VERSION:** 2
- **GDAL_DISABLE_READDIR_ON_OPEN:** "EMPTY_DIR"
- **CPL_VSIL_CURL_ALLOWED_EXTENSIONS:** ".tif"
