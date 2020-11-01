FROM hexpm/elixir:1.11.1-erlang-23.1.1-ubuntu-groovy-20201022.1 as builder

RUN apt-get install -y git build-essential
RUN mix local.rebar --force && mix local.hex --force
WORKDIR /app
ENV MIX_ENV=prod
COPY mix.* /app/
RUN mix deps.get --only prod
RUN mix deps.compile

FROM node:12.18 as frontend
WORKDIR /app
COPY assets/package.json assets/yarn.lock /app/
COPY --from=builder /app/deps/phoenix /deps/phoenix
COPY --from=builder /app/deps/phoenix_html /deps/phoenix_html
RUN yarn install
COPY assets /app
RUN npm run deploy

FROM builder as releaser
COPY --from=frontend /priv/static /app/priv/static
COPY . /app/
RUN mix phx.digest
RUN mix release

FROM ubuntu:groovy
WORKDIR /app
COPY --from=releaser /app/_build/prod/rel/ex_venture /app/
ENV MIX_ENV=prod
EXPOSE 4000
ENTRYPOINT ["bin/ex_venture"]
CMD ["start"]
