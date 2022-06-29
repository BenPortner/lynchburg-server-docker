#!/bin/bash

/usr/local/bin/start_websockets.sh &

# Add specified admin password
python -c "from gluon.main import save_password; save_password('$WEB2PY_PASSWORD',443)"

if [ "$WEB2PY_RP" == "true" ]
then
        echo "Starting uwsgi with reverse proxy configuration"
        uwsgi --socket 0.0.0.0:80 --protocol uwsgi --wsgi wsgihandler:application $UWSGI_OPTIONS &
else
        echo "Starting uwsgi with stand-alone configuration"
        uwsgi --http 0.0.0.0:80 --protocol uwsgi --wsgi wsgihandler:application $UWSGI_OPTIONS &
fi

exec /usr/local/bin/start_scheduler.sh
