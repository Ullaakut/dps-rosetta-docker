FROM golang:1.16-buster AS build-setup

RUN apt-get update
RUN apt-get -y install cmake zip sudo git

ENV DPS_ROSETTA_DOCKER_BRANCH=v0.1
ENV FLOW_GO_BRANCH=v0.21
ENV RESTORE_INDEX_BRANCH=master
ENV ROSETTA_DISPATCHER_BRANCH=m4ksio/rosetta-dispatcher-server
ENV DPS_LIVE_BRANCH=tags/v1.3.0

RUN mkdir /dps /docker
WORKDIR /dps

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build  \
    git clone https://github.com/m4ksio/flow-dps /dps && \
    git clone --branch $DPS_ROSETTA_DOCKER_BRANCH https://github.com/dapperlabs/dps-rosetta-docker /docker && \
    git clone --branch $FLOW_GO_BRANCH https://github.com/onflow/flow-go /dps/flow-go && \
    make -C /dps/flow-go crypto/relic/build #prebuild crypto dependency


RUN  --mount=type=cache,target=/go/pkg/mod \
     --mount=type=cache,target=/root/.cache/go-build  \
     git checkout $RESTORE_INDEX_BRANCH &&  \
     go build -o /restore-index-snapshot -ldflags "-extldflags -static" ./cmd/restore-index-snapshot && \
     chmod a+x /restore-index-snapshot

# TODO once merged dispatcher should be on the same branch
RUN  --mount=type=cache,target=/go/pkg/mod \
     --mount=type=cache,target=/root/.cache/go-build  \
     git checkout $ROSETTA_DISPATCHER_BRANCH &&  \
     go build -o /rosetta-dispatcher-server -ldflags "-extldflags -static" ./cmd/rosetta-dispatcher-server && \
     chmod a+x /rosetta-dispatcher-server

## Build Relic first to maximize caching
#FROM build-setup AS build-relic
#
#RUN mkdir /build
#WORKDIR /build
#
## Copy over the crypto package
## COPY crypto ./crypto
#
## Build Relic (this places build artifacts in /build/relic/build)
#RUN cd ./crypto/ && go generate

#FROM build-setup AS build-mainnet3
#
#WORKDIR /dps
#RUN  --mount=type=cache,target=/go/pkg/mod \
#     --mount=type=cache,target=/root/.cache/go-build  \
#     git checkout m4ksio/mainnet-3-proxy &&  \
#     go build -o /app -ldflags "-extldflags -static" ./cmd/flow-rosetta-server && \
#     chmod a+x /app
#
#
#FROM build-setup AS build-mainnet4
#
#WORKDIR /dps
#RUN  --mount=type=cache,target=/go/pkg/mod \
#     --mount=type=cache,target=/root/.cache/go-build  \
#     git checkout m4ksio/mainnet-4-proxy &&  \
#     go build -o /app -ldflags "-extldflags -static" ./cmd/flow-rosetta-server && \
#     chmod a+x /app \

FROM build-setup AS build-mainnet5

WORKDIR /dps
RUN  --mount=type=cache,target=/go/pkg/mod \
     --mount=type=cache,target=/root/.cache/go-build  \
     git checkout m4ksio/mainnet-5-proxy &&  \
     go build -o /app -ldflags "-extldflags -static" ./cmd/flow-rosetta-server && \
     chmod a+x /app

FROM build-setup AS build-mainnet6

WORKDIR /dps
RUN  --mount=type=cache,target=/go/pkg/mod \
     --mount=type=cache,target=/root/.cache/go-build  \
     git checkout m4ksio/mainnet-6-proxy &&  \
     go build -o /app -ldflags "-extldflags -static" ./cmd/flow-rosetta-server && \
     chmod a+x /app

FROM build-setup AS build-mainnet7

WORKDIR /dps
RUN  --mount=type=cache,target=/go/pkg/mod \
     --mount=type=cache,target=/root/.cache/go-build  \
     git checkout m4ksio/mainnet-7-proxy &&  \
     go build -o /app -ldflags "-extldflags -static" ./cmd/flow-rosetta-server && \
     chmod a+x /app


#FROM build-setup AS build-mainnet8
#
#WORKDIR /dps
#RUN  --mount=type=cache,target=/go/pkg/mod \
#     --mount=type=cache,target=/root/.cache/go-build  \
#     git checkout m4ksio/mainnet-8-proxy &&  \
#     go build -o /app -ldflags "-extldflags -static" ./cmd/flow-rosetta-server && \
#     chmod a+x /app \
#
#FROM build-setup AS build-mainnet9
#
#WORKDIR /dps
#RUN  --mount=type=cache,target=/go/pkg/mod \
#     --mount=type=cache,target=/root/.cache/go-build  \
#     git checkout m4ksio/mainnet-9-proxy &&  \
#     go build -o /app -ldflags "-extldflags -static" ./cmd/flow-rosetta-server && \
#     chmod a+x /app

FROM build-setup AS build-live

WORKDIR /dps
RUN  --mount=type=cache,target=/go/pkg/mod \
     --mount=type=cache,target=/root/.cache/go-build  \
     git checkout $DPS_LIVE_BRANCH &&  \
     go build -o /app-index -ldflags "-extldflags -static" ./cmd/flow-dps-live && \
     chmod a+x /app-index && \
    go build -o /app-rosetta -ldflags "-extldflags -static" ./cmd/flow-rosetta-server && \
     chmod a+x /app-rosetta



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
COPY --from=build-mainnet6 /app /bin/rosetta-mainnet-6
COPY --from=build-mainnet7 /app /bin/rosetta-mainnet-7
#COPY --from=build-mainnet8 /app /bin/rosetta-mainnet-8
COPY --from=build-live /app-index /bin/dps-live-index
COPY --from=build-live /app-rosetta /bin/rosetta-live

RUN chmod a+x  /bin/restore-index-snapshot \
    /bin/rosetta-dispatcher-server \
#    /bin/rosetta-mainnet-3 \
#    /bin/rosetta-mainnet-4 \
    /bin/rosetta-mainnet-5 \
    /bin/rosetta-mainnet-6 \
    /bin/rosetta-mainnet-7 \
#    /bin/rosetta-mainnet-8 \
#    /bin/rosetta-mainnet-9
    /bin/dps-live-index \
    /bin/rosetta-live 

COPY --from=build-setup /docker/supervisord.conf /supervisord.conf
COPY --from=build-setup /docker/run.sh /run.sh

RUN chmod a+x /run.sh


EXPOSE 8080

CMD ["bash", "-x", "/run.sh"]