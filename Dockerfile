FROM hexpm/elixir:1.11.1-erlang-23.0.2-alpine-3.12.1 as builder

RUN apk add --no-cache gcc git make musl-dev
RUN mix local.rebar --force && mix local.hex --force
WORKDIR /app
ENV MIX_ENV=prod
COPY mix.* /app/
RUN mix deps.get --only prod
RUN mix deps.compile

FROM node:12.18 as frontend
WORKDIR /app
COPY assets/package.json assets/yarn.lock /app/
RUN yarn install
COPY assets /app
RUN yarn run deploy:js && \
  yarn run deploy:css && \
  yarn run deploy:static

FROM builder as releaser
COPY --from=frontend /priv/static /app/priv/static
COPY . /app/
RUN mix phx.digest
RUN mix release

FROM alpine:3.12
RUN apk add --no-cache bash openssl
WORKDIR /app
COPY --from=releaser /app/_build/prod/rel/ex_venture /app/
COPY --from=releaser /app/data /app/data/
ENV MIX_ENV=prod
EXPOSE 4000
ENTRYPOINT ["bin/ex_venture"]
CMD ["start"]
