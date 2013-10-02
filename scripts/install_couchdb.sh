#!/usr/bin/env bash
VERSION="1.4"

# Install prerequisites for couchdb to run
# apt-get update

# Install couchdb to /opt
# wget https://download.couchdb.org/couchdb/couchdb/couchdb-$VERSION.tar.gz
tar -xzf couchdb-$VERSION.tar.gz
mv couchdb-$VERSION /opt/couchdb
chown --recursive stackato:stackato /opt/couchdb

# clean up installation
rm couchdb-$VERSION.tar.gz