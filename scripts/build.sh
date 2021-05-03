#!/bin/bash

GDAL_VERSION=$1
RUNTIME=$2

echo "Building image for Amazonlinux2 | GDAL: ${GDAL_VERSION} | Runtime: ${RUNTIME}"

# Base Image
docker buildx build \
    -f dockerfiles/common/Dockerfile \
    -t lambda-gdal:common \
    .

docker buildx build \
    -f dockerfiles/gdal${GDAL_VERSION}/Dockerfile \
    -t lambgeo/lambda-gdal:${GDAL_VERSION}-al2 \
    .

docker buildx build \
    --build-arg GDAL_VERSION=${GDAL_VERSION} \
    -f dockerfiles/runtimes/${RUNTIME} \
    -t lambgeo/lambda-gdal:${GDAL_VERSION}-${RUNTIME} .
