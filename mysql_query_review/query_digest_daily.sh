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

TODAY=$1
MYSQL_HOST=$2
MYSQL_USER=$3
MYSQL_PASS=$4

### SETUP

if [ -z "$TODAY" ]; then
TODAY=`date +%F`
fi

SLOW_LOG=`mysql -h $MYSQL_HOST -u $MYSQL_USER --password=$MYSQL_PASS -BNe "SELECT @@GLOBAL.slow_query_log_file"`
if [ -z "$SLOW_LOG" ]; then
    echo "can't get query log file from @@GLOBAL.slow_query_log_file, please verify MySQL credentials"
    exit 3
fi
if [ ! -r $SLOW_LOG ]; then
    echo "can't read slow query log file: $SLOW_LOG"
    exit 5
fi

DIGEST_DIR=`dirname $SLOW_LOG`/digests
if [ ! -d $DIGEST_DIR ]; then
    mkdir -p $DIGEST_DIR
fi
if [ ! -d $DIGEST_DIR ]; then
    echo "Can't create digest directory: $DIGEST_DIR"
    exit 6
fi

DIGEST=$DIGEST_DIR/$TODAY.digest
LOG_DAILY=$DIGEST_DIR/$TODAY.log

### copy current log for processing
cat $SLOW_LOG >> $LOG_DAILY

### check if we can write to digest directory
if [ ! -w $LOG_DAILY ]; then
    echo "Can't create daily slow log. Can't write to digest dir: $DIGEST_DIR please help!"
    exit 7
fi

### clear logs
## FIXME unaccurate rotation
echo "" > $SLOW_LOG

### create query digest
./bin/pt-query-digest --noversion-check --limit 5 $LOG_DAILY > $DIGEST

### send digest to STDOUT
echo -e "\n\n==== MySQL slow queries report ===="
cat $DIGEST
