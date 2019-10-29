#!/bin/bash
set -e

SHA=`git rev-parse HEAD`
DOCKER_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

mkdir -p tmp/

docker build --build-arg sha=${SHA} -f Dockerfile.releaser -t ex_venture:releaser .

docker run -ti --name ex_venture_releaser_${DOCKER_UUID} ex_venture:releaser /bin/true
docker cp ex_venture_releaser_${DOCKER_UUID}:/opt/ex_venture.tar.gz tmp/
docker rm ex_venture_releaser_${DOCKER_UUID}
