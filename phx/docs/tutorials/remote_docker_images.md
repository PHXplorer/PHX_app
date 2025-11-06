# Remote docker images

This project is all about docker images. Application images (main app, validator app, potentially other apps in the future) are already pre-built and stored in **private** Github Container Registry (https://ghcr.io).

## Obtain Github token

By default, when running `start` script or opening project in a devcontainer, main application image will be pulled. To make sure that you can successfully pull the image, your docker needs to be authenticated with a special Github Token.

Here is the [official instruction](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic) on how to create the token.

And here is an executive summary:

1. create a new Github Personal Access token (**please choose classic version**)
2. when choosing scopes, choose **write:packages** and **delete:packages**
3. copy the token and save it somewhere - we will need to use it later and you can accidentally lose it when copying commands from this tutorial.

> [!NOTE]  
> If for any reasons you can't authenticate with the private ghcr.io, you can still run the app by building images locally.
> Also, to force local image build (for whatever reasons) set `DOCKER_BUILD=true` in _.env_ file.
> Local docker build on an M1 pro laptop takes about 15 minutes.

## Authenticate Docker engine Github Container Registry

Once you have the token, use it to authenticate with Docker by running the following command:

Windows (you must use Powershell):

```powershell
Write-Output <GITHUB TOKEN> | docker login ghcr.io -u <GITHUB USERNAME> --password-stdin
```

Linux (you can use any terminal emulator)

```shell
echo <GITHUB TOKEN> | docker login ghcr.io -u <GITHUB USERNAME> --password-stdin
```
