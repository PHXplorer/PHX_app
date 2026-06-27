docker build --platform=linux/amd64,linux/arm64 applications/main -t ghcr.io/phxplorer/phx_app-main
docker push ghcr.io/phxplorer/phx_app-main
