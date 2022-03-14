#!/bin/bash

# Copyright (c) 2009-2014 Vladimir Fedorkov (http://astellar.com/)
# All rights reserved.                                                         
#                                                                              
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# config
MNAME=$1
MHOST=$2
MUSER=$3
MPASS=$4
MPORT=$5

### Preparing for start
# Percona Tools path
PT_BIN_PATH="./bin"

### Checking credentials
### checking if there is stored MySQL password
mysql -e "SELECT 'Access check ok'"
if [ $? == 0 ] ; then
    ### great success! resetting connection string
    CMDL_DSN=""
else 
    ### checking provided credentials (might be empty)
    mysql -h $MHOST -u $MUSER --password=$MPASS --port=$MPORT -e "SELECT 1"
    if [ ! $? == 0 ] ; then
       # assuming wrong password. Asking for a new one
       echo "Assuming wrong credentials. Please enter correct mysql user and password"
       read -t 30 -p "Enter mysql user name:" MUSER
       read -s -t 30 -p "Enter mysql password:" MPASS
       echo " got it, restarting."
    fi
    CMDL_DSN=" -h $MHOST -u $MUSER --password=$MPASS --port=$MPORT"
fi
       
REVIEW_DIR="review_`hostname`_`date +%F_%H%M.%S`"

mkdir -p $REVIEW_DIR
if [ ! -d $REVIEW_DIR ]; then
    echo "Can't create output directory: $REVIEW_DIR"
    exit 1
fi

if [ "$MHOST" == 'localhost' ] || [ "$MHOST" == '127.0.0.1' ] || [ "$MHOST" == '0' ] ; then
    echo "Collecting local data (system summary) for host=$MHOST system name=$MNAME:"

    echo -n "Gathering system summary..."
    $PT_BIN_PATH/pt-summary > $REVIEW_DIR/sys-pt-summary.log

    echo -n "iostat..."
    iostat -dx 10 3 > $REVIEW_DIR/sys-iostat.log

    echo -n "vmstat..."
    vmstat 10 3 > $REVIEW_DIR/sys-vmstat.log
    echo "Done."
fi

echo "Collecting MySQL server data for host=$MHOST:"
echo -n "Mysql summary..."
$PT_BIN_PATH/pt-mysql-summary -- $CMDL_DSN > $REVIEW_DIR/db-mysql-summary.log

echo -n "Live counters (20 seconds)..."
mysqladmin $CMDL_DSN -r -c 3 -i 10 extended-status > $REVIEW_DIR/db-stats.log
echo "Done";

echo "Fetching MySQL tables and egines statistics:"

echo "1. Getting per-engine distribution..."
mysql -t $CMDL_DSN -e "SELECT engine, count(*) TABLES,  concat(round(sum(table_rows)/1000000,2),'M') rows, concat(round(sum(data_length)/(1024*1024*1024),2),'G') DATA, concat(round(sum(index_length)/(1024*1024*1024),2),'G') idx, concat(round(sum(data_length+index_length)/(1024*1024*1024),2),'G') total_size, round(sum(index_length)/sum(data_length),2) idxfrac FROM information_schema.TABLES WHERE table_schema NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys') GROUP BY engine ORDER BY sum(data_length+index_length) DESC LIMIT 10" > $REVIEW_DIR/db-engines.log

echo "2. Getting TOP 10 largest tables by size..."
mysql -t $CMDL_DSN -e "SELECT concat(table_schema,'.',table_name), engine,  concat(round(table_rows/1000000,2),'M') rows, concat(round(data_length/(1024*1024*1024),2),'G') DATA, concat(round(index_length/(1024*1024*1024),2),'G') idx, concat(round((data_length+index_length)/(1024*1024*1024),2),'G') total_size, round(index_length/data_length,2) idxfrac FROM information_schema.TABLES ORDER BY data_length+index_length DESC LIMIT 10" > $REVIEW_DIR/db-top-tables.log

echo "3. Getting tables size"
mysql -t $CMDL_DSN -e "SELECT concat(table_schema,'.',table_name), engine,  concat(round(table_rows/1000000,2),'M') rows, concat(round(data_length/(1024*1024*1024),2),'G') DATA, concat(round(index_length/(1024*1024*1024),2),'G') idx, concat(round((data_length+index_length)/(1024*1024*1024),2),'G') total_size, round(index_length/data_length,2) idxfrac FROM information_schema.TABLES WHERE table_schema NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys') ORDER BY table_schema ASC, data_length+index_length DESC" > $REVIEW_DIR/db-all-tables.log

echo "4. Getting current InnoDB engine status..."
mysql $CMDL_DSN -e "SHOW ENGINE INNODB STATUS\G" > $REVIEW_DIR/db-innodb.log

echo "5. Getting current process list..."
mysql $CMDL_DSN -e "SHOW PROCESSLIST\G" > $REVIEW_DIR/db-processlist.log

echo "6. Getting top queries"
mysql -t $CMDL_DSN -e "SELECT SCHEMA_NAME, SUBSTR(DIGEST_TEXT, 1, 380) as query,  COUNT_STAR, CONCAT('Rows scanned: ', SUM_ROWS_EXAMINED, ', Sent: ', SUM_ROWS_SENT) as rows_stats, ROUND(SUM_ROWS_SENT / COUNT_STAR, 6) as rows_per_query, FLOOR(SUM_ROWS_EXAMINED / SUM_ROWS_SENT) as index_rate,  CONCAT('Full scans: ', SUM_SELECT_SCAN, ', Range scans: ', SUM_SELECT_RANGE, ', Index scans: ', SUM_NO_INDEX_USED) as select_stats, CONCAT('Tmp tables: ', SUM_CREATED_TMP_TABLES, ', On disk tmp tables: ', SUM_CREATED_TMP_DISK_TABLES) as tmp_tables_stat, FIRST_SEEN, LAST_SEEN, ROUND(MAX_TIMER_WAIT / 1000000000000 , 6) as max_time, ROUND(SUM_TIMER_WAIT / COUNT_STAR / 1000000000000 , 6) as avg_time, ROUND(SUM_LOCK_TIME / COUNT_STAR / 1000000000000 , 6) as avg_lock_time FROM  performance_schema.events_statements_summary_by_digest  ORDER BY  SUM_TIMER_WAIT desc limit 10\G" > $REVIEW_DIR/db-top10queries-all.log
mysql -t $CMDL_DSN -e "SELECT SCHEMA_NAME, SUBSTR(DIGEST_TEXT, 1, 380) as query,  COUNT_STAR, CONCAT('Rows scanned: ', SUM_ROWS_EXAMINED, ', Sent: ', SUM_ROWS_SENT) as rows_stats, ROUND(SUM_ROWS_SENT / COUNT_STAR, 6) as rows_per_query, FLOOR(SUM_ROWS_EXAMINED / SUM_ROWS_SENT) as index_rate,  CONCAT('Full scans: ', SUM_SELECT_SCAN, ', Range scans: ', SUM_SELECT_RANGE, ', Index scans: ', SUM_NO_INDEX_USED) as select_stats, CONCAT('Tmp tables: ', SUM_CREATED_TMP_TABLES, ', On disk tmp tables: ', SUM_CREATED_TMP_DISK_TABLES) as tmp_tables_stat, FIRST_SEEN, LAST_SEEN, ROUND(MAX_TIMER_WAIT / 1000000000000 , 6) as max_time, ROUND(SUM_TIMER_WAIT / COUNT_STAR / 1000000000000 , 6) as avg_time, ROUND(SUM_LOCK_TIME / COUNT_STAR / 1000000000000 , 6) as avg_lock_time FROM  performance_schema.events_statements_summary_by_digest WHERE DIGEST_TEXT REGEXP '^(SELECT)' ORDER BY SUM_TIMER_WAIT desc limit 10\G" > $REVIEW_DIR/db-top10queries-read.log
mysql -t $CMDL_DSN -e "SELECT SCHEMA_NAME, SUBSTR(DIGEST_TEXT, 1, 380) as query,  COUNT_STAR, CONCAT('Rows scanned: ', SUM_ROWS_EXAMINED, ', Sent: ', SUM_ROWS_SENT) as rows_stats, ROUND(SUM_ROWS_SENT / COUNT_STAR, 6) as rows_per_query, FLOOR(SUM_ROWS_EXAMINED / SUM_ROWS_SENT) as index_rate,  CONCAT('Full scans: ', SUM_SELECT_SCAN, ', Range scans: ', SUM_SELECT_RANGE, ', Index scans: ', SUM_NO_INDEX_USED) as select_stats, CONCAT('Tmp tables: ', SUM_CREATED_TMP_TABLES, ', On disk tmp tables: ', SUM_CREATED_TMP_DISK_TABLES) as tmp_tables_stat, FIRST_SEEN, LAST_SEEN, ROUND(MAX_TIMER_WAIT / 1000000000000 , 6) as max_time, ROUND(SUM_TIMER_WAIT / COUNT_STAR / 1000000000000 , 6) as avg_time, ROUND(SUM_LOCK_TIME / COUNT_STAR / 1000000000000 , 6) as avg_lock_time FROM  performance_schema.events_statements_summary_by_digest WHERE DIGEST_TEXT REGEXP '^(INSERT|UPDATE|DELETE)' ORDER BY SUM_TIMER_WAIT desc limit 10\G" > $REVIEW_DIR/db-top10queries-write.log

echo "Done, paking data";
tar -zcvf $REVIEW_DIR.tar.gz $REVIEW_DIR/*

echo "Collected data is available in $REVIEW_DIR directory and as $REVIEW_DIR.tar.gz archive"
echo "For details please check http://astellar.com/mysql-health-check/initial-review-mode/"

