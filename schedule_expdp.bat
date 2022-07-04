D:
cd D:\oracle\DATAPUMP\
set ORACLE_HOME=C:\app\oracle\product\12.2.0\dbhome_1
set path=%ORACLE_HOME%\bin;%PATH%
set ORACLE_SID=JGUAR
set d=%DATE:~-4%-%DATE:~4,2%-%DATE:~7,2%
set t=%time::=.% 
set t=%t: =%
expdp \"/ as sysdba\" schemas=LOGO_HBYS directory=EXPDIR dumpfile=JGUAR_%d%_%t%.dmp logfile=JGUAR_%d%_%t%.log
zip D:\oracle\DATAPUMP\JGUAR_%d%_%t%.dmp.zip D:\oracle\DATAPUMP\JGUAR_%d%_%t%.dmp
REM expdp \"/ as sysdba\" full=Y directory=DUMP dumpfile=JGUAR_%date:~7,2%_%date:~4,2%_%date:~10,4%.dmp logfile=JGUAR_%date:~7,2%_%date:~4,2%_%date:~10,4%.log
REM copy  D:\oracle\DATAPUMP\*  D:\oracle\DATAPUMP\
REM copy  C:\app\oracle\DATAPUMP\*  E:\JGUAR_backup\datapump\
del D:\oracle\DATAPUMP\JGUAR_*.dmp
REM F:
REM cd F:\oracle\DATAPUMP\
forfiles -p "D:\oracle\DATAPUMP" -s -m JGUAR*.* -d -3 -c "cmd /c copy @file F:\oracle\DATAPUMP\"
forfiles -p "D:\oracle\DATAPUMP" -s -m JGUAR*.* -d -3 -c "cmd /c del @file"
F:
cd F:\oracle\DATAPUMP\
forfiles -p "F:\oracle\DATAPUMP\" -s -m JGUAR*.* -d -3 -c "cmd /c del @file"
