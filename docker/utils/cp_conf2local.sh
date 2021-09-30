#!/bin/bash

CONTAINERS=("cwow60_server" "cwow70_server" "cwow80_server")
VOLUME_CONF_PATH=$(pwd)/WoW/conf/

for CONTAINER in "${CONTAINERS[@]}"; do
  CORE=""
  if [[ "$CONTAINER" =~ "60" ]]; then
    CORE="60"
  elif [[ "$CONTAINER" =~ "70" ]]; then
    CORE="70"
  elif [[ "$CONTAINER" =~ "80" ]]; then
    CORE="80"
  fi
  ID=$(docker container ls -a -f name="^$CONTAINER" --format "{{.ID}}")
  if [ -n "$ID" ]; then
    echo "docker cp $ID:/etc/mangos/conf/ $VOLUME_CONF_PATH$CORE"
    docker cp "$ID:/etc/mangos/conf/" "$VOLUME_CONF_PATH$CORE"
  fi
done
