docker build --platform=linux/amd64,linux/arm64 applications/main -t ghcr.io/bmc-d4e/h2e-main
docker push ghcr.io/bmc-d4e/h2e-main
