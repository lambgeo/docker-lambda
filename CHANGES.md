# Changelog

## Unreleased

- Add support for Python 3.12 and 3.13
- Remove support for Python 3.9
- Update deploy.py script compatible runtimes list to currently-available runtimes
- update versions:
  - GDAL: 3.10.2 "Gulf of Mexico"

## 2024-02-02.patch1

- no change (fixing CI)

## 2024-02-02

- update versions (author @philvarner, https://github.com/lambgeo/docker-lambda/pull/76):
  - GDAL: 3.8.3
  - GEOS: 3.12.1
  - PROJ: 9.3.1

- fix `libsqlite3` lib links (author @jasongi, https://github.com/lambgeo/docker-lambda/pull/75)

## 2023-12-20

- update to GDAL 3.8.2

## 2023-11-28

- add `yum update` and `yum clean all` to base image (author @philvarner, https://github.com/lambgeo/docker-lambda/pull/64)
- update to GDAL 3.8.0 (author @philvarner, https://github.com/lambgeo/docker-lambda/pull/65)

## 2023-10-23

- update Python 3.11 base image (author @philvarner, https://github.com/lambgeo/docker-lambda/pull/60)
