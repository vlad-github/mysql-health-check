#!/bin/bash

if [ -z "$1" ]; then
	echo "Usage: release.sh <VERSION>"
	exit 1
fi

REL_VERSION=$1
REL_NAME=mysql-health-check-$REL_VERSION

REL_DIR=/root/hc-release
DST=$REL_DIR/$REL_NAME

echo "Making MySQL Health Check release : $REL_NAME"

mkdir -p $DST

cp -r ./bin ./mysql_counters ./mysql_query_review $DST
cp check_run.sh crontab.txt mysql_health_check.sh README $DST

echo "Making archive"
cd $REL_DIR

tar -zcvf $REL_NAME.tar.gz $REL_NAME

echo $REL_DIR/$REL_NAME.tar.gz

