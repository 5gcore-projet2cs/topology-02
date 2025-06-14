#!/bin/bash
# Enable strict error checking and robust script execution
set -euo pipefail


# =============================================
# Configuration Section
# =============================================
UE_SERVICE="$1" # specify the name of the gnb
UE_Interface="$2" # specify the name of the ue : uesimtun0 : ue1, uesimtun1 : ue2   
DNN_TEST_IP="$3"  # specify the ip : top01 : 172.17.0.1, 10.10.0.1     
FILE_NAME="after_delay.pcap"

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <UE_SERVICE> <UE_Interface> <DNN_TEST_IP>"
  exit 1
fi

PCAP_DIR="./output"
NETWORK_IF="br-free5gc"

CORE_SERVICES=("amf" "smf" "ausf" "nrf" "i-upf" "psa-upf")
LOG_DIR="$PCAP_DIR/logs"

MAIN_PCAP="$PCAP_DIR/$FILE_NAME"          # All network traffic
PING_PCAP="$PCAP_DIR/ping_test.pcap"             # Ping test traffic

# =============================================
# Initialization
# =============================================
echo "[INIT] Setting up monitoring environment"

# Verify Docker network interface exists
if ! ip link show "$NETWORK_IF" >/dev/null 2>&1; then
    echo "[ERROR] Network interface $NETWORK_IF not found!"    
    ip link show | awk -F': ' '/^[0-9]/ {print $2}'
    exit 1
fi

# =============================================
# Packet Capture Setup
# =============================================
declare -A CAPTURE_PIDS  # Dictionary to store capture PIDs

start_capture() {
    local output_file=$1
    echo "[CAPTURE] Starting capture to $output_file"
    
    # Start tcpdump and store PID in array
    sudo tcpdump -i "$NETWORK_IF" not port 5201 and not port 5101 -w "$output_file" -U >/dev/null 2>&1 &
    CAPTURE_PIDS["$output_file"]=$!
    sleep 1  # Allow tcpdump to initialize
}

stop_capture() {
    local output_file=$1
    echo "[CAPTURE] Stopping capture for $output_file"
    
    if [[ -n "${CAPTURE_PIDS[$output_file]:-}" ]]; then
        sudo kill -INT "${CAPTURE_PIDS[$output_file]}" 2>/dev/null || true
        unset "CAPTURE_PIDS[$output_file]"
    fi
}

cleanup() {
    echo "[CLEANUP] Stopping all captures"
    # Kill all stored capture processes
    for pid in "${CAPTURE_PIDS[@]}"; do
        sudo kill -INT "$pid" 2>/dev/null || true
    done
    # Kill docker log followers
    pkill -f "docker logs -f" 2>/dev/null || true
}
trap cleanup EXIT

# Start main capture (all traffic)
start_capture "$MAIN_PCAP"

# =============================================
# Verify UE Tunnel Exists
# =============================================
echo "[VERIFY] Checking UE tunnel..."
if ! docker exec "$UE_SERVICE" ip addr show "$UE_Interface" >/dev/null 2>&1; then
    echo "[ERROR] UE tunnel not found! Register UE first."
    exit 1
fi

UE_IP=$(docker exec "$UE_SERVICE" ip -4 addr show "$UE_Interface" | awk '/inet/ {print $2}' | cut -d/ -f1)
echo "[STATUS] Using existing UE tunnel with IP: $UE_IP"

# =============================================
# Connectivity Tests
# =============================================

# 1. Ping Test
start_capture "$PING_PCAP" 
echo "[TEST] Running ping test..."
docker exec "$UE_SERVICE" ping -c 4 -I "$UE_Interface" "$DNN_TEST_IP" > "$LOG_DIR/ping_test.log" 2>&1


echo "======================================"

# =============================================
# Core Network Monitoring
# =============================================
echo "[MONITOR] Starting core network logs collection..."
for service in "${CORE_SERVICES[@]}"; do
    docker logs -f "$service" > "$LOG_DIR/${service}_logs.log" 2>&1 &
done

