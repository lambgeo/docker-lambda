

import click
import hashlib

from boto3.session import Session as boto3_session

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


def _md5(fname):
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()


@click.command()
@click.argument('gdalversion', type=str)
def main(gdalversion):
    local_name = f"gdal{gdalversion}.zip"
    next_layer_sha = _md5(local_name)

    gdalversion_nodot = gdalversion.replace(".", "")
    layer_name = f"gdal{gdalversion_nodot}"
    description = f"Lambda Layer with GDAL{gdalversion} - {next_layer_sha}"

    session = boto3_session()

    click.echo(f"Deploying {layer_name}", err=True)
    for region in AWS_REGIONS:
        click.echo(f"AWS Region: {region}", err=True)

        client = session.client("lambda", region_name=region)
        res = client.list_layer_versions(LayerName=layer_name)

        layers = res.get("LayerVersions", [])
        click.echo(f"Found {len(layers)} versions.", err=True)

        if layers:
            layer = layers[0]
            layer_sha = layer["Description"].split(" ")[7]
        else:
            layer_sha = ""

        click.echo(f"Current SHA: {layer_sha}", err=True)
        click.echo(f"New SHA: {next_layer_sha}", err=True)
        if layer_sha == next_layer_sha:
            click.echo("No update needed", err=True)
            continue

        click.echo(f"Publishing new version", err=True)
        with open(local_name, 'rb') as zf:
            res = client.publish_layer_version(
                LayerName=layer_name,
                Content={"ZipFile": zf.read()},
                Description=description,
                LicenseInfo="MIT"
            )
            version = res["Version"]

        click.echo(f"Adding permission", err=True)
        client.add_layer_version_permission(
            LayerName=layer_name,
            VersionNumber=version,
            StatementId='make_public',
            Action='lambda:GetLayerVersion',
            Principal='*',
        )


if __name__ == '__main__':
    main()
