user nginx;

# 1 worker process per CPU core.
# Check max: $ grep processor /proc/cpuinfo | wc -l
worker_processes auto;

error_log /var/log/nginx/error.log warn;
pid       /var/run/nginx.pid;

events {
  # Tells worker processes how many people can be served simultaneously.
  # worker_process (1) * worker_connections (1024) = 1024
  # Check max: $ ulimit -n
  worker_connections $NGINX_WORKER_CONN;

  # Connection processing method. The epoll is efficient method used on Linux 2.6+
  use epoll;
}

http {
  include      /etc/nginx/mime.types;
  default_type application/octet-stream;

  real_ip_header    X-Forwarded-For;
  real_ip_recursive on;
  set_real_ip_from  $NGINX_CIDR;

  log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                  '$status $body_bytes_sent "$http_referer" '
                  '"$http_user_agent" "$http_x_forwarded_for"';

  map $request_uri $loggable {
    ~*/(health-?check|ping)$ 0;
    default 1;
  }

  access_log /var/log/nginx/access.log main if=$loggable;

  # Used to reduce 502 and 504 HTTP errors.
  fastcgi_buffers         8 16k;
  fastcgi_buffer_size     32k;
  fastcgi_connect_timeout 300;
  fastcgi_send_timeout    300;
  fastcgi_read_timeout    300;

  # The sendfile allows transfer data from a file descriptor to another directly in kernel.
  # Combination of sendfile and tcp_nopush ensures that the packets are full before being sent to the client.
  # This reduces network overhead and speeds the way files are sent.
  # The tcp_nodelay forces the socket to send the data.
  sendfile    on;
  tcp_nopush  on;
  tcp_nodelay on;

  # The client connection can stay open on the server up to given seconds.
  keepalive_timeout 65;

  # Sets the maximum size of the types hash tables.
  types_hash_max_size 2048;

  # Hides Nginx server version in headers.
  server_tokens off;

  # Disable Content-type sniffing on some browsers.
  add_header X-Content-Type-Options nosniff;

  # Enables the Cross-site scripting (XSS) filter built into most recent web browsers.
  # If user disables it on the browser level, this role re-enables it automatically on serve level.
  add_header X-XSS-Protection '1; mode=block';

  # Prevent the browser from rendering the page inside a frame/iframe to avoid clickjacking.
  add_header X-Frame-Options DENY;

  # Enable HSTS to prevent SSL stripping.
  #add_header Strict-Transport-Security 'max-age=31536000; includeSubdomains; preload';
  add_header Strict-Transport-Security 'max-age=31536000; includeSubdomains';

  # Prevent browser sending the referrer header when navigating from HTTPS to HTTP.
  add_header 'Referrer-Policy' 'no-referrer-when-downgrade';

  # Compress files on the fly before transmitting.
  # Compressed files are then decompressed by the browsers that support it.
  gzip on;
  gzip_buffers 16 8k;
  gzip_comp_level 9;
  gzip_disable "msie6";
  gzip_min_length 128;
  gzip_proxied any;
  gzip_types
    application/javascript
    application/json
    application/rss+xml
    application/vnd.ms-fontobject
    application/x-font
    application/x-font-opentype
    application/x-font-otf
    application/x-font-truetype
    application/x-font-ttf
    application/x-javascript
    application/xhtml+xml
    application/xml
    application/xml+rss
    font/opentype
    font/otf
    font/ttf
    image/svg+xml
    image/x-icon
    text/css
    text/javascript
    text/plain
    text/xml;
  gzip_vary on;

  # These directives responsible for the time a server will wait for a client body or client header to be sent after request.
  #client_body_timeout   3m;
  #client_header_timeout 3m;

  # If after this time client will take nothing, then NGINX is shutting down the connection.
  #send_timeout 3m;

  # This handles the client buffer size, meaning any POST actions sent to NGINX.
  #client_body_buffer_size 128k;

  # It handles the client header size.
  #client_header_buffer_size 1k;

  # The maximum allowed size for a client request.
  client_max_body_size 5M;

  # The maximum number and size of buffers for large client headers.
  #large_client_header_buffers 4 4k;

  include /etc/nginx/conf.d/*.conf;
}
