#!/bin/bash
./update-db-ver.sh
sed -i "s/^LoginDatabaseInfo     =.*$/LoginDatabaseInfo     = $LOGIN_DATABASE_INFO/" /etc/mangos/conf/mangosd.conf
sed -i "s/^WorldDatabaseInfo     =.*$/WorldDatabaseInfo     = $WORLD_DATABASE_INFO/" /etc/mangos/conf/mangosd.conf
sed -i "s/^CharacterDatabaseInfo =.*$/CharacterDatabaseInfo = $CHARACTER_DATABASE_INFO/" /etc/mangos/conf/mangosd.conf
sed -i "s/^LogsDatabaseInfo      =.*$/LogsDatabaseInfo      = $LOGS_DATABASE_INFO/" /etc/mangos/conf/mangosd.conf
tar -m --no-overwrite-dir -xzf /etc/mangos/bin/mangosd.tar.gz -C /etc/mangos/bin && rm /etc/mangos/bin/mangosd.tar.gz
exec /etc/mangos/bin/mangosd -c /etc/mangos/conf/mangosd.conf -a /etc/mangos/conf/ahbot.conf