#!/bin/sh

# Usage:
# ./delay.sh [out|in|free|status] [delay_in_ms] [interface]
# Examples:
# ./delay.sh out 200 wlan0     # adds 200ms delay to outgoing traffic on wlan0
# ./delay.sh in 200 wlan0      # adds 200ms delay to incoming traffic on wlan0
# ./delay.sh free wlan0        # removes all traffic control from wlan0 and ifb0
# ./delay.sh free              # removes all traffic control from eth0 and ifb0
# ./delay.sh status wlan0      # shows current traffic control status for wlan0 and ifb0

ACTION=$1

if [ -z "$ACTION" ]; then
  echo "Usage: $0 [out|in|free|status] [delay_in_ms] [interface]"
  echo "Note: Incoming delay requires ifb device."
  exit 1
fi

IFACE=""
DELAY=""
IFB="ifb0"

if [ "$ACTION" = "status" ]; then
  IFACE=${2:-eth0}
  echo "Traffic control status for $IFACE and $IFB:"
  echo "============================================"

  echo "Outgoing delay on $IFACE:"
  DELAYS_OUT=$(tc qdisc show dev "$IFACE" | grep netem | grep -oP 'delay \K[0-9.]+[a-z]*' || true)
  if [ -z "$DELAYS_OUT" ]; then
    echo "  none"
  else
    echo "  $DELAYS_OUT"
  fi

  echo ""
  echo "Incoming delay via $IFB:"
  DELAYS_IN=$(tc qdisc show dev "$IFB" | grep netem | grep -oP 'delay \K[0-9.]+[a-z]*' || true)
  if [ -z "$DELAYS_IN" ]; then
    echo "  none"
  else
    echo "  $DELAYS_IN"
  fi

  exit 0
fi

if [ "$ACTION" = "free" ]; then
  IFACE=${2:-eth0}
  echo "Removing all traffic control rules from $IFACE and $IFB..."

  # qdisc removal from interface root and ingress
  tc qdisc del dev "$IFACE" root 2>/dev/null || true
  tc qdisc del dev "$IFACE" ingress 2>/dev/null || true

  # qdisc removal from ifb device root
  tc qdisc del dev "$IFB" root 2>/dev/null || true

  echo "Traffic control rules removed successfully."
  exit 0
fi

DELAY=$2
IFACE=${3:-eth0}

if [ "$ACTION" = "out" ]; then
  if [ -z "$DELAY" ]; then
    echo "You must specify a delay in milliseconds for 'out'"
    exit 1
  fi

  echo "Clearing existing qdiscs on $IFACE..."
  tc qdisc del dev "$IFACE" root 2>/dev/null || true

  echo "Applying $DELAY ms delay to outgoing traffic on $IFACE"
  tc qdisc add dev "$IFACE" root netem delay "${DELAY}ms" 10ms distribution normal
  exit 0
fi

if [ "$ACTION" = "in" ]; then
  if [ -z "$DELAY" ]; then
    echo "You must specify a delay in milliseconds for 'in'"
    exit 1
  fi

  # is loaded ifb module loaded 
  if ! lsmod | grep -q ifb; then
    echo "Loading ifb kernel module..."
    modprobe ifb
  fi

  # ifb0 is created if it does not exist
  if ! ip link show "$IFB" >/dev/null 2>&1; then
    echo "Creating IFB device $IFB..."
    ip link add "$IFB" type ifb
    ip link set dev "$IFB" up
  fi

  echo "Clearing existing qdiscs on $IFACE ingress and $IFB root..."
  tc qdisc del dev "$IFACE" ingress 2>/dev/null || true
  tc qdisc del dev "$IFB" root 2>/dev/null || true

  echo "Adding ingress qdisc on $IFACE and redirecting ingress to $IFB..."
  tc qdisc add dev "$IFACE" ingress
  tc filter add dev "$IFACE" parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev "$IFB"

  echo "Applying $DELAY ms delay to incoming traffic on $IFACE via $IFB"
  tc qdisc add dev "$IFB" root netem delay "${DELAY}ms" 10ms distribution normal
  exit 0
fi

echo "Invalid action: $ACTION."
echo "Supported actions: out, in, free, status"
echo "Incoming delay requires ifb device."
exit 1