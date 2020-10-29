FROM elixir:1.9-alpine@sha256:1e46357faf35d15d803fea40f430a328a749f4b842f941edfd06896c912992d1 as builder

# The nuclear approach:
# RUN apk add --no-cache alpine-sdk
RUN apk add --no-cache gcc git make musl-dev
RUN mix local.rebar --force && mix local.hex --force
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
RUN mix release

FROM alpine:3.10
RUN apk add -U bash openssl
WORKDIR /app
COPY --from=releaser /app/_build/prod/rel/ex_venture /app/
ENV MIX_ENV=prod
EXPOSE 4000
ENTRYPOINT ["bin/ex_venture"]
CMD ["start"]
