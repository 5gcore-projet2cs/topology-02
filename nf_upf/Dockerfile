FROM free5gc/base AS my-base

RUN git clone https://github.com/free5gc/go-gtp5gnl.git && mkdir "go-gtp5gnl/bin" && \
    cd "go-gtp5gnl/cmd/gogtp5g-tunnel" &&  go build -o "${GOPATH}/gtp5g-tunnel" . && \
    cd -

FROM free5gc/upf-base:latest AS builder
FROM bitnami/minideb:bullseye

LABEL description="free5GC open source 5G Core Network" \
    version="Stage 3"

ENV F5GC_MODULE=upf
ENV DEBIAN_FRONTEND=noninteractive
ARG DEBUG_TOOLS

# Install debug tools ~ 100MB (if DEBUG_TOOLS is set to true)
RUN if [ "$DEBUG_TOOLS" = "true" ] ; then apt-get update && apt-get install -y vim strace net-tools iputils-ping curl netcat tcpdump; fi

# Install UPF dependencies
RUN apt-get update \
    && apt-get install -y iperf3 libmnl0 libyaml-0-2 iproute2 iptables tcpdump python3 python3-pip libpcap-dev \
    && pip3 install --no-cache-dir scapy \
    && apt-get clean

# Set working dir
WORKDIR /free5gc
RUN mkdir -p config/ log/

# Copy executable
COPY --from=builder /free5gc/${F5GC_MODULE} ./
COPY --from=my-base /go/gtp5g-tunnel ./gtp5g-tunnel

# Config files volume
VOLUME [ "/free5gc/config" ]