# Web deployment

The web app is deployed at <https://squiggle.ymit.dev> on the development
machine. The host uses the shared Caddy reverse proxy and Docker `edge` network
used by the other `*.ymit.dev` apps.

## Deployment layout

- `/home/dev/.t3/projects/squiggle-web/site/` contains the generated Flutter web
  build.
- `/home/dev/.t3/projects/squiggle-web/docker-compose.yml` runs nginx with that
  directory mounted read-only.
- `/home/dev/.t3/projects/squiggle-web/nginx.conf` serves Flutter routes and
  sets the required `application/wasm` content type for `sqlite3.wasm`. It also
  prevents stale Flutter entry scripts from staying cached across deployments.
- `/home/dev/edge/Caddyfile` routes `squiggle.ymit.dev` to the `squiggle-web`
  container. Caddy manages HTTPS with the other sites.

The initial deployment built this checkout with Flutter 3.50.1, copied
`build/web/` into the site directory, started the nginx Compose service, then
validated and reloaded Caddy.

## Deploy an update

First check out or update the source revision you want to publish. From the
`squiggle_flutter` directory, build and sync the output:

```sh
mise exec flutter@3.50.1 -- flutter build web --release --web-content-hash
rsync -a --delete build/web/ /home/dev/.t3/projects/squiggle-web/site/
docker compose -f /home/dev/.t3/projects/squiggle-web/docker-compose.yml up -d
```

The site directory is mounted into nginx, so syncing files publishes the new
build without rebuilding the image. Re-running `docker compose up -d` ensures
the service is running. No Caddy reload is needed for app updates. If nginx
configuration changes, validate and reload it with:

```sh
docker exec squiggle-web nginx -t
docker exec squiggle-web nginx -s reload
```

Check the deployment and WASM content type with:

```sh
curl -I https://squiggle.ymit.dev/
curl -I https://squiggle.ymit.dev/sqlite3.wasm
```

The second response should include `Content-Type: application/wasm`.

## Take the site down

To stop serving the app, stop and remove its nginx container:

```sh
docker compose -f /home/dev/.t3/projects/squiggle-web/docker-compose.yml down
```

To also remove the public hostname route, edit `/home/dev/edge/Caddyfile` and
remove the `squiggle.ymit.dev` block, then validate and reload Caddy:

```sh
docker exec edge-caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
docker exec edge-caddy caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
```

The Compose project directory and deployed files are separate from the Git
checkout, so removing a checkout does not stop the deployed site. Removing the
service does not affect the shared `edge` network or other hosted apps.
