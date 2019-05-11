FROM elixir:1.7 as builder

RUN mix local.rebar --force && \
    mix local.hex --force

WORKDIR /app
ENV MIX_ENV=prod
COPY mix.* /app/
RUN mix deps.get --only prod

RUN mix deps.compile

FROM node:10.9 as frontend

WORKDIR /app
COPY assets/package.json assets/yarn.lock /app/
COPY --from=builder /app/deps/phoenix /deps/phoenix
COPY --from=builder /app/deps/phoenix_html /deps/phoenix_html

RUN npm install -g yarn && yarn install

COPY assets /app
RUN npm run deploy

ARG sha
ENV SHA=${sha}

FROM builder as releaser
COPY --from=frontend /priv/static /app/priv/static
COPY . /app/
RUN mix deps.clean mime --build && mix deps.compile mime && \
  mix phx.digest
RUN mix release --env=prod
