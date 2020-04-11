# Package


### Create a Lambda package

`make package`

or

```
docker build --tag package:latest .
docker run --name lambda -w /var/task --volume $(shell pwd)/:/local -itd package:latest bash
docker exec -it lambda bash '/local/layer.sh'
docker stop lambda
docker rm lambda
```

### Package architecture

```
package.zip
  ....
  |___ handler.py
  |___ other python module
```

### Lambda config
- **GDAL_DATA:** /opt/share/gdal
- **PROJ_LIB:** /opt/share/proj
