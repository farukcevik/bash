export ORACLE_BASE=/u01/app/oracle
export GRID_HOME=/u01/app/19.0.0.0/grid
export DB_HOME=$ORACLE_BASE/product/19.0.0.0/db
export ORACLE_HOME=$DB_HOME
export ORACLE_SID=REPDB1
export ORACLE_TERM=xterm
export OGG_HOME=/u02/ogg/oggtrg
export BASE_PATH=/usr/sbin:$PATH
export JAVA_HOME=/u02/java/jdk1.8.0_29
export PATH=$ORACLE_HOME/bin:$OGG_HOME:$JAVA_HOME/bin:$BASE_PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
DBA_EMAIL=fcevik@innova.com.tr


logpath="/tmp"
cd $logpath
logfile="$logpath/output_lag.txt"

# Output GG information to log file
echo 'INFO ALL' | /u02/ogg/oggtrg/ggsci > $logfile

cat $logfile | egrep 'MANAGER|EXTRACT|REPLICAT'| tr ":" " " | while read LINE
do
 case $LINE in
*)
       PROCESS_TYPE=$(echo $LINE | awk -F" " '{print $1}')
       PROCESS_STATUS=$(echo $LINE | awk -F" " '{print $2}')
      PROCESS_NAME=$(echo $LINE | awk -F" " '{print $3}')
     LAG_HH=$(echo $LINE | awk -F" " '{print $4}')
       LAG_MM=$(echo $LINE | awk -F" " '{print $5}')
      LAG_SS=$(echo $LINE | awk -F" " '{print $6}')
        MES_BODY="A-)"
         let "lag_sec=LAG_SS+1"
        let "lag_min=LAG_MM+1"
        let "lag_hou=LAG_HH+1"
if [ "$PROCESS_STATUS" != "RUNNING" ]
    then
           mail -s "GoldenGate Process Not RUNNING on for database $ORACLE_SID" $DBA_EMAIL
        else
                if [[ $lag_hou -gt 1 ]] ||  [[ $lag_min -ge 5 ]]
        then
         $MES_BODY+='ALERT ... Goldengate process $PROCESS_TYPE($PROCESS_NAME)  has a lag of "$LAG_HH" hour "$LAG_MM" min on ($ORACLE_SID) \n'
            cat $logfile | mail -s "ALERT ... Goldengate process \"$PROCESS_TYPE($PROCESS_NAME)\" has a lag of "$LAG_HH" hour "$LAG_MM" min on `uname -n`($ORACLE_SID)" $DBA_EMAIL
           fi
      fi
   esac
done
