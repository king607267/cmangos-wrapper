#!/bin/bash
set -eo pipefail
if [ -f "/var/lib/mysql/allReady" ]; then
  rm /var/lib/mysql/allReady
fi
export CMANGOS_CORE=classic
export REALM_IP=${CLASSIC_REALM_IP}
export REALM_PORT=${CLASSIC_REALM_PORT}
export REALM_NAME=${CLASSIC_REALM_NAME}
./launch-mysql/launch-mysql.sh
export CMANGOS_CORE=tbc
export REALM_IP=${TBC_REALM_IP}
export REALM_PORT=${TBC_REALM_PORT}
export REALM_NAME=${TBC_REALM_NAME}
./launch-mysql/launch-mysql.sh
export CMANGOS_CORE=wotlk
export REALM_IP=${WOTLK_REALM_IP}
export REALM_PORT=${WOTLK_REALM_PORT}
export REALM_NAME=${WOTLK_REALM_NAME}
./launch-mysql/launch-mysql.sh
touch /var/lib/mysql/allReady #for readinessProbe