# Run on the server by deployer each time a release goes live. nginx keeps running across releases, so check and load
# the new config. A failure here sends the site back to the release that was live.
docker compose exec -T web nginx -t && docker compose exec -T web nginx -s reload
