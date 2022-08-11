"""Deploy aws lambda layer."""

import click

from boto3.session import Session as boto3_session
from botocore.client import Config

AWS_REGIONS = [
    # "ap-northeast-1",
    # "ap-northeast-2",
    # "ap-south-1",
    # "ap-southeast-1",
    # "ap-southeast-2",
    # "ca-central-1",
    # "eu-central-1",
    # "eu-north-1",
    # "eu-west-1",
    # "eu-west-2",
    # "eu-west-3",
    # "sa-east-1",
    "us-east-1",
    # "us-east-2",
    # "us-west-1",
    # "us-west-2",
]


CompatibleRuntimes_al2 = [
    # "nodejs12.x",
    # "nodejs14.x",
    # "nodejs16.x",
    # "java11",
    # "java8.al2",
    # "python3.8",
    "python3.9",
    # "dotnet6",
    # "dotnetcore3.1",
    # "ruby2.7",
    # "provided.al2",
]


@click.command()
@click.argument('gdalversion', type=str)
@click.option('--deploy', is_flag=True)
def main(gdalversion, deploy):
    """Build and Deploy Layers."""
    gdalversion_nodot = gdalversion.replace(".", "")
    layer_name = f"gdal{gdalversion_nodot}"
    description = f"Lambda Layer with GDAL{gdalversion} for amazonlinux2"

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
                    CompatibleRuntimes=CompatibleRuntimes_al2,
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
