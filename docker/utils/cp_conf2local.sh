#!/bin/bash

CONTAINERS=("cwow60-server-1" "cwow70-server-1" "cwow80-server-1")
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
    mkdir -p $VOLUME_CONF_PATH$CORE
    echo "docker cp $ID:/etc/mangos/conf/ $VOLUME_CONF_PATH$CORE"
    docker cp "$ID:/etc/mangos/conf/" "$VOLUME_CONF_PATH$CORE"
  fi
done
