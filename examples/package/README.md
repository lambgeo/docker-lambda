# Package


### Create a Lambda package

`make package`

or

```
docker build --tag package:latest .
docker run --name lambda -w /var/task --volume $(shell pwd)/:/local -itd package:latest bash
docker cp lambda:/tmp/package.zip package.zip
docker stop lambda
docker rm lambda
```

### Package architecture

```
package.zip
  |
  |___ lib/      # Shared libraries (GDAL, PROJ, GEOS...)
  |___ share/    # GDAL/PROJ data directories   
  |___ rasterio/
  ....
  |___ handler.py
  |___ other python module
```

### Lambda config
- **GDAL_DATA:** /var/task/share/gdal
- **PROJ_LIB:** /var/task/share/proj
