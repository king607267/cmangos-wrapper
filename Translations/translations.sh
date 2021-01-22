#!/bin/bash

CONFIG_FILE="translations.config"
DB_HOST="localhost"
DB_PORT="3306"
DATABASE="classicmangos"
USERNAME="mangos"
PASSWORD="mangos"
MYSQL="mysql"
CMANGOS_CORE="classic"

if [ ! -f ${CONFIG_FILE} ]; then
  echo "${CONFIG_FILE} not found."
  exit 1
fi

. ${CONFIG_FILE}

if [ "${CMANGOS_CORE}" = "classic" ]; then
  CMANGOS_CORE=zero
elif [ "${CMANGOS_CORE}" = "tbc" ]; then
  CMANGOS_CORE=one
elif [ "${CMANGOS_CORE}" = "wotlk" ]; then
  CMANGOS_CORE=two
fi

cd /tmp

if [ ! -d translations_${CMANGOS_CORE} ]; then
  git clone https://github.com/MangosExtras/Mangos${CMANGOS_CORE}_Localised.git translations_${CMANGOS_CORE} -b master --recursive --depth=1 && cd translations_${CMANGOS_CORE}
else
  cd translations_${CMANGOS_CORE} && git pull
fi

export MYSQL_PWD="${PASSWORD}"
MYSQL_COMMAND="${MYSQL} -h${DB_HOST} -P${DB_PORT} -u${USERNAME} ${DATABASE}"

echo "> Processing 1_LocaleTablePrepare.sql,2_Add_NewLocalisationFields.sql,3_InitialSaveEnglish.sql."
if [ -f 1+2+3.sql ]; then
  rm 1+2+3.sql
fi
cat 1_LocaleTablePrepare.sql >>1+2+3.sql
echo -e >>1+2+3.sql
cat 2_Add_NewLocalisationFields.sql >>1+2+3.sql
echo -e >>1+2+3.sql
cat 3_InitialSaveEnglish.sql >>1+2+3.sql
#注释locales_command相关sql
sed -i 's/^INSERT.*\(command\).*$/-- &/' 1+2+3.sql
sed -i '/^        ALTER.*\(command\).*/,/;$/s/^/-- &/' 1+2+3.sql
sed -i '/^UPDATE.*\(command\).*/,/;$/s/^/-- &/' 1+2+3.sql
#替换表名
sed -i 's/db_script/dbscript/' 1+2+3.sql
${MYSQL_COMMAND} <1+2+3.sql

cd Translations/${TRANSLATIONS}

echo "> Processing Translations SQL."
if [ -f full.sql ]; then
  rm full.sql
fi
cat *.sql >full.sql
sed -i 's/db_script/dbscript/' full.sql
${MYSQL_COMMAND} <full.sql
echo "Translations end."
echo
