#!/bin/bash

TODAY=$1
MYSQL_HOST=$2
MYSQL_USER=$3
MYSQL_PASS=$4

### SETUP
#PT_QUERY_DIGEST_BIN=

if [ -z "$TODAY" ]; then
TODAY=`date +%F`
fi

SLOW_LOG=`mysql -h $MYSQL_HOST -u $MYSQL_USER --password=$MYSQL_PASS -BNe "SELECT @@GLOBAL.slow_query_log_file"`

if [ -z "$SLOW_LOG" ]; then
    echo "can't get query log file from @@GLOBAL.slow_query_log_file, please verify MySQL credentials"
    exit 3
fi


DIGEST_DIR=`dirname $SLOW_LOG`/digests
DIGEST=$DIGEST_DIR/$TODAY.digest
LOG_DAILY=$DIGEST_DIR/$TODAY.log

### pre flight
## TODO:
## FIXME check if directory exists
## FIXME check if pt-query-digest is in $PATH
mkdir -p $DIGEST_DIR

### prepare
cat $SLOW_LOG >> $LOG_DAILY

### clear logs
## FIXME unaccurate rotation
echo "" > $SLOW_LOG
./bin/pt-query-digest --limit 5 $LOG_DAILY > $DIGEST

### send digest
echo -e "\n\n==== MySQL QUERY digest ===="
cat $DIGEST
