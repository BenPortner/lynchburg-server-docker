## Lynchburg Server Dockerfile
[Project Lynchburg](https://git.noc.ruhr-uni-bochum.de/lynchburg/lynchburg-page)  
https://git.noc.ruhr-uni-bochum.de/lynchburg/lynchburg-docker

#### Introduction

This Dockerfile can be used to easily install the Lynchburg Server web2py application. You can use the Docker container with or without a reverse proxy, but using one is recommended.

#### License

The Dockerfile and helper scripts are put into the public domain. For more information check the [LICENSE](/LICENSE) file.  
For information about contributors goto the [Project Lynchburg landing page](https://git.noc.ruhr-uni-bochum.de/lynchburg/lynchburg-page)

NOTE: The temporary workaround file [websocket_messaging.py](/files/websocket_messaging.py) is still licensed under LGPLv3 in compliance with the web2py LICENSE.

#### Installation

1. Build the docker image using ``docker build --build-arg "ADMIN_PASSWORD=<YOUR_ADMIN_PASSWORD>" -t lynchburg .``.  
    * Additionally add another ``--build-arg "REVERSE_PROXY=false"``, if you wish to use the docker container directly without a reverse proxy (not recommended). Note that using HTTPS for Lynchburg will require a lot of effort when not using a reverse proxy.
    * Additionally add another ``--build-arg "DB_URI=<URI>"``, if you wish to use a real database instead of the default sqlite one. Valid ``<URI>`` strings can be found [here](http://web2py.com/book/default/chapter/06).
1. Create a new docker container using ``docker create --name lynchburg lynchburg``
1. Start the container using ``docker container start lynchburg``


#### Reverse proxy

The docker container exposes port ``80`` as ``uswgi`` and ``8888`` as WebSocket server. Use a reverse proxy for *BOTH* ports.
Either forward the container ports to some host port by using the ``-p`` flag when creating the container, or use ``docker network inspect bridge`` to get the container specific IP.

If you are using nginx the basic configuration should look like this:
```
server {
    listen 0.0.0.0:80;

    # This is the websocket reverse proxy. The /realtime/ part of the URL must be forwarded too.
    # The Host must be changed to 127.0.0.1:8888
    # Replace the <IP> in proxy_pass with the container specific IP, or use a host ip:port if you used the -p flag when creating the container
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
    # Replace the <IP> in proxy_pass with the container specific IP, or use a host ip:port if you used the -p flag when creating the container
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
**HTTPS** should work flawlessly when using a reverse proxy. Just configure the webserver accordingly.

##### Connection Upgrade
nginx, and possibly other webservers, require a connection upgrade when using WebSockets. For nginx follow the standard practise of defining ``$http_upgrade`` and ``$connection_upgrade`` as:
```
map $http_upgrade $connection_upgrade {  
    default upgrade;
    ''      close;
}
```
Put that ``map`` block into the ``http`` block of your nginx configuration. The default file path for the nginx config is ``/etc/nginx/nginx.conf``
