#!/bin/bash
. /home/oracle/.setEnv
. /home/oracle/.db
########################## MYDB #######################################
export ORACLE_SID=mydb
echo '************************************'>/home/oracle/hc/hc_mydb.log
echo $(date "+%Y/%m/%d %H:%M:%S") : Baslama Zamani>>/home/oracle/hc/hc_mydb.log
rm -rf /home/oracle/hc/hcmydb.html
sqlplus / as sysdba  @/home/oracle/hc/hcmydb.sql > /dev/null
if
        test -s /home/oracle/hc/hcmydb.html
then
        echo "Mydb Veritabani health check raporu " | mail -a "/home/oracle/hc/hcmydb.html" -s          "MyDB Veritabani health check raporu " y.farukcevik@gmail.com     
        echo $(date "+%Y/%m/%d %H:%M:%S") : Gonderildi>>/home/oracle/hc/hc_mydb.log
else
        echo $(date "+%Y/%m/%d %H:%M:%S") : Gonderecek bisey yok>>/home/oracle/hc/hc_mydb.log
fi
echo $(date "+%Y/%m/%d %H:%M:%S") : Bitis Zamani>>/home/oracle/hc/hc_mydb.log
