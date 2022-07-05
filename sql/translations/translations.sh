#!/bin/bash
set -eo pipefail

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

cd /tmp

if [ -f "BroadcastTextLocales.sql" ]; then
  rm BroadcastTextLocales.sql
fi
if [ "${CMANGOS_CORE}" = "classic" ]; then
  echo "classic use tbc BroadcastTextLocales."
  CMANGOS_CORE="zero"
  wget --no-check-certificate https://raw.githubusercontent.com/cmangos/tbc-db/master/locales/BroadcastTextLocales.sql
elif [ "${CMANGOS_CORE}" = "tbc" ]; then
  wget --no-check-certificate https://raw.githubusercontent.com/cmangos/tbc-db/master/locales/BroadcastTextLocales.sql
  CMANGOS_CORE="one"
elif [ "${CMANGOS_CORE}" = "wotlk" ]; then
  wget --no-check-certificate https://raw.githubusercontent.com/cmangos/wotlk-db/master/locales/BroadcastTextLocales.sql
  CMANGOS_CORE="two"
fi

export MYSQL_PWD="${PASSWORD}"
MYSQL_COMMAND="${MYSQL} -h${DB_HOST} -P${DB_PORT} -u${USERNAME} ${DATABASE}"
#TODO 验证用户名密码

LOCALE=""
if [ "${TRANSLATIONS}" = "German" ]; then
  LOCALE="deDE"
elif [ "${TRANSLATIONS}" = "Spanish" ]; then
  LOCALE="esES"
elif [ "${TRANSLATIONS}" = "Spanish_South_American" ]; then
  LOCALE="esMX"
elif [ "${TRANSLATIONS}" = "French" ]; then
  LOCALE="frFR"
elif [ "${TRANSLATIONS}" = "Korean" ]; then
  LOCALE="koKR"
elif [ "${TRANSLATIONS}" = "Russian" ]; then
  LOCALE="ruRU"
elif [ "${TRANSLATIONS}" = "Taiwanese" ]; then
  LOCALE="zhTW"
elif [ "${TRANSLATIONS}" = "Italian" ]; then
  LOCALE="itIT"
else
  LOCALE="zhCN"
fi

echo "> Processing BroadcastTextLocales.sql."
cp -f BroadcastTextLocales.sql BroadcastTextLocales_bak.sql
sed -i "s/),(/);\nINSERT INTO \`broadcast_text_locale\` VALUES (/g" BroadcastTextLocales_bak.sql
cat BroadcastTextLocales_bak.sql | grep -E "${LOCALE}|/\*|SET CHARACTER|SET NAMES|RUNCATE TABLE|LOCK TABLES|UNLOCK TABLES" >>BroadcastTextLocales_temp.sql
${MYSQL_COMMAND} <BroadcastTextLocales_temp.sql
rm BroadcastTextLocales*.sql

if [ ! -d translations_${CMANGOS_CORE} ]; then
  git clone https://github.com/MangosExtras/Mangos${CMANGOS_CORE}_Localised.git translations_${CMANGOS_CORE} -b master --recursive --depth=1 && cd translations_${CMANGOS_CORE}
else
  cd translations_${CMANGOS_CORE} && git pull
fi

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

#https://github.com/cmangos/issues/issues/2331
#注释creature_ai_texts,dbscript_string相关sql
sed -i 's/^INSERT.*\(creature_ai_texts\).*$/-- &/' 1+2+3.sql
sed -i '/^        ALTER.*\(creature_ai_texts\).*/,/;$/s/^/-- &/' 1+2+3.sql
sed -i '/^UPDATE.*\(creature_ai_texts\).*/,/;$/s/^/-- &/' 1+2+3.sql

sed -i 's/^INSERT.*\(dbscript_string\).*$/-- &/' 1+2+3.sql
sed -i '/^        ALTER.*\(dbscript_string\).*/,/;$/s/^/-- &/' 1+2+3.sql
sed -i '/^UPDATE.*\(dbscript_string\).*/,/;$/s/^/-- &/' 1+2+3.sql

${MYSQL_COMMAND} <1+2+3.sql

cd Translations/${TRANSLATIONS}

echo "> Processing Translations SQL."
if [ -f full.sql ]; then
  rm full.sql
fi
#https://github.com/cmangos/issues/issues/2331
cat $(ls -I "Chinese_CommandHelp.sql" -I "*db_script_string.sql" -I "*Creature_AI_Texts.sql" -I "*creature_ai_texts.sql" | grep ".*\.sql") >full.sql
sed -i 's/db_script/dbscript/' full.sql
${MYSQL_COMMAND} <full.sql
echo "Translations end."
echo
