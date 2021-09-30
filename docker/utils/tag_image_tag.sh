#!/bin/bash

for key in $(docker images --format "{{.Repository}}:{{.Tag}}" --filter=reference="king607267/*"); do
  REPO=${key%:*}
  if [ "${key#*:}" == "latest" ]; then
    continue
  fi
  echo "docker tag $key to ${REPO}:latest"
  docker tag "$key" "$REPO":latest
done
