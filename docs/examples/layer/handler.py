"""Test."""

import rasterio
import mercantile
import numpy


def test(event, context):
    print(rasterio.__version__)
    print(numpy.__version__)
    print(mercantile.__version__)
