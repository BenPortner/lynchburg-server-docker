#!/bin/bash

until python3 $WEB2PY_ROOT/web2py.py -K app; do
        echo "Scheduler exited with $?" >&2
        sleep 3
done
