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

CompatibleRuntimes_amx1 = [
    "java8",
    "python2.7",
    "python3.6",
    "python3.7",
    "dotnetcore2.1",
    "go1.x",
    "ruby2.5",
    "provided",
]

CompatibleRuntimes_amx2 = [
    "nodejs10.x",
    "nodejs12.x",
    "java11",
    "java8.al2",
    "python3.8",
    "dotnetcore3.1",
    "ruby2.7",
    "provided.al2",
]


def _md5(fname):
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()


@click.command()
@click.argument("package", type=str)
@click.argument("gdalversion", type=str)
@click.argument("image_version", type=str)
def main(package, gdalversion, image_version):
    """Deploy Lambda Package."""
    next_layer_sha = _md5(package)

    if image_version == "base":
        suffix = ""
        supported = CompatibleRuntimes_amx1
    elif image_version == "base-2":
        suffix = "-al2"
        supported = CompatibleRuntimes_amx2
    else:
        raise Exception("Invalid Base")

    gdalversion_nodot = gdalversion.replace(".", "")
    layer_name = f"gdal{gdalversion_nodot}{suffix}"
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

        click.echo("Publishing new version", err=True)
        with open(package, "rb") as zf:
            res = client.publish_layer_version(
                LayerName=layer_name,
                Content={"ZipFile": zf.read()},
                Description=description,
                LicenseInfo="MIT",
                CompatibleRuntimes=supported,
            )
            version = res["Version"]

        click.echo("Adding permission", err=True)
        client.add_layer_version_permission(
            LayerName=layer_name,
            VersionNumber=version,
            StatementId="make_public",
            Action="lambda:GetLayerVersion",
            Principal="*",
        )


if __name__ == "__main__":
    main()
