
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

Based on `public.ecr.aws/lambda/provided:al2` (AmazonLinux 2)
  - GDAL 3.5.0
    - **ghcr.io/lambgeo/lambda-gdal:3.5** (May 2022)


Runtimes images:
  - Python (based on `public.ecr.aws/lambda/python:{version}`)
    - **ghcr.io/lambgeo/lambda-gdal:3.5-python3.9**
    - **ghcr.io/lambgeo/lambda-gdal:3.5-python3.8**

# Creating Lambda packages

## Using

### 1. Create Dockerfile

```Dockerfile
FROM ghcr.io/lambgeo/lambda-gdal:3.5 as gdal

# We use the official AWS Lambda image
FROM public.ecr.aws/lambda/{RUNTIME: python|node|go...}:{RUNTIME version}

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

# Copy local files or install modules

# Create package.zip (we zip the whole content of $PACKAGE_PREFIX because we moved the gdal libs over)
RUN cd $PACKAGE_PREFIX && zip -r9q /tmp/package.zip *
```

If you are working with **python3.8|3.9**, you can use lambgeo pre-build docker images:

```Dockerfile
FROM ghcr.io/lambgeo/lambda-gdal:3.5-python3.9

ENV PACKAGE_PREFIX=/var/task

# Copy any local files to the package
COPY handler.py ${PACKAGE_PREFIX}/handler.py

# Install some requirements to `/var/task` (using `-t` otpion)
RUN pip install numpy rasterio mercantile --no-binary :all: -t ${PACKAGE_PREFIX}/

# Reduce size of the C libs
RUN cd $PREFIX && find lib -name \*.so\* -exec strip {} \;

# Create package.zip
# Archive python code (installed in $PACKAGE_PREFIX/)
RUN cd $PACKAGE_PREFIX && zip -r9q /tmp/package.zip *

# Archive GDAL libs (in $PREFIX/lib $PREFIX/bin $PREFIX/share)
RUN cd $PREFIX && zip -r9q --symlinks /tmp/package.zip lib/*.so* share
RUN cd $PREFIX && zip -r9q --symlinks /tmp/package.zip bin/gdal* bin/ogr* bin/geos* bin/nearblack
```

### 2. Build and create package.zip

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

### 3. Deploy and Set Environment variables

Libraries might need to be aware of GDAL/PROJ C libraries so you **HAVE TO** to set up those 2 envs:
- **GDAL_DATA:** /var/task/share/gdal
- **PROJ_LIB:** /var/task/share/proj

Other variables:

Starting with gdal3.1 (PROJ 7.1), you can set `PROJ_NETWORK=ON` to use remote grids: https://proj.org/usage/network.html

---

# AWS Lambda Layers

gdal | amazonlinux version| size (Mb)| unzipped size (Mb)| arn
  ---|                 ---|       ---|                ---| ---
3.5  |                   1|         0|                   0| arn:aws:lambda:{REGION}:524387336408:layer:gdal35:{VERSION}

### archived

gdal | amazonlinux version| size (Mb)| unzipped size (Mb)| arn
  ---|                 ---|       ---|                ---| ---
3.3  |                   2|      27.7|               67.3| arn:aws:lambda:{REGION}:524387336408:layer:gdal33-al2:{VERSION}
3.2  |                   2|      26.7|               64.6| arn:aws:lambda:{REGION}:524387336408:layer:gdal32-al2:{VERSION}
3.1  |                   2|      25.8|                 61| arn:aws:lambda:{REGION}:524387336408:layer:gdal31-al2:{VERSION}
2.4  |                   2|      19.5|               63.6| arn:aws:lambda:{REGION}:524387336408:layer:gdal24-al2:{VERSION}

see [/layer.json](/layer.json) for the list of arns

```bash
cat layer.json| jq '.[] | select(.region == "us-west-2")'
{
  "region": "us-west-2",
  "layers": [
    {
      "name": "gdal35",
      "arn": "arn:aws:lambda:us-west-2:524387336408:layer:gdal35:1",
      "version": 1
    }
  ]
}
```
**Layer content:**

```
layer.zip
  |
  |___ bin/      # Binaries
  |___ lib/      # Shared libraries (GDAL, PROJ, GEOS...)
  |___ share/    # GDAL/PROJ data directories
```

At Lambda runtime, the layer content will be unzipped in the `/opt` directory. To be able to use the C libraries you **HAVE TO** make sure to set 2 important environment variables:

- **GDAL_DATA:** /opt/share/gdal
- **PROJ_LIB:** /opt/share/proj

## How To Use

There are 2 ways to use the layers:

### 1. Simple (No dependencies)

If you don't need to add more runtime dependencies, you can just create a lambda package (zip file) with your lambda handler.

```bash
zip -r9q package.zip handler.py
```

**Content:**

```
package.zip
  |___ handler.py   # aws lambda python handler
```

**AWS Lambda Config:**
- arn: `arn:aws:lambda:us-east-1:524387336408:layer:gdal35:1` (example)
- env:
  - **GDAL_DATA:** /opt/share/gdal
  - **PROJ_LIB:** /opt/share/proj
- lambda handler: `handler.handler`


### 2. Advanced (need other dependencies)

If your lambda handler needs more dependencies you'll have to use the exact same environment create the package.

#### Create a Dockerfile

```dockerfile
FROM ghcr.io/lambgeo/lambda-gdal:3.5 as gdal

FROM public.ecr.aws/lambda/python:3.9

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

ENV PACKAGE_PREFIX=/var/task

# Copy local files
COPY handler.py ${PACKAGE_PREFIX}/handler.py

# install package
RUN ...

# Create package.zip
RUN cd $PACKAGE_PREFIX && zip -r9q /tmp/package.zip *
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

**AWS Lambda Config:**
- arn: `arn:aws:lambda:us-east-1:524387336408:layer:gdal35:1` (example)
- env:
  - **GDAL_DATA:** /opt/share/gdal
  - **PROJ_LIB:** /opt/share/proj
- lambda handler: `handler.handler`
