antip.in
========

Source code of [antip.in](https://antip.in) website: a personal page, built with [Hugo](https://gohugo.io/). For now
it is a placeholder.

| Path | What it is |
|---|---|
| `content/` | The pages, as Markdown |
| `src/layouts/`, `src/assets/`, `src/static/` | Templates, the stylesheet, files served as they are |
| `src/nginx.conf` | The one nginx config, in production and locally |
| `compose.yml` | How the site runs on the server, behind the shared edge (`../edge`) |
| `compose.local.yml` | Local: https://antip.test, 127.0.0.1:8095 for the tests, and the pinned Hugo |
| `compose.ci.yml` | CI: leaves out the edge |
| `tests/` | Smoke test, and the check that no link points to antip.in absolutely |

## Run locally

With the shared edge running locally (`../edge`, see its README, Local):

```sh
make build start   # the site at https://antip.test, in its production container
make test
make dev           # for writing: Hugo's live-reload server on http://127.0.0.1:1315 (needs Hugo installed)
make stop
```

`make help` lists the commands. They are the same in every site (the edge's README, Project standard). `make build`
runs the same pinned Hugo as CI, in a container.

Links and assets are relative (`/`), never `https://antip.in/...`: `make test` fails on any absolute link to the site
itself. Only the canonical link, the sitemap and `robots.txt` are absolute, from `baseURL`.

## Publish

Not live yet: the workflow only builds and tests. To deploy, follow deployer's "Add a site" (an inventory entry,
deploy access, and a deploy job running `antipin/deployer` with `files: public src/nginx.conf compose.yml
deploy/on-activate.sh`), then its "Go live" steps for DNS.
