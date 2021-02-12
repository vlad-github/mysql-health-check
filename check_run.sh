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

### SETUP
HOSTNAME=`hostname -s`

MYSQL_HOST=localhost
MYSQL_USER=root
MYSQL_PASS=""
MYSQL_PORT=3306

usage()
{
	echo -e "\nUsage check_run.sh [--email <send-to@email-address>] | [--first-look ] | [--remote <host> ]"
}

if [ "$1" == '--email' ] ; then
	if [ ! -z "$2" ] ; then
		### send output to EMAIL provided
		EMAIL=$2
		./mysql_health_check.sh $HOSTNAME $MYSQL_HOST $MYSQL_USER "$MYSQL_PASS" $MYSQL_PORT | mail -s "$HOSTNAME MySQL health check report" $EMAIL
	else
		usage
		exit 1
	fi 
elif [ "$1" == '--first-look' ] || [ "$1" == '--initial-review' ] ; then
    echo "Starting complete report for $MYSQL_HOST ($HOSTNAME)"
    ./first_look.sh $HOSTNAME $MYSQL_HOST $MYSQL_USER "$MYSQL_PASS" $MYSQL_PORT
elif [ "$1" == '--remote' ] && [ ! -z "$2" ] ; then
    REMOTE=$2
    CDIR=${PWD##*/}
    echo "Running via SSH on $REMOTE:~/$CDIR..."
    ssh $REMOTE "mkdir -p $CDIR"
    SSH_RC=$?
    if [ ! $SSH_RC == 0 ] ; then
        echo "SSH failed. You need to have SSH access configured to $REMOTE"
        exit 2
    fi
    scp -r bin check_run.sh crontab.txt first_look.sh .gitignore mysql_counters mysql_health_check.sh mysql_query_review README $REMOTE:~/$CDIR
    SCP_RC=$?
    if [ ! $SCP_RC == 0 ] ; then
        echo "SCP failed. Can't copy files to $REMOTE~:/$CDIR"
        exit 2
    fi
    ssh -t $REMOTE "cd $CDIR && ./check_run.sh --first-look"
    scp $REMOTE:~/$CDIR/review*.tar.gz .
else
    echo "$HOSTNAME MySQL health check report"
    ./mysql_health_check.sh $HOSTNAME $MYSQL_HOST $MYSQL_USER "$MYSQL_PASS" $MYSQL_PORT

fi
