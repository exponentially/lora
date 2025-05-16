# Build stage
FROM elixir:1.17-slim AS builder

# Install build dependencies
RUN apt-get update && \
    apt-get install -y build-essential git npm nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV MIX_ENV=prod \
    LANG=C.UTF-8

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Create and set working directory
WORKDIR /app

# Copy over the mix.exs and mix.lock files to load dependencies
COPY mix.exs mix.lock ./
COPY apps/lora/mix.exs ./apps/lora/
COPY apps/lora_web/mix.exs ./apps/lora_web/
COPY config config

# Install dependencies
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy over the remaining application code
COPY . .

# Build and digest assets
RUN cd apps/lora_web/assets && \
    npm ci --progress=false --no-audit --loglevel=error && \
    npm run deploy && \
    cd ../../.. && \
    mix assets.deploy

# Compile and build release
RUN mix do compile, release

# Release stage
FROM debian:bullseye-slim AS app

RUN apt-get update && \
    apt-get install -y openssl libncurses5 locales && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Create a non-root user and group
RUN groupadd --gid 1000 lora && \
    useradd --uid 1000 --gid lora --shell /bin/bash --create-home lora

WORKDIR /app
COPY --from=builder /app/_build/prod/rel/lora ./

# Set ownership to non-root user
RUN chown -R lora:lora /app
USER lora

EXPOSE 4000

ENV RELEASE_NODE=lora@127.0.0.1
ENV PHX_SERVER=true
ENV PHX_HOST=localhost

CMD ["bin/lora", "start"]
