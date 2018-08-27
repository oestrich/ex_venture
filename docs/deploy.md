## Deployment

Distillery is used to generate releases. Once a release is generated you can copy the tar file to the server and start it up.

```bash
cd assets && node node_modules/brunch/bin/brunch build && cd ..
MIX_ENV=prod mix compile
MIX_ENV=prod mix phx.digest
MIX_ENV=prod mix release
```

The `release.sh` script will also do the same.

### TLS

The game does not support TLS natively, but you can get nginx to serve as a termination point and forward locally to the app. Nginx needs to be built with two modules, [stream_core](http://nginx.org/en/docs/stream/ngx_stream_core_module.html) and [stream_ssl](http://nginx.org/en/docs/stream/ngx_stream_ssl_module.html). You will also need to set the `ssl_port` option in networking. By default it will load from the `SSL_PORT` ENV variable.

```nginx
stream {
  upstream exventure {
    server 127.0.0.1:5555;
  }

  server {
    listen 5443 ssl;

    # Copy in your main site's settings here
    ssl_certificate /path/to/file.pem
    ssl_certificate_key /path/to/file.key

    proxy_pass exventure;
  }
}
```
