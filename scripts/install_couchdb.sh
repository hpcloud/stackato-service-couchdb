#!/usr/bin/env bash

# Install prerequisites for couchdb to run
# apt-get update

# get couchdb
wget https://dl.dropboxusercontent.com/u/13515458/couchdb.tar.gz

# untar and put it in /opt/
tar -zxf couchdb.tar.gz
mv build-couchdb /opt/

# set correct permissions
chown --recursive stackato:stackato /opt/build-couchdb

#setup path
. /opt/build-couchdb/build/env.sh

# clean up source
rm couchdb.tar.gz
