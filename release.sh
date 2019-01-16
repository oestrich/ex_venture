#!/bin/bash
set -e

SHA=`git rev-parse HEAD`
DOCKER_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

mkdir -p tmp/

echo -e "travis_fold:start:docker-build\r"
docker build --build-arg sha=${SHA} -f Dockerfile.releaser -t ex_venture:releaser .
echo -e "\ntravis_fold:end:docker-build\r"

docker run -ti --name ex_venture_releaser_${DOCKER_UUID} ex_venture:releaser /bin/true
docker cp ex_venture_releaser_${DOCKER_UUID}:/app/_build/prod/rel/ex_venture/releases/0.29.0/ex_venture.tar.gz tmp/
docker rm ex_venture_releaser_${DOCKER_UUID}
