#!/bin/bash

TODAY=$1

### SETUP
#PT_QUERY_DIGEST_BIN=

if [ -z "$TODAY" ]; then
TODAY=`date +%F`
fi

SLOW_LOG=/data/data/mysql-logs/slow.log
DIGEST=/data/data/mysql-logs/digests/$TODAY.digest
LOG_DAILY=/data/data/mysql-logs/digests/$TODAY.log

### pre flight
#mkdir -p /data/data/mysql-logs/digests/

### prepare
cat $SLOW_LOG >> $LOG_DAILY

### clear logs
echo "" > $SLOW_LOG
pt-query-digest --limit 5 $LOG_DAILY > $DIGEST

### send digest
echo -e "\n\n==== MySQL QUERY digest ===="
cat /data/data/mysql-logs/digests/$TODAY.digest
