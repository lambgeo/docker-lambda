#!/bin/bash

IMAGE_VERSION=$1
GDAL_VERSION=$2
RUNTIME=$3

LAMBDA_VERSION=$(echo $IMAGE_VERSION | sed -E 's/base(-)?//g')

echo "Building image for Amazonlinux ${IMAGE_VERSION} | GDAL: ${GDAL_VERSION} | Runtime: ${RUNTIME}"

# Base Image
docker build -f dockerfiles/common/${IMAGE_VERSION}/Dockerfile -t ${IMAGE_VERSION}:build .

docker build \
    --build-arg IMAGE_VERSION=${IMAGE_VERSION} \
    -f dockerfiles/gdal${GDAL_VERSION}/Dockerfile \
    -t lambgeo/lambda${LAMBDA_VERSION}-gdal:${GDAL_VERSION} .

docker build \
    --build-arg GDAL_VERSION=${GDAL_VERSION} \
    -f dockerfiles/runtimes/${RUNTIME} \
    -t lambgeo/lambda-gdal:${GDAL_VERSION}-${RUNTIME} .
