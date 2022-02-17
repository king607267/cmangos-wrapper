#!/bin/bash
set -eo pipefail

function importDB() {
  #path see export_db.sh
  cd
  cd "dataBack/${1}/$(date '+%Y-%m-%d')"
  #get newest file name
  fileName=$(ls -t | head -1)
  #delete ADMINISTRATOR,GAMEMASTER,MODERATOR,PLAYER
  sed -i "s/INSERT INTO \`account\` VALUES /delete from \`account\` where username in ('ADMINISTRATOR','GAMEMASTER','MODERATOR','PLAYER');\nINSERT INTO \`account\` VALUES /" "$fileName"
  MYSQL_COMMAND="${2} -h${3} -P${4} -p${5} -u${6}"
  echo "use "${fileName}
  ${MYSQL_COMMAND} <"$fileName"
}
#change username,pwd,host,port
importDB '60' 'mysql' "127.0.0.1" "3360" "mangos" "mangos"
echo "import classic successful"
importDB '70' 'mysql' "127.0.0.1" "3370" "mangos" "mangos"
echo "import tbc successful"
importDB '80' 'mysql' "127.0.0.1" "3380" "mangos" "mangos"
echo "import wotlk successful"
