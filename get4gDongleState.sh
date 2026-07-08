#!/bin/bash

# Webhook URL
WEBHOOK_URL="https://<webhook-url>"

# Getting data
HOSTNAME=$(hostname)
LOG=$(/bin/cat /phion0/logs/box_Network_umts.log | tail -1)
SERIAL=$(/opt/phion/bin/hwtool -e 2>/dev/null | grep -o 'SN = .*' | cut -f2- -d=)

# JSON build
JSON_PAYLOAD=$(cat <<EOF
{
  "hostname": "$HOSTNAME",
  "serial": "$SERIAL",
  "status": "$LOG"
}
EOF
)

# CURL execution
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD"




