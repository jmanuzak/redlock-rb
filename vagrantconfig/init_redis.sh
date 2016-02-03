#!/bin/bash

apt-get update > /dev/null

apt-get -y install make

mkdir /opt/redis

cd /opt/redis
# Use latest stable
wget http://download.redis.io/redis-stable.tar.gz
# Only update newer files
tar -xz --keep-newer-files -f redis-stable.tar.gz

cd redis-stable
make
make install
mkdir -p /etc/redis
mkdir /var/redis
chmod -R 777 /var/redis
useradd redis

sed "s/REDIS_PORT/6379/g" /tmp/redis.conf > /etc/redis/6379.conf
sed "s/REDIS_PORT/6380/g" /tmp/redis.conf > /etc/redis/6380.conf

sed "s/REDIS_PORT/6379/g" /tmp/redis.init.d > /etc/init.d/redis_6379
sed "s/REDIS_PORT/6380/g" /tmp/redis.init.d > /etc/init.d/redis_6380

update-rc.d redis_6379 defaults
update-rc.d redis_6380 defaults

chmod a+x /etc/init.d/redis_*

/etc/init.d/redis_6379 start
/etc/init.d/redis_6380 start
