#!/bin/bash
echo "----------------------------------"
echo "Creating lambda package from layer"
echo "----------------------------------"
# We move all the package to the root directory
version=$(python -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")')
PYPATH=${PYTHONUSERBASE}/lib/python${version}/site-packages/
mv ${PYPATH}/* ${PYTHONUSERBASE}/
rm -rf ${PYTHONUSERBASE}/lib

echo "Create archive"
cd $PYTHONUSERBASE && zip -r9q /tmp/layer.zip *

cp /tmp/layer.zip /local/layer.zip
