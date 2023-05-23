# Oracle GOldengate 23C MA Architecture adminclient LAG and Abend fallow script
source /home/ogg/.bash_profile
LONG_SYSTEM_NAME=$(hostname -f)
SHORT_SYSTEM_NAME=$(hostname -a)
IP=$(hostname -i)
TO_MAIL_GRUBU="info@farukcevik.com.tr"
FROM_MAIL_GRUBU="goldengate@farukcevik.com.tr"
SMTP_SERVER="relay.farukcevik.com.tr"
SMTP_USER=""
SMTP_PASS=""
DBA_EMAIL=faruk.cevik@partner.turktelekom.com.tr
export GG_HOSTNAME=goldeng
logpath="/tmp"
logfile="$logpath/output_lag.txt"
BASE_DIRECTORY="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Output GG information to log file
#echo 'INFO ALL' | /u02/ogg/oggtrg/ggsci > $logfile

echo "connect https://localhost:7889 deployment MAGG1 as oggadmin Password Wwelcome#123 !
info all
" | adminclient > $logfile



cat $logfile | egrep 'ADMINSRVR|DISTSRVR|PMSRVR|RECVSRVR|EXTRACT|REPLICAT'| tr ":" " " | while read LINE
do
 case $LINE in
*)
       PROCESS_TYPE=$(echo $LINE | awk -F" " '{print $1}')
       PROCESS_STATUS=$(echo $LINE | awk -F" " '{print $2}')
       PROCESS_NAME=$(echo $LINE | awk -F" " '{print $3}')
       LAG_HH=$(echo $LINE | awk -F" " '{print $4}')
       LAG_MM=$(echo $LINE | awk -F" " '{print $5}')
       LAG_SS=$(echo $LINE | awk -F" " '{print $6}')
        let "lag_sec=LAG_SS+1"
        let "lag_min=LAG_MM+1"
        let "lag_hou=LAG_HH+1"
if [ "$PROCESS_STATUS" != "RUNNING" ]
    then
                $BASE_DIRECTORY/sendEmail -t $TO_MAIL_GRUBU -f $FROM_MAIL_GRUBU -s $SMTP_SERVER -u "KONTROL ET! GG PROCESS NOT RUNING!" -m "goldengate process not running for  $LONG_SYSTEM_NAME
 Process Type $PROCESS_TYPE  Process Name $PROCESS_NAME"
        else
                if [[ $lag_hou -gt 1 ]] ||  [[ $lag_min -ge 5 ]]
        then
         $MES_BODY+="ALERT ... Goldengate process $PROCESS_TYPE($PROCESS_NAME)  has a lag of "$LAG_HH" hour "$LAG_MM" min on ($SHORT_SYSTEM_NAME) \n"
         $BASE_DIRECTORY/sendEmail -t $TO_MAIL_GRUBU -f $FROM_MAIL_GRUBU -s $SMTP_SERVER -u "LAG VAR! - $SISTEM_ADI -  LAG VAR!" -m "ALERT ... Goldengate process \"$PROCESS_TYPE($PROCESS_NAME)\" has a lag of "$LAG_HH" hour "$LAG_MM" min on `uname -n`  $MES_BODY"
           fi
      fi
   esac
done
