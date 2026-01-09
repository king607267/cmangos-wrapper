@echo off
setlocal

for /f "tokens=2 delims=[]" %%i in ('ping -n 1 %wow_domain%^| find "["') do set ip=%%i

if not defined ip (
    echo network is unreachable
    pause
) else (
    if exist "Data\wmo.MPQ" (  
        echo set realmlist %ip%:3760 > realmlist.wtf  
    ) else ( 
       if exist "Data\lichking.MPQ" (
           echo set realmlist %ip%:3780 > Data\zhCN\realmlist.wtf
           echo set realmlist %ip%:3780 > Data\zhTW\realmlist.wtf
           echo set realmlist %ip%:3780 > Data\enUS\realmlist.wtf
       ) else (
           echo set realmlist %ip%:3770 > realmlist.wtf   
       )
    )
)

start WoW.exe

endlocal
