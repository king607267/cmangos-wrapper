#!/bin/bash
while true; do
  if [ `tail -50 /etc/mangos/${1}.log | grep -E 'SQL ERROR:|ERROR:SQL' | wc -l` -gt 0 ]; then
      echo "db query error kill ${1}" >> "${1}".log
      kill 1
  fi
  sleep 300
done