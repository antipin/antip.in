#!/bin/sh
# No absolute links to the site itself: links and assets must be relative (/about), so the site behaves the same on
# any host (locally https://<name>.test). Standards that need absolute URLs (<link rel=canonical/alternate/prev/next>,
# <meta property=og:...>, sitemap.xml, feeds, robots.txt) are exempt: they aren't checked here.
#
#   tests/test-self-links.sh <built site dir> <domain>
#
# POSIX sh with find and grep only: `make test` runs it inside the site's nginx container, where the build is mounted,
# so it works the same locally (where a build can live in a Docker volume) and on CI.
set -eu
dir=$1
domain=$(printf '%s' "$2" | sed 's/\./\\./g')
self="https?://(www\.)?$domain([/\"' ?#]|$)"

html=$(find "$dir" -name '*.html' -exec grep -HoE "<(a|img|script|iframe|source|form|video|audio|embed|object|area) [^>]*(href|src|srcset|action|data|poster)=[\"']?$self" {} + 2>/dev/null || true)
css=$(find "$dir" -name '*.css' -exec grep -HoE "url\([\"']?$self" {} + 2>/dev/null || true)
found=$(printf '%s\n%s\n' "$html" "$css" | grep -c . || true)

if [ "$found" -eq 0 ]; then
  echo "no absolute links to $2: ok"
else
  echo "FAIL: $found absolute links to $2 (make them relative):"
  printf '%s\n%s\n' "$html" "$css" | grep . | sed "s|^$dir/||" | head -20
  exit 1
fi
