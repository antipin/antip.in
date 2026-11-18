#!/usr/bin/env python3
"""A quick check that a running site answers: the home page, its files, and the 404 page.

Usage (from the repo root, with `make start` running; or against the real site after a deploy):
  tests/test-smoke.py [--base https://antip.in]

Exits 1 if any case fails.
"""
import argparse
import re
import sys
import urllib.error
import urllib.request


def fetch(url):
    request = urllib.request.Request(url, headers={'User-Agent': 'antipin-smoke-test'})
    try:
        response = urllib.request.urlopen(request, timeout=20)
    except urllib.error.HTTPError as e:
        response = e
    return response.status, response.headers.get('Content-Type', ''), response.read().decode('utf-8', 'replace')


def check(base, path, status, content_type, text):
    got_status, got_type, body = fetch(base + path)
    if got_status != status:
        return f'answers {got_status}'
    if not got_type.startswith(content_type):
        return f'Content-Type {got_type}'
    if not body:
        return 'empty body'
    if text and text not in body:
        return f'no "{text}"'
    return ''


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--base', default='http://127.0.0.1:8095')
    args = ap.parse_args()
    base = args.base.rstrip('/')

    # The stylesheet's name has a hash in it: take it from the home page.
    try:
        css = re.search(r'<link rel=stylesheet href=(/css/[^ >]+)', fetch(base + '/')[2])
    except OSError:
        css = None
    cases = [
        ('home page', '/', 200, 'text/html', 'Alexander Antipin'),
        ('stylesheet', css.group(1) if css else '/css/(not linked)', 200, 'text/css', None),
        ('icon', '/favicon.svg', 200, 'image/svg+xml', None),
        ('robots', '/robots.txt', 200, 'text/plain', 'Sitemap: https://antip.in/sitemap.xml'),
        ('sitemap', '/sitemap.xml', 200, 'text/xml', '<urlset'),
        ('missing page', '/no-such-page', 404, 'text/html', 'Page not found'),
    ]
    failed = 0
    for what, path, *expected in cases:
        try:
            problem = check(base, path, *expected)
        except OSError as e:
            problem = str(e)
        failed += bool(problem)
        print(f'{"FAIL" if problem else "ok":5}{what:16}{path}{"  " + problem if problem else ""}')
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main()
