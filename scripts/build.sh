#!/bin/bash

GDAL_VERSION=$1
GDAL_VERSION_TAG=${GDAL_VERSION%.*}
RUNTIME=$2
RUNTIME_VERSION=$3

echo "Building image for AWS Lambda | GDAL: ${GDAL_VERSION} | Runtime: ${RUNTIME}:${RUNTIME_VERSION}"

docker buildx build \
    --platform=linux/amd64 \
    --build-arg GDAL_VERSION=${GDAL_VERSION} \
    -f dockerfiles/Dockerfile \
    -t ghcr.io/lambgeo/lambda-gdal:${GDAL_VERSION_TAG} .

docker buildx build \
    --platform=linux/amd64 \
    --build-arg GDAL_VERSION_TAG=${GDAL_VERSION_TAG} \
    --build-arg RUNTIME_VERSION=${RUNTIME_VERSION} \
    -f dockerfiles/runtimes/${RUNTIME} \
    -t ghcr.io/lambgeo/lambda-gdal:${GDAL_VERSION_TAG}-${RUNTIME}${RUNTIME_VERSION} .
