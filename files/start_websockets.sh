#!/bin/bash

KEY=$(cat websocket_key.txt)

echo "Starting WebSocket server"
until python3 $WEB2PY_ROOT/websocket_messaging.py -k $KEY -p 8888 1>/dev/null; do
        echo "WebSocket server exited with $?" >&2
        sleep 1
done
