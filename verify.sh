set -e

mix format --check-formatted
mix compile --force --warnings-as-errors
mix credo
mix test

cd assets

yarn lint:ci
yarn test
