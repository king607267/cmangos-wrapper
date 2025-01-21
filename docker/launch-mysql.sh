#!/bin/bash
mysql=(mysql -uroot -hlocalhost)
if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
  mysql+=(-p"${MYSQL_ROOT_PASSWORD}")
fi
if [ -f "/var/lib/mysql/ready" ]; then
  rm /var/lib/mysql/ready #for k8s readinessProbe
fi
echo "WOW DATABASE CREATION..."
  CMANGOS_WORLD_DB=classicmangos
  CMANGOS_CHARACTER_DB=classiccharacters
  CMANGOS_REALMD_DB=classicrealmd
  CMANGOS_LOGS_DB=classiclogs
  CMANGOS_SERVER_PATH=mangos-classic
  CMANGOS_DB_FILE_PATH=classic-db
if [ "$CMANGOS_CORE" = "tbc" ]; then
  CMANGOS_WORLD_DB=tbcmangos
  CMANGOS_CHARACTER_DB=tbccharacters
  CMANGOS_REALMD_DB=tbcrealmd
  CMANGOS_LOGS_DB=tbclogs
  CMANGOS_SERVER_PATH=mangos-tbc
  CMANGOS_DB_FILE_PATH=tbc-db
elif [ "$CMANGOS_CORE" = "wotlk" ]; then
  CMANGOS_WORLD_DB=wotlkmangos
  CMANGOS_CHARACTER_DB=wotlkcharacters
  CMANGOS_REALMD_DB=wotlkrealmd
  CMANGOS_LOGS_DB=wotlklogs
  CMANGOS_SERVER_PATH=mangos-wotlk
  CMANGOS_DB_FILE_PATH=wotlk-db
fi
tar -m --no-overwrite-dir -xzf "${CMANGOS_SERVER_PATH}".tar.gz
tar -m --no-overwrite-dir -xzf "${CMANGOS_DB_FILE_PATH}".tar.gz
echo "CREATE DATABASE \`${CMANGOS_WORLD_DB}\` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci ;" | "${mysql[@]}"
echo "CREATE DATABASE \`${CMANGOS_CHARACTER_DB}\` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci ;" | "${mysql[@]}"
echo "CREATE DATABASE \`${CMANGOS_REALMD_DB}\` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci ;" | "${mysql[@]}"
echo "CREATE DATABASE \`${CMANGOS_LOGS_DB}\` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci ;" | "${mysql[@]}"

"${mysql[@]}" -D${CMANGOS_WORLD_DB} <"${CMANGOS_SERVER_PATH}"/sql/base/mangos.sql
echo "WORLD DATABASE CREATED."

echo "CHARACTER DATABASE CREATION..."
"${mysql[@]}" -D${CMANGOS_CHARACTER_DB} <"${CMANGOS_SERVER_PATH}"/sql/base/characters.sql
echo "CHARACTER DATABASE CREATED."

echo "REALM DATABASE CREATION..."
"${mysql[@]}" -D${CMANGOS_REALMD_DB} <"${CMANGOS_SERVER_PATH}"/sql/base/realmd.sql
echo "REALM DATABASE CREATED."

echo "LOGS DATABASE CREATION..."
"${mysql[@]}" -D${CMANGOS_LOGS_DB} <"${CMANGOS_SERVER_PATH}"/sql/base/logs.sql
echo "LOGS DATABASE CREATED."

echo "GRANT ALL DATABASES TO $MYSQL_USER ."
if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
  #echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;" | "${mysql[@]}"
  echo "GRANT ALL ON \`${CMANGOS_WORLD_DB}\`.* TO '$MYSQL_USER'@'%' ;" | "${mysql[@]}"
  echo "GRANT ALL ON \`${CMANGOS_CHARACTER_DB}\`.* TO '$MYSQL_USER'@'%' ;" | "${mysql[@]}"
  echo "GRANT ALL ON \`${CMANGOS_REALMD_DB}\`.* TO '$MYSQL_USER'@'%' ;" | "${mysql[@]}"
  echo "GRANT ALL ON \`${CMANGOS_LOGS_DB}\`.* TO '$MYSQL_USER'@'%' ;" | "${mysql[@]}"

  echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
fi

echo "GRANT OK ."

cd ${CMANGOS_DB_FILE_PATH}
sed -i "s/^USERNAME=.*$/USERNAME=\"$MYSQL_USER\"/g" InstallFullDB.sh
sed -i "s/^PASSWORD=.*$/PASSWORD=\"$MYSQL_PASSWORD\"/g" InstallFullDB.sh
sed -i "s/^CORE_PATH=\"\"/CORE_PATH=\"\/docker-entrypoint-initdb.d\/${CMANGOS_SERVER_PATH}\"/" InstallFullDB.sh

echo "DB_HOST=\"localhost\"" >>InstallFullDB.config
echo "DB_PORT=\"3306\"" >>InstallFullDB.config
echo "DATABASE="${CMANGOS_WORLD_DB}"" >>InstallFullDB.config
echo "USERNAME="$MYSQL_USER"" >>InstallFullDB.config
echo "PASSWORD="$MYSQL_PASSWORD"" >>InstallFullDB.config
echo "CORE_PATH=\"/docker-entrypoint-initdb.d/"${CMANGOS_SERVER_PATH}"\"" >>InstallFullDB.config
echo "MYSQL=\"mysql\"" >>InstallFullDB.config
echo "FORCE_WAIT=\"YES\"" >>InstallFullDB.config
echo "AHBOT=\"NO\"" >>InstallFullDB.config

./InstallFullDB.sh

if [ "$REALM_IP" != "127.0.0.1" ]; then
  echo "UPDATE ${CMANGOS_REALMD_DB}.realmlist SET ADDRESS='${REALM_IP}' WHERE ID=1;" | "${mysql[@]}"
  echo "UPDATED REALM IP: ${REALM_IP}"
fi

if [ "$REALM_PORT" != "8085" ]; then
  echo "UPDATE ${CMANGOS_REALMD_DB}.realmlist SET PORT='${REALM_PORT}' WHERE ID=1;" | "${mysql[@]}"
  echo "UPDATED REALM PORT: ${REALM_PORT}"
fi

if [ "$REALM_NAME" != "MaNGOS" ]; then
  echo "SET NAMES utf8;UPDATE ${CMANGOS_REALMD_DB}.realmlist SET NAME='${REALM_NAME}' WHERE ID=1;" | "${mysql[@]}"
  echo "UPDATED REALM NAME: ${REALM_NAME}"
fi
echo "WOW DATABASE CREATED..."
cd /docker-entrypoint-initdb.d
if [ -f "translations-db-${CMANGOS_CORE}.tar.gz" ]&&[ -n "${I18N}" ]; then
  echo "START TRANSLATIONS DB ${I18N}."
  tar -m --no-overwrite-dir -xzf "translations-db-${CMANGOS_CORE}".tar.gz
  "${mysql[@]}" -D${CMANGOS_WORLD_DB} < translations-db-"${CMANGOS_CORE}"/"${I18N}"/BroadcastTextLocales*.sql
  "${mysql[@]}" -D${CMANGOS_WORLD_DB} < translations-db-"${CMANGOS_CORE}"/"${I18N}"/1+2+3*.sql
  "${mysql[@]}" -D${CMANGOS_WORLD_DB} < translations-db-"${CMANGOS_CORE}"/"${I18N}"/full*.sql
  echo "END TRANSLATIONS DB ."
fi
if [ -n "${CUSTOM_SQL_URL}" ]; then
  echo "Trying to customSql."
  curl -L -o "${CMANGOS_CORE}-db"/"${CMANGOS_CORE}".sql "${CUSTOM_SQL_URL}"/"${CMANGOS_CORE}".sql
  "${mysql[@]}" < "${CMANGOS_CORE}-db"/"${CMANGOS_CORE}".sql
  echo "END customSql."
fi
echo "USE ${CMANGOS_CORE}realmd;CREATE TABLE IF NOT EXISTS db_ready(id int); ;" | "${mysql[@]}" #for k8s readinessProbe
touch /var/lib/mysql/ready #for k8s readinessProbe Delete in the future
echo "COMPLETED."
echo