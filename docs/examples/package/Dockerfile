FROM lambgeo/lambda-base:gdal3.0-py3.7

ENV PACKAGE_PREFIX=/var/task

################################################################################
#                            CREATE PACKAGE                                    #
################################################################################
COPY handler.py ${PACKAGE_PREFIX}/handler.py
RUN pip install numpy rasterio mercantile --no-binary :all: -t ${PACKAGE_PREFIX}/

################################################################################
#                            REDUCE PACKAGE SIZE                               #
################################################################################
RUN rm -rdf $PACKAGE_PREFIX/boto3/ \
  && rm -rdf $PACKAGE_PREFIX/botocore/ \
  && rm -rdf $PACKAGE_PREFIX/docutils/ \
  && rm -rdf $PACKAGE_PREFIX/dateutil/ \
  && rm -rdf $PACKAGE_PREFIX/jmespath/ \
  && rm -rdf $PACKAGE_PREFIX/s3transfer/ \
  && rm -rdf $PACKAGE_PREFIX/numpy/doc/

RUN rm -rdf $PREFIX/share/doc \
  && rm -rdf $PREFIX/share/man \
  && rm -rdf $PREFIX/share/hdf*

# Strip shared libraries
RUN cd $PREFIX && find lib -name \*.so\* -exec strip {} \;

################################################################################
#                              CREATE ARCHIVE                                  #
################################################################################
RUN cd $PACKAGE_PREFIX && zip -r9q /tmp/package.zip *
RUN cd $PREFIX && zip -r9q --symlinks /tmp/package.zip lib/*.so* share
RUN cd $PREFIX && zip -r9q --symlinks /tmp/package.zip bin/gdal* bin/ogr* bin/geos* bin/nearblack
