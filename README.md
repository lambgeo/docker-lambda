# GDAL based docker-lambda

[![CircleCI](https://circleci.com/gh/lambgeo/docker-lambda.svg?style=svg)](https://circleci.com/gh/lambgeo/docker-lambda)

Create an **AWS lambda** like docker images and lambda layer with GDAL.


## Images
### GDAL - Based on lambci/lambda-base:build
  - 3.1.0 (April. 2020) - **lambgeo/lambda:gdal3.1** - Pre-release
  - 3.0.4 (April. 2020) - **lambgeo/lambda:gdal3.0** 
  - 2.4.4 (April. 2020) - **lambgeo/lambda:gdal2.4**

## Lambda Layers

We are publishing each gdal version as lambda layer on the AWS infrastructure. 
Each layer are available for all runtimes.

**gdal${version}**

arn: **arn:aws:lambda:{REGION}:524387336408:layer:gdal${version}**

[Full list of version and ARN](https://github.com/RemotePixel/amazonlinux/blob/master/arns.json)

#### versions:

gdal | version | size (Mb)| unzipped size (Mb)
  ---|      ---|       ---|                ---
3.1  |        1|      46.4|              136.9
3.0  |        1|      46.4|              136.9
2.4  |        1|      37.7|              126.2

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

### Python - Based on lambci/lambda:build-python*

Those images are here to help for the creation of lambda package or lambda layer.

- **3.1**
  - **lambgeo/lambda:gdal3.1-py3.7**
  - **lambgeo/lambda:gdal3.1-py3.8**

- **3.0**
  - **lambgeo/lambda:gdal3.0-py3.7**
  - **lambgeo/lambda:gdal3.0-py3.8**

- **2.4**
  - **lambgeo/lambda:gdal2.4-py3.7**
  - **lambgeo/lambda:gdal2.4-py3.8**

Content: GDAL Libs and python with numpy and cython

Checkout [/base/python/Dockerfile](/base/python/Dockerfile) to see how to create other runtime supported images.

# Create a Python Lambda package

You can use the docker container to either build a full package (you provide all the libraries)
or adapt for the use of AWS Lambda layer.

## 1. Create full package (see [/examples/package](/examples/package))
This is like we used to do before (with remotepixel/amazonlinux-gdal images)

- dockerfile
```Dockerfile
FROM lambgeo/lambda:gdal3.0-py3.7

ENV PACKAGE_PREFIX=/var/task

COPY handler.py ${PACKAGE_PREFIX}/handler.py
RUN pip install numpy rasterio mercantile --no-binary :all: -t ${PACKAGE_PREFIX}/
```

- package.sh
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

## 2. Use Lambda Layer (see [/examples/layer](/examples/layer))

- dockerfile

Here we install rasterio and we add our handler method. 
The final package structure should be 

```
package/
  |___ handler.py  
  |___ rasterio/
```

```Dockerfile
FROM lambgeo/lambda:gdal3.0-py3.7

# Basically we don't want to replicated existant modules found in the layer ($PYTHONPATH)
# So we use the $PYTHONUSERBASE trick to set the output directory
ENV PYTHONUSERBASE=/var/task

# Create a package
COPY handler.py $PYTHONUSERBASE/handler.py
RUN pip install --user rasterio --no-binary rasterio 
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

# AWS Lambda Layer architecture

The AWS Layer created within this repository have this architecture:

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

# AWS Lambda config
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
