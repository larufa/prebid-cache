FROM ubuntu:20.04 AS build
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y wget
ARG TARGETARCH
ENV GO_INSTALLER=go1.19.5.linux-$TARGETARCH.tar.gz
WORKDIR /tmp
RUN wget https://dl.google.com/go/$GO_INSTALLER && \
    tar -C /usr/local -xzf $GO_INSTALLER
RUN mkdir -p /app/prebid-cache/
WORKDIR /app/prebid-cache/
ENV GOROOT=/usr/local/go
ENV PATH=$GOROOT/bin:$PATH
ENV GOPROXY="https://proxy.golang.org"
RUN apt-get update && \
    apt-get install -y git && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENV CGO_ENABLED 0
COPY ./ ./
RUN go mod vendor
RUN go mod tidy
ARG TEST="true"
RUN if [ "$TEST" != "false" ]; then ./validate.sh ; fi
RUN go build -mod=vendor -ldflags "-X github.com/prebid/prebid-cache/version.Ver=`git describe --tags` -X github.com/prebid/prebid-cache/version.Rev=`git rev-parse HEAD`" .

FROM ubuntu:20.04 AS release
LABEL maintainer="hans.hjort@xandr.com" 
ARG config="config.yaml"
RUN apt-get update && \
    apt-get install --assume-yes apt-utils && \
    apt-get install -y ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
WORKDIR /usr/local/bin/
COPY --from=build /app/prebid-cache/prebid-cache .
RUN chmod a+xr prebid-cache
COPY --from=build /app/prebid-cache/$config ./config.yaml
RUN chmod a+r config.yaml
RUN adduser prebid_user
USER prebid_user
EXPOSE 2424
EXPOSE 2525
ENTRYPOINT ["/usr/local/bin/prebid-cache"]
