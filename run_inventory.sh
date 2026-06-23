#!/bin/bash

# Configuration and directories
INPUT_FILE="serveurs_client.txt"
TARGET_SCRIPT="check_versions.sh"
OUTPUT_DIR="$HOME/rapports"
DATE_SUFFIX=$(date +'%Y-%m-%d')

# Ensure the input inventory file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo " [⚠️] Error: Input file '$INPUT_FILE' is missing."
    exit 1
fi

# Ensure the inventory script engine exists
if [ ! -f "$TARGET_SCRIPT" ]; then
    echo " [⚠️] Error: Target script '$TARGET_SCRIPT' is missing."
    exit 1
fi

# Create output directory if it does not exist
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "📁 Creating report repository directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
fi

echo "=================================================="
echo "      STARTING GLOBAL INFRASTRUCTURE INVENTORY     "
echo "=================================================="

# Loop through server list
while read -r server || [ -n "$server" ]; do
    # Skip empty lines or commented lines
    [[ -z "$server" || "$server" =~ ^# ]] && continue

    echo "🔍 Scanning server: $server ..."
    
    # Run remote execution over SSH and dump clean logs into ~/rapports
    ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 root@"$server" 'bash -s' < "$TARGET_SCRIPT" > "$OUTPUT_DIR/rapports_${server}_${DATE_SUFFIX}.TXT" 2>&1
    
    if [ $? -eq 0 ]; then
        echo " [✓] Inventory log successfully written for $server"
    else
        echo " [❌] Connection or execution failure on $server (check output log)"
    fi
done < "$INPUT_FILE"

echo "=================================================="
echo " 🎉 Collection complete. Output available in: $OUTPUT_DIR"
echo "=================================================="
