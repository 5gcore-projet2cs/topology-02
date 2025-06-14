FROM free5gc/ueransim:latest

# Update package list and install dependencies
RUN apt-get update && \
    apt-get install -y iperf3 python3 python3-pip libpcap-dev tcpdump && \
    pip3 install --no-cache-dir scapy && \
    apt-get clean