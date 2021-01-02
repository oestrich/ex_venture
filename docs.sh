#/bin/bash

set -ex

export DOCKER_BUILDKIT=1
sha=$(git rev-parse HEAD)

docker build -f Dockerfile.site -t oestrich/exventure.org:${sha} .
docker push oestrich/exventure.org:${sha}

cd helm
helm upgrade exventure static/ --namespace static-sites -f values.yaml --set image.tag=${sha}
