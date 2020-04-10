#!/bin/bash

GDAL_VERSION=$1
PYTHON_VERSION=$2

echo "Building image for GDAL: ${GDAL_VERSION} - Python ${PYTHON_VERSION}"

# GDAL
docker build -f base/gdal${GDAL_VERSION}/Dockerfile -t gdal${GDAL_VERSION} .
docker run --name lambda --volume $(pwd)/:/local -itd gdal${GDAL_VERSION} bash
docker exec -it lambda bash -c 'cd /local/tests/ && sh tests.sh'
docker stop lambda
docker rm lambda

# # PYTHON
# docker build --build-arg PYTHON_VERSION=${PYTHON_VERSION} --build-arg GDAL_VERSION=${GDAL_VERSION} -f base/python/Dockerfile -t lambgeo:gdal${GDAL_VERSION}-py${PYTHON_VERSION} .

# # LAYER
# docker run --name lambda --volume $(pwd)/:/local -itd lambgeo:gdal${GDAL_VERSION} bash
# docker cp ./scripts/create-lambda-layer.sh lambda:/tmp/create-lambda-layer.sh
# docker exec -it lambda bash -c '/tmp/create-lambda-layer.sh'
# docker stop lambda
# docker rm lambda