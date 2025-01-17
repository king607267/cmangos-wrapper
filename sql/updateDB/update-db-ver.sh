#!/bin/bash

DB_HOST="127.0.0.1"
DB_PORT="3380"
USERNAME="mangos"
PASSWORD="mangos"
MYSQL="mysql"
CMANGOS_CORE="wotlk"

REPO_DIR="${CMANGOS_CORE}_core"

cd /tmp
if [ ! -d ${REPO_DIR} ]; then
  git clone https://github.com/cmangos/mangos-${CMANGOS_CORE}.git ${REPO_DIR} -b master --recursive --depth=1 && cd ${REPO_DIR}
else
  cd ${REPO_DIR} && git pull
fi

MYSQL_COMMAND="${MYSQL} -h${DB_HOST} -P${DB_PORT} -p${PASSWORD} -u${USERNAME}"

function exec() {
  TABLE=""
  DATABASE=""
  if [ "$1" = "mangos" ]; then
    cd /tmp/${REPO_DIR}/sql/updates/mangos
    TABLE="db_version"
    DATABASE="${CMANGOS_CORE}mangos"
  elif [ "$1" = "realmd" ]; then
    cd /tmp/${REPO_DIR}/sql/updates/realmd
    TABLE="realmd_db_version"
    DATABASE="${CMANGOS_CORE}realmd"
  elif [ "$1" = "characters" ]; then
    cd /tmp/${REPO_DIR}/sql/updates/characters
    TABLE="character_db_version"
    DATABASE="${CMANGOS_CORE}characters"
  elif [ "$1" = "characters" ]; then
    cd /tmp/${REPO_DIR}/sql/updates/logs
    TABLE="logs_db_version"
    DATABASE="${CMANGOS_CORE}logs"
  fi

  NUM=0
  SQLs=()
  for sql_file in $(ls *.sql -r); do
    value=$(${MYSQL_COMMAND} ${DATABASE} -s -e "SELECT required_${sql_file%.*} FROM ${TABLE} LIMIT 1")
    if [ "${value}" = "NULL" ]; then
      echo "current ${DATABASE} db version:"${sql_file%.*}"."
      break
    else
      NUM=$(expr $NUM + 1)
      SQLs[$NUM]=${sql_file}
    fi
  done
  if [ ${NUM} = 0 ]; then
    echo "db "${DATABASE} "are up-to-date."
  fi
  for i in $(seq $NUM -1 1); do
    echo "exec update ${DATABASE} "${SQLs[i]}
    ${MYSQL_COMMAND} ${DATABASE} <${SQLs[i]}
  done
}

exec mangos
exec realmd
exec characters
