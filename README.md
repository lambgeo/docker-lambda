
# GDAL based docker image made for AWS Lambda

<p align="center">
  <img src="https://user-images.githubusercontent.com/10407788/95621320-7b226080-0a3f-11eb-8194-4b55a5555836.png" style="max-width: 800px;" alt="docker-lambda"></a>
</p>
<p align="center">
  <em>AWS lambda (Amazonlinux) like docker images with GDAL.</em>
</p>
<p align="center">
  <a href="https://github.com/lambgeo/docker-lambda/actions?query=workflow%3ACI" target="_blank">
      <img src="https://github.com/lambgeo/docker-lambda/workflows/CI/badge.svg" alt="Test">
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
    - **lambgeo/lambda-gdal:3.2-al2**

  - GDAL 3.1.4 (Oct. 2020)
    - **lambgeo/lambda-gdal:3.1-al2**

  - GDAL 2.4.4 (June 2020)
    - **lambgeo/lambda-gdal:2.4-al2**

  - For python 3.8
    - **lambgeo/lambda-gdal:3.2-python3.8**
    - **lambgeo/lambda-gdal:3.1-python3.8**
    - **lambgeo/lambda-gdal:2.4-python3.8**

## Creating Lambda packages

1. Dockerfile

```Dockerfile
FROM lambgeo/lambda-gdal:3.2-al2 as gdal

# We use lambci docker image for the runtime
FROM lambci/lambda:build-python3.8

ENV PACKAGE_PREFIX=/var/task

# Bring C libs from lambgeo/lambda-gdal image
COPY --from=gdal /opt/lib/ ${PACKAGE_PREFIX}/lib/
COPY --from=gdal /opt/include/ ${PACKAGE_PREFIX}/include/
COPY --from=gdal /opt/share/ ${PACKAGE_PREFIX}/share/
COPY --from=gdal /opt/bin/ ${PACKAGE_PREFIX}/bin/
ENV \
  GDAL_DATA=${PACKAGE_PREFIX}/share/gdal \
  PROJ_LIB=${PACKAGE_PREFIX}/share/proj \
  GDAL_CONFIG=${PACKAGE_PREFIX}/bin/gdal-config \
  GEOS_CONFIG=${PACKAGE_PREFIX}/bin/geos-config \
  PATH=${PACKAGE_PREFIX}/bin:$PATH

# Set some useful env
ENV \
  LANG=en_US.UTF-8 \
  LC_ALL=en_US.UTF-8 \
  CFLAGS="--std=c99"

# Copy any local files to the package
COPY handler.py ${PACKAGE_PREFIX}/handler.py

# This is needed for rasterio
RUN pip3 install cython numpy --no-binary numpy

# Install some requirements to `/var/task` (using `-t` otpion)
RUN pip install numpy rasterio mercantile --no-binary :all: -t ${PACKAGE_PREFIX}/

# Reduce size of the C libs
RUN cd $PACKAGE_PREFIX && find lib -name \*.so\* -exec strip {} \;

# Create package.zip
RUN cd $PACKAGE_PREFIX && zip -r9q /tmp/package.zip *
```

Or if you are working with python, you can use lambgeo pre-build docker images:

```Dockerfile
FROM lambgeo/lambda-gdal:3.2-python3.8

# Copy any local files to the package
COPY handler.py ${PACKAGE_PREFIX}/handler.py

# Install some requirements to `/var/task` (using `-t` otpion)
RUN pip install numpy rasterio mercantile --no-binary :all: -t ${PACKAGE_PREFIX}/

# Reduce size of the C libs
RUN cd $PREFIX && find lib -name \*.so\* -exec strip {} \;

# Create package.zip
RUN cd $PACKAGE_PREFIX && zip -r9q /tmp/package.zip *
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
  |___ bin/      # GDAL binaries
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

---

## AWS Lambda Layers

gdal | amazonlinux version| size (Mb)| unzipped size (Mb)| arn
  ---|                 ---|       ---|                ---| ---
3.2  |                   1|      27.9|               64.8| arn:aws:lambda:{REGION}:524387336408:layer:gdal32:{VERSION}
3.1  |                   1|      27.3|               68.7| arn:aws:lambda:{REGION}:524387336408:layer:gdal31:{VERSION}
2.4  |                   1|        21|               71.4| arn:aws:lambda:{REGION}:524387336408:layer:gdal24:{VERSION}
  ---|                    |       ---|                ---| ---
3.2  |                   2|      26.4|               56.1| arn:aws:lambda:{REGION}:524387336408:layer:gdal32-al2:{VERSION}
3.1  |                   2|      25.8|                 61| arn:aws:lambda:{REGION}:524387336408:layer:gdal31-al2:{VERSION}
2.4  |                   2|      19.5|               63.6| arn:aws:lambda:{REGION}:524387336408:layer:gdal24-al2:{VERSION}

see [/layer.json](/layer.json) for the list of arns

**Layer content:**

```
layer.zip
  |
  |___ bin/      # Binaries
  |___ lib/      # Shared libraries (GDAL, PROJ, GEOS...)
  |___ share/    # GDAL/PROJ data directories
```

The layer content will be unzip in `/opt` directory in AWS Lambda. For the python libs to be able to use the C libraries you have to make sure to set 2 important environment variables:

- **GDAL_DATA:** /opt/share/gdal
- **PROJ_LIB:** /opt/share/proj

### How To

There are 2 ways to use the layers:

#### 1. Simple (No dependencies)

If you don't need to add more runtime dependencies, you can just create a lambda package (zip file) with you lambda handler.

```bash
zip -r9q package.zip handler.py
```

**Content:**

```
package.zip
  |___ handler.py   # aws lambda python handler
```

**AWS Lambda Config:**
- arn: `arn:aws:lambda:us-east-1:524387336408:layer:gdal32:1` (example)
- env:
  - **GDAL_DATA:** /opt/share/gdal
  - **PROJ_LIB:** /opt/share/proj
- lambda handler: `handler.handler`


#### 2. Advanced (need other python dependencies)

If your lambda handler needs more dependencies you'll have to use the exact same environment. To ease this you can find the docker images for each lambda on docker hub.

- Create a docker file

```dockerfile
FROM lambgeo/lambda-gdal:3.2-al2

# We use lambci docker image for the runtime
FROM lambci/lambda:build-python3.8

# Bring C libs from lambgeo/lambda-gdal image
COPY --from=gdal /opt/lib/ /opt/lib/
COPY --from=gdal /opt/include/ /opt/include/
COPY --from=gdal /opt/share/ /opt/share/
COPY --from=gdal /opt/bin/ /opt/bin/
ENV \
  GDAL_DATA=/opt/share/gdal \
  PROJ_LIB=/opt/share/proj \
  GDAL_CONFIG=/opt/bin/gdal-config \
  GEOS_CONFIG=/opt/bin/geos-config \
  PATH=/opt/bin:$PATH

# Set some useful env
ENV \
  LANG=en_US.UTF-8 \
  LC_ALL=en_US.UTF-8 \
  CFLAGS="--std=c99"

ENV PYTHONUSERBASE=/var/task

# Install dependencies
COPY handler.py $PYTHONUSERBASE/handler.py

# Here we use the `--user` option to make sure to not replicate modules.
RUN pip install rio-tiler --user

# Move some files around
RUN mv ${PYTHONUSERBASE}/lib/python3.8/site-packages/* ${PYTHONUSERBASE}/
RUN rm -rf ${PYTHONUSERBASE}/lib

echo "Create archive"
RUN cd $PYTHONUSERBASE && zip -r9q /tmp/package.zip *
```

- create package
```bash
docker build --tag package:latest .
docker run --name lambda -w /var/task -itd package:latest bash
docker cp lambda:/tmp/package.zip package.zip
docker stop lambda
docker rm lambda
```

**Content:**

```
package.zip
  |___ handler.py   # aws lambda python handler
  |___ module1/     # dependencies
  |___ module2/
  |___ module3/
  |___ ...
```


### Refactor

We recently refactored the repo, to see old documentation please refer to https://github.com/lambgeo/docker-lambda/tree/ef66339724b1b7e1a375df912dfd58a9c59ac109
