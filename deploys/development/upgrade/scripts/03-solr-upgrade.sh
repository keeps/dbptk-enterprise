#!/bin/bash

DOCKER_COMPOSE_PATH="$1"

if [ -z "$1" ]; then
  echo "Error: Missing docker compose path."
  echo "Syntax: $0 [docker_compose_path]"
  exit 1
fi

# Run the container in detached mode, mounting the solr-config volume
container_name=$(docker compose -f $DOCKER_COMPOSE_PATH run -d -v $(pwd)/../solr-config:/tmp/solr-config solr)

echo "Updating Solr configuration..."

# Execute the Solr configuration update command inside the container
docker exec "$container_name" bash -c "for config in \$(solr zk ls /configs -z localhost:9983 | tr -d '[],\"'); do solr zk upconfig -n \$config -d /tmp/solr-config/ -z localhost:9983; done"

echo "Solr configuration updated successfully."

echo "Stopping the Solr container..."
# Stop the container
docker stop "$container_name"

echo "Solr container stopped successfully."

echo "Removing the Solr container..."
# Remove the container
docker rm "$container_name"
echo "Solr container removed successfully."