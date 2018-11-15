#!/bin/bash
set -e

rm -rf priv/static/*
cd assets && npm run deploy && cd ..
MIX_ENV=prod mix phx.digest
MIX_ENV=prod mix release
rm -r priv/static/*
cd assets && npm run build && cd ..
