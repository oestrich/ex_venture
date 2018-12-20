FROM elixir:1.7.2-alpine as builder

# The nuclear approach:
# RUN apk add --no-cache alpine-sdk
RUN apk add --no-cache \
    gcc \
    git \
    make \
    musl-dev

RUN mix local.rebar --force && \
    mix local.hex --force

WORKDIR /app
ENV MIX_ENV=prod
COPY mix.* /app/
RUN mix deps.get --only prod

RUN mix deps.compile

FROM node:10.9 as frontend

WORKDIR /app
COPY assets/package*.json /app/
COPY --from=builder /app/deps/phoenix /deps/phoenix
COPY --from=builder /app/deps/phoenix_html /deps/phoenix_html

RUN npm install -g yarn && yarn install

COPY assets /app
RUN npm run deploy

FROM builder as releaser
COPY --from=frontend /priv/static /app/priv/static
COPY . /app/
RUN mix phx.digest
ARG APP_VERSION=0.24.0
RUN mix deps.clean mime --build && mix deps.compile mime && \
  mix release --env=prod --no-tar

FROM alpine:3.8
RUN apk add -U bash libssl1.0
WORKDIR /app
COPY --from=releaser /app/_build/prod/rel/ex_venture /app/
COPY config/prod.docker.exs /etc/exventure.config.exs

ENV MIX_ENV=prod

EXPOSE 4000 5555 5556

VOLUME /var/log/ex_venture/

ENTRYPOINT ["bin/ex_venture"]
CMD ["foreground"]
