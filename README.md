# LogGraph

This is a log analytics project.

Key technologies used:
- PostgreSQL
- PostgREST (for API server)
- Next.js (frontend app)

## Setup

In your nginx config, set the log format to include all fields in JSON format:

```conf
log_format json_analytics escape=json '{'
    '"method":"$request_method",'
    '"host":"$host",'
    '"path":"$uri",'
    '"user_agent":"$http_user_agent",'
    '"request_length":$request_length,'
    '"status_code":$status,'
    '"server_protocol":"$server_protocol",'
    '"server_name":"$server_name",'
    '"remote_addr":"$remote_addr",'
    '"query_string":"$args",'
    '"accept_encoding":"$http_accept_encoding",'
    '"content_type":"$http_content_type"'
'}';

access_log /var/log/nginx/access_json json_analytics;
```

Create the FIFO for Nginx: `sudo mkfifo /var/log/nginx/access_json`

Build the uploader:
```sh
sudo apt-get update && sudo apt-get install -y gcc libcurl4-openssl-dev libjson-c-dev
gcc upload/main.c -lcurl -ljson-c -o loggraph
sudo cp loggraph /usr/local/bin/loggraph
sudo chown root:root /usr/local/bin/loggraph
sudo chmod 755 /usr/local/bin/loggraph
```

Create the env files for the uploader in `/etc/loggraph/config.env`:

```env
UPLOAD_TOKEN=JWT_ACCESS_TOKEN
UPLOAD_ENDPOINT=https://something
```

Make sure it has the correct permissions:

```sh
sudo chown root:root /etc/loggraph/config.env
sudo chmod 600 /etc/loggraph/config.env
```

For security, create an additional user for the uploader:

```shell
sudo useradd -r -s /bin/false loggraph
sudo chown www-data:loggraph /var/log/nginx/access_json
sudo chmod 640 /var/log/nginx/access_json
```

Create the systemd service for the uploader in `/etc/systemd/system/loggraph.service`:

```conf
[Unit]
Description=Loggraph
After=network.target

[Service]
Type=simple
User=loggraph
Group=loggraph

EnvironmentFile=/etc/loggraph/config.env

ExecStart=/usr/local/bin/loggraph /var/log/nginx/access_json
Restart=on-failure
RestartSec=5s

# Security sandboxing
ProtectSystem=full
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```
