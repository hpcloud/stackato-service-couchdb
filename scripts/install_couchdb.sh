#!/bin/bash

# ===== install the libraries which couchdb needs ===== #
sudo apt-get install erlang libicu42 libicu-dev libcurl4-openssl-dev


# ===== install Spidermonkey 1.9.2 from PPA ===== #
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 74EE6429
sudo bash -c 'echo "deb http://ppa.launchpad.net/commonjs/ppa/ubuntu karmic main" >> /etc/apt/sources.list.d/commonjs.list'
sudo apt-get update
sudo apt-get install libmozjs-1.9.2 libmozjs-1.9.2-dev
sudo ln -s /usr/lib/libmozjs-1.9.2.so /usr/lib/libmozjs.so


# ===== download and install couchdb ===== #
wget http://apache.mirror.rafal.ca/couchdb/source/1.4.0/apache-couchdb-1.4.0.tar.gz 
tar zxvf apache-couchdb-1.4.0.tar.gz
rm apache-couchdb-1.4.0.tar.gz
cd apache-couchdb-1.4.0
./configure
make
sudo make install


# ===== start couchdb ===== #
# couchdb -b -p /s/vcap/services/couchdb/couchdb.pid

# make dev