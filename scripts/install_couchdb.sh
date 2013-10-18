#!/usr/bin/env bash

# install the libraries which couchdb needs
apt-get install libicu-dev -y
apt-get install libtool -y
apt-get install erlang -y

# download and install spidermonkey 1.8.5
wget http://ftp.mozilla.org/pub/mozilla.org/js/js185-1.0.0.tar.gz
tar zxvf js185-1.0.0.tar.gz
cd js-1.8.5/js/src
./configure
make && make install
/sbin/ldconfig

# download and install couchdb
wget http://apache.mirror.rafal.ca/couchdb/source/1.4.0/apache-couchdb-1.4.0.tar.gz 
tar zxvf apache-couchdb-1.4.0.tar.gz
cd apache-couchdb-1.4.0
./configure
make && make check
make install

# clean up
rm -rf ~/stackato-couchdb
ln -s /s/vcap/services/couchdb/ stackato-couchdb

rm /s/vcap/services/couchdb/js185-1.0.0.tar.gz
rm -rf /s/vcap/services/couchdb/js-1.8.5
