#
# This is the Project Lynchburg Dockerfile
# It creates a docker container with web2py, uwsgi and tornado
# ready to connect to a reverse proxy on the system.
#
# Exposed are ports 80 and 8888 which requires uwsgi_pass and a reverse
# connection upgrade to websockts proxy_pass respectively
#
# This Dockerfile is inspired by the one @smithmicro created (https://github.com/smithmicro/web2py)
#

# Initial setup
FROM python:alpine

ARG ADMIN_PASSWORD=
ARG REVERSE_PROXY=true

RUN [ ! -z "${ADMIN_PASSWORD}" ] || { echo "Please specify an web2py admin password using the 'docker build --build-arg \"ADMIN_PASSWORD=<PASSWORD>\"' build flag"; exit 1; }

ENV WEB2PY_PASSWORD $ADMIN_PASSWORD
ENV WEB2PY_ROOT=/opt/web2py

# This enables logging only for 5xx errors
ENV UWSGI_OPTIONS="--master --thunder-lock --enable-threads --disable-logging --log-5xx"

WORKDIR /opt

# Install necessary packages
RUN apk update && apk add \
    build-base \
    linux-headers \
    pcre-dev \
    wget \
    nano \
    bash \
    git \
    tzdata

RUN pip install --upgrade pip \
 && pip install uwsgi \
 && pip install tornado

# Download and install the latest web2py
RUN wget http://web2py.com/examples/static/web2py_src.zip \
 && unzip web2py_src.zip \
 && rm web2py_src.zip

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# WORKAROUND:
#
# Replace the web2py "websocket_messaging.py" with a custom one fixed for python3.8
# If at some point this file is fixed for python3.8 in the Git Repo, this can be removed
# (https://github.com/web2py/web2py/blob/master/gluon/contrib/websocket_messaging.py)
#
COPY files/websocket_messaging.py $WEB2PY_ROOT
RUN cp $WEB2PY_ROOT/websocket_messaging.py $WEB2PY_ROOT/gluon/contrib/websocket_messaging.py
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

RUN mv $WEB2PY_ROOT/handlers/wsgihandler.py $WEB2PY_ROOT \
 && mv $WEB2PY_ROOT/gluon/contrib/websocket_messaging.py $WEB2PY_ROOT \
 && ln -s $WEB2PY_ROOT/wsgihandler.py $WEB2PY_ROOT/handlers \
 && ln -s $WEB2PY_ROOT/websocket_messaging.py $WEB2PY_ROOT/gluon/contrib/

# Copy meta files
COPY files/entrypoint.sh /usr/local/bin/
COPY files/start_websockets.sh /usr/local/bin/
COPY files/start_scheduler.sh /usr/local/bin/
COPY files/routes.py $WEB2PY_ROOT

RUN chmod +x /usr/local/bin/entrypoint.sh \
 && chmod +x /usr/local/bin/start_websockets.sh \
 && chmod +x /usr/local/bin/start_scheduler.sh

# Clone project files
WORKDIR $WEB2PY_ROOT/applications
RUN git clone https://git.noc.ruhr-uni-bochum.de/lynchburg/lynchburg-server app

# Set reverse proxy flag
WORKDIR $WEB2PY_ROOT/applications/app/private
RUN sed -i -e "/rproxy\s*=/ s/= .*/= $REVERSE_PROXY/" ./appconfig.ini

# Generate websocket key from admin pw
WORKDIR $WEB2PY_ROOT
RUN echo "$WEB2PY_PASSWORD$(date)" | sha256sum | cut -c1-32 > websocket_key.txt \
 && cat websocket_key.txt

ENTRYPOINT [ "entrypoint.sh" ]
CMD [ "uwsgi" ]

EXPOSE 80 8888
