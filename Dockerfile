FROM golang:1.16-buster AS build-setup

RUN apt-get update
RUN apt-get -y install cmake zip sudo git

RUN mkdir /dps
WORKDIR /dps
RUN git clone https://github.com/m4ksio/flow-dps /dps

RUN  --mount=type=cache,target=/go/pkg/mod \
     --mount=type=cache,target=/root/.cache/go-build  \
     git checkout master &&  \
     go build -o /restore-index-snapshot -ldflags "-extldflags -static" ./cmd/restore-index-snapshot && \
     chmod a+x /restore-index-snapshot

# TODO once merged dispatcher should be on the same branch
RUN  --mount=type=cache,target=/go/pkg/mod \
     --mount=type=cache,target=/root/.cache/go-build  \
     git checkout m4ksio/rosetta-dispatcher-server &&  \
     go build -o /rosetta-dispatcher-server -ldflags "-extldflags -static" ./cmd/rosetta-dispatcher-server && \
     chmod a+x /rosetta-dispatcher-server

RUN mkdir /docker
RUN git clone https://github.com/dapperlabs/dps-rosetta-docker /docker

## Build Relic first to maximize caching
FROM build-setup AS build-relic

RUN mkdir /build
WORKDIR /build

# Copy over the crypto package
# COPY crypto ./crypto

# Build Relic (this places build artifacts in /build/relic/build)
RUN cd ./crypto/ && go generate

FROM build-setup AS build-mainnet3

WORKDIR /dps
RUN  --mount=type=cache,target=/go/pkg/mod \
     --mount=type=cache,target=/root/.cache/go-build  \
     git checkout m4ksio/mainnet-3-proxy &&  \
     go build -o /app -ldflags "-extldflags -static" ./cmd/flow-rosetta-server && \
     chmod a+x /app


FROM build-setup AS build-mainnet4

WORKDIR /dps
RUN  --mount=type=cache,target=/go/pkg/mod \
     --mount=type=cache,target=/root/.cache/go-build  \
     git checkout m4ksio/mainnet-4-proxy &&  \
     go build -o /app -ldflags "-extldflags -static" ./cmd/flow-rosetta-server && \
     chmod a+x /app \

FROM build-setup AS build-mainnet5

WORKDIR /dps
RUN  --mount=type=cache,target=/go/pkg/mod \
     --mount=type=cache,target=/root/.cache/go-build  \
     git checkout m4ksio/mainnet-5-proxy &&  \
     go build -o /app -ldflags "-extldflags -static" ./cmd/flow-rosetta-server && \
     chmod a+x /app

## Add the statically linked binary to a distroless image
FROM ubuntu:latest as production

#RUN mkdir /app/mainnet-3 /app/mainnet-4 /app/mainnet-5 /app/mainnet-6 /app/mainnet-7 /app/mainnet-8 /app/mainnet-9

RUN apt-get update
RUN apt-get -y install supervisor wget

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY --from=build-setup /restore-index-snapshot /bin/restore-index-snapshot
COPY --from=build-setup /rosetta-dispatcher-server /bin/rosetta-dispatcher-server
#COPY --from=build-mainnet3 /app /bin/rosetta-mainnet-3
#COPY --from=build-mainnet4 /app /bin/rosetta-mainnet-4
COPY --from=build-mainnet5 /app /bin/rosetta-mainnet-5
#COPY --from=build-mainnet6 /app /bin/rosetta-mainnet-6
#COPY --from=build-mainnet7 /app /bin/rosetta-mainnet-7
#COPY --from=build-mainnet8 /app /bin/rosetta-mainnet-8

RUN chmod a+x  /bin/restore-index-snapshot \
    /bin/rosetta-dispatcher-server \
#    /bin/rosetta-mainnet-3 \
#    /bin/rosetta-mainnet-4 \
    /bin/rosetta-mainnet-5
#    /bin/rosetta-mainnet-6 \
#    /bin/rosetta-mainnet-7 \
#    /bin/rosetta-mainnet-8 \
#    /bin/rosetta-mainnet-9

COPY --from=build-setup /docker/supervisord.conf /supervisord.conf
COPY --from=build-setup /docker/run.sh /run.sh

RUN chmod a+x /run.sh


EXPOSE 8080

CMD ["bash", "-x", "/run.sh"]