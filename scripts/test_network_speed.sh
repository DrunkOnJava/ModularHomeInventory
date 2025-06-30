#!/bin/bash
# Network Speed Test Script

echo "🌐 Network Speed Test Tool"
echo "========================="
echo ""

# Function to test ping latency
test_ping() {
    local host=$1
    echo "📡 Testing ping to $host..."
    ping -c 10 $host | tail -1 | awk -F '/' '{print "Average latency: " $5 " ms"}'
    echo ""
}

# Function to test throughput using iperf3
test_iperf() {
    local host=$1
    echo "📊 Testing throughput with iperf3..."
    echo "Note: Requires iperf3 server running on iMac (iperf3 -s)"
    
    if command -v iperf3 &> /dev/null; then
        iperf3 -c $host -t 10 -i 1
    else
        echo "❌ iperf3 not installed. Install with: brew install iperf3"
    fi
    echo ""
}

# Function to test file transfer speed
test_file_transfer() {
    local host=$1
    local user=$2
    
    echo "📁 Testing file transfer speed..."
    echo "Creating 100MB test file..."
    
    # Create test file
    dd if=/dev/zero of=/tmp/speedtest.tmp bs=1m count=100 2>/dev/null
    
    # Test upload speed
    echo "⬆️  Testing upload speed..."
    start_time=$(date +%s.%N)
    scp -q /tmp/speedtest.tmp $user@$host:/tmp/speedtest.tmp
    end_time=$(date +%s.%N)
    
    duration=$(echo "$end_time - $start_time" | bc)
    speed=$(echo "scale=2; 100 / $duration * 8" | bc)
    echo "Upload speed: $speed Mbps"
    
    # Test download speed
    echo "⬇️  Testing download speed..."
    start_time=$(date +%s.%N)
    scp -q $user@$host:/tmp/speedtest.tmp /tmp/speedtest2.tmp
    end_time=$(date +%s.%N)
    
    duration=$(echo "$end_time - $start_time" | bc)
    speed=$(echo "scale=2; 100 / $duration * 8" | bc)
    echo "Download speed: $speed Mbps"
    
    # Cleanup
    rm -f /tmp/speedtest.tmp /tmp/speedtest2.tmp
    ssh $user@$host "rm -f /tmp/speedtest.tmp"
    
    echo ""
}

# Function to test using nc (netcat)
test_netcat() {
    local host=$1
    
    echo "🔌 Testing raw TCP throughput with netcat..."
    echo "Run this on iMac first: nc -l 5555 > /dev/null"
    echo "Press Enter when ready..."
    read
    
    # Create test data and send
    dd if=/dev/zero bs=1m count=100 2>/dev/null | pv -s 100m | nc $host 5555
    
    echo ""
}

# Main menu
echo "Please provide your iMac's details:"
read -p "iMac IP address: " IMAC_IP
read -p "iMac username (for SCP test): " IMAC_USER

echo ""
echo "Select test to run:"
echo "1. Ping test (latency)"
echo "2. iperf3 test (requires iperf3 server on iMac)"
echo "3. File transfer test (SCP)"
echo "4. Netcat test (raw TCP)"
echo "5. All tests"
echo ""

read -p "Enter choice (1-5): " choice

case $choice in
    1)
        test_ping $IMAC_IP
        ;;
    2)
        test_iperf $IMAC_IP
        ;;
    3)
        test_file_transfer $IMAC_IP $IMAC_USER
        ;;
    4)
        test_netcat $IMAC_IP
        ;;
    5)
        test_ping $IMAC_IP
        test_iperf $IMAC_IP
        test_file_transfer $IMAC_IP $IMAC_USER
        test_netcat $IMAC_IP
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo "✅ Speed test complete!"