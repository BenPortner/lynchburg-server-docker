## Lynchburg Server Dockerfile

#### Introduction

This Dockerfile can be used to easily install the Lynchburg Server.

#### Installation

1. Build the docker image using ``docker build --build-arg "ADMIN_PASSWORD=<YOUR_ADMIN_PASSWORD>" -t lynchburg .``
1. Create a new docker container using ``docker create --name lynchburg lynchburg``
1. Start the container using ``docker container start lynchburg``

#### Reverse proxy

The docker container exposes port ``80`` as uswgi and ``8888`` as websocket server. Use a reverse proxy for BOTH ports.
Either forward the container ports to some host port, or use ``docker network inspect bridge`` to get the container specific IP.

If you are using nginx the basic configuration should look like this:
```
server {
    listen 0.0.0.0:80;

    # This is the websocket reverse proxy. The /realtime/ part of the URL must be forwarded too.
    # The Host must be changed to 127.0.0.1:8888
    # Replace the <IP> in proxy_pass with the container specific IP
    location /realtime/ {
        proxy_pass                  http://<IP>:8888;
        proxy_http_version          1.1;
        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host       127.0.0.1:8888;
        error_log                   /var/log/nginx/lynchburg_ws.err warn;
        access_log                  /var/log/nginx/lynchburg_ws.log;
    }

    # This is the http reverse proxy
    # Replace the <IP> in proxy_pass with the container specific IP
    location / {
        uwsgi_pass      <IP>:80;
        include         uwsgi_params;
        uwsgi_param     UWSGI_SCHEME $scheme;
        uwsgi_param     SERVER_SOFTWARE nginx/$nginx_version;
        error_log       /var/log/nginx/lynchburg.err warn;
        access_log      /var/log/nginx/lynchburg.log;
    }
}
```
**HTTPS** should work flawlessly. Just configure the nginx ``server {`` accordingly.

Follow the standard nginx practise of defining ``$http_upgrade`` and ``$connection_upgrade`` as:
```
map $http_upgrade $connection_upgrade {  
    default upgrade;
    ''      close;
}
```
