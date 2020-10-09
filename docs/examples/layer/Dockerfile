FROM lambgeo/lambda-base:gdal3.0-py3.7

# Build a lambda package to be used with the lambda layer.
# Basically we don't want to replicated existant modules found in the layer ($PYTHONPATH)
# So we use the $PYTHONUSERBASE trick to set the output directory
ENV PYTHONUSERBASE=/var/task

# Create a package
COPY handler.py $PYTHONUSERBASE/handler.py
RUN pip install numpy rasterio mercantile --no-binary :all: --user
