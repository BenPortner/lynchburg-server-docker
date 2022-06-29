#!/bin/bash

if [ ! -f $WEB2PY_ROOT/applications/app/databases/sql.log ]
then
        echo "Waiting for database initialization..."
        while [ ! -f $WEB2PY_ROOT/applications/app/databases/sql.log ]
        do
                sleep 3
        done
        echo "Database initialized"
fi

echo "Starting scheduler"
until python3 $WEB2PY_ROOT/web2py.py -K app; do
        echo "Scheduler exited with $?" >&2
        sleep 3
done
