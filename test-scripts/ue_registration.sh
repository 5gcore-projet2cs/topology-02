#!/bin/bash
set -euo pipefail

# Configuration
BASE_DIR="./output"
PCAP_DIR="$BASE_DIR/ue_pcaps"
LOG_DIR="$BASE_DIR/ue_logs"
NETWORK_IF="br-free5gc"
UE_SERVICES=("ueransim-1" "ueransim-2" "ueransim-3")
UE_CONFIGS=("uecfg-1.yaml" "uecfg-2.yaml")

# Clean and recreate output directories
echo "[INIT] Cleaning old output and preparing directories..."
sudo rm -rf "$BASE_DIR"
mkdir -p "$PCAP_DIR" "$LOG_DIR" "output/logs"

# Iterate over UE services
for UE_SERVICE in "${UE_SERVICES[@]}"; do
    # iterate by index so we know 0 → uesimtun0, 1 → uesimtun1
    for idx in "${!UE_CONFIGS[@]}"; do
        UE_CONFIG="${UE_CONFIGS[idx]}"
        UE_ID=$(basename "$UE_CONFIG" .yaml)
        EXPECTED_IFACE="uesimtun${idx}"

        echo "[$UE_SERVICE:$UE_ID] Starting registration..."

        # File paths
        REGISTRATION_PCAP="$PCAP_DIR/${UE_SERVICE}_${UE_ID}.pcap"
        LOG_FILE="$LOG_DIR/${UE_SERVICE}_${UE_ID}.log"

        # Start packet capture
        echo "[$UE_SERVICE:$UE_ID] Capturing packets on $NETWORK_IF..."
        sudo tcpdump -i "$NETWORK_IF" -w "$REGISTRATION_PCAP" &
        CAP_PID=$!

        # Start the UE
        docker exec "$UE_SERVICE" ./nr-ue -c "config/$UE_CONFIG" > "$LOG_FILE" 2>&1 &

        # Wait for the specific tunnel interface
        echo "[$UE_SERVICE:$UE_ID] Waiting for $EXPECTED_IFACE to appear..."
        for i in {1..10}; do
            if docker exec "$UE_SERVICE" ip addr show "$EXPECTED_IFACE" >/dev/null 2>&1; then
                UE_IP=$(docker exec "$UE_SERVICE" ip -4 addr show "$EXPECTED_IFACE" \
                         | awk '/inet/ {print $2}' | cut -d/ -f1)
                echo "[$UE_SERVICE:$UE_ID] Tunnel $EXPECTED_IFACE established with IP: $UE_IP"
                break
            fi
            sleep 2
            if [ "$i" -eq 10 ]; then
                echo "[ERROR] $EXPECTED_IFACE failed to come up for $UE_SERVICE ($UE_CONFIG)"
                sudo kill -INT $CAP_PID
                exit 1
            fi
        done

        # Stop tcpdump now that the IP is captured
        sudo kill -INT $CAP_PID
        echo "[$UE_SERVICE:$UE_ID] PCAP saved to $REGISTRATION_PCAP"

    done
done

# Log container IP addresses
docker ps --format "{{.ID}}" \
  | xargs -I {} sudo docker inspect -f '{{.Name}} -> {{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' {} \
> "$BASE_DIR/containers_ipAddr.log" 2>&1

echo "[COMPLETE] All UE registrations finished. Logs and PCAPs stored in $BASE_DIR."