#!/bin/bash
ip=`ping -c 1 ${wow_domain} | head -n1 | awk -F "(" '{print $2}' | awk -F ")" '{print $1}'`
if [ -n "${ip}" ]; then
	if [ -f "Data/wmo.MPQ" ]; then
    echo "set realmlist $ip:3760" > realmlist.wtf
	elif [ -f "Data/lichking.wmo" ]; then
	  echo "set realmlist $ip:3780" > Data/zhCN/realmlist.wtf
    echo "set realmlist $ip:3780" > Data/zhTW/realmlist.wtf
    echo "set realmlist $ip:3780" > Data/enUS/realmlist.wtf
	else
	  echo "set realmlist $ip:3770" > realmlist.wtf
	fi
  if [ -f "WoW.exe" ]; then
    wine WoW.exe
  elif [ -f "Wow.exe" ]; then
    wine Wow.exe
  fi
fi