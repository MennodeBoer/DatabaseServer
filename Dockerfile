FROM fpco/stack-build:lts-15 AS builder
RUN mkdir /opt/build
COPY . /opt/build
RUN cd /opt/build && stack install --system-ghc

FROM ubuntu:18.04
RUN mkdir -p /opt/haskelldatabase
ARG BINARY_PATH
WORKDIR /opt/haskelldatabase
RUN apt-get update && apt-get install -y \
  ca-certificates \
  libgmp-dev
COPY --from=builder /root/.local/bin .

EXPOSE 8081

CMD ./HaskellDatabase-exe