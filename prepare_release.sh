ssh on quark

cd /root/hc-dev/health_check

git pull

./release.sh <VERSION>

pscp root@quark:<REL> .

pscp root@quark:/root/hc-release/mysql-health-check-0.4a.tar.gz .

upload to SF