#!/bin/bash

COUCHDB_VERSION=1.5.0

sudo apt-get update

# install the libraries which couchdb needs
sudo apt-get install -y build-essential
sudo apt-get install -y erlang-base-hipe
sudo apt-get install -y erlang-dev
sudo apt-get install -y erlang-manpages
sudo apt-get install -y erlang-eunit
sudo apt-get install -y erlang-nox
sudo apt-get install -y libicu-dev
sudo apt-get install -y libmozjs-dev
sudo apt-get install -y libcurl4-openssl-dev

# download couchdb source
wget http://apache.mirror.vexxhost.com/couchdb/source/$COUCHDB_VERSION/apache-couchdb-$COUCHDB_VERSION.tar.gz
tar zxvf apache-couchdb-$COUCHDB_VERSION.tar.gz
rm apache-couchdb-$COUCHDB_VERSION.tar.gz

# configure couchdb
cd apache-couchdb-$COUCHDB_VERSION
./configure --prefix=/opt/couchdb-$COUCHDB_VERSION

sudo mkdir -p "/opt/couchdb-$COUCHDB_VERSION/var/lib/couchdb"
sudo mkdir -p "/opt/couchdb-$COUCHDB_VERSION/var/log/couchdb"
sudo mkdir -p "/opt/couchdb-$COUCHDB_VERSION/var/run/couchdb"

# install couchdb
make && sudo make install

cd ../
rm -rf apache-couchdb-$COUCHDB_VERSION

# permissions
sudo chown -R stackato:stackato /opt/couchdb-$COUCHDB_VERSION
sudo chmod 0770 /opt/couchdb-$COUCHDB_VERSION

# upstart config

echo "# Upstart file at /etc/init/couchdb.conf
# CouchDB

start on runlevel [2345]
stop on runlevel [06]

script
   exec su stackato /opt/couchdb-$COUCHDB_VERSION/bin/couchdb
end script

respawn
respawn limit 10 5" > couchdb.conf

sudo mv couchdb.conf /etc/init
