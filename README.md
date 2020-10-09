# GDAL based docker-lambda

<p align="center">
  <img src="" style="max-width: 800px;" alt="docker-lambda"></a>
</p>
<p align="center">
  <em>AWS lambda (Amazonlinux) like docker images and lambda layer with GDAL.</em>
</p>
<p align="center">
  <a href="https://github.com/cogeotiff/rio-tiler/actions?query=workflow%3ACI" target="_blank">
      <img src="https://github.com/cogeotiff/rio-tiler/workflows/CI/badge.svg" alt="Test">
  </a>
</p>


# Docker Images

Based on lambci/lambda-base:build (amazonlinux)
  - GDAL 3.1.3 (Oct. 2020)
    - **lambgeo/lambda-base:gdal3.1**
    - **lambgeo/lambda-base:gdal3.1-py3.7**

  - GDAL 2.4.4 (June 2020)
    - **lambgeo/lambda-base:gdal2.4**
    - **lambgeo/lambda-base:gdal2.4-py3.7**

Based on lambci/lambda-base-2:build (amazonlinux2)
  - GDAL 3.1.3 (Oct. 2020)
    - **lambgeo/lambda-base-2:gdal3.1**
    - **lambgeo/lambda-base-2:gdal3.1-py3.8**

  - GDAL 2.4.4 (June 2020)
    - **lambgeo/lambda-base-2:gdal2.4**
    - **lambgeo/lambda-base-2:gdal2.4-py3.8**


# Lambda Layers

### **amazonlinux**

  name | gdal | runtime | version | size (Mb)| unzipped size (Mb)| arn
  ---|   ---|      ---|      ---|       ---|                ---| ---
  gdal24 |   2.4.4|    All  |        2|      15.4|               50.1| arn:aws:lambda:us-east-1:524387336408:layer:gdal24:2
  gdal31 |   3.1.3|    All  |        2|        25|               64.5| arn:aws:lambda:us-east-1:524387336408:layer:gdal31:2


### **amazonlinux:2 (al2)**

  name | gdal | runtime | version | size (Mb)| unzipped size (Mb)| arn
  ---|   ---|      ---|      ---|       ---|                ---| ---
  gdal24-al2 |   2.4.4|    All  |        1|        14|               41.7| arn:aws:lambda:us-east-1:524387336408:layer:gdal24-al2:1
  gdal31-al2 |   3.1.3|    All  |        1|      22.9|               53.6| arn:aws:lambda:us-east-1:524387336408:layer:gdal31-al2:1


[Full list of version and ARN](/arns.json)

### Regions
- ap-northeast-1
- ap-northeast-2
- ap-south-1
- ap-southeast-1
- ap-southeast-2
- ca-central-1
- eu-central-1
- eu-north-1
- eu-west-1
- eu-west-2
- eu-west-3
- sa-east-1
- us-east-1
- us-east-2
- us-west-1
- us-west-2

### content

```
layer.zip
  |
  |___ bin/      # Binaries
  |___ lib/      # Shared libraries (GDAL, PROJ, GEOS...)
  |___ share/    # GDAL/PROJ data directories
```
