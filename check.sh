#!/bin/bash

host="ET14-MySQL-master"

TODAY=`date +%y%m%d`

echo "HOST: $host"
w | grep load
echo -e "\n==== disks ===="
df -h
echo -e "\n==== memory ===="
free -m
echo -e "\n==== network ===="
netstat -i

echo -e "\n\n==== MySQL error log ===="
cat /var/log/mysql/error.log | grep $TODAY

echo -e "\n==== MySQL counters ===="
/usr/bin/php -q ./counters_report.php

### Making slow query digest
/root/health_check/query_digest_daily.sh $TODAY

echo -e "\n\n==== QUERY digest ===="
cat /data/data/mysql-logs/digests/$TODAY.digest
