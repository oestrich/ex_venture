#!/bin/bash
set -e

rm -r priv/static/*
cd assets && node node_modules/brunch/bin/brunch build && cd ..
MIX_ENV=prod mix phx.digest
MIX_ENV=prod mix release
rm -r priv/static/*
