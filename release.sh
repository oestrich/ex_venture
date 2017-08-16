#!/bin/bash
set -e

cd assets && node node_modules/brunch/bin/brunch build && cd ..
MIX_ENV=prod mix phx.digest
MIX_ENV=prod mix release
