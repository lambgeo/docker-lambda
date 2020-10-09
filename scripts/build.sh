#!/bin/bash

IMAGE_VERSION=$1
GDAL_VERSION=$2
RUNTIME=$3

echo "Building image for Amazonlinux ${IMAGE_VERSION} | GDAL: ${GDAL_VERSION} | Runtime: ${RUNTIME}"

# Base Image
docker build -f common/${IMAGE_VERSION}/Dockerfile -t ${IMAGE_VERSION}:build .

docker build \
    --build-arg IMAGE_VERSION=${IMAGE_VERSION} \
    -f gdal${GDAL_VERSION}/Dockerfile \
    -t lambgeo/lambda-${IMAGE_VERSION}:gdal${GDAL_VERSION} .

docker build \
    --build-arg GDAL_VERSION=${GDAL_VERSION} \
    -f runtimes/${RUNTIME} \
    -t lambgeo/lambda-${IMAGE_VERSION}:gdal${GDAL_VERSION}-${RUNTIME} .
