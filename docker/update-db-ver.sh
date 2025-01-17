#!/bin/bash
MYSQL_HOST=$(echo "$LOGIN_DATABASE_INFO" | awk -F ";" '{print $1}')
MYSQL_PORT=$(echo "$LOGIN_DATABASE_INFO" | awk -F ";" '{print $2}')
MYSQL_USER=$(echo "$LOGIN_DATABASE_INFO" | awk -F ";" '{print $3}')
MYSQL_PASSWORD=$(echo "$LOGIN_DATABASE_INFO" | awk -F ";" '{print $4}')

MYSQL_COMMAND="mysql -h${MYSQL_HOST} -P${MYSQL_PORT} -p${MYSQL_PASSWORD} -u${MYSQL_USER}"
until mysql -h$MYSQL_HOST -P${MYSQL_PORT:-3306} -u$MYSQL_USER -p$MYSQL_PASSWORD -e "USE ${CMANGOS_CORE}logs; DESCRIBE logs_db_version;USE ${CMANGOS_CORE}realmd; DESCRIBE realmd_db_version;USE ${CMANGOS_CORE}mangos; DESCRIBE db_version;"; do
  >&2 echo "MySQL is unavailable - sleeping-15s"
  sleep 15
done

REPO_DIR="/etc/mangos/updates-sql"
mkdir -p $REPO_DIR && chmod 755 $REPO_DIR && tar -m --no-overwrite-dir -xzf /etc/mangos/updates-sql.tar.gz -C $REPO_DIR

function doUpdate() {
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

function updateDB() {
  TABLE=""
  DATABASE=""
  if [ "$TARGET" == "mangosd" ]; then
    cd ${REPO_DIR}/mangos
    TABLE="db_version"
    DATABASE="${CMANGOS_CORE}mangos"
    doUpdate
    cd ${REPO_DIR}/characters
    TABLE="character_db_version"
    DATABASE="${CMANGOS_CORE}characters"
    doUpdate
    cd ${REPO_DIR}/logs
    TABLE="logs_db_version"
    DATABASE="${CMANGOS_CORE}logs"
    doUpdate
  else
    cd ${REPO_DIR}/realmd
    TABLE="realmd_db_version"
    DATABASE="${CMANGOS_CORE}realmd"
    doUpdate
  fi
}
updateDB