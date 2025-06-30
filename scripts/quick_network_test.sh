#!/bin/bash
# Quick Network Speed Test

if [ $# -eq 0 ]; then
    echo "Usage: $0 <imac-ip-address>"
    echo "Example: $0 192.168.1.100"
    exit 1
fi

IMAC_IP=$1

echo "🚀 Quick Network Speed Test to iMac ($IMAC_IP)"
echo "=============================================="
echo ""

# 1. Basic connectivity
echo "1️⃣ Testing connectivity..."
if ping -c 1 -W 1 $IMAC_IP > /dev/null 2>&1; then
    echo "✅ iMac is reachable"
else
    echo "❌ Cannot reach iMac at $IMAC_IP"
    exit 1
fi
echo ""

# 2. Latency test
echo "2️⃣ Testing latency (10 pings)..."
ping -c 10 $IMAC_IP | tail -1 | awk -F '/' '{print "📊 Average latency: " $5 " ms"}'
echo ""

# 3. Quick throughput test using curl
echo "3️⃣ Testing download speed (if web sharing is enabled)..."
# Try to download from iMac's web server if available
if curl -s --connect-timeout 2 http://$IMAC_IP/ > /dev/null; then
    echo "Downloading test file..."
    time curl -s -w "Downloaded at %{speed_download} bytes/sec\n" http://$IMAC_IP/ -o /dev/null
else
    echo "⚠️  Web sharing not available on iMac"
fi
echo ""

# 4. Network interface info
echo "4️⃣ Your network interface details:"
echo "Current active interfaces:"
ifconfig | grep -E "^en[0-9]:" -A 4 | grep -E "(^en|inet |media:)" | grep -B1 "inet $"

echo ""
echo "💡 For more detailed speed tests, use:"
echo "   - iperf3 (install on both machines: brew install iperf3)"
echo "   - ./test_network_speed.sh (comprehensive test suite)"
echo ""