--Tum durumlarda deger doner
set linesize 132;
set pagesize 100;
--set head off;
set feedback off;
column host format a12
column host_name format a12
column instance_name format a13
column uygulanan_son_zaman format a19
column current_time format a19
alter session set nls_date_format='YYYY-MM-DD HH24:MI:SS';
SET MARKUP HTML ON
spool /home/oracle/hc/hc_esso.html

-- db genel bilgiler
set head off;
select 'GENEL VERITABANI BILGILERI' from dual;
set head on;
select (select name from v$database) db_name,
(select count(*) from dba_data_files) DF_Sayisi,
(select round(sum(bytes/1024/1024/1024)) from dba_data_files) Toplam_DF_Size
,(select round(sum(bytes/1024/1024/1024)) from dba_segments) Toplam_Segment_Size
,(select round(sum(bytes/1024/1024/1024)) from dba_temp_files) Toplam_Temp_Size
 from dual;

--instance durumu
set head off;
select 'INSTANCE DURUMU' from dual;
set head on;
select INST_ID,INSTANCE_NAME,HOST_NAME,VERSION,STARTUP_TIME,STATUS,ARCHIVER,DATABASE_STATUS from gv$instance;

-- Standby guncelleme durumu
set head off;
select 'STANDBY VERITABANLARI GUNCELLEME DURUMU' from dual;
set head on;
SELECT  distinct a.thread#,  b. last_seq, a.applied_seq, a. last_app_timestamp, b.last_seq-a.applied_seq   ARC_DIFF FROM
     ( select thread#,sequence# applied_seq, next_time last_app_timestamp from gv$archived_log c,  (SELECT thread# th, MAX(next_time) last_app_timestamp FROM gv$archived_log WHERE applied = 'YES' GROUP BY thread#) d where   d.last_app_timestamp=c.NEXT_TIME and c.thread#=d.th) a, 
              (select thread#,sequence# last_seq, next_time last_app_timestamp from gv$archived_log c,  (SELECT thread# th, MAX(next_time) last_app_timestamp FROM gv$archived_log GROUP BY thread#) d where   d.last_app_timestamp=c.NEXT_TIME and c.thread#=d.th) b WHERE a.thread# = b.thread#;

 
 
-- backup
set head off;
select 'BACKUPLAR' from dual;
set head on;
select SESSION_KEY"Session", INPUT_TYPE, STATUS,
  start_time  "Start",output_bytes_display "Size",TIME_TAKEN_DISPLAY "Time Taken"
 from V$RMAN_BACKUP_JOB_DETAILS where start_time>sysdate-1
 order by session_key desc;

select device_type,handle,start_time,completion_time from v$backup_piece where start_time>sysdate-1 order by start_time desc;

 -- tablespace kontrol
set head off;
select 'TABLESPACE KONTROL' from dual;
set head on;
 select
   a.tablespace_name,
  -- a.bytes_alloc/(1024*1024) "TOTAL ALLOC (MB)",
   --a.physical_bytes/(1024*1024) "TOTAL PHYS ALLOC (MB)",
   round(nvl(b.tot_used,0)/(1024*1024*1024),1) "SIZE (GB)",
   round((nvl(b.tot_used,0)/a.bytes_alloc)*100,1) "% USED"
from
   (select tablespace_name,
      sum(bytes) physical_bytes,
      sum(decode(autoextensible,'NO',bytes,'YES',maxbytes)) bytes_alloc
    from
      dba_data_files
    group by
      tablespace_name ) a,
   (select
      tablespace_name,
      sum(bytes) tot_used
    from
      dba_segments
    group by
      tablespace_name ) b
where
   a.tablespace_name = b.tablespace_name (+)
and
   a.tablespace_name not in
   (select distinct
       tablespace_name
    from
       dba_temp_files)
and  a.tablespace_name not like 'UNDO%' --and (nvl(b.tot_used,0)/a.bytes_alloc)*100>80
order by 3 desc;

--asm doluluk orani
set head off;
select 'ASM DURUMU' from dual;
set head on;
SELECT g.group_number  "Group"
,      g.name          "Group Name"
,      count(*)        "DiskCnt"
,      g.state         "State"
,      g.type          "Type"
,      round(g.total_mb/1024,1) "Total GB"
,      round(g.free_mb/1024,1)  "Free GB"
,      round(100-round(g.free_mb/1024,1)*100/round(g.total_mb/1024,1),1)  "% USED"
,      round(g.USABLE_FILE_MB/1024,1)  "USABLE FILE GB"
FROM v$asm_disk d, v$asm_diskgroup g
WHERE d.group_number = g.group_number and
d.group_number <> 0 and
d.state = 'NORMAL' and
d.mount_status = 'CACHED'
GROUP BY g.group_number, g.name, g.state, g.type, g.total_mb, g.free_mb,g.USABLE_FILE_MB
ORDER BY 1;  

--fra kullanimi
set head off;
select 'FRA KULLANIMI' from dual;
set head on;
select * from v$recovery_area_usage;

--Block Corruption
set head off;
select 'Block Corruption' from dual;
 select FILE#,CORRUPTION_TYPE from V$DATABASE_BLOCK_CORRUPTION;
--ora hatalari
set head off;
select 'ALERT.LOG ORA HATALARI' from dual;
set head on;

SELECT  originating_timestamp, MESSAGE_TEXT
        FROM v$diag_alert_ext
          WHERE     originating_timestamp > (SYSDATE - 7)
            AND MESSAGE_TEXT LIKE '%ORA-%' 
            ORDER BY originating_timestamp;
set head off;
select 'DB RESPONSE TIME' from dual;
set head on;
select  CASE METRIC_NAME
            WHEN 'SQL Service Response Time' then 'SQL Service Response Time (secs)'
            WHEN 'Response Time Per Txn' then 'Response Time Per Txn (secs)'
            ELSE METRIC_NAME
            END METRIC_NAME,
                CASE METRIC_NAME
            WHEN 'SQL Service Response Time' then ROUND((MINVAL / 100),2)
            WHEN 'Response Time Per Txn' then ROUND((MINVAL / 100),2)
            ELSE MINVAL
            END MININUM,
                CASE METRIC_NAME
            WHEN 'SQL Service Response Time' then ROUND((MAXVAL / 100),2)
            WHEN 'Response Time Per Txn' then ROUND((MAXVAL / 100),2)
            ELSE MAXVAL
            END MAXIMUM,
                CASE METRIC_NAME
            WHEN 'SQL Service Response Time' then ROUND((AVERAGE / 100),2)
            WHEN 'Response Time Per Txn' then ROUND((AVERAGE / 100),2)
            ELSE AVERAGE
            END AVERAGE
from    SYS.V_$SYSMETRIC_SUMMARY 
where   METRIC_NAME in ('CPU Usage Per Sec',
                      'CPU Usage Per Txn',
                      'Database CPU Time Ratio',
                      'Database Wait Time Ratio',
                      'Executions Per Sec',
                      'Executions Per Txn',
                      'Response Time Per Txn',
                      'SQL Service Response Time',
                      'User Transaction Per Sec')
ORDER BY 1;

--bekleyen islemler
set head off;
select 'BEKLEYEN ISLEMLER' from dual;
set head on;
SELECT * FROM DBA_2PC_PENDING;

 
--degisen parametreler
set head off;
select 'DEGISEN PARAMETRELERIN IZLENMESI' from dual;
set head on;

select instance_number instance--, snap_id
, time, parameter_name, old_value, new_value from (
select --a.snap_id,
to_char(end_interval_time,'DD-MON-YY HH24:MI') TIME, a.instance_number, parameter_name, value new_value, 
lag(parameter_name,1) over (partition by parameter_name, a.instance_number order by a.snap_id) old_pname,
lag(value,1) over (partition by parameter_name, a.instance_number order by a.snap_id)old_value ,
decode(substr(parameter_name,1,2),'__',2,1) calc_flag
from dba_hist_parameter a, dba_Hist_snapshot b , gv$instance v
where a.snap_id=b.snap_id 
and a.instance_number=b.instance_number
) 
where 
new_value != old_value
--and parameter_name not like '__%'
--and instance_number=1
order by 1,2;

-- okuma ve yazma bilgileri
set head off;
select 'FIZIKSEL OKUMA VE YAZMA DEGERLERI' from dual;
set head on;
SELECT a.tablespace_name,
       a.file_id,
       a.file_name,
       b.phyrds,
              ROUND (100 * (b.phyrds / c.phyrds), 2) read_orani  ,
        b.phywrts,
              ROUND (100 * (b.phywrts / c.phywrts), 2) wrt_orani          
  FROM v$filestat b,
       dba_data_files a,
       (SELECT SUM (phyrds) phyrds, SUM (phywrts) phywrts FROM v$filestat) c
 WHERE b.file# = a.file_id
ORDER BY 5 DESC;

-- wait eventler
set head off;
select 'WAIT EVENTLER' from dual;
set head on;
SELECT   
   wait_class, 
   NAME, 
   ROUND (time_secs, 2) time_secs,
   ROUND (time_secs * 100 / SUM (time_secs) OVER (), 2) pct
FROM 
   (SELECT 
      n.wait_class, 
      e.event NAME, 
      e.time_waited / 100 time_secs
    FROM 
      v$system_event e, 
      v$event_name n
    WHERE 
       n.NAME = e.event AND n.wait_class <> 'Idle'
    AND 
       time_waited > 0
    UNION
    SELECT 
      'CPU', 
      'server CPU', 
      SUM (VALUE / 1000000) time_secs
    FROM 
      v$sys_time_model
   -- WHERE stat_name IN ('background cpu time', 'DB CPU')
      )
ORDER BY 
   time_secs DESC;

-- user bazinda cpu tuketimi
set head off;
select 'USER BAZINDA CPU TUKETIMI' from dual;
set head on;
select ss.username, sum(VALUE/100) cpu_usage_seconds
from v$session ss, v$sesstat se, v$statname sn
where se.STATISTIC# = sn.STATISTIC#
--and NAME like '%CPU used by this session%'
and se.SID = ss.SID --and ss.status='ACTIVE'
and ss.username is not null
group by ss.username;


-- chained rows
set head off;
select 'CHAINED ROWS' from dual;
set head on;
select 
   owner              c1, 
   table_name         c2, 
   pct_free           c3, 
   pct_used           c4, 
   avg_row_len        c5, 
   num_rows           c6, 
   chain_cnt          c7,
   chain_cnt/num_rows c8
from dba_tables
where
owner not in ('SYS','SYSTEM')
and
table_name not in
 (select table_name from dba_tab_columns
   where
 data_type in ('RAW','LONG RAW')
 )
and
chain_cnt > 0
order by chain_cnt desc
;



--Disk Reads
set head off;
select 'DISK READ YAPAN SQL LER' from dual;
set head on;
SELECT module,
       sql_text,
       disk_reads_per_exec,
       buffer_gets,
       disk_reads,
       executions,
       hit_ratio,
       cpu_time
        FROM (
          SELECT module,
          sql_text,
          u.username,
          ROUND ( (s.disk_reads / DECODE (s.executions, 0, 1, s.executions)),2) disk_reads_per_exec,
          s.disk_reads,
          s.buffer_gets,
          s.parse_calls,
          s.sorts,
          s.executions,
          s.rows_processed,
          100 - ROUND (100 * s.disk_reads / GREATEST (s.buffer_gets, 1), 2) hit_ratio,
          s.first_load_time,
          sharable_mem,
          persistent_mem,
          runtime_mem,
          cpu_time,
          elapsed_time,
          address,
          hash_value FROM sys.v_$sql s,sys.all_users u
WHERE s.parsing_user_id=u.user_id and UPPER(u.username) not in ('SYS','SYSTEM') ORDER BY 4 desc) WHERE rownum <= 20;

--invalid objects

set head off;
select 'INVALID OBJELER' from dual;
set head on;

SELECT   owner,object_type,object_name  FROM dba_objects
 WHERE status = 'INVALID'
 order by 2,1; 


-- ANALYZE job
set head off;
select 'JOB ANALIZi' from dual;
set head on;

SELECT sid, job, instance FROM dba_jobs_running;
SELECT next_date,broken,interval,what FROM dba_jobs;
SELECT job_name,enabled,restartable,run_count,failure_count,last_start_date,next_run_date FROM DBA_SCHEDULER_JOBS;
SELECT job_name,status,log_date FROM DBA_SCHEDULER_JOB_LOG where log_date>=sysdate-30 and status<>'SUCCEEDED' order by log_date desc;





-- sAATlik arsiv dagilimi
set head off;
select 'ARCIVELOG OLUSMA BILGISI' from dual;
set head on;
select inst_id,--to_char(first_time,'DD-MON-RR') "Date",
trunc(first_time) "Date",
to_char(sum(decode(to_char(first_time,'HH24'),'00',1,0)),'999') " 00",
to_char(sum(decode(to_char(first_time,'HH24'),'01',1,0)),'999') " 01",
to_char(sum(decode(to_char(first_time,'HH24'),'02',1,0)),'999') " 02",
to_char(sum(decode(to_char(first_time,'HH24'),'03',1,0)),'999') " 03",
to_char(sum(decode(to_char(first_time,'HH24'),'04',1,0)),'999') " 04",
to_char(sum(decode(to_char(first_time,'HH24'),'05',1,0)),'999') " 05",
to_char(sum(decode(to_char(first_time,'HH24'),'06',1,0)),'999') " 06",
to_char(sum(decode(to_char(first_time,'HH24'),'07',1,0)),'999') " 07",
to_char(sum(decode(to_char(first_time,'HH24'),'08',1,0)),'999') " 08",
to_char(sum(decode(to_char(first_time,'HH24'),'09',1,0)),'999') " 09",
to_char(sum(decode(to_char(first_time,'HH24'),'10',1,0)),'999') " 10",
to_char(sum(decode(to_char(first_time,'HH24'),'11',1,0)),'999') " 11",
to_char(sum(decode(to_char(first_time,'HH24'),'12',1,0)),'999') " 12",
to_char(sum(decode(to_char(first_time,'HH24'),'13',1,0)),'999') " 13",
to_char(sum(decode(to_char(first_time,'HH24'),'14',1,0)),'999') " 14",
to_char(sum(decode(to_char(first_time,'HH24'),'15',1,0)),'999') " 15",
to_char(sum(decode(to_char(first_time,'HH24'),'16',1,0)),'999') " 16",
to_char(sum(decode(to_char(first_time,'HH24'),'17',1,0)),'999') " 17",
to_char(sum(decode(to_char(first_time,'HH24'),'18',1,0)),'999') " 18",
to_char(sum(decode(to_char(first_time,'HH24'),'19',1,0)),'999') " 19",
to_char(sum(decode(to_char(first_time,'HH24'),'20',1,0)),'999') " 20",
to_char(sum(decode(to_char(first_time,'HH24'),'21',1,0)),'999') " 21",
to_char(sum(decode(to_char(first_time,'HH24'),'22',1,0)),'999') " 22",
to_char(sum(decode(to_char(first_time,'HH24'),'23',1,0)),'999') " 23"
from gv$log_history where trunc(first_time)>=trunc(sysdate) -7
group by inst_id,trunc(first_time)
order by 1,2 desc;




-- Cache hit percentage
set head off;
select 'CACHE HIT YUZDESI' from dual;
set head on;
   select v3.value ,v1.value , v2.value,
    100*(1 - (v3.value / (v1.value + v2.value))) "Cache Hit Ratio [%]"
from
  v$sysstat v1, v$sysstat v2, v$sysstat v3
where
  v1.name = 'db block gets from cache' and
  v2.name = 'consistent gets from cache' and
  v3.name = 'physical reads cache';
set head off;
select 'PGA CACHE HIT DEGERI' from dual;
set head on;
  select * from v$pgastat 
  where name in ('aggregate PGA target parameter','total PGA inuse','total PGA allocated','maximum PGA allocated','cache hit percentage')
  order by value desc;
    
-- Redologlarin durumu
set head off;
select 'REDOLOG BILGISI' from dual;
set head on;
select group#,type,member from v$logfile where type='ONLINE' order by 1;

-- default password taramasi
set head off;
select 'DEFAULT PASSWORD TARAMASI' from dual;
set head on;
SELECT username,account_status
  FROM dba_users
 WHERE username IN
          ('EXFSYS',
           'MDSYS',
           'ORDPLUGINS',
           'ORDSYS',
           'OUTLN',
           'SI_INFORMTN_SCHEMA',
           'WMSYS',
           'XDB');

-- DBA rolune sahip kullanicilar
set head off;
select 'DBA ROLUNE SAHIP KULLANICILAR' from dual;
set head on;
select GRANTEE,GRANTED_ROLE,ADMIN_OPTION,DEFAULT_ROLE from dba_role_privs WHERE GRANTED_ROLE='DBA';

-- sysdba rolune sahip kullanicilar
set head off;
select 'SYSDBA ROLUNE SAHIP KULLANICILAR' from dual;
set head on;
SELECT inst_id,username,sysdba,sysoper FROM gv$pwfile_users;

-- Any hakkina sahip kullanicilar
set head off;
select 'ANY HAKKINA SAHIP KULLANICILAR' from dual;
set head on;
  SELECT grantee, privilege, admin_option
    FROM dba_sys_PRIVS
   WHERE     privilege LIKE '%ANY%'
         AND grantee NOT LIKE '%SYS%'
         AND GRANTEE NOT IN ('CLOG', 'DBTOOLS')
         AND GRANTEE IN (SELECT username
                           FROM dba_users
                          WHERE account_status = 'OPEN')
ORDER BY 1;

-- parametreler
set head off;
select 'DATABASE PARAMETRELERI' from dual;
set head on;
select inst_id,name,value,description from gv$parameter where value is not null;


SET MARKUP HTML OFF SPOOL OFF

exit;
