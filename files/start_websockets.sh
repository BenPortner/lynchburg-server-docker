#!/bin/bash

KEY=$(cat websocket_key.txt)

until python3 $WEB2PY_ROOT/websocket_messaging.py -k $KEY -p 8888 1>/dev/null; do
	echo "Websocket server exited with $?" >&2
	sleep 1
done
