#!/bin/bash
./update-db-ver.sh
sed -i "s/^LoginDatabaseInfo =.*$/LoginDatabaseInfo = $LOGIN_DATABASE_INFO/" /etc/mangos/conf/realmd.conf
./kill-server.sh Realmd & exec /etc/mangos/bin/realmd -c /etc/mangos/conf/realmd.conf