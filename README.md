# GDAL based docker-lambda

<p align="center">
  <img src="" style="max-width: 800px;" alt="docker-lambda"></a>
</p>
<p align="center">
  <em>Create an AWS lambda like docker images and lambda layer with GDAL.</em>
</p>
<p align="center">
  <a href="https://github.com/cogeotiff/rio-tiler/actions?query=workflow%3ACI" target="_blank">
      <img src="https://github.com/cogeotiff/rio-tiler/workflows/CI/badge.svg" alt="Test">
  </a>
</p>


# Docker Images
Based on lambci/lambda-base:build (amazonlinux)
  - GDAL 3.1.3 (Oct. 2020)
    - **lambgeo/lambda:gdal3.1**

  - GDAL 2.4.4 (June 2020)
    - **lambgeo/lambda:gdal2.4**

<!-- Based on lambci/lambda-base-2:build (amazonlinux2)
  - GDAL 3.1.3 (Oct. 2020)
    - **lambgeo/lambda:base2-gdal3.1**

  - GDAL 2.4.4 (June 2020)
    - **lambgeo/lambda:base2-gdal2.4** -->


# Lambda Layers
We are publishing each gdal version as lambda layer on the AWS infrastructure.

**amazonlinux** (version 1)

name | gdal | runtime | version | size (Mb)| unzipped size (Mb)| arn
---|   ---|      ---|      ---|       ---|                ---| ---
gdal31 |   3.1|    All  |        2|        24|               61.7| arn:aws:lambda:us-east-1:524387336408:layer:gdal31:2
gdal24 |   2.4|    All  |        2|      14.8|               48.6| arn:aws:lambda:us-east-1:524387336408:layer:gdal24:2


<!-- **amazonlinux:2** (for latest runtime like python 3.8)-->

[Full list of version and ARN](/arns.json)

#### Regions
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

#### content

```
layer.zip
  |
  |___ bin/      # Binaries
  |___ lib/      # Shared libraries (GDAL, PROJ, GEOS...)
  |___ share/    # GDAL/PROJ data directories
```
