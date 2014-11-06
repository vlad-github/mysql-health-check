#!/bin/bash

HOST=$1
TODAY=`date +%y%m%d`

echo "HOST: $HOST"
w | grep load

echo -e "\n==== disks ===="
df -h

echo -e "\n==== memory ===="
free -m

echo -e "\n==== network ===="
netstat -i

echo -e "\n\n==== MySQL error log ===="
cat /var/log/mysql/error.log | grep $TODAY

### Run MySQL counters report
### 
echo -e "\n==== MySQL counters ===="
php -q ./mysql_counters/counters_report.php $HOST

### Run slow query digest
./mysql_query_review/query_digest_daily.sh $TODAY

