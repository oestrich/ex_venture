#!/bin/bash
set -e

rm -rf tmp/build
mkdir -p tmp/build
git archive --format=tar kalevala | tar x -C tmp/build/
cd tmp/build

docker build -f Dockerfile.releaser -t ex_venture:releaser .

DOCKER_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
docker run -ti --name ex_venture_releaser_${DOCKER_UUID} ex_venture:releaser /bin/true
docker cp ex_venture_releaser_${DOCKER_UUID}:/opt/ex_venture.tar.gz ../
docker rm ex_venture_releaser_${DOCKER_UUID}
