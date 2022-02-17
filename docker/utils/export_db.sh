#!/bin/bash

#only export characters realmd
function exportDB() {
  cd
  path="dataBack/$1"
  if [ ! -d "$path" ]; then
    /bin/mkdir -p $path && cd $path
  else
    cd $path
  fi
  day=$(date '+%Y-%m-%d')
  if [ ! -d "$day" ]; then
    /bin/mkdir -p $day && cd $day
  else
    cd $day
  fi
  fileName=""
  if [ "$1" = "60" ]; then
    fileName="WoWDBback60_$(date '+%H%M').sql"
    #change username,pwd,host,port
    mysqldump --no-tablespaces -t -umangos -pmangos -P3360 -h127.0.0.1 --databases classiccharacters classicrealmd --ignore-table=classicrealmd.antispam_blacklist --ignore-table=classicrealmd.antispam_replacement --ignore-table=classicrealmd.antispam_unicode_replacement --ignore-table=classicrealmd.realmlist >"$fileName"
  elif [ "$1" = "70" ]; then
    fileName="WoWDBback70_$(date '+%H%M').sql"
    #change username,pwd,host,port
    mysqldump --no-tablespaces -t -umangos -pmangos -P3370 -h127.0.0.1 --databases tbccharacters tbcrealmd --ignore-table=tbcrealmd.antispam_blacklist --ignore-table=tbcrealmd.antispam_replacement --ignore-table=tbcrealmd.antispam_unicode_replacement --ignore-table=tbcrealmd.realmlist >"$fileName"
  elif [ "$1" = "80" ]; then
    fileName="WoWDBback80_$(date '+%H%M').sql"
    #change username,pwd,host,port
    mysqldump --no-tablespaces -t -umangos -pmangos -P3380 -h127.0.0.1 --databases wotlkcharacters --ignore-table=wotlkcharacters.playerbot_talentspec wotlkrealmd --ignore-table=wotlkrealmd.realmlist --ignore-table=wotlkrealmd.antispam_blacklist --ignore-table=wotlkrealmd.antispam_replacement --ignore-table=wotlkrealmd.antispam_unicode_replacement >"$fileName"
  fi
}
exportDB '60'
exportDB '70'
exportDB '80'
