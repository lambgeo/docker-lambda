

import os
import click

import docker

from boto3.session import Session as boto3_session
from botocore.client import Config

AWS_REGIONS = [
    "ap-northeast-1",
    "ap-northeast-2",
    "ap-south-1",
    "ap-southeast-1",
    "ap-southeast-2",
    "ca-central-1",
    "eu-central-1",
    "eu-north-1",
    "eu-west-1",
    "eu-west-2",
    "eu-west-3",
    "sa-east-1",
    "us-east-1",
    "us-east-2",
    "us-west-1",
    "us-west-2",
]

CompatibleRuntimes_al1 = [
    "java8",
    "python2.7",
    "python3.6",
    "python3.7",
    "dotnetcore2.1",
    "go1.x",
    "ruby2.5",
    "provided",
]

CompatibleRuntimes_al2 = [
    "nodejs10.x",
    "nodejs12.x",
    "java11",
    "java8.al2",
    "python3.8",
    "dotnetcore3.1",
    "ruby2.7",
    "provided.al2",
]


@click.command()
@click.argument('gdalversion', type=str)
@click.argument('alversion', type=str)
@click.option('--deploy', is_flag=True)
def main(gdalversion, alversion, deploy):
    """Build and Deploy Layers."""
    client = docker.from_env()

    version = "-al2" if alversion == "base-2" else ""
    runtimes = CompatibleRuntimes_al2 if alversion == "base-2" else CompatibleRuntimes_al1

    docker_name = f"lambgeo/lambda-gdal:{gdalversion}{version}"

    click.echo(f"Pulling docker image: {docker_name}...")
    client.images.pull(docker_name)

    click.echo("Create Package")
    client.containers.run(
        image="layer:latest",
        command="/bin/sh /local/scripts/create-layer.sh",
        remove=True,
        volumes={os.path.abspath("./"): {"bind": "/local/", "mode": "rw"}},
        user=0,
    )

    gdalversion_nodot = gdalversion.replace(".", "")
    layer_name = f"gdal{gdalversion_nodot}{version}"
    description = f"Lambda Layer with GDAL{gdalversion} for amazonlinux {alversion}"

    if deploy:
        session = boto3_session()

        # Increase connection timeout to work around timeout errors
        config = Config(connect_timeout=6000, retries={'max_attempts': 5})

        click.echo(f"Deploying {layer_name}", err=True)
        for region in AWS_REGIONS:
            click.echo(f"AWS Region: {region}", err=True)
            client = session.client("lambda", region_name=region, config=config)

            click.echo("Publishing new version", err=True)
            with open("package.zip", 'rb') as zf:
                res = client.publish_layer_version(
                    LayerName=layer_name,
                    Content={"ZipFile": zf.read()},
                    CompatibleRuntimes=[runtimes],
                    Description=description,
                    LicenseInfo="MIT"
                )

            click.echo("Adding permission", err=True)
            client.add_layer_version_permission(
                LayerName=layer_name,
                VersionNumber=res["Version"],
                StatementId='make_public',
                Action='lambda:GetLayerVersion',
                Principal='*',
            )


if __name__ == '__main__':
    main()
